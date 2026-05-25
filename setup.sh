#!/usr/bin/env bash
#
# Dotfiles setup — idempotent symlink installer.
# Run once; safe to re-run to pick up newly added entries.
#
# Config file mappings:
#
# $HOME
# ├── .zshrc                        → DOTFILES/.zshrc
# ├── .zsh_aliases                  → DOTFILES/.zsh_aliases
# ├── .config/
# │   ├── nvim/                     → DOTFILES/.config/nvim/
# │   ├── sheldon/
# │   │   └── plugins.toml          → DOTFILES/.config/sheldon/plugins.toml
# │   └── starship.toml             → DOTFILES/.config/starship.toml
#
# Binaries (managed by update-apps.sh, symlinked from DOTFILES/.local/):
#
# $HOME/.local/bin/<name>           → DOTFILES/.local/bin/<name>
# $HOME/.local/lib/<name>           → DOTFILES/.local/lib/<name>
# $HOME/.local/share/<name>         → DOTFILES/.local/share/<name>

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

symlink() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok       $dst"
        return
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "  backup   $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi

    ln -s "$src" "$dst"
    echo "  linked   $dst → $src"
}

echo "Dotfiles: $DOTFILES"
echo

# Config files
symlink "$DOTFILES/.zshrc"                       "$HOME/.zshrc"
symlink "$DOTFILES/.zsh_aliases"                 "$HOME/.zsh_aliases"
symlink "$DOTFILES/.config/starship.toml"        "$HOME/.config/starship.toml"
symlink "$DOTFILES/.config/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
symlink "$DOTFILES/.config/nvim"                 "$HOME/.config/nvim"

# Binaries and support dirs from .local/
for subdir in bin lib share; do
    src_dir="$DOTFILES/.local/$subdir"
    [ -d "$src_dir" ] || continue
    for src in "$src_dir"/*; do
        [ -e "$src" ] || continue
        symlink "$src" "$HOME/.local/$subdir/$(basename "$src")"
    done
done

echo
echo "Done."
