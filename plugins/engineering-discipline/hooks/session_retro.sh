#!/usr/bin/env bash
# Optional advisory UserPromptSubmit hook: capture durable lessons on wrap-up prompts.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
prompt="$(printf '%s' "$input" | python3 "$helper" prompt 2>/dev/null || true)"

TRIGGERS="done for|wrap up|that's all|let's stop here|call it a day|/clear|wrapping up|retro|recap|postmortem|that's it for today"
printf '%s' "$prompt" | grep -qiE "$TRIGGERS" || exit 0

msg="Wrap-up detected. Spend a minute crystallizing durable lessons: the non-obvious issue and root cause, any rule of thumb that survived scrutiny, and any docs or follow-up notes needed so the next session does not relearn it."
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": sys.argv[1]}}))
PY
