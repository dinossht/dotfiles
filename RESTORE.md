# Full-system restore — from a dead/bricked laptop

This is the runbook for getting back to a working setup if this laptop is lost,
stolen, bricked, or ransomware'd. Time budget: **~1.5–2 hours**.

## What you need on hand

- **Ubuntu 24.04 LTS** install USB (or newer)
- Your **password manager** (e.g. Proton Pass, 1Password) — you'll need:
  1. **Restic repo password** — stored as "restic-laptop repo password"
  2. **Backblaze B2 keyID** — stored as "B2 keyID restic-laptop"
  3. **Backblaze B2 applicationKey** — stored as "B2 applicationKey restic-laptop"
  4. **GitHub SSH key or PAT** — for cloning this dotfiles repo
- Internet (40+ GB of download: system + your backup)

> ⚠️ **Without items 1–3 above the B2 backup is unrecoverable.** The repo is
> client-side encrypted — losing the password means losing the data. Verify
> those values exist in your password manager **before** you need them.

## Step-by-step

### 1. Fresh Ubuntu install

Install Ubuntu 24.04 from USB, normal workflow. Username `dino`, same hostname
`dino-legion-...`. Update (`sudo apt update && sudo apt upgrade -y`). Reboot.

### 2. Install the three things needed to pull everything else

```bash
sudo apt install -y restic git curl stow
```

### 3. Clone dotfiles

```bash
cd ~
git clone git@github.com:dinossht/dotfiles.git .dotfiles
# Or, if SSH not set up yet:
# git clone https://github.com/dinossht/dotfiles.git .dotfiles
```

### 4. Recreate the two credential files (paste from password manager)

```bash
mkdir -p ~/.config/restic
umask 077

# Restic repo password
printf '%s' 'PASTE_RESTIC_PASSWORD_FROM_PW_MANAGER' > ~/.config/restic/password
chmod 600 ~/.config/restic/password

# B2 credentials
cat > ~/.config/restic/b2-credentials <<'EOF'
export B2_ACCOUNT_ID="PASTE_KEYID_FROM_PW_MANAGER"
export B2_ACCOUNT_KEY="PASTE_APPLICATIONKEY_FROM_PW_MANAGER"
EOF
chmod 600 ~/.config/restic/b2-credentials
```

### 5. Restore `/home/dino` from the B2 snapshot

```bash
source ~/.dotfiles/restic/env.sh
restic snapshots                 # sanity check — should list your snapshots
restic restore latest --target /  # restores /home/dino/... and /etc/... paths
```

Typical time: 30–90 min depending on internet speed.

### 6. Reinstall apps + stow configs

```bash
cd ~/.dotfiles
./bootstrap.sh
```

This installs every apt package in `packages-apt.txt`, every snap in
`packages-snap.txt`, every flatpak in `packages-flatpak.txt`, enables the
daily restic timer, and stows all dotfiles. ~15–30 min.

### 7. Final touches

- **WiFi**: click the network icon → enter passwords (not in backup by design).
- **Chrome / Firefox**: log in, bookmarks/extensions re-sync from your account.
- **ProtonVPN**: log in via the app.
- **Conda envs** (if needed): `conda env create -f ~/.dotfiles/conda-envs/<env>.yml`
- **SSH keys**: verify `~/.ssh/` was restored (should be — it's in `$HOME`).
- **Verify backups run**: `bkp` — you should see the timer active and your
  snapshots. Trigger a manual fresh backup with `bkp run` to confirm.

## Getting to a file without a full restore

If the laptop is fine but you just need one file from a past snapshot:

```bash
# Mount the remote repo as a filesystem (FUSE):
bkp mount                        # defaults to ~/restic-mount; Ctrl+C to unmount
# Or restore just one path:
bkp restore latest --include /home/dino/Documents/foo.pdf --target /tmp/recover
```

## If something is off

- `bkp status` — shows repo, running backup, timer, log tail
- `bkp logs 100` — recent log
- `bkp check` — verifies repo integrity
- `restic snapshots --no-lock` — raw snapshot list

## The two secrets — where they live on a working system

- **Restic repo password:** `~/.config/restic/password` (mode 600)
- **B2 credentials:** `~/.config/restic/b2-credentials` (mode 600)

Both are NOT in this git repo. Back them up only to your password manager.
