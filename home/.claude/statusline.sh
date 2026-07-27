#!/usr/bin/env bash
set -uo pipefail

input=$(cat)

MODEL=$(jq -r '.model.display_name' <<<"$input")
DIR=$(jq -r '.workspace.current_dir' <<<"$input")
SESSION_ID=$(jq -r '.session_id' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // 0' <<<"$input" | cut -d. -f1)
COST=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
DURATION_MS=$(jq -r '.cost.total_duration_ms // 0' <<<"$input")
FIVE_H=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
SEVEN_D=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'

# --- git branch + dirty state, cached per-session for 5s (git status/diff
# are slow and this script runs on every assistant message) ---
CACHE_FILE="/tmp/claude-statusline-git-${SESSION_ID}"
CACHE_MAX_AGE=5

mtime() {
  # Try GNU coreutils form first: this machine's `stat` resolves to Nix's
  # coreutils package, where `-f` means "filesystem mode" (not BSD's format
  # string) and silently emits garbage to stdout on the wrong invocation.
  # Validate the result is purely numeric before trusting either form.
  local f="$1" val
  val=$(stat -c %Y "$f" 2>/dev/null)
  [[ "$val" =~ ^[0-9]+$ ]] && { echo "$val"; return; }
  val=$(stat -f %m "$f" 2>/dev/null)
  [[ "$val" =~ ^[0-9]+$ ]] && { echo "$val"; return; }
  echo 0
}

cache_is_stale() {
  [ ! -f "$CACHE_FILE" ] && return 0
  local age
  age=$(( $(date +%s) - $(mtime "$CACHE_FILE") ))
  [ "$age" -gt "$CACHE_MAX_AGE" ]
}

if cache_is_stale; then
  if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    echo "${BRANCH}|${STAGED}|${MODIFIED}" >"$CACHE_FILE"
  else
    echo "||" >"$CACHE_FILE"
  fi
fi
IFS='|' read -r BRANCH STAGED MODIFIED <"$CACHE_FILE"
STAGED=${STAGED:-0}
MODIFIED=${MODIFIED:-0}

GIT_SEG=""
if [ -n "$BRANCH" ]; then
  GIT_SEG="🌿 ${BRANCH}"
  [ "$STAGED" -gt 0 ] && GIT_SEG="${GIT_SEG} ${GREEN}+${STAGED}${RESET}"
  [ "$MODIFIED" -gt 0 ] && GIT_SEG="${GIT_SEG} ${YELLOW}~${MODIFIED}${RESET}"
fi

# --- context usage bar, color-coded by threshold ---
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"
fi

# --- cost + duration ---
COST_FMT=$(printf '$%.2f' "$COST")
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))

# --- rate limits, only shown when present (Pro/Max subscribers only) ---
RATE_SEG=""
[ -n "$FIVE_H" ] && RATE_SEG="⏳ 5h:$(printf '%.0f' "$FIVE_H")%"
[ -n "$SEVEN_D" ] && RATE_SEG="${RATE_SEG:+${RATE_SEG} }7d:$(printf '%.0f' "$SEVEN_D")%"

LINE1="🧠 ${MODEL}  │  📁 ${DIR##*/}"
[ -n "$GIT_SEG" ] && LINE1="${LINE1}  │  ${GIT_SEG}"

LINE2="${BAR_COLOR}${BAR}${RESET} ${PCT}%  │  💰 ${COST_FMT}  │  ⏱️  ${MINS}m ${SECS}s"
[ -n "$RATE_SEG" ] && LINE2="${LINE2}  │  ${RATE_SEG}"

echo -e "$LINE1"
echo -e "$LINE2"
