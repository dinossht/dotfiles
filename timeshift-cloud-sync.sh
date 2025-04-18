#!/bin/bash

SNAPSHOT_DIR="/timeshift/snapshots"
REMOTE="gdrive:TimeshiftBackup"
CONFIG="/home/dino/.config/rclone/rclone.conf"
LOGFILE="$HOME/timeshift-cloud-sync.log"

echo "=== Timeshift Cloud Sync @ $(date) ===" >> "$LOGFILE"

sudo rclone sync "$SNAPSHOT_DIR" "$REMOTE" \
  --config="$CONFIG" \
  --progress \
  --transfers=4 \
  --checkers=8 \
  --log-level INFO \
  --log-file "$LOGFILE"

echo "=== Done @ $(date) ===" >> "$LOGFILE"

