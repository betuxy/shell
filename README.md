# dotfiles

Personal shell environment for Linux — managed with a single CLI, versioned in git.

```
~
├── .zshrc / .zsh_aliases          shell config
├── .p10k.zsh                      prompt config
├── .config/
│   ├── nvim/                      LazyVim + LSP
│   └── sheldon/plugins.toml       zsh plugin manager
└── .local/
    ├── bin/                       self-contained binaries (no package manager)
    │   ├── dots                   ← this CLI
    │   ├── nvim  bat  eza  fzf
    │   ├── atuin  zoxide  zellij
    │   └── age  gocryptfs  ...
    └── lib/  share/               nvim parsers & runtime
```

## Quick start

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles/scripts
./setup.sh          # symlink everything into ~/
```

After that, `dots` is on your `$PATH` via `~/.local/bin/dots`.

## dots CLI

```
dots                     interactive fzf menu
dots status              full overview: git · symlinks · apps · changelog
dots setup               install / re-verify all symlinks
dots apps list           show managed binaries and install status
dots apps update         download latest releases from GitHub
dots apps update nvim    update a single app
dots apps add <n> <r>    add app to applications.txt
dots apps remove <n>     remove app from applications.txt
dots config list         list dotfiles config files
dots config edit         open a config file in $EDITOR (fzf picker)
dots secrets init        create encrypted secrets file (age)
dots secrets edit        decrypt → edit → re-encrypt
dots secrets load        print export statements
eval "$(dots secrets load)"
dots changelog           formatted update history
```

## Apps

Binaries are downloaded directly from GitHub Releases by `update-apps.sh` and stored in `.local/bin/`. No package manager required — the whole environment is self-contained.

| Tool | Purpose |
|---|---|
| [nvim](https://github.com/neovim/neovim) | editor (LazyVim) |
| [zellij](https://github.com/zellij-org/zellij) | terminal multiplexer |
| [atuin](https://github.com/atuinsh/atuin) | shell history |
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | prompt (via sheldon) |
| [sheldon](https://github.com/rossmacarthur/sheldon) | zsh plugin manager |
| [fzf](https://github.com/junegunn/fzf) | fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | smarter `cd` |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [eza](https://github.com/eza-community/eza) | modern `ls` |
| [fd](https://github.com/sharkdp/fd) | fast `find` |
| [age](https://github.com/FiloSottile/age) | file encryption (used by secrets) |
| [gocryptfs](https://github.com/rfjakob/gocryptfs) | encrypted filesystem |

## Secrets

Secrets are encrypted with [age](https://github.com/FiloSottile/age) and committed as `secrets.age`.

```sh
dots secrets init   # create and encrypt a new secrets file
dots secrets edit   # decrypt → edit in $EDITOR → re-encrypt on save
```

`dots secrets load` prints `export KEY=VALUE` lines — a subprocess can't modify the parent shell's environment directly, so `.zshrc` wraps it in `eval` to apply the exports on every shell start:

```sh
# already in .zshrc
eval "$(dots secrets load 2>/dev/null)" || true
#                          ^ silent if no secrets file yet
#                                         ^ don't abort shell startup on error
```

## Shell plugins (sheldon / zsh)

- `zsh-autosuggestions` — inline history suggestions
- `fast-syntax-highlighting` — real-time syntax colouring
- `zsh-completions` — extended completion definitions
- `fzf-tab` — fzf-powered tab completion
