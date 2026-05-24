#!/usr/bin/env bash
#
# Dotfiles setup — idempotent symlink installer.
# Run once; safe to re-run to pick up newly added entries.
#
# File mappings:
#
# $HOME
# ├── .zshrc                        → DOTFILES/.config/.zshrc
# ├── .zsh_aliases                  → DOTFILES/.config/.zsh_aliases
# ├── .config/
# │   ├── nvim/                     → DOTFILES/.config/nvim/
# │   ├── sheldon/
# │   │   └── plugins.toml          → DOTFILES/.config/sheldon/plugins.toml
# │   └── starship.toml             → DOTFILES/.config/starship.toml
# └── .local/
#     └── bin/
#         └── nvim                  → DOTFILES/.local/bin/nvim
# (other binaries in ~/.local/bin/ are managed by update-apps.sh)

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

symlink "$DOTFILES/.config/.zshrc"               "$HOME/.zshrc"
symlink "$DOTFILES/.config/.zsh_aliases"         "$HOME/.zsh_aliases"
symlink "$DOTFILES/.config/starship.toml"        "$HOME/.config/starship.toml"
symlink "$DOTFILES/.config/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
symlink "$DOTFILES/.config/nvim"                 "$HOME/.config/nvim"
symlink "$DOTFILES/.local/bin/nvim"              "$HOME/.local/bin/nvim"

echo
echo "Done."
