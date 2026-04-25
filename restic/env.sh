#!/bin/bash
# Source this file before running restic commands.
# Example:  source ~/.dotfiles/restic/env.sh && restic snapshots
#
# This setup uses LOCAL backup to the secondary SSD at /mnt/ssd2 only.
# That is fast, free, and reliable, but offers NO protection against laptop
# theft, fire, or whole-machine loss. To add an off-site mirror later,
# look into restic's `copy` command to a B2 / S3 / SFTP target.

# --- Repo (local SSD) -------------------------------------------------------
export RESTIC_REPOSITORY="/mnt/ssd2/restic-laptop"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"

# --- Tuning -----------------------------------------------------------------
# Local repo: bigger pack files = fewer files = faster scans.
export RESTIC_PACK_SIZE=128
