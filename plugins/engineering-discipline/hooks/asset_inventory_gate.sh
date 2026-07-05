#!/usr/bin/env bash
# Optional advisory UserPromptSubmit hook: inventory existing assets before building new ones.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
prompt="$(printf '%s' "$input" | python3 "$helper" prompt 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

TRIGGERS='create a|build a|add a new|write a new|implement a|make a new|a new (script|module|hook|tool|feature)'
printf '%s' "$prompt" | grep -qiE "$TRIGGERS" || exit 0

msg="Build-new request detected. Before adding new code in $cwd, inventory existing assets: check relevant paths with rg --files or ls, search keywords with rg, and prefer extending existing code when it already owns the behavior. If new code is still justified, state why the existing asset was not enough."
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": sys.argv[1]}}))
PY
