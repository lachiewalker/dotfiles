# dotfiles

Personal dotfiles — managed with [chezmoi](https://chezmoi.io), secrets in [Bitwarden](https://bitwarden.com), work files encrypted with [age](https://age-encryption.org).

**Source:** `~/Projects/repos/dotfiles` (non-standard path — see chezmoi config)

## Quick start (new machine)

```bash
curl -fsSL https://raw.githubusercontent.com/lachiewalker/dotfiles/main/install.sh | bash
```

`install.sh` orchestrates everything: git → chezmoi → nvm + node → bw CLI → bw login → age key from Bitwarden → chezmoi apply (dotfiles, wallpapers) → NVIDIA driver (if GPU present) → apt repos and packages → docker group → SSH keys → auth (gh, glab, SSH key registration, Mullvad, Tailscale, Coder) → Docker registry login → 2pi VPN import and split-tunnel → GNOME settings → NVIDIA Docker runtime (if GPU present).

Steps that cannot be automated pause with instructions and wait for Enter. The last step asks you to reboot.

On desktop, `install.sh` turns off screen blanking, screen lock and idle suspend on AC power (permanently), so the screen does not lock while a step waits for you. `gnome/restore.sh` sets them again, with the other GNOME settings (dark mode, clock, dock click-to-minimize).

## What's tracked

Shell config (bashrc, aliases, profile), git identity, SSH host config, AWS config, tmux, Docker credential helper, Claude Code settings and skills, GNOME interface preferences, GNOME Terminal profiles and matching Ptyxis palettes, wallpapers, and profile pictures. Work-specific files (AWS config, work aliases) are age-encrypted. Secrets (name, email, work GitLab hostname) are templated from Bitwarden — nothing sensitive is stored in plaintext in the repo.

## VPN split-tunnel (2pi OpenVPN)

`scripts/setup-vpn-split-tunnel.sh` (called from `install.sh`) installs a NetworkManager dispatcher script so only `*.2pisoftware.com` internal hosts route through the `2piLachlan` OpenVPN connection — everything else stays on the normal connection.

- `packages/pipx.txt` — installs `vpn-slice`, which does the actual host-route / `/etc/hosts` management on connect/disconnect
- `scripts/networkmanager/90-2pisoftware-vpn-slice` — the dispatcher script itself (lives outside `$HOME`, so it's outside chezmoi's scope; copied into `/etc/NetworkManager/dispatcher.d/` by the setup script, since that requires root)
- `scripts/setup-vpn-split-tunnel.sh` — copies the dispatcher script into place and sets `ipv4.never-default` on the connection

**VPN profile import:** `scripts/setup-vpn-import.sh` fetches `2piLachlan.ovpn` from Bitwarden and imports it into NetworkManager. The file embeds a private key and cert, so it is never stored in this repo. If the Bitwarden item is missing, the script pauses and walks you through a manual import. To add more internal hosts to the split-tunnel, edit the `HOSTS` array in `scripts/networkmanager/90-2pisoftware-vpn-slice` and re-run `setup-vpn-split-tunnel.sh`.

## Notes (`~/.help`)

`~/.help` is a symlink to `help/` in this repo, so notes you write there are already in the repo. Commit and push them like any other change. The repo is public: keep private notes elsewhere.

## Backups (rustic)

`~/.config/rustic/rustic.toml` (age-encrypted in the repo) backs up Documents, Projects, Videos, Pictures, Downloads, `~/.claude`, Minecraft world saves (official launcher and every Prism Launcher instance) and the Firefox session files (open windows and tabs only — no history, passwords or cookies). Backups run only when you start them.

On a new desktop install, `scripts/restore-from-backup.sh` (called from `install.sh`) restores the Firefox session. It waits while you get AWS session tokens in Firefox, then asks you to paste the `export AWS_...` lines and the rustic password. You can run it again later.

Minecraft saves are not restored automatically. To restore them, export your AWS session tokens, then run:

```bash
rustic restore --filter-paths "$HOME/.minecraft/saves,$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances" latest /tmp/mc-saves
```

The worlds land under `/tmp/mc-saves/home/<user>/...` with their original paths. Copy each world folder into `~/.minecraft/saves/` or into the matching Prism instance's `minecraft/saves/`.

**Before you wipe a machine:** close Firefox, then run `rustic backup`.

## Shell init pattern

Tools that self-install shell config write to `~/.bashrc.d/`, not `~/.bashrc`. Install scripts use `PROFILE=/dev/null` to prevent tools from modifying `~/.bashrc` directly.

```
~/.bashrc              ← chezmoi-managed; sources ~/.bashrc.d/*.sh at end
~/.bashrc.d/
    nvm.sh             ← chezmoi-managed
~/.bashrc.local        ← machine-local, not tracked
~/.bash_aliases        ← chezmoi-managed (personal, public)
~/.bash_aliases.work   ← chezmoi-managed (work, age-encrypted)
```

## Secrets architecture

```
Bitwarden vault (chezmoi/ folder)
    chezmoi/git-config  →  name, email, workGitlab  →  ~/.gitconfig, chezmoi data
    chezmoi/age-key     →  notes: age private key  →  ~/.age/key.txt
    chezmoi/2pi-vpn     →  attachment 2piLachlan.ovpn, username  →  NetworkManager VPN
```

On each `chezmoi apply`:
1. chezmoi unlocks Bitwarden (`BW_PASSWORD` env var or interactive prompt)
2. Templates pull values from vault items
3. Files written with secrets interpolated — no secrets ever in git

**Adding a new secret:**
1. Add field to appropriate Bitwarden item
2. Reference in template: `{{ (bitwardenFields "item" "chezmoi/item-name").fieldname.value }}`

## Age encryption

Work-specific files encrypted with age. Anyone without `~/.age/key.txt` sees ciphertext.

```bash
# Encrypt a new file
chezmoi add --encrypt ~/.bash_aliases.work

# Edit an encrypted file
chezmoi edit ~/.bash_aliases.work

# Decrypt to inspect
chezmoi cat ~/.bash_aliases.work
```

**Key management:**
- Private key: `~/.age/key.txt` — store in Bitwarden as a secure note
- Public key (recipient): committed in `~/.config/chezmoi/chezmoi.toml` (safe to share)
- On new machines: restore private key from Bitwarden before `chezmoi apply`

## Day-to-day workflows

### Editing a tracked file (e.g. .bashrc)

Always edit via chezmoi — editing `~/.bashrc` directly won't update the repo:

```bash
chezmoi edit ~/.bashrc          # opens in $EDITOR, saves to source dir
chezmoi diff                    # preview what will change in ~
chezmoi apply                   # write changes to ~
cd ~/Projects/repos/dotfiles
git add dot_bashrc
git commit -m "update bashrc"
git push
```

### Checking for drift (you edited ~ directly by accident)

```bash
chezmoi status                  # lists files that differ between ~ and repo
chezmoi diff                    # shows the actual diff
chezmoi apply                   # overwrite ~ with repo version (repo wins)
# OR
chezmoi add ~/.bashrc           # overwrite repo with ~ version (~ wins)
```

### Adding a new dotfile to tracking

```bash
chezmoi add ~/.config/some-tool/config      # copies file into repo
chezmoi diff                                 # verify it looks right
chezmoi apply                                # no-op if file unchanged
cd ~/Projects/repos/dotfiles
git add -A && git commit -m "track some-tool config"
git push
```

### Adding an encrypted file

```bash
chezmoi add --encrypt ~/.bash_aliases.work  # encrypts and copies into repo
chezmoi diff                                 # verify
chezmoi apply
cd ~/Projects/repos/dotfiles
git add -A && git commit -m "update encrypted work aliases"
git push
```

### After editing an encrypted file in ~ (e.g. ~/.aws/config changed)

```bash
# You edited ~/.aws/config directly — now re-encrypt into repo:
chezmoi add --encrypt ~/.aws/config
cd ~/Projects/repos/dotfiles
git add dot_aws/encrypted_private_config.age
git commit -m "update aws config"
git push
```

### Pulling updates on this machine after pushing from another

```bash
cd ~/Projects/repos/dotfiles
git pull
chezmoi apply
```
