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

assert_not_contains() {
    local actual="$1"
    local needle="$2"
    local msg="$3"
    if [[ "$actual" == *"$needle"* ]]; then
        fail "$msg (unexpected '$needle')"
    else
        pass "$msg"
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
assert_contains "$HELP_OUTPUT" "task-add PROJECT_DIR TASK_ID TITLE" "help documents task-add"
assert_contains "$HELP_OUTPUT" "task-set-status PROJECT_DIR TASK_ID STATUS" "help documents task-set-status"
assert_contains "$HELP_OUTPUT" "task-update-title PROJECT_DIR TASK_ID TITLE" "help documents task-update-title"
assert_contains "$HELP_OUTPUT" "task-archive PROJECT_DIR TASK_ID" "help documents task-archive"
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

echo "--- Command: task operations ---"
if TASK_ADD_USAGE_ERR=$("$WRAPPER" task-add "$PROJECT" T-MISSING 2>&1 >/dev/null); then
    fail "task-add requires TITLE"
else
    assert_contains "$TASK_ADD_USAGE_ERR" "task-add requires PROJECT_DIR TASK_ID TITLE" "task-add explains missing title"
fi

if TASK_ADD_ID_ERR=$("$WRAPPER" task-add "$PROJECT" "bad/id" "Bad task id" 2>&1 >/dev/null); then
    fail "task-add rejects invalid task id"
else
    assert_contains "$TASK_ADD_ID_ERR" "TASK_ID contains unsupported characters" "task-add explains invalid task id"
fi

if TASK_ADD_TYPE_ERR=$("$WRAPPER" task-add "$PROJECT" T-BADTYPE "Bad task type" unsupported planned 2>&1 >/dev/null); then
    fail "task-add rejects invalid task type"
else
    assert_contains "$TASK_ADD_TYPE_ERR" "TYPE must be one of" "task-add explains invalid task type"
fi

if TASK_ADD_STATUS_ERR=$("$WRAPPER" task-add "$PROJECT" T-BADSTATUS "Bad task status" feature started 2>&1 >/dev/null); then
    fail "task-add rejects invalid task status"
else
    assert_contains "$TASK_ADD_STATUS_ERR" "STATUS must be one of" "task-add explains invalid task status"
fi

TASK_ADD_OUTPUT=$("$WRAPPER" task-add "$PROJECT" T-001 "Wrapper task" feature planned)
assert_contains "$TASK_ADD_OUTPUT" "Created task: T-001" "task-add reports created task id"
CREATED_TASK_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE id = 'T-001' AND title = 'Wrapper task' AND status = 'planned' AND type = 'feature' AND priority = 'medium' AND parent_id IS NULL;")
assert_eq "$CREATED_TASK_COUNT" "1" "task-add inserts one task row with safe defaults"

NEXT_PARENT_OUTPUT=$("$WRAPPER" next "$PROJECT")
assert_contains "$NEXT_PARENT_OUTPUT" "T-001" "next prints available parent task id"
assert_contains "$NEXT_PARENT_OUTPUT" "Wrapper task" "next prints available parent task title"

if TASK_ADD_DUPLICATE_ERR=$("$WRAPPER" task-add "$PROJECT" T-001 "Duplicate task" 2>&1 >/dev/null); then
    fail "task-add refuses duplicate task ids"
else
    assert_contains "$TASK_ADD_DUPLICATE_ERR" "Task already exists: T-001" "task-add explains duplicate task id"
fi

if TASK_ADD_PARENT_ERR=$("$WRAPPER" task-add "$PROJECT" T-MISSING-PARENT "Missing parent" feature planned T-NOPE 2>&1 >/dev/null); then
    fail "task-add refuses a missing parent"
else
    assert_contains "$TASK_ADD_PARENT_ERR" "Parent task not found: T-NOPE" "task-add explains missing parent"
fi

TASK_CHILD_OUTPUT=$("$WRAPPER" task-add "$PROJECT" T-001.1 "Wrapper child task" task planned T-001)
assert_contains "$TASK_CHILD_OUTPUT" "Created task: T-001.1" "task-add creates a child task when parent exists"
CHILD_PARENT_ID=$(sqlite3 "$DB" "SELECT parent_id FROM tasks WHERE id = 'T-001.1';")
assert_eq "$CHILD_PARENT_ID" "T-001" "task-add stores the child parent id"
CHILD_TYPE=$(sqlite3 "$DB" "SELECT type FROM tasks WHERE id = 'T-001.1';")
assert_eq "$CHILD_TYPE" "feature" "task-add normalizes generic task type to schema default"

if TASK_SET_STATUS_USAGE_ERR=$("$WRAPPER" task-set-status "$PROJECT" T-001.1 2>&1 >/dev/null); then
    fail "task-set-status requires STATUS"
else
    assert_contains "$TASK_SET_STATUS_USAGE_ERR" "task-set-status requires PROJECT_DIR TASK_ID STATUS" "task-set-status explains missing status"
fi

if TASK_SET_STATUS_INVALID_ERR=$("$WRAPPER" task-set-status "$PROJECT" T-001.1 started 2>&1 >/dev/null); then
    fail "task-set-status rejects invalid status"
else
    assert_contains "$TASK_SET_STATUS_INVALID_ERR" "STATUS must be one of" "task-set-status explains invalid status"
fi

TASK_STATUS_OUTPUT=$("$WRAPPER" task-set-status "$PROJECT" T-001.1 in-progress)
assert_contains "$TASK_STATUS_OUTPUT" "Updated task status: T-001.1 -> in-progress" "task-set-status reports in-progress update"
STARTED_AT=$(sqlite3 "$DB" "SELECT COALESCE(started_at, '') FROM tasks WHERE id = 'T-001.1';")
if [[ -n "$STARTED_AT" ]]; then
    pass "task-set-status sets started_at when entering in-progress"
else
    fail "task-set-status sets started_at when entering in-progress"
fi

TASK_DONE_OUTPUT=$("$WRAPPER" task-set-status "$PROJECT" T-001.1 done)
assert_contains "$TASK_DONE_OUTPUT" "Updated task status: T-001.1 -> done" "task-set-status reports done update"
COMPLETED_AT=$(sqlite3 "$DB" "SELECT COALESCE(completed_at, '') FROM tasks WHERE id = 'T-001.1';")
if [[ -n "$COMPLETED_AT" ]]; then
    pass "task-set-status sets completed_at when entering done"
else
    fail "task-set-status sets completed_at when entering done"
fi

TASK_PLANNED_OUTPUT=$("$WRAPPER" task-set-status "$PROJECT" T-001.1 planned)
assert_contains "$TASK_PLANNED_OUTPUT" "Updated task status: T-001.1 -> planned" "task-set-status reports planned update"
COMPLETED_AFTER_REOPEN=$(sqlite3 "$DB" "SELECT COALESCE(completed_at, '') FROM tasks WHERE id = 'T-001.1';")
assert_eq "$COMPLETED_AFTER_REOPEN" "$COMPLETED_AT" "task-set-status preserves completed_at when moving away from done"

if TASK_UPDATE_TITLE_USAGE_ERR=$("$WRAPPER" task-update-title "$PROJECT" T-001.1 2>&1 >/dev/null); then
    fail "task-update-title requires TITLE"
else
    assert_contains "$TASK_UPDATE_TITLE_USAGE_ERR" "task-update-title requires PROJECT_DIR TASK_ID TITLE" "task-update-title explains missing title"
fi

TITLE_CONTEXT_BEFORE=$(sqlite3 "$DB" "SELECT status || '|' || type || '|' || priority || '|' || COALESCE(parent_id, '') || '|' || created_at || '|' || COALESCE(started_at, '') || '|' || COALESCE(completed_at, '') || '|' || COALESCE(archived_at, '') FROM tasks WHERE id = 'T-001.1';")
UPDATED_AT_BEFORE=$(sqlite3 "$DB" "SELECT updated_at FROM tasks WHERE id = 'T-001.1';")
sleep 1
TASK_UPDATE_TITLE_OUTPUT=$("$WRAPPER" task-update-title "$PROJECT" T-001.1 "Wrapper child task updated")
assert_contains "$TASK_UPDATE_TITLE_OUTPUT" "Updated task title: T-001.1" "task-update-title reports updated task id"
UPDATED_TITLE=$(sqlite3 "$DB" "SELECT title FROM tasks WHERE id = 'T-001.1';")
assert_eq "$UPDATED_TITLE" "Wrapper child task updated" "task-update-title changes title"
TITLE_CONTEXT_AFTER=$(sqlite3 "$DB" "SELECT status || '|' || type || '|' || priority || '|' || COALESCE(parent_id, '') || '|' || created_at || '|' || COALESCE(started_at, '') || '|' || COALESCE(completed_at, '') || '|' || COALESCE(archived_at, '') FROM tasks WHERE id = 'T-001.1';")
assert_eq "$TITLE_CONTEXT_AFTER" "$TITLE_CONTEXT_BEFORE" "task-update-title preserves non-title core fields"
UPDATED_AT_AFTER=$(sqlite3 "$DB" "SELECT updated_at FROM tasks WHERE id = 'T-001.1';")
if [[ "$UPDATED_AT_AFTER" > "$UPDATED_AT_BEFORE" ]]; then
    pass "task-update-title advances updated_at"
else
    fail "task-update-title advances updated_at"
fi

SHOW_CREATED_TASKS=$("$WRAPPER" show "$PROJECT" tasks 10)
assert_contains "$SHOW_CREATED_TASKS" "T-001" "show tasks prints created parent task"
assert_contains "$SHOW_CREATED_TASKS" "T-001.1" "show tasks prints created child task"
SHOW_CREATED_TASK=$("$WRAPPER" show "$PROJECT" task T-001.1)
assert_contains "$SHOW_CREATED_TASK" "Task T-001.1" "show task prints created child heading"
assert_contains "$SHOW_CREATED_TASK" "Wrapper child task updated" "show task prints updated child title"

NEXT_OUTPUT=$("$WRAPPER" next "$PROJECT")
assert_contains "$NEXT_OUTPUT" "T-001.1" "next prints available child task id"
assert_contains "$NEXT_OUTPUT" "Wrapper child task updated" "next prints available child task title"
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
assert_contains "$SHOW_OVERVIEW" "tasks: 3" "show overview prints task count"
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

echo "--- Command: task archive ---"
if TASK_ARCHIVE_USAGE_ERR=$("$WRAPPER" task-archive "$PROJECT" 2>&1 >/dev/null); then
    fail "task-archive requires TASK_ID"
else
    assert_contains "$TASK_ARCHIVE_USAGE_ERR" "task-archive requires PROJECT_DIR TASK_ID" "task-archive explains missing task id"
fi

TASK_ARCHIVE_ADD_OUTPUT=$("$WRAPPER" task-add "$PROJECT" T-ARCH "Archive candidate" feature planned)
assert_contains "$TASK_ARCHIVE_ADD_OUTPUT" "Created task: T-ARCH" "task-add creates an archive candidate"
TASK_ARCHIVE_OUTPUT=$("$WRAPPER" task-archive "$PROJECT" T-ARCH)
assert_contains "$TASK_ARCHIVE_OUTPUT" "Archived task: T-ARCH" "task-archive reports archived task id"
ARCHIVED_AT=$(sqlite3 "$DB" "SELECT COALESCE(archived_at, '') FROM tasks WHERE id = 'T-ARCH';")
if [[ -n "$ARCHIVED_AT" ]]; then
    pass "task-archive sets archived_at"
else
    fail "task-archive sets archived_at"
fi
ARCHIVED_ROW_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE id = 'T-ARCH';")
assert_eq "$ARCHIVED_ROW_COUNT" "1" "task-archive keeps the task row"
SHOW_TASKS_AFTER_ARCHIVE=$("$WRAPPER" show "$PROJECT" tasks 100)
assert_not_contains "$SHOW_TASKS_AFTER_ARCHIVE" "T-ARCH" "task-archive hides task from show tasks"
NEXT_AFTER_ARCHIVE=$("$WRAPPER" next "$PROJECT")
assert_not_contains "$NEXT_AFTER_ARCHIVE" "T-ARCH" "task-archive hides task from next"
echo ""

echo "--- Command: run-sql-tests ---"
"$WRAPPER" run-sql-tests
pass "run-sql-tests delegates to copied SQL suites"
echo ""

finish
