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
assert_contains "$HELP_OUTPUT" "show PROJECT_DIR" "help documents read-only show"
assert_contains "$HELP_OUTPUT" "memory-list PROJECT_DIR" "help documents memory-list"
assert_contains "$HELP_OUTPUT" "memory-add PROJECT_DIR" "help documents memory-add"
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
echo ""

echo "--- Command: show on empty DB ---"
SHOW_EMPTY_OVERVIEW=$("$WRAPPER" show "$PROJECT" overview)
assert_contains "$SHOW_EMPTY_OVERVIEW" "tasks: 0" "show overview handles empty tasks"
assert_contains "$SHOW_EMPTY_OVERVIEW" "memories: 0" "show overview handles empty memories"
SHOW_EMPTY_TASKS=$("$WRAPPER" show "$PROJECT" tasks)
assert_contains "$SHOW_EMPTY_TASKS" "No tasks found" "show tasks handles empty table"
SHOW_EMPTY_MILESTONES=$("$WRAPPER" show "$PROJECT" milestones)
assert_contains "$SHOW_EMPTY_MILESTONES" "No milestones found" "show milestones handles empty table"
SHOW_EMPTY_MEMORIES=$("$WRAPPER" show "$PROJECT" memories)
assert_contains "$SHOW_EMPTY_MEMORIES" "No memories found" "show memories handles empty table"
SHOW_EMPTY_DEFERRALS=$("$WRAPPER" show "$PROJECT" deferrals)
assert_contains "$SHOW_EMPTY_DEFERRALS" "No deferrals found" "show deferrals handles empty table"
SHOW_EMPTY_VERIFICATIONS=$("$WRAPPER" show "$PROJECT" verifications)
assert_contains "$SHOW_EMPTY_VERIFICATIONS" "No verifications found" "show verifications handles empty table"
SHOW_EMPTY_REGRESSIONS=$("$WRAPPER" show "$PROJECT" regressions)
assert_contains "$SHOW_EMPTY_REGRESSIONS" "No regression checks found" "show regressions handles empty table"
echo ""

echo "--- Command: memory operations ---"
MEMORY_LIST_EMPTY=$("$WRAPPER" memory-list "$PROJECT")
assert_contains "$MEMORY_LIST_EMPTY" "No memories found" "memory-list handles empty table"

if MEMORY_ADD_USAGE_ERR=$("$WRAPPER" memory-add "$PROJECT" decision "Missing body" 2>&1 >/dev/null); then
    fail "memory-add requires body"
else
    assert_contains "$MEMORY_ADD_USAGE_ERR" "memory-add requires PROJECT_DIR TYPE TITLE BODY" "memory-add explains missing body"
fi

if MEMORY_ADD_TYPE_ERR=$("$WRAPPER" memory-add "$PROJECT" unsupported "Bad type" "Body" 2>&1 >/dev/null); then
    fail "memory-add rejects invalid memory type"
else
    assert_contains "$MEMORY_ADD_TYPE_ERR" "TYPE must be one of" "memory-add explains invalid type"
fi

if MEMORY_ADD_IMPORTANCE_ERR=$("$WRAPPER" memory-add "$PROJECT" decision "Bad importance" "Body" 6 2>&1 >/dev/null); then
    fail "memory-add rejects invalid importance"
else
    assert_contains "$MEMORY_ADD_IMPORTANCE_ERR" "IMPORTANCE must be between 1 and 5" "memory-add explains invalid importance"
fi

if MEMORY_ADD_CONFIDENCE_ERR=$("$WRAPPER" memory-add "$PROJECT" decision "Bad confidence" "Body" 3 1.5 2>&1 >/dev/null); then
    fail "memory-add rejects invalid confidence"
else
    assert_contains "$MEMORY_ADD_CONFIDENCE_ERR" "CONFIDENCE must be a number between 0 and 1" "memory-add explains invalid confidence"
fi

if MEMORY_SHOW_USAGE_ERR=$("$WRAPPER" memory-show "$PROJECT" 2>&1 >/dev/null); then
    fail "memory-show requires MEMORY_ID"
else
    assert_contains "$MEMORY_SHOW_USAGE_ERR" "memory-show requires PROJECT_DIR MEMORY_ID" "memory-show explains missing memory id"
fi

if MEMORY_SEARCH_USAGE_ERR=$("$WRAPPER" memory-search "$PROJECT" 2>&1 >/dev/null); then
    fail "memory-search requires QUERY"
else
    assert_contains "$MEMORY_SEARCH_USAGE_ERR" "memory-search requires PROJECT_DIR QUERY" "memory-search explains missing query"
fi

MEMORY_ADD_OUTPUT=$("$WRAPPER" memory-add "$PROJECT" decision "Manual memory" "This manual memory proves wrapper writes." 4 0.95)
assert_contains "$MEMORY_ADD_OUTPUT" "Created memory:" "memory-add reports created memory id"
CREATED_MEMORY_ID="${MEMORY_ADD_OUTPUT##*: }"
assert_eq "$CREATED_MEMORY_ID" "M-001" "memory-add creates the first stable memory id"
CREATED_MEMORY_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE id = 'M-001' AND kind = 'decision' AND title = 'Manual memory' AND importance = 4 AND confidence = 0.95 AND status = 'active';")
assert_eq "$CREATED_MEMORY_COUNT" "1" "memory-add inserts one active memory row"

MEMORY_FALLBACK_OUTPUT=$("$WRAPPER" memory-add "$PROJECT" decision "Fallback \"memory" "This title forces FTS fallback search coverage." 3 0.8)
assert_contains "$MEMORY_FALLBACK_OUTPUT" "Created memory: M-002" "memory-add creates the next stable memory id"

MEMORY_QUOTE_OUTPUT=$("$WRAPPER" memory-add "$PROJECT" convention "Owner's memory" "Don't skip SQL quoting coverage." 3 0.8)
assert_contains "$MEMORY_QUOTE_OUTPUT" "Created memory: M-003" "memory-add handles apostrophes in title and body"

DB_SHA_MEMORY_READS_BEFORE=$(sha256sum "$DB")
MEMORY_LIST_OUTPUT=$("$WRAPPER" memory-list "$PROJECT" 5)
assert_contains "$MEMORY_LIST_OUTPUT" "M-001" "memory-list prints created memory id"
assert_contains "$MEMORY_LIST_OUTPUT" "Manual memory" "memory-list prints created memory title"

MEMORY_SHOW_OUTPUT=$("$WRAPPER" memory-show "$PROJECT" "$CREATED_MEMORY_ID")
assert_contains "$MEMORY_SHOW_OUTPUT" "Memory M-001" "memory-show prints memory heading"
assert_contains "$MEMORY_SHOW_OUTPUT" "Manual memory" "memory-show prints title"
assert_contains "$MEMORY_SHOW_OUTPUT" "This manual memory proves wrapper writes." "memory-show prints body"

MEMORY_SEARCH_OUTPUT=$("$WRAPPER" memory-search "$PROJECT" "manual wrapper")
assert_contains "$MEMORY_SEARCH_OUTPUT" "M-001" "memory-search finds created memory"
assert_contains "$MEMORY_SEARCH_OUTPUT" "Manual memory" "memory-search prints matching title"

MEMORY_SEARCH_FALLBACK=$("$WRAPPER" memory-search "$PROJECT" "Fallback \"memory")
assert_contains "$MEMORY_SEARCH_FALLBACK" "M-002" "memory-search falls back to LIKE when FTS query syntax fails"

DB_SHA_MEMORY_READS_AFTER=$(sha256sum "$DB")
assert_eq "$DB_SHA_MEMORY_READS_AFTER" "$DB_SHA_MEMORY_READS_BEFORE" "memory read commands do not mutate taskmanager.db"

MEMORY_DEPRECATE_OUTPUT=$("$WRAPPER" memory-deprecate "$PROJECT" "$CREATED_MEMORY_ID" "Covered by a better memory")
assert_contains "$MEMORY_DEPRECATE_OUTPUT" "Deprecated memory: M-001" "memory-deprecate reports deprecated memory id"
assert_contains "$MEMORY_DEPRECATE_OUTPUT" "reason is not stored" "memory-deprecate documents schema reason limitation"
MEMORY_STATUS=$(sqlite3 "$DB" "SELECT status FROM memories WHERE id = 'M-001';")
assert_eq "$MEMORY_STATUS" "deprecated" "memory-deprecate marks memory deprecated"

if MEMORY_DEPRECATE_REASON_ERR=$("$WRAPPER" memory-deprecate "$PROJECT" "$CREATED_MEMORY_ID" "" 2>&1 >/dev/null); then
    fail "memory-deprecate requires non-empty reason"
else
    assert_contains "$MEMORY_DEPRECATE_REASON_ERR" "REASON must not be empty" "memory-deprecate explains empty reason"
fi
echo ""

sqlite3 "$DB" "INSERT INTO tasks (id, title, status, type, priority, dependencies) VALUES ('T-001', 'Wrapper task', 'planned', 'feature', 'high', '[]');"
NEXT_OUTPUT=$("$WRAPPER" next "$PROJECT")
assert_contains "$NEXT_OUTPUT" "T-001" "next prints available task id"
assert_contains "$NEXT_OUTPUT" "Wrapper task" "next prints available task title"
echo ""

sqlite3 "$DB" <<'SQL'
INSERT INTO milestones (id, title, description, acceptance_criteria, status, phase_order)
VALUES ('MS-001', 'Wrapper milestone', 'Milestone detail', '["Milestone works"]', 'active', 1);

UPDATE tasks
SET milestone_id = 'MS-001',
    acceptance_criteria = '["Task works"]',
    description = 'Task description',
    test_strategy = 'Task test strategy'
WHERE id = 'T-001';

INSERT INTO tasks (id, title, status, type, priority, dependencies, milestone_id)
VALUES ('T-002', 'Dependent wrapper task', 'blocked', 'feature', 'medium', '["T-001"]', 'MS-001');

INSERT INTO plan_analyses (id, prd_source, scope_in, scope_out, milestone_ids, acceptance_criteria)
VALUES ('PA-001', 'prompt', 'Runtime visibility', 'Mutating workflows', '["MS-001"]', '["Dashboard visible"]');

INSERT INTO deferrals (id, source_task_id, target_task_id, title, body, reason, status)
VALUES ('D-001', 'T-002', 'T-001', 'Deferred detail', 'Wait for visibility', 'Dependency order', 'pending');

INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, evidence, verified_by)
VALUES ('V-001', 'task', 'T-001', 'Task works', 0, 'met', 'self', 'Wrapper evidence', 'test_wrapper_cli');

INSERT INTO regression_checks (id, target_type, target_id, status, verified_by, attempt, verdict_reasoning)
VALUES ('RC-001', 'task', 'T-001', 'pass', 'test_wrapper_cli', 1, 'Wrapper regression passed');

INSERT INTO memories (id, title, kind, why_important, body, source_type, source_name, importance, confidence, status, tags)
VALUES ('M-004', 'Wrapper memory', 'process', 'Visible in show', 'Remember read-only visibility.', 'user', 'test_wrapper_cli', 4, 0.9, 'active', '["show"]');
SQL

echo "--- Command: show ---"
if SHOW_USAGE_ERR=$("$WRAPPER" show 2>&1 >/dev/null); then
    fail "show requires an explicit project directory"
else
    assert_contains "$SHOW_USAGE_ERR" "PROJECT_DIR" "show explains missing project directory"
fi

if SHOW_UNKNOWN_ERR=$("$WRAPPER" show "$PROJECT" missing-view 2>&1 >/dev/null); then
    fail "show rejects an unknown view"
else
    assert_contains "$SHOW_UNKNOWN_ERR" "unknown show view" "show explains unknown view"
fi

if SHOW_TASK_USAGE_ERR=$("$WRAPPER" show "$PROJECT" task 2>&1 >/dev/null); then
    fail "show task requires TASK_ID"
else
    assert_contains "$SHOW_TASK_USAGE_ERR" "TASK_ID" "show task explains missing task id"
fi

DB_SHA_BEFORE=$(sha256sum "$DB")
SHOW_OVERVIEW=$("$WRAPPER" show "$PROJECT" overview)
assert_contains "$SHOW_OVERVIEW" "TaskManager engine overview" "show overview prints heading"
assert_contains "$SHOW_OVERVIEW" "Schema version: 4.2.0" "show overview prints schema version"
assert_contains "$SHOW_OVERVIEW" "tasks: 2" "show overview prints task count"
assert_contains "$SHOW_OVERVIEW" "regression_checks: 1" "show overview prints regression count"

SHOW_DEFAULT=$("$WRAPPER" show "$PROJECT")
assert_contains "$SHOW_DEFAULT" "TaskManager engine overview" "show defaults to overview"

SHOW_TASKS=$("$WRAPPER" show "$PROJECT" tasks 1)
assert_contains "$SHOW_TASKS" "Tasks" "show tasks prints heading"
assert_contains "$SHOW_TASKS" "T-001" "show tasks prints task id"
if [[ "$SHOW_TASKS" == *"T-002"* ]]; then
    fail "show tasks honors explicit limit"
else
    pass "show tasks honors explicit limit"
fi

SHOW_TASK=$("$WRAPPER" show "$PROJECT" task T-001)
assert_contains "$SHOW_TASK" "Task T-001" "show task prints task heading"
assert_contains "$SHOW_TASK" "Wrapper task" "show task prints title"
assert_contains "$SHOW_TASK" "Task description" "show task prints core fields"

SHOW_MILESTONES=$("$WRAPPER" show "$PROJECT" milestones 5)
assert_contains "$SHOW_MILESTONES" "MS-001" "show milestones prints milestone id"

SHOW_MEMORIES=$("$WRAPPER" show "$PROJECT" memories 5)
assert_contains "$SHOW_MEMORIES" "M-004" "show memories prints memory id"

SHOW_DEFERRALS=$("$WRAPPER" show "$PROJECT" deferrals 5)
assert_contains "$SHOW_DEFERRALS" "D-001" "show deferrals prints deferral id"

SHOW_VERIFICATIONS=$("$WRAPPER" show "$PROJECT" verifications)
assert_contains "$SHOW_VERIFICATIONS" "V-001" "show verifications prints verification id"
SHOW_VERIFICATIONS_TASK=$("$WRAPPER" show "$PROJECT" verifications T-001)
assert_contains "$SHOW_VERIFICATIONS_TASK" "V-001" "show verifications filters by task id"

SHOW_REGRESSIONS=$("$WRAPPER" show "$PROJECT" regressions)
assert_contains "$SHOW_REGRESSIONS" "RC-001" "show regressions prints regression id"
SHOW_REGRESSIONS_TARGET=$("$WRAPPER" show "$PROJECT" regressions T-001)
assert_contains "$SHOW_REGRESSIONS_TARGET" "RC-001" "show regressions filters by target id"

DB_SHA_AFTER=$(sha256sum "$DB")
assert_eq "$DB_SHA_AFTER" "$DB_SHA_BEFORE" "show modes do not mutate taskmanager.db"
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
