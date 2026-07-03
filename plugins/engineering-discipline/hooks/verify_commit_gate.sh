#!/usr/bin/env bash
# Optional strict PreToolUse[Bash] hook: check ledger before git commit.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
cmd="$(printf '%s' "$input" | python3 "$helper" tool_input.command 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

COMMIT_RE='\bgit\b[^;&|]*[[:space:]]commit([[:space:]]|[;&|]|$)'
printf '%s' "$cmd" | grep -qE "$COMMIT_RE" || exit 0

cd "$cwd" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
ledger="$root/hooks/lib/ledger.sh"
[ -f "$ledger" ] || exit 0

cmd_flags="$(printf '%s' "$cmd" | sed "s/\"[^\"]*\"//g; s/'[^']*'//g")"
scope="--cached"
if printf '%s' "$cmd_flags" | grep -qE "[[:space:]](-[A-Za-z]*[aio][A-Za-z]*|--all|--only|--include|--pathspec-from-file)([[:space:]]|=|$)" \
   || printf '%s' "$cmd_flags" | grep -qE "[[:space:]]--([[:space:]]|$)"; then
  scope="--head"
fi

ref="$(bash "$ledger" hash "$scope" 2>/dev/null || echo EMPTY)"
if [ "$ref" = "EMPTY" ] && [ "$scope" = "--cached" ]; then
  head_ref="$(bash "$ledger" hash --head 2>/dev/null || echo EMPTY)"
  [ "$head_ref" != "EMPTY" ] && ref="$head_ref"
fi
[ "$ref" = "EMPTY" ] && exit 0

if [ "$ref" = "NOHASH" ]; then
  python3 - <<'PY'
import json
reason = "engineering-discipline: no sha256 tool found, so verification cannot be bound to this change."
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
PY
  exit 0
fi

if bash "$ledger" covered "$ref" >/dev/null 2>&1; then
  exit 0
fi

reason="engineering-discipline: this change ($ref) is not covered by tests+adversarial evidence or a waiver. Record evidence with: bash '$ledger' pass all '<what was run and what survived>'; or waive with: bash '$ledger' waive $ref '<why low risk>'."
python3 - "$reason" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": sys.argv[1]}}))
PY
