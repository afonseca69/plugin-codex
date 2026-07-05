#!/usr/bin/env bash
# Optional advisory Stop hook: remind to curate docs while session context is fresh.
set -euo pipefail
input="$(cat || true)"
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
helper="$root/hooks/lib/json_value.py"
cwd="$(printf '%s' "$input" | python3 "$helper" cwd 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

docs_dir="${SCRIBE_DOCS_DIR:-docs}"
case "$docs_dir" in
  /*) docs_path="$docs_dir" ;;
  *) docs_path="$cwd/$docs_dir" ;;
esac

[ -d "$docs_path" ] || exit 0

capture_log="${SCRIBE_CAPTURE_LOG:-$docs_dir/.scribe/capture.log}"
case "$capture_log" in
  /*) capture_path="$capture_log" ;;
  *) capture_path="$cwd/$capture_log" ;;
esac

capture_note=""
if [ -s "$capture_path" ]; then
  capture_note=" Uncurated breadcrumbs exist in $capture_log."
fi

msg="Session stopping with $docs_dir/ present. Curate decisions, errors, and shipped behavior into docs/ while context is fresh; sweep stale roadmap, open-question, ADR, and status claims; then verify changed docs against code.$capture_note"
python3 - "$msg" <<'PY'
import json
import sys

print(json.dumps({"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": sys.argv[1]}}))
PY
