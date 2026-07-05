#!/usr/bin/env bash
# Optional advisory UserPromptSubmit hook: verify real files before describing a system.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
prompt="$(printf '%s' "$input" | python3 "$helper" prompt 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

TRIGGERS='how does|what does|how is|explain the|explain how|describe the|walk me through|how it works|what this (code|module|file) does'
printf '%s' "$prompt" | grep -qiE "$TRIGGERS" || exit 0

msg="System-description request detected. Before explaining $cwd, verify the current reality: confirm target files exist, inspect definitions and callers with rg, run safe read-only checks when output matters, and check recent git history when stale memory could mislead the answer."
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": sys.argv[1]}}))
PY
