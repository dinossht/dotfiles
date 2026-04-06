# dotfiles

My dev environment config. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

| Config | Description |
|--------|-------------|
| `zsh` | Zsh with starship prompt, lazy-loaded pyenv/nvm, fzf + fd + bat previews, modern aliases (eza, bat, zoxide, yazi) |
| `nvim` | Neovim (Kickstart base) with Gruber Darker theme, trouble.nvim, flash.nvim, harpoon, vim-tmux-navigator, DAP debugging |
| `tmux` | tmux with TPM, resurrect/continuum, vim-tmux-navigator, true color |
| `kitty` | Kitty terminal with Catppuccin Mocha, JetBrainsMono Nerd Font |
| `starship` | Starship prompt — single-line, Catppuccin colors, minimal |
| `i3` | i3wm with Catppuccin Mocha, gaps, rofi, i3status, vim keys |
| `conky` | Desktop system monitor widget — CPU, RAM, GPU, disk, network |
| `git` | Git config with delta (side-by-side diffs), kitten diff/merge tools |

## Install

```bash
git clone git@github.com:dinossht/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

## Manual stow

```bash
cd ~/.dotfiles
stow zsh        # symlinks .zshrc
stow nvim       # symlinks .config/nvim/
stow tmux       # symlinks .tmux.conf
stow kitty      # symlinks .config/kitty/
stow starship   # symlinks .config/starship.toml
stow conky      # symlinks .config/conky/
stow git        # symlinks .gitconfig
stow i3         # symlinks .config/i3/
```

## Dependencies

Installed by `bootstrap.sh`: neovim, tmux, kitty, zsh, fzf, ripgrep, fd-find, bat, eza, zoxide, starship, yazi, lazydocker, conky, copyq, flameshot, i3, rofi, picom
