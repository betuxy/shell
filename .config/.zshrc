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

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
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
