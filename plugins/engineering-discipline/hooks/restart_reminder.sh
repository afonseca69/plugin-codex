#!/usr/bin/env bash
# Advisory PostToolUse[Bash] hook: remind after successful commits to check runtime reload.
set -euo pipefail
input="$(cat || true)"
helper="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}/hooks/lib/json_value.py"
cmd="$(printf '%s' "$input" | python3 "$helper" tool_input.command 2>/dev/null || true)"

printf '%s' "$cmd" | grep -qE '\bgit\b[^;&|]*[[:space:]]commit([[:space:]]|[;&|]|$)' || exit 0

python3 - <<'PY'
import json
msg = "If this commit changes runtime-loaded code or assets, restart/rebuild the affected service and verify logs or observable behavior before claiming the change is live."
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
PY
