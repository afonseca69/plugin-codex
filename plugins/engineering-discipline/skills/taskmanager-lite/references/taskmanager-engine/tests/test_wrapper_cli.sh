#!/usr/bin/env bash
# TaskManager engine wrapper CLI smoke/regression test.
#
# Exercises the manual wrapper only inside disposable temp directories. The
# copied SQL suites invoked by run-sql-tests also create their own temp state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WRAPPER="$ENGINE_DIR/bin/taskmanager-engine.sh"

PASS=0
FAIL=0
ERRORS=""

pass() {
    PASS=$((PASS + 1))
    echo "  PASS: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  FAIL: $1"
    echo "  FAIL: $1"
}

finish() {
    echo "=============================================="
    echo "  PASSED: $PASS"
    echo "  FAILED: $FAIL"
    echo "  TOTAL:  $((PASS + FAIL))"
    echo "=============================================="
    if [[ $FAIL -gt 0 ]]; then
        echo -e "FAILURES:$ERRORS"
        exit 1
    fi
}

assert_contains() {
    local actual="$1"
    local needle="$2"
    local msg="$3"
    if [[ "$actual" == *"$needle"* ]]; then
        pass "$msg"
    else
        fail "$msg (missing '$needle')"
    fi
}

assert_eq() {
    local actual="$1"
    local expected="$2"
    local msg="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$msg"
    else
        fail "$msg (expected='$expected' got='$actual')"
    fi
}

echo "=============================================="
echo "  TASKMANAGER ENGINE WRAPPER CLI"
echo "=============================================="
echo ""

if [[ -x "$WRAPPER" ]]; then
    pass "wrapper script exists and is executable"
else
    fail "wrapper script exists and is executable"
    finish
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PROJECT="$WORK_DIR/project with spaces"
UNINITIALIZED="$WORK_DIR/uninitialized"
mkdir -p "$UNINITIALIZED"

echo "--- Command: help ---"
HELP_OUTPUT=$("$WRAPPER" help)
assert_contains "$HELP_OUTPUT" "init [PROJECT_DIR]" "help documents init"
assert_contains "$HELP_OUTPUT" "run-sql-tests" "help documents run-sql-tests"
assert_contains "$HELP_OUTPUT" "manual" "help includes manual safety note"
echo ""

echo "--- Command: status before init ---"
if STATUS_ERR=$("$WRAPPER" status "$UNINITIALIZED" 2>&1 >/dev/null); then
    fail "status refuses an uninitialized project"
else
    assert_contains "$STATUS_ERR" "not initialized" "status reports clear uninitialized error"
fi
echo ""

echo "--- Command: init ---"
INIT_OUTPUT=$("$WRAPPER" init "$PROJECT")
assert_contains "$INIT_OUTPUT" "Initialized TaskManager engine" "init reports success"
if [[ -f "$PROJECT/.taskmanager/taskmanager.db" ]]; then
    pass "init creates taskmanager.db"
else
    fail "init creates taskmanager.db"
fi
if [[ -f "$PROJECT/.taskmanager/config.json" ]]; then
    pass "init creates config.json"
else
    fail "init creates config.json"
fi
if [[ -d "$PROJECT/.taskmanager/logs" ]]; then
    pass "init creates logs directory"
else
    fail "init creates logs directory"
fi
if SECOND_INIT_ERR=$("$WRAPPER" init "$PROJECT" 2>&1 >/dev/null); then
    fail "init refuses to overwrite an existing database"
else
    assert_contains "$SECOND_INIT_ERR" "already initialized" "init explains existing database refusal"
fi
echo ""

DB="$PROJECT/.taskmanager/taskmanager.db"

echo "--- Command: status ---"
STATUS_OUTPUT=$("$WRAPPER" status "$PROJECT")
assert_contains "$STATUS_OUTPUT" "Schema version: 4.2.0" "status prints schema version"
assert_contains "$STATUS_OUTPUT" "tasks: 0" "status prints task count"
assert_contains "$STATUS_OUTPUT" "regression_checks: 0" "status prints regression check count"
echo ""

echo "--- Command: next ---"
NEXT_EMPTY=$("$WRAPPER" next "$PROJECT")
assert_contains "$NEXT_EMPTY" "No next tasks available" "next reports empty queue"

sqlite3 "$DB" "INSERT INTO tasks (id, title, status, type, priority, dependencies) VALUES ('T-001', 'Wrapper task', 'planned', 'feature', 'high', '[]');"
NEXT_OUTPUT=$("$WRAPPER" next "$PROJECT")
assert_contains "$NEXT_OUTPUT" "T-001" "next prints available task id"
assert_contains "$NEXT_OUTPUT" "Wrapper task" "next prints available task title"
echo ""

echo "--- Command: export-json ---"
COUNT_BEFORE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks;")
EXPORT_OUTPUT=$("$WRAPPER" export-json "$PROJECT")
printf '%s' "$EXPORT_OUTPUT" | python3 -c "import json,sys; data=json.load(sys.stdin); assert data['schema_version']=='4.2.0'; assert data['tasks'][0]['id']=='T-001'; assert isinstance(data['milestones'], list)"
pass "export-json prints parseable core table JSON"
COUNT_AFTER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks;")
assert_eq "$COUNT_AFTER" "$COUNT_BEFORE" "export-json does not mutate tasks"
echo ""

echo "--- Command: run-sql-tests ---"
"$WRAPPER" run-sql-tests
pass "run-sql-tests delegates to copied SQL suites"
echo ""

finish
