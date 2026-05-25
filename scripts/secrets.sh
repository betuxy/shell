#!/usr/bin/env bash
#
# Manage encrypted secrets using age (https://age-encryption.org).
#
# Usage:
#   ./secrets.sh init          # create the encrypted secrets file
#   ./secrets.sh edit          # decrypt, open in $EDITOR, re-encrypt
#   ./secrets.sh load          # print export statements for eval
#                              # eval "$(./secrets.sh load)"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_FILE="$SCRIPT_DIR/secrets.age"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
    command -v "$1" &>/dev/null || die "'$1' not found — install it with: sudo apt install age"
}

cmd="${1:-}"

case "$cmd" in

    init)
        require_cmd age
        [ -f "$SECRETS_FILE" ] && die "secrets file already exists — run './secrets.sh edit' to modify it"

        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT

        cat > "$tmp" <<'EOF'
# One KEY=VALUE pair per line. Lines starting with # are ignored.
# Example:
# GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
EOF

        ${EDITOR:-vi} "$tmp"
        age --passphrase -o "$SECRETS_FILE" "$tmp"
        printf 'Secrets encrypted to %s — commit it to git.\n' "$SECRETS_FILE"
        ;;

    edit)
        require_cmd age
        [ -f "$SECRETS_FILE" ] || die "no secrets file found — run './secrets.sh init' first"

        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT

        age --decrypt -o "$tmp" "$SECRETS_FILE"
        ${EDITOR:-vi} "$tmp"
        age --passphrase -o "$SECRETS_FILE" "$tmp"
        printf 'Secrets updated.\n'
        ;;

    load)
        require_cmd age
        [ -f "$SECRETS_FILE" ] || die "no secrets file found — run './secrets.sh init' first"

        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            printf 'export %s\n' "$line"
        done < <(age --decrypt "$SECRETS_FILE")
        ;;

    *)
        printf 'Usage: %s {init|edit|load}\n' "$(basename "$0")" >&2
        exit 1
        ;;

esac
