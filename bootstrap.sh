#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

echo "Starting system setup..."

# --- APT packages -----------------------------------------------------------
echo "Installing apt packages..."
sudo apt update

# Essentials needed to bootstrap before the full list
sudo apt install -y \
    git zsh tmux neovim stow curl wget unzip build-essential rclone restic

# Full package list (if present). Missing packages are skipped individually so
# the whole run doesn't die on a renamed/dropped package.
if [ -f packages-apt.txt ]; then
  echo "Installing $(wc -l < packages-apt.txt) apt packages from packages-apt.txt..."
  # Filter out blanks / comments, try to install in one shot; fall back to per-line on error.
  mapfile -t pkgs < <(grep -v -E '^\s*($|#)' packages-apt.txt)
  if ! sudo apt install -y "${pkgs[@]}"; then
    echo "Bulk install hit a snag — retrying packages one by one..."
    for p in "${pkgs[@]}"; do
      sudo apt install -y "$p" || echo "  skipped: $p"
    done
  fi
fi

# --- Snap packages ----------------------------------------------------------
if [ -f packages-snap.txt ] && command -v snap >/dev/null 2>&1; then
  echo "Installing snap packages..."
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    sudo snap install "$pkg" || echo "  skipped snap: $pkg"
  done < packages-snap.txt
fi

# --- Flatpak packages -------------------------------------------------------
if [ -f packages-flatpak.txt ] && command -v flatpak >/dev/null 2>&1; then
  echo "Installing flatpak packages..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  while read -r app; do
    [ -z "$app" ] && continue
    flatpak install -y flathub "$app" || echo "  skipped flatpak: $app"
  done < packages-flatpak.txt
fi

# --- Manual tools (not in apt) ---------------------------------------------
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

if ! command -v yazi &> /dev/null; then
    echo "Installing yazi..."
    mkdir -p ~/.local/bin
    YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep -o 'https://.*yazi-x86_64-unknown-linux-gnu.zip' | head -1)
    cd /tmp && curl -sL "$YAZI_URL" -o yazi.zip && unzip -o yazi.zip
    cp yazi-x86_64-unknown-linux-gnu/yazi ~/.local/bin/
    cp yazi-x86_64-unknown-linux-gnu/ya ~/.local/bin/
    chmod +x ~/.local/bin/yazi ~/.local/bin/ya
    cd "$DOTFILES"
fi

if ! command -v lazydocker &> /dev/null; then
    echo "Installing lazydocker..."
    mkdir -p ~/.local/bin
    LAZY_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -o 'https://.*Linux_x86_64.tar.gz' | head -1)
    cd /tmp && curl -sL "$LAZY_URL" -o lazydocker.tar.gz && tar xzf lazydocker.tar.gz lazydocker
    cp lazydocker ~/.local/bin/ && chmod +x ~/.local/bin/lazydocker
    cd "$DOTFILES"
fi

if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# --- Stow dotfiles ----------------------------------------------------------
echo "Stowing dotfiles..."
stow zsh
stow tmux
stow nvim
stow kitty
stow starship
stow conky
stow git
stow i3

# --- Conda environments -----------------------------------------------------
if command -v conda >/dev/null 2>&1 && [ -d conda-envs ]; then
  echo "Restoring conda environments..."
  for f in conda-envs/*.yml; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .yml)
    if conda env list | awk '{print $1}' | grep -qx "$name"; then
      echo "  env '$name' already exists — skipping"
    else
      echo "  creating env '$name' from $f..."
      conda env create -f "$f" || echo "    failed: $f"
    fi
  done
fi

# --- Systemd user timer for restic backup -----------------------------------
if [ -f ~/.config/systemd/user/restic-backup.timer ]; then
  echo "Enabling restic-backup.timer..."
  systemctl --user daemon-reload
  systemctl --user enable --now restic-backup.timer || true
fi

# --- Default shell ----------------------------------------------------------
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo "Changing default shell to Zsh..."
    chsh -s /usr/bin/zsh
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal to pick up zsh + configs"
echo "  2. In tmux: press Ctrl-a I to install tmux plugins"
echo "  3. See RESTORE.md for full restore procedure if this is a disaster-recovery run."
