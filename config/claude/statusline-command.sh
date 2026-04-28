#!/usr/bin/env bash
# Claude Code status line — colorful, git-aware, worktree-safe
# Worktree:  🌳 ⎇ gleaming-twirling-moon ✓ │ voice-eval-stack │ [██ 19% ░░░░]
# Main repo: ⚠ MAIN REPO │ ⎇ main ±2 ⇡3 │ voice-eval-stack │ [██████ 85% ]

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- ANSI colors ---
R=$'\033[0m'
DIM=$'\033[38;5;240m'
BRED=$'\033[1;91m'
GRN=$'\033[32m'
BGRN=$'\033[92m'
YLW=$'\033[33m'
BYLW=$'\033[93m'
BLU=$'\033[34m'
MAG=$'\033[35m'
RED=$'\033[31m'
BCYN=$'\033[96m'
BMAG=$'\033[95m'

sep="${DIM} │ ${R}"

# --- Git info ---
git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
  || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

# --- Worktree detection & project name ---
is_worktree=false
if echo "$cwd" | grep -q '\.claude/worktrees/'; then
  is_worktree=true
  # Real repo name from path before .claude/worktrees/
  project_name=$(echo "$cwd" | sed 's|/.claude/worktrees/.*||' | awk -F'/' '{print $NF}')
  # Strip "worktree-" prefix from branch name (🌳 already signals worktree)
  git_branch="${git_branch#worktree-}"
else
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$git_root" ]; then
    project_name=$(basename "$git_root")
  else
    project_name=$(basename "$cwd")
  fi
fi

# Dirty state
dirty_count=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
staged_count=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')

# Ahead/behind remote
ahead=0; behind=0
upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
if [ -n "$upstream" ]; then
  ab=$(git -C "$cwd" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)
  ahead=$(echo "$ab" | awk '{print $1}')
  behind=$(echo "$ab" | awk '{print $2}')
fi

# Stash count
stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')

# --- Build output ---
out=""

# 1) Safety indicator
if [ "$is_worktree" = true ]; then
  out+="${GRN}🌳${R}"
else
  out+="${BRED}⚠ MAIN REPO${R}"
fi

out+="$sep"

# 2) Git branch + status
if [ -n "$git_branch" ]; then
  if [ "$dirty_count" -gt 0 ] 2>/dev/null; then
    out+="${BYLW}⎇ ${git_branch}${R}"
    if [ "$staged_count" -gt 0 ] 2>/dev/null; then
      out+=" ${GRN}●${staged_count}${R}"
    fi
    unstaged=$((dirty_count - staged_count))
    if [ "$unstaged" -gt 0 ] 2>/dev/null; then
      out+=" ${YLW}±${unstaged}${R}"
    fi
  else
    out+="${BGRN}⎇ ${git_branch} ✓${R}"
  fi

  if [ "$ahead" -gt 0 ] 2>/dev/null; then
    out+=" ${BCYN}⇡${ahead}${R}"
  fi
  if [ "$behind" -gt 0 ] 2>/dev/null; then
    out+=" ${BMAG}⇣${behind}${R}"
  fi
  if [ "$stash_count" -gt 0 ] 2>/dev/null; then
    out+=" ${MAG}≡${stash_count}${R}"
  fi
else
  out+="${RED}no git${R}"
fi

out+="$sep"

# 3) Project name
out+="${BLU}${project_name}${R}"

# 4) Context bar with percentage INSIDE (background-colored)
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")

  # Color thresholds
  if [ "$used_int" -lt 50 ]; then
    fill_bg=$'\033[42m';  fill_fg=$'\033[97m'   # green bg, white text
  elif [ "$used_int" -lt 75 ]; then
    fill_bg=$'\033[43m';  fill_fg=$'\033[30m'   # yellow bg, black text
  else
    fill_bg=$'\033[41m';  fill_fg=$'\033[97m'   # red bg, white text
  fi
  empty_bg=$'\033[48;5;238m'; empty_fg=$'\033[97m'  # dark gray bg, white text

  # Build centered text in a 10-char bar, character by character
  # Each char gets filled or empty bg; text is centered white overlay
  bar_w=10
  pct_str="${used_int}%"
  pct_len=${#pct_str}
  txt_start=$(( (bar_w - pct_len) / 2 ))
  filled_w=$(( used_int * bar_w / 100 ))
  if [ "$filled_w" -gt "$bar_w" ]; then filled_w=$bar_w; fi
  fg=$'\033[97m'  # always white text

  out+="$sep"
  for ((i=0; i<bar_w; i++)); do
    if ((i < filled_w)); then bg="$fill_bg"; else bg="$empty_bg"; fi
    if ((i >= txt_start && i < txt_start + pct_len)); then
      ch="${pct_str:$((i - txt_start)):1}"
    else
      ch=" "
    fi
    out+="${bg}${fg}${ch}"
  done
  out+="${R}"
fi

printf '%s\n' "$out"
