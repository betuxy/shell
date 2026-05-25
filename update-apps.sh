#!/usr/bin/env bash
#
# Download/update binaries from GitHub releases into the repo's .local/ tree.
# Reads applications.txt for the list of apps.
# Run setup.sh afterwards to symlink them into ~/.local/.
#
# Usage:
#   ./update-apps.sh             # update all apps
#   ./update-apps.sh nvim fzf   # update specific apps only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_FILE="$SCRIPT_DIR/applications.txt"
INSTALL_DIR="$SCRIPT_DIR/.local/bin"
CHANGELOG_JSON_FILE="$SCRIPT_DIR/CHANGELOG.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

# Resolve a GitHub token: prefer $GITHUB_TOKEN, fall back to gh CLI.
resolve_github_token() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        return
    fi
    if command -v gh &>/dev/null; then
        local token
        token="$(gh auth token 2>/dev/null || true)"
        [ -n "$token" ] && export GITHUB_TOKEN="$token"
    fi
}

resolve_github_token

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Append an update entry to CHANGELOG.json.
write_changelog() {
    local name="$1" repo="$2" version="$3"
    printf '{"timestamp":"%s","name":"%s","repo":"%s","version":"%s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$name" "$repo" "$version" >> "$CHANGELOG_JSON_FILE"
}

# Ordered list of arch strings to try against release filenames.
arch_candidates() {
    case "$(uname -m)" in
        x86_64)  printf '%s\n' x86_64 amd64 x86-64 ;;
        aarch64) printf '%s\n' aarch64 arm64 ;;
        armv7l)  printf '%s\n' armv7 armhf arm ;;
        *)       printf '%s\n' "$(uname -m)" ;;
    esac
}

# Fetch the latest release for owner/repo.
# Output: line 1 = tag_name, remaining lines = asset download URLs.
github_release() {
    local repo="$1"
    local json
    json="$(curl -fsSL \
        ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$repo/releases/latest")"
    printf '%s\n' "$json" \
        | grep -o '"tag_name": *"[^"]*"' \
        | sed 's/.*"tag_name": *"//;s/"//'
    printf '%s\n' "$json" \
        | grep -o '"browser_download_url": *"[^"]*"' \
        | sed 's/.*"browser_download_url": *"//;s/"//'
}

# Choose the best asset URL for the current OS/arch.
pick_asset() {
    local assets="$1"
    local arch

    while IFS= read -r arch; do
        local match
        match="$(printf '%s\n' "$assets" \
            | grep -i linux \
            | grep -iv android \
            | grep -i "$arch" \
            | grep -Ev '\.(sha256|sha512|md5|asc|sig|deb|rpm|apk|dmg|exe|msi)$' \
            | grep -E '\.(tar\.gz|tar\.xz|tar\.bz2|tgz|zip)$' \
            | head -1)"
        if [ -n "$match" ]; then
            printf '%s\n' "$match"
            return 0
        fi
    done < <(arch_candidates)

    # Last resort: AppImage
    printf '%s\n' "$assets" | grep -i AppImage | head -1 || true
}

# Download an asset, extract it, and install into the repo's .local/ tree.
install_asset() {
    local name="$1"
    local url="$2"
    local filename
    filename="$(basename "$url")"
    local download="$TMP_DIR/$filename"
    local extract="$TMP_DIR/${name}_extract"

    printf '  downloading %s\n' "$filename"
    curl -fsSL --progress-bar -o "$download" "$url"

    mkdir -p "$extract"

    case "$filename" in
        *.tar.gz|*.tgz) tar -xzf "$download" -C "$extract" ;;
        *.tar.xz)        tar -xJf "$download" -C "$extract" ;;
        *.tar.bz2)       tar -xjf "$download" -C "$extract" ;;
        *.zip)           unzip -q  "$download" -d "$extract" ;;
        *.AppImage)
            install -m755 "$download" "$INSTALL_DIR/$name"
            printf '  installed  %s (AppImage)\n' "$name"
            return 0
            ;;
    esac

    # If the archive has a standard FHS tree (bin/<name>, lib/, share/), install the whole tree.
    local bin_in_tree
    bin_in_tree="$(find "$extract" -type f -name "$name" -path "*/bin/$name" -perm /111 2>/dev/null | head -1)"
    if [ -n "$bin_in_tree" ]; then
        local tree_root
        tree_root="$(dirname "$(dirname "$bin_in_tree")")"
        cp -a "$tree_root/." "$SCRIPT_DIR/.local/"
        printf '  installed  %s (tree) → .local/\n' "$name"
        return 0
    fi

    # Single binary install.
    local binary
    binary="$(find "$extract" -type f -name "$name" -perm /111 2>/dev/null | head -1)"
    if [ -z "$binary" ]; then
        binary="$(find "$extract" -maxdepth 4 -type f -perm /111 \
            ! -name '*.so' ! -name '*.so.*' 2>/dev/null | head -1)"
    fi

    if [ -z "$binary" ]; then
        printf '  ERROR: no executable found for %s in %s\n' "$name" "$filename" >&2
        return 1
    fi

    install -m755 "$binary" "$INSTALL_DIR/$name"
    printf '  installed  %s → .local/bin/%s\n' "$binary" "$name"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

mkdir -p "$INSTALL_DIR"

if [ ! -f "$APPS_FILE" ]; then
    printf 'Error: %s not found\n' "$APPS_FILE" >&2
    exit 1
fi

# Build set of names to process (empty = all)
wanted=("$@")

while IFS= read -r line || [ -n "$line" ]; do
    # skip blank lines and comments
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue

    read -r name repo asset_hint <<< "$line"
    [ -z "${name:-}" ] || [ -z "${repo:-}" ] && continue

    # filter by args if provided
    if [ "${#wanted[@]}" -gt 0 ]; then
        skip=1
        for w in "${wanted[@]}"; do
            [ "$w" = "$name" ] && skip=0 && break
        done
        [ "$skip" -eq 1 ] && continue
    fi

    printf '\n[%s] %s\n' "$name" "$repo"

    release="$(github_release "$repo")" || { printf '  ERROR: GitHub API request failed\n' >&2; continue; }
    release_tag="$(printf '%s\n' "$release" | head -1)"
    assets="$(printf '%s\n' "$release" | tail -n +2)"

    if [ -z "$assets" ]; then
        printf '  ERROR: no assets found\n' >&2
        continue
    fi

    if [ -n "${asset_hint:-}" ]; then
        url="$(printf '%s\n' "$assets" | grep -i "$asset_hint" | head -1)"
    else
        url="$(pick_asset "$assets")"
    fi

    if [ -z "${url:-}" ]; then
        printf '  ERROR: no matching asset for arch=%s\n' "$(uname -m)" >&2
        printf '  available assets:\n' >&2
        printf '%s\n' "$assets" | sed 's/^/    /' >&2
        continue
    fi

    already_installed=0
    [ -f "$INSTALL_DIR/$name" ] && already_installed=1

    install_asset "$name" "$url"

    if [ "$already_installed" -eq 1 ] && [ -n "$release_tag" ]; then
        write_changelog "$name" "$repo" "$release_tag"
        printf '  changelog  → %s\n' "$release_tag"
    fi

done < "$APPS_FILE"

printf '\nDone.\n'
