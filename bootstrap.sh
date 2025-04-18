#!/bin/bash

set -e  # Exit on error

echo "🔧 Starting system setup..."

# Install essential packages
echo "📦 Installing packages..."
sudo apt update
sudo apt install -y \
    git zsh tmux neovim stow curl wget unzip build-essential \
    i3 i3status dmenu feh x11-xserver-utils picom lxappearance rofi

# Use stow to symlink dotfiles
echo "🔗 Stowing dotfiles..."
cd "$HOME/.dotfiles"

stow zsh
stow tmux
stow nvim

# Set Zsh as default shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  echo "🌀 Changing default shell to Zsh..."
  chsh -s /usr/bin/zsh
fi

echo "✅ Setup complete!"

