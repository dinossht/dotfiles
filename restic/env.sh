#!/bin/bash
# Source this file before running restic commands.
# Example:  source ~/.dotfiles/restic/env.sh && restic snapshots

# --- Repo -------------------------------------------------------------------
# Backblaze B2, native restic backend (no rclone in the loop).
# Format:  b2:<bucket>:<path-prefix>
export RESTIC_REPOSITORY="b2:dino-legion-backup:laptop"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"

# --- B2 credentials ---------------------------------------------------------
# Read from a separate file (mode 600, NOT in dotfiles git). Create it with:
#   umask 077
#   cat > ~/.config/restic/b2-credentials <<'EOF'
#   export B2_ACCOUNT_ID="<keyID from Backblaze>"
#   export B2_ACCOUNT_KEY="<applicationKey from Backblaze>"
#   EOF
if [ -f "$HOME/.config/restic/b2-credentials" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/restic/b2-credentials"
fi

# --- Tuning -----------------------------------------------------------------
# Native restic B2 flags — B2 happily accepts parallelism.
export RESTIC_PACK_SIZE=64
# Connections for B2; 5-10 is a good sweet spot for a home uplink.
# (set on the command line via --option b2.connections=8 if needed)
