# My Dotfiles

Personal configuration files managed by Dotbot.

## Setting up a new Mac (full runbook)

`./install` assumes several prerequisites it does not install itself (Homebrew,
Xcode CLT, Rosetta, App Store sign-in, 1Password SSH agent, auth tokens).
`scripts/bootstrap.sh` handles them and then runs `./install`:

```bash
# 1. Xcode Command Line Tools (gives you git)
xcode-select --install

# 2. Clone over HTTPS (SSH isn't wired up yet)
git clone https://github.com/amtagrwl/dots ~/git/dots
cd ~/git/dots

# 3. Bootstrap: Rosetta + Homebrew + submodules + ./install + guided auth
./scripts/bootstrap.sh
```

The bootstrap pauses for the steps that can't be scripted:

- **App Store** — sign in, then install **Amphetamine** and **Bear** from the App Store GUI
  (most reliable). The `mas` lines only succeed if you're signed in *and* already own the apps —
  otherwise `mas install` fails with a misleading `sudo: a terminal is required`.
- **1Password** — sign in; optionally enable Settings → Developer → **Use the SSH
  agent** + **Integrate with 1Password CLI** for human key flows. Agent tooling
  does NOT depend on either: install the **WorkspaceAgents service-account token**
  at `~/.config/agents/op-token` (chmod 600; from the 1Password item
  "Service Account Auth Token: WorkspaceAgents") — the `claude`/`codex` wrappers
  and all unattended agents read the `Agents` vault through it, headless.
- **gh / gcloud** — `gh auth login`, `gh auth setup-git`, `gcloud auth login`, `gcloud auth application-default login`.

Keep this repo on HTTPS so unattended agent automation never blocks on key
approval (`gh auth setup-git` handles credentials):

```bash
git remote set-url origin https://github.com/amtagrwl/dots.git
```

> openclaw / hermes / local-LLM tooling are intentionally **not** in this repo —
> install them per-machine as needed.

## Setup (existing machine)

1. Clone the repository.
2. Run the install script: `./install` (This will link configs and install Brew packages from `Brewfile`)

## Remote iMac Hermes session: Tailscale + mosh + tmux

Use this for MacBook → iMac Hermes TUI work. `tmux` keeps the remote Hermes
session alive; `mosh` makes the interactive terminal survive Wi-Fi drops,
sleep/wake, and IP changes; Tailscale keeps the path private.

Installed by `Brewfile`:

- `tailscale` — tailnet access + `tailscale ip`/`tailscale ping` diagnostics
- `mosh` — resilient UDP interactive shell; uses SSH only for bootstrap
- `tmux` — persistent remote session (`hermes` session name by default)

From the MacBook after `./install` / new shell:

```bash
himac
```

Equivalent explicit command:

```bash
mosh imac
# or for the managed Hermes tmux session:
mosh --server=/opt/homebrew/bin/mosh-server imac -- /opt/homebrew/bin/tmux start-server \; source-file ~/.tmux.conf \; new-session -A -s hermes
```

Diagnostics before first use or after network changes:

```bash
./scripts/check_mosh_tailscale.sh imac
```

First-run MacBook checklist if diagnostics show missing tools or SSH host-key errors:

```bash
cd ~/git/dots
brew bundle install --file Brewfile
./install                                    # writes the iMac SSH block (agents key, not 1P agent)
ssh-keygen -t ed25519 -f ~/.ssh/agents_ed25519 -N ""  # then append the .pub (with from="100.64.0.0/10") to iMac ~/.ssh/authorized_keys
ssh imac                                    # accept the iMac host key once
```

Expected iMac host-key fingerprints:

- ED25519: `SHA256:Af4RDTYJelvGTskwG2KuE1LtzQrRBnDkFTYGTbX67Ns`
- RSA: `SHA256:GYgJ2cZ9Iod5vJzEVQ8LdxRrk1csrQ3ib8wkK/WlwSo`
- ECDSA: `SHA256:RN5VR+5AvHHZoXvtz0/jY5I7z7fF/zNQXmOIXtBayFg`

If the iMac tailnet name or user differs, set overrides in `~/.zshrc.local`:

```bash
export IMAC_TAILSCALE_HOST=imac
export IMAC_TAILSCALE_USER=amtagrwl
export HERMES_TMUX_SESSION=hermes
```

If a dropped TUI leaves Ghostty printing mouse escape sequences like `;151;36M`, run:

```bash
fixterm
```

Copying text:

- `~/.tmux.conf` keeps tmux mouse mode off by default, so normal Ghostty drag/select works in tmux panes.
- If Hermes or another full-screen TUI captures the mouse anyway, hold **Shift** while dragging to force Ghostty native selection.
- tmux keyboard copy still works: `Ctrl-b [` enters copy-mode, select text, then `Enter` or `y` copies to tmux/terminal clipboard when supported.

Notes:

- Tailscale works with mosh: mosh's SSH bootstrap and encrypted UDP session both
  ride the tailnet. This avoids public UDP port-forwarding.
- If mosh starts but shows `Nothing received from server on UDP port ...`, allow
  the iMac mosh server through macOS Application Firewall:

  ```bash
  cd ~/git/dots
  ./scripts/allow_mosh_firewall.sh
  ```

- `mosh` is for interactive shells/TUIs only. Keep using SSH for port forwarding,
  `scp`, `rsync`, and Git.

## Managing Brew Packages

This setup uses a **curated** `Brewfile`. **Edit it by hand** — do *not* run
`brew bundle dump` (it wipes the section grouping, the inline comments, the
install-on-demand block, and the `# Pruned` list, and re-adds everything you
deliberately removed).

1.  **Add a package you actually use:** add the `brew`/`cask`/`mas`/`vscode` line
    in the right section with a short "why" comment.
2.  **Remove a package:** delete its line and move it into the `# Pruned` block so
    it isn't reinstalled by accident.
3.  **Verify it parses:** `brew bundle list --file Brewfile`.
4.  **Install missing packages without upgrading everything:** `./install` uses
    `brew bundle install --file Brewfile --no-upgrade` by design. Use
    `brew bundle upgrade --file Brewfile` or `brew upgrade <name>` only when you
    intentionally want upgrades.
5.  **Commit:**
    ```bash
    git add Brewfile
    git commit -m "feat: add <package/app name> to Brewfile"
    git push
    ```

See `AGENTS.md` → *How to maintain* for the full convention.

## TODO

- [x] Update Dotbot submodule to latest version
- [x] Configure Zsh (`~/.zshrc`)
  - [x] Add PATH modifications
  - [x] Set up `eza` aliases for `ls`, `ll`
  - [x] Add other useful aliases (grep, hist, wget)
  - [x] Add `mkcd` function
  - [x] Enable `AUTO_CD`
- [x] Set up Brew package management (`Brewfile`)
- [x] Review and potentially link other config files (e.g., `tmux.conf`, `profile`?)
- [x] Clean up unused files (bash configs, tmux installer script?)
- [x] Configure Git settings (`.gitconfig_dotfiles`, ensure include in `~/.gitconfig`)
- [ ] Review installed Brew packages & configure:
  - [x] Set up `starship` prompt (config file + `zshrc` init)
  - [ ] Verify/Configure `zsh-autocomplete` (check if `zshrc` sourcing needed)
  - [x] Add manual step reminder for `gh auth login` (see `scripts/bootstrap.sh`)
- [x] Configure VS Code/Cursor settings (`settings.json`, `keybindings.json`)
  - [x] Add files to repository (`config/vscode/`)
  - [x] Review existing settings & extensions (remove unused, consolidate e.g. Ruff, remove Copilot, review IntelliCode)
  - [x] Review Vim extension settings/keybindings specifically
  - [x] Add Dotbot links for `settings.json` and `keybindings.json` (to Cursor config path)
  - [x] Automate extension installation (Brewfile `vscode` lines; `brew bundle` auto-detects the Cursor CLI)
- [x] Configure global Ruff settings (`~/.config/ruff/ruff.toml`)
  - [x] Create `config/ruff/ruff.toml` in repository
  - [x] Add Dotbot link
