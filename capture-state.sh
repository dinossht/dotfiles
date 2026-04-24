#!/bin/bash
# Capture current system state into ~/.dotfiles/ so it can be reproduced on
# a fresh machine. Run weekly (or via systemd timer).
#   ~/.dotfiles/capture-state.sh
# After running, commit and push the updated files.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

echo "Capturing apt packages..."
apt-mark showmanual | sort > packages-apt.txt

echo "Capturing snap packages..."
if command -v snap >/dev/null 2>&1; then
  snap list 2>/dev/null | awk 'NR>1 {print $1}' | sort > packages-snap.txt || true
else
  : > packages-snap.txt
fi

echo "Capturing flatpak packages..."
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application 2>/dev/null | sort > packages-flatpak.txt || true
else
  : > packages-flatpak.txt
fi

echo "Capturing pip user packages..."
if command -v pip >/dev/null 2>&1; then
  pip freeze --user 2>/dev/null | sort > pip-user.txt || true
fi

echo "Capturing conda environments..."
if command -v conda >/dev/null 2>&1; then
  mkdir -p conda-envs
  conda env list 2>/dev/null | awk 'NR>2 && $1 !~ /^#/ && $1 != "" {print $1}' | while read -r env; do
    [ -z "$env" ] && continue
    [ "$env" = "base" ] && continue
    echo "  exporting $env..."
    conda env export -n "$env" --from-history > "conda-envs/${env}.yml" 2>/dev/null || true
  done
fi

echo "Capturing enabled systemd user units..."
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null \
  | awk '{print $1}' | sort > systemd-user-enabled.txt || true

echo "Done. Review diffs and commit:"
echo "  cd $DOTFILES && git status"
