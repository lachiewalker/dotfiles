# dotfiles

Personal dotfiles — managed with [chezmoi](https://chezmoi.io), secrets in [Bitwarden](https://bitwarden.com), work files encrypted with [age](https://age-encryption.org).

**Machine:** Ubuntu 24.04 Noble, GNOME 46  
**Source:** `~/Projects/repos/dotfiles` (non-standard path — see chezmoi config)

## Quick start (new machine)

```bash
curl -fsSL https://raw.githubusercontent.com/lachiewalker/dotfiles/main/install.sh | bash
```

`install.sh` orchestrates everything: git → chezmoi → nvm + node → bw CLI → bw login → age key from Bitwarden → chezmoi apply → apt repos → packages → SSH keys → auth → GNOME settings → pictures → NVIDIA Docker (if GPU present).

Afterwards, log in to remaining services manually:

```bash
tailscale up
nordvpn login
docker login gitlab.yourcompany.com   # credentials stored in GNOME keyring
```

## What's tracked

Shell config (bashrc, aliases, profile), git identity, SSH host config, AWS config, tmux, Docker credential helper, Claude Code settings and skills, GNOME interface preferences and terminal profiles, wallpapers, and profile pictures. Work-specific files (AWS config, work aliases) are age-encrypted. Secrets (name, email, work GitLab hostname) are templated from Bitwarden — nothing sensitive is stored in plaintext in the repo.

## VPN split-tunnel (2pi OpenVPN)

`scripts/setup-vpn-split-tunnel.sh` (called from `install-packages.sh`) installs a NetworkManager dispatcher script so only `*.2pisoftware.com` internal hosts route through the `2piLachlan` OpenVPN connection — everything else stays on the normal connection.

- `packages/pipx.txt` — installs `vpn-slice`, which does the actual host-route / `/etc/hosts` management on connect/disconnect
- `scripts/networkmanager/90-2pisoftware-vpn-slice` — the dispatcher script itself (lives outside `$HOME`, so it's outside chezmoi's scope; copied into `/etc/NetworkManager/dispatcher.d/` by the setup script, since that requires root)
- `scripts/setup-vpn-split-tunnel.sh` — copies the dispatcher script into place and sets `ipv4.never-default` on the connection

**Not automated:** importing the `.ovpn` file itself into NetworkManager — it embeds a private key/cert, so it's a manual step (import it, name the connection `2piLachlan`, then this setup script picks it up). To add more internal hosts to the split-tunnel, edit the `HOSTS` array in `scripts/networkmanager/90-2pisoftware-vpn-slice` and re-run `setup-vpn-split-tunnel.sh`.

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
    chezmoi/git  →  name, email  →  ~/.gitconfig
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
