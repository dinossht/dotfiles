# Full-system restore — from a dead/bricked laptop

This is the runbook for getting back to a working setup if this laptop is lost,
stolen, bricked, or ransomware'd. Time budget: **~1.5 hours** if Drive mirror
is healthy.

## Architecture

- **Primary repo:** `/mnt/ssd2/restic-laptop` — fast local NVMe, daily backups
- **Off-site mirror:** `gdrive-personal:RestricBackup-laptop` — weekly rclone sync from primary
- Both repos are restic format, encrypted with the same password

The restore strategy is: **download the Drive mirror to a working filesystem,
then `restic restore` from there.**

## What you need on hand

- **Ubuntu 24.04 LTS** install USB (or newer)
- Your **password manager** with:
  1. **Restic repo password** — required to decrypt the backup
- Internet (35+ GB of total download: Ubuntu + your repo)
- A working Google account with rclone access to the personal gdrive

> ⚠️ **Without the restic password the backup is unrecoverable.** It's
> encrypted client-side. The password lives only at `~/.config/restic/password`
> on the laptop AND in your password manager. Verify both.

## Step-by-step

### 1. Fresh Ubuntu install

Install Ubuntu 24.04 from USB. Username `dino`. Update + reboot.

### 2. Install the tools

```bash
sudo apt install -y restic git curl rclone stow
```

### 3. Clone dotfiles (has bkp, scripts, package lists)

```bash
cd ~
git clone git@github.com:dinossht/dotfiles.git .dotfiles
# or, if SSH not set up yet:
# git clone https://github.com/dinossht/dotfiles.git .dotfiles
```

### 4. Restore the restic password from your password manager

```bash
mkdir -p ~/.config/restic
umask 077
printf '%s' 'PASTE_RESTIC_PASSWORD_FROM_PW_MANAGER' > ~/.config/restic/password
chmod 600 ~/.config/restic/password
```

### 5. Configure rclone for Google Drive

Use your own OAuth client ID (recommended) or fall back to the shared one:

```bash
rclone config
# Add new remote named "gdrive-personal", type drive
# Use existing OAuth client_id/secret from a Google Cloud project,
# or leave blank for the (rate-limited) default
```

### 6. Pull the off-site mirror down to a working location

```bash
mkdir -p /tmp/restic-mirror
rclone copy gdrive-personal:RestricBackup-laptop /tmp/restic-mirror \
  --progress --transfers 8
```

This downloads ~25 GiB. ~30–60 min on home fiber.

### 7. Restore /home from the local copy

```bash
export RESTIC_REPOSITORY=/tmp/restic-mirror
export RESTIC_PASSWORD_FILE=$HOME/.config/restic/password
restic snapshots                  # sanity check
restic restore latest --target /  # writes to /home/dino/... and /etc/...
```

### 8. Reinstall apps + stow configs

```bash
cd ~/.dotfiles
./bootstrap.sh
```

This installs every apt/snap/flatpak from the lists, enables the daily restic
timer (which will start writing to `/mnt/ssd2/restic-laptop` again — make sure
that path exists or change it), and stows all dotfiles. ~15–30 min.

### 9. Final touches

- **Mount /mnt/ssd2** (fstab is restored, but if the SSD is brand new, format
  it and update `/etc/fstab`).
- **WiFi**: click the network icon → enter passwords (not in backup by design).
- **Browsers, ProtonVPN, etc**: log in.
- **Conda envs** (if any): `conda env create -f ~/.dotfiles/conda-envs/<env>.yml`
- **Verify backups run**: `bkp` — should show daily timer active. Trigger a
  fresh backup with `bkp run`. Trigger a fresh mirror with `bkp mirror`.

## Recovering one file (no full restore)

```bash
bkp mount             # FUSE-mount repo at ~/restic-mount; Ctrl+C to unmount
# or:
bkp restore latest --include /home/dino/Documents/foo.pdf --target /tmp/recover
```

## If something is off

```bash
bkp status            # one-shot summary
bkp logs 100          # recent backup log
bkp check             # verify repo integrity
bkp progress          # bytes uploaded + ETA when running
```

## The secret(s) — where they live on a working system

- **Restic repo password:** `~/.config/restic/password` (mode 600)

This is NOT in the dotfiles git repo. Back it up only to your password manager.
