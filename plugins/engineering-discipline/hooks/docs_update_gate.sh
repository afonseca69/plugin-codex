#!/usr/bin/env bash
# Optional advisory PreToolUse[Bash] hook: remind before commit when docs may need updates.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
cmd="$(printf '%s' "$input" | python3 "$helper" tool_input.command 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

COMMIT_RE='\bgit\b[^;&|]*[[:space:]]commit([[:space:]]|[;&|]|$)'
printf '%s' "$cmd" | grep -qE "$COMMIT_RE" || exit 0

msg="Commit detected. Before committing in $cwd, confirm docs debt is paid: update README/docs when behavior, commands, workflows, or constraints changed; record durable decisions, incidents, architecture changes, status, or open questions in docs/ as appropriate; and verify changed docs against code."
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": sys.argv[1]}}))
PY
