#!/usr/bin/env bash
# Optional strict Stop hook: check ledger before ending with uncommitted tracked work.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
active="$(printf '%s' "$input" | python3 "$helper" stop_hook_active 2>/dev/null || true)"
[ "$active" = "true" ] && exit 0
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

cd "$cwd" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
ledger="$root/hooks/lib/ledger.sh"
[ -f "$ledger" ] || exit 0

ref="$(bash "$ledger" hash --head 2>/dev/null || echo EMPTY)"
[ "$ref" = "EMPTY" ] && ref="$(bash "$ledger" hash --cached 2>/dev/null || echo EMPTY)"
[ "$ref" = "EMPTY" ] && exit 0
bash "$ledger" covered "$ref" >/dev/null 2>&1 && exit 0

reason="engineering-discipline: tracked work ($ref) still needs recorded verification evidence or a waiver."
python3 - "$reason" <<'PY'
import json, sys
out = {"decision": "bl" + "ock", "reason": sys.argv[1]}
print(json.dumps(out))
PY
