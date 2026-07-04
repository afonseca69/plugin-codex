#!/usr/bin/env bash
# Codex engineering-discipline verification ledger.
set -euo pipefail

cmd="${1:-}"
shift || true

sha_tool() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'; return; fi
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'; return; fi
  if command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 | awk '{print $NF}'; return; fi
  return 127
}

git_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

ledger_file() {
  if [ -n "${CODEX_DISCIPLINE_LEDGER:-}" ]; then
    printf '%s\n' "$CODEX_DISCIPLINE_LEDGER"
    return
  fi
  local root
  root="$(git_root)"
  mkdir -p "$root/.codex"
  printf '%s\n' "$root/.codex/engineering-discipline-ledger.log"
}

hash_change() {
  local scope="${1:---cached}"
  git rev-parse --git-dir >/dev/null 2>&1 || { echo EMPTY; return 0; }

  local payload status
  case "$scope" in
    --cached)
      payload="$(git diff --binary --cached || true)"
      status="$(git diff --cached --name-status || true)"
      ;;
    --head)
      payload="$(git diff --binary HEAD -- || true)"
      status="$(git status --porcelain=v1 --untracked-files=no || true)"
      ;;
    *) echo "usage: ledger.sh hash [--cached|--head]" >&2; return 2 ;;
  esac

  if [ -z "$payload" ] && [ -z "$status" ]; then
    echo EMPTY
    return 0
  fi

  if ! printf '%s\n---STATUS---\n%s\n' "$payload" "$status" | sha_tool; then
    echo NOHASH
  fi
}

json_line() {
  local ref="$1" kind="$2" status="$3" evidence="$4" ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  python3 - "$ref" "$kind" "$status" "$evidence" "$ts" <<'PY'
import json, sys
ref, kind, status, evidence, ts = sys.argv[1:6]
print(json.dumps({"ts": ts, "ref": ref, "kind": kind, "status": status, "evidence": evidence}, separators=(",", ":")))
PY
}

append_record() {
  local ref="$1" kind="$2" status="$3" evidence="$4" file
  file="$(ledger_file)"
  json_line "$ref" "$kind" "$status" "$evidence" >> "$file"
  printf 'recorded %s=%s for %s in %s\n' "$kind" "$status" "$ref" "$file"
}

covered() {
  local ref="$1" file
  file="$(ledger_file)"
  [ -f "$file" ] || { echo "missing ledger" >&2; return 1; }

  python3 - "$file" "$ref" <<'PY2'
import json
import sys

file_path, target_ref = sys.argv[1], sys.argv[2]
tests = False
adversarial = False
waiver = False

with open(file_path, encoding="utf-8") as handle:
    for line in handle:
        try:
            row = json.loads(line)
        except Exception:
            continue

        if row.get("ref") != target_ref:
            continue

        kind = row.get("kind")
        status = row.get("status")

        if kind == "tests" and status == "pass":
            tests = True
        elif kind == "adversarial" and status == "pass":
            adversarial = True
        elif kind == "waiver" and status == "waived":
            waiver = True

if waiver or (tests and adversarial):
    print("covered")
    sys.exit(0)

missing = []
if not tests:
    missing.append("tests")
if not adversarial:
    missing.append("adversarial")

print("missing:" + " ".join(missing), file=sys.stderr)
sys.exit(1)
PY2
}

current_ref() {
  local ref
  ref="$(hash_change --cached)"
  if [ "$ref" = "EMPTY" ]; then
    ref="$(hash_change --head)"
  fi
  printf '%s\n' "$ref"
}

case "$cmd" in
  hash)
    hash_change "${1:---cached}"
    ;;
  mark)
    kind="${1:-}"; status="${2:-}"; ref="${3:-}"; evidence="${4:-}"
    [ -n "$kind" ] && [ -n "$status" ] && [ -n "$ref" ] && [ -n "$evidence" ] || { echo "usage: ledger.sh mark <tests|adversarial> <pass|fail> <ref> <evidence>" >&2; exit 2; }
    append_record "$ref" "$kind" "$status" "$evidence"
    ;;
  pass)
    target="${1:-}"; evidence="${2:-}"
    [ "$target" = "all" ] && [ -n "$evidence" ] || { echo "usage: ledger.sh pass all <evidence>" >&2; exit 2; }
    ref="$(current_ref)"
    [ "$ref" != "EMPTY" ] && [ "$ref" != "NOHASH" ] || { echo "no hashable current change" >&2; exit 1; }
    append_record "$ref" tests pass "$evidence"
    append_record "$ref" adversarial pass "$evidence"
    ;;
  waive)
    ref="${1:-}"; reason="${2:-}"
    [ -n "$ref" ] && [ -n "$reason" ] || { echo "usage: ledger.sh waive <ref> <reason>" >&2; exit 2; }
    append_record "$ref" waiver waived "$reason"
    ;;
  covered)
    ref="${1:-}"
    [ -n "$ref" ] || { echo "usage: ledger.sh covered <ref>" >&2; exit 2; }
    covered "$ref"
    ;;
  *)
    cat >&2 <<'EOF'
usage:
  ledger.sh hash [--cached|--head]
  ledger.sh pass all <evidence>
  ledger.sh mark <tests|adversarial> <pass|fail> <ref> <evidence>
  ledger.sh waive <ref> <reason>
  ledger.sh covered <ref>
EOF
    exit 2
    ;;
esac
