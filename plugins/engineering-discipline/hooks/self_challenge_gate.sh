#!/usr/bin/env bash
# Optional advisory UserPromptSubmit hook: challenge deep-task conclusions before delivery.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
prompt="$(printf '%s' "$input" | python3 "$helper" prompt 2>/dev/null || true)"

TRIGGERS='architect|refactor|analy|investigat|design|debug|\bwhy\b|how does|root cause|optimi'
printf '%s' "$prompt" | grep -qiE "$TRIGGERS" || exit 0

msg="Deep task detected. Treat the first draft as unverified: substantiate key claims with concrete reads, searches, logs, or tests; challenge the framing; and deliver the corrected conclusion with any assumptions or gaps called out."
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": sys.argv[1]}}))
PY
