# Agent guide — this dotfiles repo

Guidance for an AI agent (Claude Code, Codex, …) working **on this repository**.
For the user's global working-style, see their `~/.claude/CLAUDE.md` (this repo's
`config/claude/CLAUDE.md`) and `~/.codex/AGENTS.md` (`config/codex/AGENTS.md`).

> Don't confuse the two: the files under `config/` are the **user-global**
> configs this repo symlinks into `$HOME`. **This** file is **project** context,
> read in place when an agent operates inside `~/git/dots`.

## What this repo is

Personal macOS dotfiles managed by [dotbot](https://github.com/anishathalye/dotbot)
(vendored as the `dotbot` submodule). `./install` reads `install.conf.yaml` to:
install Homebrew packages from `Brewfile`, symlink configs into `$HOME`, and run
setup scripts (`scripts/`). Idempotent — safe to re-run after any change.

## Map

| Path | Purpose |
|---|---|
| `install.conf.yaml` | dotbot manifest — the source of truth for links + setup steps |
| `Brewfile` | Homebrew formulae / casks / `mas` apps / Cursor extensions |
| `zshrc` | shell config (PATH, aliases, fzf/zoxide/starship init, `op`-backed `claude`/`codex` wrappers) |
| `gitconfig_dotfiles` | non-secret git config (aliases, delta pager); included into `~/.gitconfig` |
| `config/claude/` | Claude Code global config (`CLAUDE.md`, `settings.json`, statusline) |
| `config/codex/` | Codex global config (`config.toml`, `AGENTS.md`) |
| `config/mcp/servers.json` | **canonical** MCP server list (synced to all tools) |
| `config/claude-skills/` | tracked Claude/agent skills (symlinked into `~/.claude/skills`) |
| `config/{ruff,starship,vscode}/` | tool configs |
| `scripts/` | `bootstrap.sh` (fresh Mac), `ensure_*.sh`, `sync_mcp_servers.sh`, macOS defaults |

## Setting up a machine

- **Fresh Mac:** `./scripts/bootstrap.sh` — does Xcode CLT, Rosetta, Homebrew,
  App Store check, Claude Code CLI (native installer), clones `browser-harness`,
  runs `./install`, `brew bundle check`, reinstalls Claude plugins, and guides
  1Password / `gh` / `gcloud` auth. See the README runbook.
- **Existing Mac:** `./install`.

## How to maintain (do it this way)

- **Add/remove a Homebrew package** → edit `Brewfile` by hand. Do **not** blind
  `brew bundle dump` (it re-adds churn). The repo is curated to **actual use**:
  before adding something installed on the machine, check usage
  (`mdls -name kMDItemLastUsedDate <app>`, config-dir recency, stale casks whose
  `.app` is gone) and prune what isn't used. Keep the section grouping; record
  removals in the `# Pruned` comment block. Keep experimental/local-AI tooling
  (local LLMs, Ollama, openclaw, hermes) and heavy cloud/IaC/DB tools as
  **install-on-demand** (commented), not default.
- **Add/remove an MCP server** → edit `config/mcp/servers.json` (canonical) then
  run `./scripts/sync_mcp_servers.sh`. Never hand-edit the per-tool MCP configs;
  the script propagates to Claude Code, Cursor, and Codex (plus VS Code if a
  standalone `code` CLI is present — there normally isn't one here, so that target
  skips) and tracks a manifest for clean removals. Non-canonical entries (manually added per tool)
  are preserved by the sync — and may carry secrets, so don't commit them.
- **Add a skill** → drop it under `config/claude-skills/<name>/` and add a
  `~/.claude/skills/<name>` link block to `install.conf.yaml` (mirror the
  existing ones). No secrets in skill files.
- **Change global working-style** → edit `config/claude/CLAUDE.md` AND
  `config/codex/AGENTS.md` together; they intentionally mirror each other
  (Codex's drops the Claude-specific bits).
- **After changing links/scripts** → run `./install` (idempotent) to apply.

## Conventions & gotchas

- **Shell scripts in `scripts/`** are `sh`/`bash` and must pass `shellcheck`
  (it's installed). Prefer `if/then/else` over `A && B || C`. Mark executable;
  wire into `install.conf.yaml` with a `chmod +x` step + a guarded run step.
  (Vendored skill helpers under `config/claude-skills/` are upstream content and
  aren't held to this bar.)
- **`config/codex/config.toml` is symlinked into `~/.codex/`, and Codex writes
  machine-specific state into it** (`[projects.*]`, `[marketplaces.*]`, `notify`,
  `[mcp_servers.node_repl]`, `[desktop]`). Only commit the **portable subset**
  (`personality`, `model`, `model_reasoning_effort`, network `[mcp_servers.*]`,
  `[plugins.*]`). Never `git add` the machine churn — restore with
  `git checkout HEAD -- config/codex/config.toml` and re-apply just the real change.
- **Secrets never live in the repo.** They come from 1Password via `op read`
  (see the `claude`/`codex` wrappers in `zshrc`). GitHub access is over **SSH via
  the 1Password agent** — pushes fail until `scripts/ensure_1password_ssh.sh` has
  run and the agent is enabled; clone over **HTTPS** on a fresh machine.
- `mas` lines need the **App Store app signed in** *and* the apps already owned on
  the Apple ID — otherwise `mas install` fails with a misleading `sudo: a terminal
  is required` error; the App Store GUI is the reliable fallback. `vscode` lines
  install into **Cursor** (`brew bundle` auto-detects the `cursor` CLI; there is no `code`).
- `.DS_Store` is gitignored. `brew bundle` continues past failures — always
  follow installs with `brew bundle check --file Brewfile`. It also **prefetches every
  download before installing any package**, so one slow/CDN-throttled cask (e.g. spotify)
  can stall the whole bundle for minutes with nothing installed — expected, not a hang.
- **`node` is required even though nothing here imports it directly.** `agent-browser`'s
  global bin has a `#!/usr/bin/env node` shebang (engines >= 24) and bun ships no node shim,
  so without `brew "node"` the `agent-browser install` step in `install.conf.yaml` dies with
  `env: node: No such file or directory`. Do **not** prune it as "unused".
- **Claude Code is not brew-managed.** `bootstrap.sh` installs it via the native installer to
  `~/.local/bin`, which `brew shellenv` does **not** add to PATH. `install`, `bootstrap.sh`, and
  `sync_mcp_servers.sh` each export `~/.local/bin` so `command -v claude` resolves in
  non-interactive runs; remove that and the Claude Code MCP sync + `claude plugin install` steps
  silently skip on a fresh machine. (Open a new login shell before `claude` is on PATH interactively.)
- **`docker-desktop`, `zoom`, `openvpn-connect` need sudo/TTY** (pkg installers / a `/usr/local/bin`
  symlink); they fail in a no-TTY `./install` and `brew bundle check` flags them missing — re-run
  `brew bundle install` in a real terminal to finish them.

## Verifying a change before committing

- `brew bundle list --file Brewfile` — Brewfile parses.
- `shellcheck scripts/*.sh` — scripts clean.
- TOML/YAML: `python3 -c "import tomllib; tomllib.load(open('config/codex/config.toml','rb'))"`
  and validate `install.conf.yaml` (`uv run --with pyyaml python -c "import yaml,sys; yaml.safe_load(open('install.conf.yaml'))"`).
