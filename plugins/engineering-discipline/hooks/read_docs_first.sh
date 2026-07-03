#!/usr/bin/env bash
# Advisory UserPromptSubmit hook: remind Codex to read living docs before editing.
set -euo pipefail
input="$(cat || true)"
helper="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}/hooks/lib/json_value.py"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

if [ -d "$cwd/docs" ] || [ -f "$cwd/AGENTS.md" ]; then
  python3 - <<'PY'
import json
msg = "Before changing code, inspect AGENTS.md and relevant docs/ files. Treat docs as living project truth and update them when behavior changes."
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}}))
PY
fi
