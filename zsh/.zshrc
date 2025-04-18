# Enable history and completion
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt inc_append_history
autoload -Uz compinit && compinit

# Prompt
PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gl='git log --oneline --graph'
alias ..='cd ..'

# Enable syntax highlighting (requires plugin)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Enable autosuggestions (requires plugin)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Git aliases
alias gst='git status'
alias ga='git add'
alias gp='git push'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias go='git checkout'
alias gl='git log'
alias gcm='git commit -m'

alias cursor="/home/dino/Applications/cursor/cursor.AppImage --no-sandbox"
