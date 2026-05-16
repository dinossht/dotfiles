#!/bin/bash
# Daily restic backup of /home/dino and selected /etc files to Workspace Google Drive.
# Run manually or via the systemd user timer (restic-backup.timer).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

LOG_DIR="$HOME/.local/state/restic"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/backup.log"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*" | tee -a "$LOGFILE"; }

# Desktop notification on failure. Fires for any non-zero exit, including
# uncaught errors from `set -e`. Best-effort; silently no-op if notify-send
# isn't installed or there's no graphical session.
notify_failure() {
  local rc=$?
  [ "$rc" -eq 0 ] && return
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical -i dialog-error \
      "Backup failed" \
      "restic backup exited with status $rc. Run: bkp logs" 2>/dev/null || true
  fi
  log "=== restic backup FAILED with exit $rc ==="
}
trap notify_failure EXIT

# Concurrency guard — two layers:
#   1. pgrep for any live restic backup process (catches orphans from older
#      script invocations that predate the flock layer)
#   2. flock so regular cases bail cleanly and clean up on SIGKILL
if pgrep -f 'restic backup' >/dev/null; then
  log "another restic backup process is already running (pgrep) — skipping"
  exit 0
fi
LOCK="$LOG_DIR/backup.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  log "another restic backup is already running (flock) — skipping"
  exit 0
fi

log "=== restic backup starting ==="

# Fail fast if repo is not initialized yet
if ! restic snapshots >/dev/null 2>&1; then
  log "ERROR: repo not initialized or unreachable. Run 'restic init' first (see env.sh)."
  exit 1
fi

# Targets come from targets.txt (one path per line, # for comments).
# Edit with: bkp targets --edit
mapfile -t TARGETS < <(grep -v -E '^\s*($|#)' "$SCRIPT_DIR/targets.txt")
[ ${#TARGETS[@]} -gt 0 ] || { log "ERROR: no targets in $SCRIPT_DIR/targets.txt"; exit 1; }

# Back up.  --verbose=2 emits periodic progress lines so we can see how far
# along we are in bkp logs / the log file (restic's TTY progress bar is not
# shown when stdout is not a terminal).
restic backup \
  --exclude-file="$SCRIPT_DIR/excludes.txt" \
  --exclude-caches \
  --one-file-system \
  --tag="auto" \
  --verbose=2 \
  "${TARGETS[@]}" \
  2>&1 | tee -a "$LOGFILE"

log "=== backup done, running forget/prune ==="

# Retention: generous since 2TB+ quota
forget_args=( --keep-daily 14 --keep-weekly 8 --keep-monthly 24 --prune )

if ! restic forget "${forget_args[@]}" 2>&1 | tee -a "$LOGFILE"; then
  # forget failed — usually because of a stale lock left by an earlier
  # interrupted restic op. Only safe to auto-clear if no other restic is
  # running right now.
  log "forget failed — checking for stale lock..."
  if pgrep -f 'restic ' >/dev/null; then
    log "ERROR: another restic process is live; refusing to unlock"
    exit 1
  fi
  log "no other restic process; clearing stale lock and retrying..."
  restic unlock 2>&1 | tee -a "$LOGFILE" || true
  if ! restic forget "${forget_args[@]}" 2>&1 | tee -a "$LOGFILE"; then
    log "ERROR: forget still failed after auto-unlock — giving up"
    exit 1
  fi
  log "forget succeeded after auto-unlock"
fi

log "=== restic backup finished successfully ==="
