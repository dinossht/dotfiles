# Restore runbook

How to recover this laptop's setup. Two scenarios; pick the one that matches.

| Scenario | When | Time budget | Restore source |
|---|---|---|---|
| **A** | Ubuntu corrupted, both NVMe disks intact | ~1 hour | local `/mnt/ssd2/restic-laptop` |
| **B** | Total loss (laptop dead, stolen, or both disks gone) | ~1.5–2 hours | Google Drive mirror |

## Architecture (so the steps make sense)

- **Primary backup:** `/mnt/ssd2/restic-laptop` — restic repo on the secondary NVMe (`/dev/nvme1n1`). Daily `bkp run` via systemd timer.
- **Off-site mirror:** Google Drive `gdrive-personal:RestricBackup-laptop` — weekly `bkp mirror` (rclone sync). Independent copy for disaster recovery.
- Both copies are encrypted with the same restic password.

## Inventory: what's where

| Where | What's stored | Encrypted? |
|---|---|---|
| `/home/dino/.dotfiles` (= `github.com/dinossht/dotfiles`) | scripts, package lists, bkp CLI, this doc | no (public-OK) |
| `/mnt/ssd2/restic-laptop` | restic repo with `/home` + `/etc` snapshots | yes (restic) |
| Google Drive `RestricBackup-laptop` | weekly mirror of the local restic repo | yes (restic) |
| `~/.config/restic/password` | restic repo password — **the only secret you need** | mode 600, NOT in git |
| Password manager | restic repo password (backup of above) | encrypted by pw mgr |

> ⚠️ **The restic password is the one thing you can't recover from anywhere else.** Without it, both repos are unrecoverable encrypted blobs. Verify it's in your password manager *before* you ever need it.

---

# Scenario A — Ubuntu corrupted, SSD2 intact

This is the easy one. Your `/mnt/ssd2` lives on a separate physical disk (`/dev/nvme1n1`); reinstalling Ubuntu only affects the main disk (`/dev/nvme0n1`). The backup survives untouched.

### A.1. Reinstall Ubuntu — but DON'T touch /dev/nvme1n1

Boot Ubuntu 24.04 Live USB. **Critical step in the installer:**
- The installer will show **two NVMe disks**:
  - `nvme0n1` (~470 GB) — the broken one, **wipe this**
  - `nvme1n1` (~1.9 TB) — your `/mnt/ssd2`, **DO NOT format or touch**
- Choose **"Something else"** (manual partitioning) → only modify `nvme0n1`
- If unsure: physically disconnect `nvme1n1` before installing, reconnect after

Username `dino`. Same hostname `dino-Legion-Slim-5-16IRH8` (recommended for restic).

### A.2. Install minimum tools

```bash
sudo apt update
sudo apt install -y restic git curl rclone stow
```

### A.3. Mount the backup disk

```bash
sudo blkid | grep nvme1n1     # note the UUID
# Add to fstab so it auto-mounts every boot:
echo "UUID=<paste-uuid-here> /mnt/ssd2 ext4 defaults 0 2" | sudo tee -a /etc/fstab
sudo mkdir -p /mnt/ssd2
sudo mount -a

# Verify backup is intact:
ls /mnt/ssd2/restic-laptop
# expect: config  data  index  keys  snapshots
```

### A.4. Clone dotfiles + restore the restic password

```bash
git clone https://github.com/dinossht/dotfiles.git ~/.dotfiles

mkdir -p ~/.config/restic
umask 077
printf '%s' 'PASTE_FROM_PASSWORD_MANAGER' > ~/.config/restic/password
chmod 600 ~/.config/restic/password
```

### A.5. Sanity-check, then restore

```bash
source ~/.dotfiles/restic/env.sh
restic snapshots                          # should list your snapshots — confirms password works
restic restore latest --target /          # restores /home/dino/... + /etc/... (~20-40 min)
```

### A.6. Reinstall apps + stow configs

```bash
cd ~/.dotfiles
./bootstrap.sh
# 323 apt packages + 32 snaps + flatpaks + stow + enable timer
```

### A.7. Reboot, finishing touches

```bash
sudo reboot
```

After reboot:
- WiFi: re-enter passwords (not in backup by design)
- Browsers / ProtonVPN: log in
- Conda envs: `conda env create -f ~/.dotfiles/conda-envs/<env>.yml`
- `bkp` to confirm daily timer is active

---

# Scenario B — Total loss (new machine)

You don't have access to `/mnt/ssd2`. Pull from the Google Drive mirror.

### B.1. Install Ubuntu 24.04 on the new machine

Normal install. Same username `dino` recommended.

### B.2. Install tools

```bash
sudo apt install -y restic git curl rclone stow
```

### B.3. Clone dotfiles

```bash
git clone https://github.com/dinossht/dotfiles.git ~/.dotfiles
```

### B.4. Restore restic password from password manager

```bash
mkdir -p ~/.config/restic
umask 077
printf '%s' 'PASTE_FROM_PASSWORD_MANAGER' > ~/.config/restic/password
chmod 600 ~/.config/restic/password
```

### B.5. Configure rclone to access Google Drive

```bash
rclone config
# Add new remote named "gdrive-personal", type "drive", scope "1"
# Either reuse your own OAuth client_id from Google Cloud Console
# or leave blank to use the (rate-limited) default
```

### B.6. Pull the mirror down

```bash
mkdir -p /tmp/restic-mirror
rclone copy gdrive-personal:RestricBackup-laptop /tmp/restic-mirror \
  --progress --transfers 8
# downloads ~25 GiB; ~30-60 min on home fiber
```

### B.7. Restore from the local copy

```bash
export RESTIC_REPOSITORY=/tmp/restic-mirror
export RESTIC_PASSWORD_FILE=$HOME/.config/restic/password
restic snapshots
restic restore latest --target /
```

### B.8. Reinstall apps, finish

```bash
cd ~/.dotfiles
./bootstrap.sh
sudo reboot
```

> **After Scenario B, set up `/mnt/ssd2` again** (or a different secondary disk) so future backups have a primary local target. Without it, `bkp run` will fail. Edit `~/.dotfiles/restic/env.sh` if you choose a different path.

---

# Common operations

### Get just one file from a snapshot

```bash
bkp mount                                  # FUSE-mount the repo at ~/restic-mount
# or:
bkp restore latest --include /home/dino/Documents/foo.pdf --target /tmp/recover
```

### Check repo health

```bash
bkp check        # full integrity verification
bkp status       # quick summary
bkp logs 100     # last 100 lines of backup log
bkp progress     # live ETA when a backup is running
```

### List snapshots / browse contents

```bash
bkp snapshots
bkp ls latest /home/dino/Documents
```

### Force a fresh mirror to Google Drive

```bash
bkp mirror
```

---

# What's in the dotfiles repo (everything you need)

```
~/.dotfiles/
├── RESTORE.md                  # this file
├── README.md
├── bootstrap.sh                # one-command rebuild
├── capture-state.sh            # regenerates the package lists below
├── packages-apt.txt            # 323 apt packages (apt-mark showmanual)
├── packages-snap.txt           # 32 snaps
├── packages-flatpak.txt        # flatpak apps
├── pip-user.txt                # user pip packages
├── conda-envs/                 # exported conda envs (if any captured)
├── systemd-user-enabled.txt    # for reference
├── restic/
│   ├── bkp                     # CLI wrapper, symlinked to ~/.local/bin/bkp
│   ├── backup.sh               # what the timer runs daily
│   ├── env.sh                  # repo URL + tuning (no secrets)
│   ├── targets.txt             # paths backed up (/home/dino + a few /etc files)
│   └── excludes.txt            # rules for what to skip (caches, build dirs, etc.)
├── zsh/, tmux/, nvim/, kitty/, starship/, conky/, git/, i3/   # stowed configs
└── timeshift-cloud-{sync,restore}.sh   # legacy, can be ignored
```

The bare minimum to recover with no internet for the dotfiles repo would be: just the `restic` folder + `packages-apt.txt` + the password — the first two restore the backup process, then a normal `apt install` rebuilds the rest. But you don't need to think about that — `git clone` of the repo is one command.

---

# What you DO need to keep safe outside the laptop

1. **Restic repo password** in your password manager (and ideally a paper/USB copy in another physical location)
2. **GitHub access** to `dinossht/dotfiles` (your personal account)
3. **Google account access** for the Drive mirror (Scenario B only)

That's it.
