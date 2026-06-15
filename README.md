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
- **1Password** — sign in, then Settings → Developer → enable **Use the SSH agent**
  and **Integrate with 1Password CLI**. This is what makes `git push` over SSH work
  (keys live in 1Password) and what lets the `claude`/`codex` shell wrappers read
  `op://Personal/Claude Code Github MCP/credential`.
- **gh / gcloud** — `gh auth login`, `gcloud auth login`, `gcloud auth application-default login`.

After 1Password's SSH agent is on, switch this repo to SSH:

```bash
git remote set-url origin git@github.com:amtagrwl/dots.git
ssh -T git@github.com   # should greet you by username
```

> openclaw / hermes / local-LLM tooling are intentionally **not** in this repo —
> install them per-machine as needed.

## Setup (existing machine)

1. Clone the repository.
2. Run the install script: `./install` (This will link configs and install Brew packages from `Brewfile`)

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
4.  **Commit:**
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
