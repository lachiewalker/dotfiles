# dotfiles

Personal dotfiles — managed with [chezmoi](https://chezmoi.io), secrets in [Bitwarden](https://bitwarden.com), work files encrypted with [age](https://age-encryption.org).

**Machine:** Ubuntu 24.04 Noble, GNOME 46  
**Source:** `~/Projects/repos/dotfiles` (non-standard path — see chezmoi config)

---

## Quick start (new machine)

### 1. Bootstrap (automated)

Copy `~/.age/key.txt` from your previous machine (or Bitwarden secure note) first — needed to decrypt work files.

Then run:

```bash
curl -fsSL https://raw.githubusercontent.com/lachiewalker/dotfiles/main/install.sh | bash
```

`install.sh` handles: git → chezmoi → nvm + node → bw CLI → bw login → chezmoi apply.

### 2. SSH keys

Generate fresh keys per machine — never copy private keys:

```bash
bash scripts/setup-ssh.sh you@example.com
bash scripts/setup-auth.sh
```

### 3. Install packages

```bash
bash scripts/install-packages.sh
```

### 4. Post-install

```bash
gh auth login
glab auth login
tailscale up
nordvpn login
docker login gitlab.yourcompany.com            # credentials stored in GNOME keyring
```

---

## What's tracked

| File | Source | Notes |
|------|--------|-------|
| `~/.bashrc` | `dot_bashrc` | `.bashrc.d/` pattern for tool init |
| `~/.bash_aliases` | `dot_bash_aliases` | Personal aliases (public) |
| `~/.bash_aliases.work` | `encrypted_dot_bash_aliases.work.age` | Work aliases — age encrypted |
| `~/.profile` | `dot_profile` | Login shell config |
| `~/.gitconfig` | `dot_gitconfig.tmpl` | name/email from Bitwarden |
| `~/.ssh/config` | `private_dot_ssh/config.tmpl` | Host entries, no keys |
| `~/.aws/config` | `dot_aws/encrypted_private_config.age` | Age-encrypted — profiles + SSO config |
| `~/.bashrc.d/nvm.sh` | `dot_bashrc.d/nvm.sh` | NVM init |
| `~/.tmux.conf` | `dot_tmux.conf` | tmux config |
| `~/.config/docker/config.json` | `private_dot_config/private_docker/config.json` | Uses secretservice credential helper; XDG path set via `DOCKER_CONFIG` in bashrc |
| `~/.claude/settings.json` | `dot_claude/private_settings.json` | Claude Code settings |
| `~/.claude/CLAUDE.md` | `dot_claude/CLAUDE.md` | Global Claude instructions |
| `~/.agents/skills/` | `dot_agents/skills/` | Custom Claude skills (symlinked from `~/.claude/skills/`) |

## What's never tracked

| Path | Reason |
|------|--------|
| `~/.ssh/github`, `~/.ssh/gitlab` | Generate fresh per machine |
| `~/.gnupg/` | Import manually |
| `~/.aws/credentials` | Ephemeral session tokens only |
| `~/.git-credentials` | Not used (dropped `credential.helper = store`) |
| `~/.bashrc.local` | Machine-local overrides |
| `~/.bash_aliases.work` (plaintext) | Encrypted in repo |
| `~/.age/key.txt` | Private age key — store in Bitwarden |
| `~/.nvm/`, `~/.local/share/cargo/`, `~/.local/share/go/` | Managed by installers |

---

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

---

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

---

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

---

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

---

## Repo structure

```
install.sh                  # bootstrap script — run on a fresh machine
.chezmoi.toml.tmpl          # chezmoi config — pulls identity from Bitwarden
.chezmoiignore              # files chezmoi will never touch
dot_bashrc                  # ~/.bashrc
dot_bashrc.d/
    nvm.sh                  # ~/.bashrc.d/nvm.sh
dot_bash_aliases            # ~/.bash_aliases (personal, public)
encrypted_dot_bash_aliases.work.age     # ~/.bash_aliases.work (age-encrypted)
dot_profile                 # ~/.profile
dot_gitconfig.tmpl          # ~/.gitconfig (template)
private_dot_ssh/
    config.tmpl             # ~/.ssh/config (template)
dot_aws/
    config                  # ~/.aws/config
private_dot_config/
    private_docker/
        config.json         # ~/.config/docker/config.json (secretservice creds helper)
dot_claude/
    CLAUDE.md               # ~/.claude/CLAUDE.md
    private_settings.json   # ~/.claude/settings.json
    skills/                 # symlinks → ~/.agents/skills/
dot_agents/
    skills/                 # ~/.agents/skills/ — actual skill content
gnome/                      # GNOME interface prefs + restore script
packages/                   # apt/snap/flatpak/pipx/npm package lists + install scripts
scripts/                    # runtime + CLI install scripts, repo setup
```
