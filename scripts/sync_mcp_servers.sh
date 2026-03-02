#!/usr/bin/env bash
# sync_mcp_servers.sh — Sync MCP servers from canonical config to all AI tools.
# Reads config/mcp/servers.json, writes tool-specific configs for:
#   Claude Code, Cursor, Codex, VS Code
# Idempotent. Preserves non-canonical entries. Tracks managed servers via manifest.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVERS_JSON="$SCRIPT_DIR/config/mcp/servers.json"
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

# ─── Claude Code ────────────────────────────────────────────────────────────
sync_claude() {
  if ! command -v claude &>/dev/null; then
    echo "  [skip] claude not installed"
    return
  fi

  # Remove servers no longer in canonical config
  for name in "${SERVERS_TO_REMOVE[@]+"${SERVERS_TO_REMOVE[@]}"}"; do
    echo "  [remove] $name"
    claude mcp remove -s user "$name" 2>/dev/null || true
  done

  # Add/update each canonical server
  python3 -c "
import json, subprocess, sys

with open('$SERVERS_JSON') as f:
    servers = json.load(f)['servers']

for name, cfg in servers.items():
    transport = cfg.get('transport', 'stdio')

    # Remove first to ensure clean state
    subprocess.run(['claude', 'mcp', 'remove', '-s', 'user', name],
                   capture_output=True)

    cmd = ['claude', 'mcp', 'add', '-s', 'user', '-t', transport]

    if transport == 'stdio':
        cmd += [name, cfg['command']] + cfg.get('args', [])
    elif transport in ('http', 'sse'):
        url = cfg['url']
        # Positional args must come before -H (which is variadic)
        cmd += [name, url]
        auth = cfg.get('auth', {})
        if auth.get('type') == 'bearer':
            env_var = auth['env_var']
            cmd += ['-H', f'Authorization: Bearer \${{{env_var}}}']

    result = subprocess.run(cmd, capture_output=True, text=True)
    status = 'ok' if result.returncode == 0 else 'FAIL'
    print(f'  [{status}] {name}')
    if result.returncode != 0 and result.stderr:
        print(f'         {result.stderr.strip()}')
"
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
sync_codex() {
  if ! command -v codex &>/dev/null; then
    echo "  [skip] codex not installed"
    return
  fi

  # Remove servers no longer in canonical config
  for name in "${SERVERS_TO_REMOVE[@]+"${SERVERS_TO_REMOVE[@]}"}"; do
    echo "  [remove] $name"
    codex mcp remove "$name" 2>/dev/null || true
  done

  # Add/update each canonical server
  python3 -c "
import json, subprocess, sys

with open('$SERVERS_JSON') as f:
    servers = json.load(f)['servers']

for name, cfg in servers.items():
    transport = cfg.get('transport', 'stdio')

    # Remove first to ensure clean state
    subprocess.run(['codex', 'mcp', 'remove', name], capture_output=True)

    cmd = ['codex', 'mcp', 'add', name]

    if transport == 'stdio':
        cmd += ['--', cfg['command']] + cfg.get('args', [])
    elif transport in ('http', 'sse'):
        cmd += ['--url', cfg['url']]
        auth = cfg.get('auth', {})
        if auth.get('type') == 'bearer':
            cmd += ['--bearer-token-env-var', auth['env_var']]

    result = subprocess.run(cmd, capture_output=True, text=True)
    status = 'ok' if result.returncode == 0 else 'FAIL'
    print(f'  [{status}] {name}')
    if result.returncode != 0 and result.stderr:
        print(f'         {result.stderr.strip()}')
"
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
