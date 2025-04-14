# My Dotfiles

Personal configuration files managed by Dotbot.

## Setup

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
- [ ] Configure Cursor/VS Code settings sync (Decide method: Built-in Sync or Manual Link)
- [ ] Configure Git settings (`.gitconfig`, potentially `.gitignore_global`) 
    - [ ] User review `.gitconfig` for sensitive data
    - [ ] Copy file(s) to repo
    - [ ] Add link directives
- [ ] Configure installed Brew packages:
    - [ ] Set up `starship` prompt (config file + `zshrc` init)
    - [ ] Verify/Configure `zsh-autocomplete` (check if `zshrc` sourcing needed)
    - [ ] Add manual step reminder for `gh auth login`
