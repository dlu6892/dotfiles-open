#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")

if echo "$command" | grep -qE \
  'push[^|;&]*(--force([-a-z]*)?\b|-f\b)|(--force([-a-z]*)?\b|-f\b)[^|;&]*push|reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*f|checkout[[:space:]]+(--[[:space:]]*)?\.[[:space:]]*$|branch[[:space:]]+-D'
then
  jq -n --arg cmd "$command" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Blocked by hook: destructive git command (" + $cmd + "). Run it manually outside Claude Code if this is truly intended.")
    }
  }'
else
  exit 0
fi
