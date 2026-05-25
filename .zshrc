# p10k instant prompt — must be at the very top before any output
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----------------------------
# Dotfiles self-check
# If this .zshrc is a symlink into the dotfiles repo, verify that all other
# expected symlinks are in place and run setup.sh automatically if any are
# missing. This makes the setup idempotent across machines and re-runs.
# ----------------------------
_df_zshrc="${HOME}/.zshrc"
if [ -L "$_df_zshrc" ]; then
    _df_repo="$(dirname "$(readlink "$_df_zshrc")")"
    _df_missing=0
    for _df_link in \
        "${HOME}/.zsh_aliases" \
        "${HOME}/.config/starship.toml" \
        "${HOME}/.config/sheldon/plugins.toml" \
        "${HOME}/.config/nvim" \
        "${HOME}/.local/bin/nvim"
    do
        [ -L "$_df_link" ] || _df_missing=1
    done
    if [ "$_df_missing" -eq 1 ] && [ -f "$_df_repo/setup.sh" ]; then
        echo "[dotfiles] Missing symlinks detected — running setup.sh..."
        bash "$_df_repo/setup.sh"
    fi
    unset _df_repo _df_missing _df_link
fi
unset _df_zshrc

# ----------------------------
# Applications check
# Warn if any binary from applications.txt is missing from ~/.local/bin
# ----------------------------
_df_zshrc="${HOME}/.zshrc"
if [ -L "$_df_zshrc" ]; then
    _df_repo="$(dirname "$(readlink "$_df_zshrc")")"
    _df_apps="${_df_repo}/applications.txt"
    if [ -f "$_df_apps" ]; then
        _df_missing_apps=()
        while IFS= read -r _df_line; do
            [[ "$_df_line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${_df_line// }" ]] && continue
            _df_app="${_df_line%%[[:space:]]*}"
            [ -f "${HOME}/.local/bin/${_df_app}" ] || _df_missing_apps+=("$_df_app")
        done < "$_df_apps"
        if [ "${#_df_missing_apps[@]}" -gt 0 ]; then
            echo "[dotfiles] Missing apps in ~/.local/bin: ${_df_missing_apps[*]}"
            echo "[dotfiles] Run update-apps.sh to install them."
        fi
        unset _df_missing_apps _df_app _df_line
    fi
    unset _df_apps _df_repo
fi
unset _df_zshrc

# ----------------------------
# Variables / environment
# ----------------------------
export PATH="${PATH}:${HOME}/bin:${HOME}/.local/bin:/usr/local/bin:${HOME}/.cargo/bin:/${HOME}/go/bin"
export EDITOR="nvim"
export HISTTIMEFORMAT="%d/%m/%y %T "
export errno="2> /dev/null"
export WORDCHARS=''

export GOROOT=/usr/local/go
export GOPATH=$HOME/go

# ----------------------------
# History settings
# ----------------------------
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=15000
SAVEHIST=15000

setopt SHARE_HISTORY
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt nonomatch

# ----------------------------
# Completion styles
# Set these BEFORE compinit
# ----------------------------
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:*:ssh:*:*' known-hosts-files "${HOME}/.ssh/known_hosts"
zstyle ':fzf-tab:*' fzf-command fzf

# ----------------------------
# Enable completion
# ----------------------------
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
autoload -Uz compinit
compinit

# ----------------------------
# History search widgets
# ----------------------------
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA'  up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB'  down-line-or-beginning-search

# ----------------------------
# Word movement
# ----------------------------
# Ctrl + Left / Right
# bindkey '^[[1;5D' backward-word
# bindkey '^[[1;5C' forward-word

# Alt + Left / Right
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# ----------------------------
# Local python3 venv
# ----------------------------
if [ -d "${HOME}/venv/bin" ]; then
    source "${HOME}/venv/bin/activate"
fi

# ----------------------------
# Tool init
# ----------------------------
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi


# ----------------------------
# Plugin manager
# Must come AFTER compinit
# ----------------------------
if command -v sheldon >/dev/null 2>&1; then
    eval "$(sheldon source)"
fi

# ----------------------------
# fzf
# ----------------------------
[ -f "${HOME}/.fzf.zsh" ] && source "${HOME}/.fzf.zsh"

# ----------------------------
# Aliases / custom completions
# ----------------------------
if [ -f "${HOME}/.zsh_aliases" ]; then
    source "${HOME}/.zsh_aliases"
fi

if [ -f "${HOME}/.zsh_completions" ]; then
    source "${HOME}/.zsh_completions"
fi

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
_ssh_bridge() {
  local pid_file="$HOME/.ssh/agent-bridge.pid"
  mkdir -p "$HOME/.ssh"
  if [ -f "$pid_file" ] && ! kill -0 "$(cat $pid_file)" 2>/dev/null; then
    rm -f "$pid_file" "$SSH_AUTH_SOCK"
  fi
  if [ ! -S "$SSH_AUTH_SOCK" ]; then
    rm -f "$SSH_AUTH_SOCK"
    ( setsid socat \
        UNIX-LISTEN:"$SSH_AUTH_SOCK",fork \
        EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork \
      &>/dev/null & echo $! > "$pid_file" )
  fi
}
_ssh_bridge

# p10k config — run 'p10k configure' to regenerate
[[ -f "${HOME}/.p10k.zsh" ]] && source "${HOME}/.p10k.zsh"
