#!/usr/bin/env bash
# Advisory PreToolUse[Bash] hook: remind before git commit.
set -euo pipefail
input="$(cat || true)"
helper="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}/hooks/lib/json_value.py"
cmd="$(printf '%s' "$input" | python3 "$helper" tool_input.command 2>/dev/null || true)"

printf '%s' "$cmd" | grep -qE '\bgit\b[^;&|]*[[:space:]]commit([[:space:]]|[;&|]|$)' || exit 0

python3 - <<'PY'
import json
msg = "Commit detected. Before committing, run the relevant tests/lint, perform an adversarial review for the change, update docs if behavior changed, then record evidence with hooks/lib/ledger.sh pass all '<evidence>' or deliberately waive with a reason."
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg}}))
PY
