#!/bin/bash
set -e

echo "Starting system setup..."

# Install essential packages
echo "Installing packages..."
sudo apt update
sudo apt install -y \
    git zsh tmux neovim stow curl wget unzip build-essential \
    i3 i3status dmenu feh picom rofi brightnessctl i3lock dunst \
    kitty fzf ripgrep fd-find bat eza zoxide \
    conky-all xpad copyq flameshot \
    zsh-syntax-highlighting zsh-autosuggestions

# Install starship
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install yazi
if ! command -v yazi &> /dev/null; then
    echo "Installing yazi..."
    mkdir -p ~/.local/bin
    YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep -o 'https://.*yazi-x86_64-unknown-linux-gnu.zip' | head -1)
    cd /tmp && curl -sL "$YAZI_URL" -o yazi.zip && unzip -o yazi.zip
    cp yazi-x86_64-unknown-linux-gnu/yazi ~/.local/bin/
    cp yazi-x86_64-unknown-linux-gnu/ya ~/.local/bin/
    chmod +x ~/.local/bin/yazi ~/.local/bin/ya
fi

# Install lazydocker
if ! command -v lazydocker &> /dev/null; then
    echo "Installing lazydocker..."
    mkdir -p ~/.local/bin
    LAZY_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -o 'https://.*Linux_x86_64.tar.gz' | head -1)
    cd /tmp && curl -sL "$LAZY_URL" -o lazydocker.tar.gz && tar xzf lazydocker.tar.gz lazydocker
    cp lazydocker ~/.local/bin/ && chmod +x ~/.local/bin/lazydocker
fi

# Install TPM for tmux
if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Stow dotfiles
echo "Stowing dotfiles..."
cd "$HOME/.dotfiles"
stow zsh
stow tmux
stow nvim
stow kitty
stow starship
stow conky
stow git
stow i3

# Set Zsh as default shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo "Changing default shell to Zsh..."
    chsh -s /usr/bin/zsh
fi

echo "Setup complete! Open a new terminal to see changes."
echo "Run 'tmux' then press Ctrl-a I to install tmux plugins."
