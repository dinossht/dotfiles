#!/bin/bash

REMOTE="gdrive:TimeshiftBackup"
DEST_DIR="/timeshift/snapshots"
CONFIG="/home/dino/.config/rclone/rclone.conf"
LOGFILE="$HOME/timeshift-cloud-restore.log"

echo "============================================" >> "$LOGFILE"
echo "=== Timeshift Restore @ $(date) ===" >> "$LOGFILE"
echo "Restoring from: $REMOTE" >> "$LOGFILE"
echo "Destination: $DEST_DIR" >> "$LOGFILE"
echo "Using rclone config: $CONFIG" >> "$LOGFILE"
echo "--------------------------------------------" >> "$LOGFILE"

# Ensure target directory exists
sudo mkdir -p "$DEST_DIR"

# Restore everything from Google Drive
sudo rclone sync "$REMOTE" "$DEST_DIR" \
  --config="$CONFIG" \
  --progress \
  --transfers=4 \
  --checkers=8 \
  --log-level INFO \
  --log-file "$LOGFILE"

# Set proper ownership for Timeshift to recognize
sudo chown -R root:root "$DEST_DIR"

echo "=== Restore Completed @ $(date) ===" >> "$LOGFILE"
echo "============================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"

