# ============================================================
#  ZSH CONFIGURATION WITH FZF FUZZY HISTORY SEARCH
# ============================================================

# -------------------------
# History configuration
# -------------------------
HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000

setopt APPEND_HISTORY        # append to history file
setopt INC_APPEND_HISTORY    # write commands immediately
setopt SHARE_HISTORY         # share history across sessions
setopt HIST_IGNORE_DUPS      # ignore duplicate entries
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY      # store timestamps

# -------------------------
# Completion (cached, rebuilds once per day)
# -------------------------
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# FZF integration: key bindings for Ctrl-T (files), Alt-C (cd), Ctrl-R (history)
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

# -------------------------
# Prompt (starship)
# -------------------------
eval "$(starship init zsh)"

# -------------------------
# Modern CLI tools
# -------------------------
alias ls='eza --icons'
alias ll='eza -lah --icons --git'
alias lt='eza -lah --icons --git --tree --level=2'
alias cat='batcat --style=plain --paging=never'
alias catp='batcat'
alias fd='fdfind'
alias gs='git status'
alias ..='cd ..'

# Git aliases
alias gst='git status'
alias ga='git add'
alias gp='git push'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias go='git checkout'
alias gl='git log --oneline --graph'
alias gcm='git commit -m'

alias cursor="/home/dino/Applications/cursor/cursor.AppImage --no-sandbox"

# -------------------------
# Syntax highlighting (optional plugin)
# -------------------------
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# -------------------------
# Autosuggestions (optional plugin)
# -------------------------
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# -------------------------
# Python / CUDA paths (pyenv lazy-loaded)
# -------------------------
export PATH="$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH"
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init --path)"
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init -)"
  pyenv "$@"
}

export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH

# -------------------------
# FZF: fuzzy finder setup (powered by fd + bat)
# -------------------------
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fdfind --type d --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:500 {}'"
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# Custom fuzzy history widget using fzf
fzf_history_widget() {
  # Load history (newest first, remove duplicates and timestamps)
  local selected
  selected=$(fc -rl 1 \
    | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]*//' \
    | awk '!seen[$0]++' \
    | fzf --height 40% --reverse --border --prompt="history> ") || return

  if [[ -n $selected ]]; then
    BUFFER=$selected
    zle -I               # clear any pending input
    echo "$BUFFER"       # show the command being run
    zle accept-line      # execute it
  fi
}
zle -N fzf_history_widget
bindkey '^R' fzf_history_widget

# -------------------------
# Misc (add any exports, tools, etc. below)
# -------------------------

export VCPKG_ROOT=/home/dino/vcpkg

# opencode
export PATH=/home/dino/.opencode/bin:$PATH
export PATH="$HOME/.npm-global/bin:$PATH"

# NVM (lazy-loaded — initializes on first use of nvm/node/npm/npx/pnpm/yarn)
export NVM_DIR="$HOME/.nvm"
export PATH="$NVM_DIR/versions/node/$(ls -1 "$NVM_DIR/versions/node/" 2>/dev/null | tail -1)/bin:$PATH" 2>/dev/null
_nvm_lazy_load() {
  unfunction nvm node npm npx pnpm yarn 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
for cmd in nvm node npm npx pnpm yarn; do
  eval "${cmd}() { _nvm_lazy_load; ${cmd} \"\$@\" }"
done


# Kitty-spesifikke aliaser og innstillinger
if [ "$TERM" = "xterm-kitty" ]; then
    # Vis bilder direkte i terminalen
    alias icat="kitten icat"

    # Kraftig diff-verktøy for filer og bilder
    alias kdiff="kitten diff"

    # SSH med automatisk overføring av terminfo (viktig for farger/snarveier)
    alias ssh="kitten ssh"

    # Velg og bytt fargetema interaktivt
    alias themes="kitten themes"

    # Søk og sett inn Unicode/Emoji
    alias kunicode="kitten unicode-input"

    # Administrer fonter
    alias kfonts="kitten choose-fonts"
fi

# -------------------------
# Help cheatsheet
# -------------------------
function helpme() {
  batcat --style=plain --paging=never --language=markdown <<'HELP'
## Navigation
  z <dir>          Smart cd (learns your habits)
  y                Yazi file manager (q to quit, cd's into dir)
  Alt+C            Fuzzy cd into directory
  ..               Go up one directory

## Search
  Ctrl+T           Fuzzy file search with preview
  Ctrl+R           Fuzzy command history
  fd <pattern>     Find files fast (e.g. fd "\.py$")

## Files
  ls / ll          List files with icons & git status
  lt               Tree view (2 levels)
  cat <file>       Syntax-highlighted file view
  catp <file>      Full bat with pager & line numbers

## Git
  gs               git status
  gl               git log (graph)
  ga               git add
  gc               git commit
  gcm "msg"        git commit -m
  gd               git diff
  gp               git push
  gb               git branch
  go <branch>      git checkout

## Tools
  btop             System monitor
  nvtop            GPU monitor
  lazygit          Git TUI
  icat <img>       Show image in terminal (kitty)
  kdiff            Kitty diff tool
  helpme           Show this help

## Desktop
  Super+V          Clipboard history (CopyQ)
  Print Screen     Screenshot with annotations (Flameshot)
  Ctrl+Alt+T       Kitty terminal

## Docker
  lazydocker       Docker TUI

## GitHub
  gh pr create     Create pull request
  gh pr list       List PRs
  gh issue list    List issues
HELP
}

# -------------------------
# Zoxide (smart cd)
# -------------------------
eval "$(zoxide init zsh)"

# -------------------------
# Yazi (file manager - cd into dir on exit with 'y')
# -------------------------
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

