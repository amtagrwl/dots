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

- **App Store** — sign in (so `mas` can install Amphetamine, Bear).
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

This setup uses a `Brewfile` to manage Homebrew packages (formulae and casks).

1.  **Install normally:** Use `brew install <formula>` or `brew install --cask <app>` as usual.
2.  **Update Brewfile:** If you want the new package to be part of your permanent setup (and automatically installed by `./install` on new machines), run:
    ```bash
    brew bundle dump --file=./Brewfile --force
    ```
    This overwrites the existing `Brewfile` with your current explicitly installed packages.
3.  **Commit changes:**
    ```bash
    git add Brewfile
    git commit -m "feat: Add <package/app name> to Brewfile"
    git push
    ```

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
