#!/usr/bin/env bash
# sync_mcp_servers.sh — Sync MCP servers from canonical config to all AI tools.
# Reads config/mcp/servers.json, writes tool-specific configs for:
#   Claude Code (~/.claude.json mcpServers key — direct JSON round-trip, backed up first)
#   Codex (config/codex/config.toml [mcp_servers.*] tables — direct text patch, touches
#          ONLY the tables for canonical server names; node_repl, its env block, notify,
#          and [plugins.*] are Codex.app-generated and are never touched)
#   Cursor, VS Code (best-effort, non-canonical tools)
# Idempotent. Preserves non-canonical/manually-added entries. Tracks managed
# servers via manifest so removing a server from servers.json removes it everywhere.
set -euo pipefail

# dotbot runs shell steps non-interactively, so ~/.zshrc PATH edits don't apply.
# Make user-local bins reachable (this is where the native `claude` install lives).
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVERS_JSON="$SCRIPT_DIR/config/mcp/servers.json"
CODEX_CONFIG="$SCRIPT_DIR/config/codex/config.toml"
MANIFEST="$HOME/.config/dots-mcp-managed.json"

if [ ! -f "$SERVERS_JSON" ]; then
  echo "ERROR: $SERVERS_JSON not found" >&2
  exit 1
fi

# Extract server names from canonical config
CANONICAL_SERVERS=$(python3 -c "
import json, sys
with open('$SERVERS_JSON') as f:
    data = json.load(f)
for name in sorted(data['servers']):
    print(name)
")

# Load previous manifest (for removal tracking)
PREV_MANAGED=()
if [ -f "$MANIFEST" ]; then
  while IFS= read -r line; do
    PREV_MANAGED+=("$line")
  done < <(python3 -c "
import json
with open('$MANIFEST') as f:
    data = json.load(f)
for name in data.get('servers', []):
    print(name)
")
fi

# Compute servers to remove (in previous manifest but not in canonical)
SERVERS_TO_REMOVE=()
for prev in "${PREV_MANAGED[@]+"${PREV_MANAGED[@]}"}"; do
  found=false
  for canonical in $CANONICAL_SERVERS; do
    if [ "$prev" = "$canonical" ]; then
      found=true
      break
    fi
  done
  if [ "$found" = false ]; then
    SERVERS_TO_REMOVE+=("$prev")
  fi
done
MCP_TO_REMOVE="${SERVERS_TO_REMOVE[*]+"${SERVERS_TO_REMOVE[*]}"}"

# ─── Claude Code ────────────────────────────────────────────────────────────
# Direct JSON round-trip on ~/.claude.json — this file is large, live, and
# machine-local (app state, project cache, etc). We touch ONLY the top-level
# "mcpServers" key: merge canonical servers in, drop previously-managed ones
# that were removed from servers.json, leave every other key byte-identical,
# and leave any manually-added (untracked) server entries alone. Back up
# first since a live Claude Code session may also write this file.
sync_claude() {
  local target="$HOME/.claude.json"
  if [ ! -f "$target" ]; then
    echo "  [skip] $target not found"
    return
  fi

  CLAUDE_JSON="$target" SERVERS_JSON="$SERVERS_JSON" MCP_TO_REMOVE="$MCP_TO_REMOVE" \
    python3 - <<'PYEOF'
import json
import os
import shutil
import sys

TARGET = os.environ["CLAUDE_JSON"]
SERVERS_JSON = os.environ["SERVERS_JSON"]
TO_REMOVE = set(n for n in os.environ.get("MCP_TO_REMOVE", "").split() if n)

with open(SERVERS_JSON) as f:
    servers = json.load(f)["servers"]


def build_entry(cfg):
    transport = cfg.get("transport", "stdio")
    if transport == "stdio":
        return {
            "type": "stdio",
            "command": cfg["command"],
            "args": cfg.get("args", []),
            "env": {},
        }
    entry = {"type": transport, "url": cfg["url"]}
    auth = cfg.get("auth", {})
    if auth.get("type") == "bearer":
        entry["headers"] = {"Authorization": "Bearer ${%s}" % auth["env_var"]}
    return entry


with open(TARGET) as f:
    data = json.load(f)

old_mcp = data.get("mcpServers", {})
new_mcp = dict(old_mcp)  # preserve any untracked/manually-added entries

for name, cfg in servers.items():
    new_mcp[name] = build_entry(cfg)

for name in TO_REMOVE - set(servers.keys()):
    new_mcp.pop(name, None)

if new_mcp == old_mcp:
    print("  [ok] no changes (mcpServers already in sync)")
    sys.exit(0)

added = sorted(set(new_mcp) - set(old_mcp))
removed = sorted(set(old_mcp) - set(new_mcp))
changed = sorted(
    n for n in (set(new_mcp) & set(old_mcp)) if old_mcp[n] != new_mcp[n]
)

backup = TARGET + ".bak-mcp-sync"
shutil.copy2(TARGET, backup)

data["mcpServers"] = new_mcp
with open(TARGET, "w") as f:
    json.dump(data, f, indent=2)

for n in added:
    print(f"  [add] {n}")
for n in removed:
    print(f"  [remove] {n}")
for n in changed:
    print(f"  [update] {n}")
print(f"  backup: {backup}")
PYEOF
}

# ─── Cursor ─────────────────────────────────────────────────────────────────
sync_cursor() {
  if [ ! -d "$HOME/.cursor" ]; then
    echo "  [skip] ~/.cursor not found"
    return
  fi

  local target="$HOME/.cursor/mcp.json"

  python3 -c "
import json, os

target = '$target'
servers_json = '$SERVERS_JSON'
to_remove = '''${SERVERS_TO_REMOVE[*]+"${SERVERS_TO_REMOVE[*]}"}'''.split()

# Load existing config (preserve non-canonical entries like DBHub)
existing = {}
if os.path.exists(target):
    with open(target) as f:
        existing = json.load(f)

mcp = existing.setdefault('mcpServers', {})

# Remove servers no longer in canonical config
for name in to_remove:
    if name in mcp:
        del mcp[name]
        print(f'  [remove] {name}')

# Load canonical servers
with open(servers_json) as f:
    servers = json.load(f)['servers']

for name, cfg in servers.items():
    transport = cfg.get('transport', 'stdio')
    entry = {}

    if transport == 'stdio':
        entry['command'] = cfg['command']
        entry['args'] = cfg.get('args', [])
    elif transport in ('http', 'sse'):
        entry['url'] = cfg['url']
        auth = cfg.get('auth', {})
        if auth.get('type') == 'bearer':
            env_var = auth['env_var']
            entry['headers'] = {
                'Authorization': f'Bearer \${{{\"env:\" + env_var}}}'
            }

    mcp[name] = entry
    print(f'  [ok] {name}')

with open(target, 'w') as f:
    json.dump(existing, f, indent=2)
    f.write('\n')
"
}

# ─── Codex ──────────────────────────────────────────────────────────────────
# Direct text patch on config/codex/config.toml (the real file — ~/.codex/config.toml
# is a symlink to it). Touches ONLY [mcp_servers.<name>] tables whose name is in the
# canonical set or was previously managed by this script; every other top-level table
# (mcp_servers.node_repl + its env sub-table, notify, [plugins.*], [projects.*],
# [marketplaces.*], [features], [desktop], ...) is reproduced byte-for-byte untouched,
# in its original position.
sync_codex() {
  if [ ! -f "$CODEX_CONFIG" ]; then
    echo "  [skip] $CODEX_CONFIG not found"
    return
  fi

  CODEX_CONFIG="$CODEX_CONFIG" SERVERS_JSON="$SERVERS_JSON" MCP_TO_REMOVE="$MCP_TO_REMOVE" \
    python3 - <<'PYEOF'
import json
import os
import re
import sys

CONFIG = os.environ["CODEX_CONFIG"]
SERVERS_JSON = os.environ["SERVERS_JSON"]
TO_REMOVE = [n for n in os.environ.get("MCP_TO_REMOVE", "").split() if n]

with open(SERVERS_JSON) as f:
    servers = json.load(f)["servers"]

with open(CONFIG) as f:
    text = f.read()

managed_names = set(servers.keys()) | set(TO_REMOVE)

# Split into top-level blocks by exact "[table.name]" header lines.
header_re = re.compile(r'^\[([A-Za-z0-9_.\"-]+)\]\s*$', re.MULTILINE)
matches = list(header_re.finditer(text))

preamble = text[: matches[0].start()] if matches else text
blocks = []  # (header_name, full_block_text_including_header_line)
for i, m in enumerate(matches):
    start = m.start()
    end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
    blocks.append((m.group(1), text[start:end]))


def render_block(name, cfg):
    transport = cfg.get("transport", "stdio")
    lines = [f"[mcp_servers.{name}]"]
    if transport == "stdio":
        lines.append(f'command = {json.dumps(cfg["command"])}')
        lines.append(f'args = {json.dumps(cfg.get("args", []))}')
    else:
        lines.append(f'url = {json.dumps(cfg["url"])}')
        auth = cfg.get("auth", {})
        if auth.get("type") == "bearer":
            lines.append(f'bearer_token_env_var = {json.dumps(auth["env_var"])}')
    return "\n".join(lines) + "\n"


# Managed blocks: header is EXACTLY "mcp_servers.<name>" for a name we manage.
# Never matches "mcp_servers.node_repl", "mcp_servers.node_repl.env", or [plugins.*].
managed_indices = []
for i, (name, _) in enumerate(blocks):
    if name.startswith("mcp_servers."):
        server_name = name[len("mcp_servers."):]
        if server_name in managed_names and name == f"mcp_servers.{server_name}":
            managed_indices.append(i)

old_present = {
    blocks[i][0][len("mcp_servers."):]: blocks[i][1] for i in managed_indices
}

insertion_index = min(managed_indices) if managed_indices else 0

# Remove old managed blocks (highest index first to keep remaining indices valid)
for i in sorted(managed_indices, reverse=True):
    del blocks[i]

# Fresh canonical blocks in servers.json order, blank-line separated, with a
# trailing blank line so whatever follows (e.g. node_repl) keeps its separator.
new_managed_text = "\n".join(render_block(n, c) for n, c in servers.items()) + "\n"
blocks.insert(insertion_index, ("__MANAGED__", new_managed_text))

new_text = preamble + "".join(body for _, body in blocks)

added = sorted(set(servers) - set(old_present))
removed = sorted(set(old_present) - set(servers))
changed = sorted(
    n for n in (set(servers) & set(old_present))
    if old_present[n].strip() != render_block(n, servers[n]).strip()
)

if new_text == text:
    print("  [ok] no changes (config.toml already in sync)")
    sys.exit(0)

with open(CONFIG, "w") as f:
    f.write(new_text)

for n in added:
    print(f"  [add] {n}")
for n in removed:
    print(f"  [remove] {n}")
for n in changed:
    print(f"  [update] {n}")
if not (added or removed or changed):
    print("  [ok] formatting normalized (no server changes)")
PYEOF
}

# ─── VS Code ───────────────────────────────────────────────────────────────
sync_vscode() {
  if ! command -v code &>/dev/null; then
    echo "  [skip] VS Code not installed"
    return
  fi

  local target="$HOME/.vscode/mcp.json"
  mkdir -p "$HOME/.vscode"

  python3 -c "
import json, os

target = '$target'
servers_json = '$SERVERS_JSON'
to_remove = '''${SERVERS_TO_REMOVE[*]+"${SERVERS_TO_REMOVE[*]}"}'''.split()

# Load existing config
existing = {}
if os.path.exists(target):
    with open(target) as f:
        existing = json.load(f)

svrs = existing.setdefault('servers', {})

# Remove servers no longer in canonical config
for name in to_remove:
    if name in svrs:
        del svrs[name]
        print(f'  [remove] {name}')

# Load canonical servers
with open(servers_json) as f:
    servers = json.load(f)['servers']

for name, cfg in servers.items():
    transport = cfg.get('transport', 'stdio')
    entry = {'type': transport}

    if transport == 'stdio':
        entry['command'] = cfg['command']
        entry['args'] = cfg.get('args', [])
    elif transport in ('http', 'sse'):
        entry['url'] = cfg['url']
        auth = cfg.get('auth', {})
        if auth.get('type') == 'bearer':
            env_var = auth['env_var']
            entry['headers'] = {
                'Authorization': f'Bearer \${{{\"env:\" + env_var}}}'
            }

    svrs[name] = entry
    print(f'  [ok] {name}')

with open(target, 'w') as f:
    json.dump(existing, f, indent=2)
    f.write('\n')
"
}

# ─── Main ───────────────────────────────────────────────────────────────────
echo "Syncing MCP servers from $SERVERS_JSON"
echo ""

echo "Claude Code:"
sync_claude

echo ""
echo "Cursor:"
sync_cursor

echo ""
echo "Codex:"
sync_codex

echo ""
echo "VS Code:"
sync_vscode

# Update manifest
mkdir -p "$(dirname "$MANIFEST")"
python3 -c "
import json
servers = '''$CANONICAL_SERVERS'''.split()
with open('$MANIFEST', 'w') as f:
    json.dump({'servers': servers}, f, indent=2)
    f.write('\n')
"

echo ""
echo "Manifest updated: $MANIFEST"
echo "Done."
