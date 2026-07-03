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
    --cached) payload="$(git diff --binary --cached || true)" ;;
    --head) payload="$(git diff --binary HEAD -- || true)" ;;
    *) echo "usage: ledger.sh hash [--cached|--head]" >&2; return 2 ;;
  esac

  status="$(git status --porcelain=v1 --untracked-files=no || true)"
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
  local ref="$1" file tests adversarial waiver
  file="$(ledger_file)"
  [ -f "$file" ] || { echo "missing ledger" >&2; return 1; }
  tests=0; adversarial=0; waiver=0
  while IFS= read -r line; do
    python3 - "$ref" "$line" <<'PY'
import json, sys
ref = sys.argv[1]
line = sys.argv[2]
try:
    row = json.loads(line)
except Exception:
    sys.exit(1)
if row.get("ref") != ref:
    sys.exit(1)
print(f"{row.get('kind','')}={row.get('status','')}")
PY
  done < "$file" | while IFS= read -r pair; do
    case "$pair" in
      tests=pass) echo tests ;;
      adversarial=pass) echo adversarial ;;
      waiver=waived) echo waiver ;;
    esac
  done | sort -u | {
    while IFS= read -r item; do
      case "$item" in
        tests) tests=1 ;;
        adversarial) adversarial=1 ;;
        waiver) waiver=1 ;;
      esac
    done
    if [ "$waiver" = 1 ] || { [ "$tests" = 1 ] && [ "$adversarial" = 1 ]; }; then
      echo covered
      exit 0
    fi
    missing=""
    [ "$tests" = 0 ] && missing="${missing} tests"
    [ "$adversarial" = 0 ] && missing="${missing} adversarial"
    echo "missing:${missing}" >&2
    exit 1
  }
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
