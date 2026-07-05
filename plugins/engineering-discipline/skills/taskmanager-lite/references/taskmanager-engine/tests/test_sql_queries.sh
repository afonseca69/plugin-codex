#!/usr/bin/env bash
# Taskmanager SQL Query Tests
#
# Self-contained test script: creates a temp directory with DB + config,
# runs all SQL query tests, then cleans up automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA_FILE="$PLUGIN_DIR/schemas/schema.sql"
CONFIG_SRC="$PLUGIN_DIR/schemas/default-config.json"

# Create temp working directory with .taskmanager structure
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR/.taskmanager/logs"
cp "$CONFIG_SRC" "$WORK_DIR/.taskmanager/config.json"
touch "$WORK_DIR/.taskmanager/logs/activity.log"

DB="$WORK_DIR/.taskmanager/taskmanager.db"

# Initialize database from schema
sqlite3 "$DB" < "$SCHEMA_FILE"

# Insert sample data: 3 epics, ~15 tasks, 3 memories
sqlite3 "$DB" <<'SEED'
-- Epic 1: Authentication (in-progress, high priority)
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority, complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
VALUES
('1', NULL, 'Authentication System', 'Build full auth system', 'JWT-based auth with login, register, reset', NULL, 'in-progress', 'feature', 'high', 'L', 'Multi-endpoint system', 14400, '["auth","security","sprint-1"]', '[]'),
('1.1', '1', 'JWT Login/Logout', 'Implement JWT endpoints', 'POST /login, POST /logout', 'Test valid/invalid credentials, token expiry', 'done', 'feature', 'high', 'S', 'Standard JWT', 3600, '["auth","security"]', '[]'),
('1.2', '1', 'Password Reset', 'Implement password reset via email', 'POST /reset-request, POST /reset-confirm', 'Test email sending, token validation', 'planned', 'feature', 'medium', 'S', 'Email integration', 3600, '["auth","security"]', '["1.1"]'),
('1.3', '1', 'Role-Based Access Control', 'Implement RBAC', 'Admin, User, Guest roles', 'Test role enforcement on endpoints', 'planned', 'feature', 'medium', 'M', 'Complex permissions', 7200, '["auth","security","rbac"]', '["1.1"]'),
('1.3.1', '1.3', 'RBAC Middleware', 'Express middleware for role checks', NULL, 'Test middleware with each role', 'planned', 'feature', 'medium', 'S', 'Standard middleware', 1800, '["auth","security"]', '[]'),
('1.3.2', '1.3', 'RBAC Admin Panel', 'Admin UI for managing roles', NULL, 'Test role CRUD operations', 'planned', 'feature', 'medium', 'S', 'CRUD UI', 3600, '["auth","admin"]', '["1.3.1"]');

-- Epic 2: Dashboard (planned)
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority, complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
VALUES
('2', NULL, 'Dashboard', 'Build analytics dashboard', 'Charts, stats, data viz', NULL, 'planned', 'feature', 'medium', 'L', 'Complex frontend', 14400, '["dashboard","frontend","sprint-1"]', '[]'),
('2.1', '2', 'Chart Components', 'Build D3 chart library', 'Line, bar, pie charts', 'Visual regression tests', 'planned', 'feature', 'medium', 'M', 'D3 integration', 3600, '["dashboard","frontend"]', '[]'),
('2.2', '2', 'Data Aggregation API', 'Backend for dashboard data', 'Aggregate queries, caching', 'Test with sample datasets', 'planned', 'feature', 'medium', 'S', 'SQL aggregates', 3600, '["dashboard","api"]', '["2.1"]'),
('2.3', '2', 'Real-time Updates', 'WebSocket live data', 'Socket.io integration', 'Test reconnection, latency', 'planned', 'feature', 'medium', 'M', 'WebSocket complexity', 3600, '["dashboard","websocket"]', '["2.1"]');

-- Epic 3: Infrastructure (critical priority)
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority, complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
VALUES
('3', NULL, 'Infrastructure', 'Set up CI/CD and monitoring', 'Docker, GH Actions, monitoring', NULL, 'planned', 'chore', 'critical', 'M', 'DevOps setup', 10800, '["infra","devops"]', '[]'),
('3.1', '3', 'Docker Setup', 'Containerize application', 'Dockerfile, docker-compose', 'Build and run tests in container', 'planned', 'chore', 'critical', 'XS', 'Standard Docker', 1800, '["infra","docker","security"]', '[]'),
('3.2', '3', 'CI Pipeline', 'GitHub Actions workflow', 'Test, lint, build, deploy', 'Verify pipeline runs', 'planned', 'chore', 'high', 'S', 'Standard CI', 3600, '["infra","ci"]', '["3.1"]'),
('3.3', '3', 'Monitoring', 'Set up Prometheus + Grafana', 'Metrics, alerts, dashboards', 'Test alert triggers', 'blocked', 'chore', 'medium', 'S', 'Standard monitoring', 3600, '["infra","monitoring","security"]', '["3.1","3.2"]');

-- Memories (3 entries for FTS5 tests)
INSERT INTO memories (id, title, kind, why_important, body, source_type, source_name, source_via, auto_updatable, importance, confidence, status, scope, tags, links)
VALUES
('M-0001', 'Use Pest for testing', 'convention', 'Standardizes test framework', 'All tests must use Pest v4 with parallel execution. Use expect() assertions.', 'user', 'developer', 'manual', 1, 4, 0.9, 'active', '{"files": ["tests/"]}', '["testing","pest","convention"]', '[]'),
('M-0002', 'Redis for session caching', 'architecture', 'Performance requirement', 'Use Redis with token bucket rate limiting for API endpoints. TTL: 3600s for sessions.', 'agent', 'research', 'taskmanager:research', 1, 3, 0.8, 'active', '{"domains": ["caching","api"]}', '["redis","caching","architecture"]', '[]'),
('M-0003', 'Fix: SQLite WAL mode on NFS', 'bugfix', 'Prevents data corruption', 'SQLite WAL mode does not work on NFS mounts. Use DELETE journal mode for shared filesystems.', 'user', 'developer', 'manual', 0, 5, 1.0, 'active', '{"files": ["db/"]}', '["sqlite","bugfix","nfs"]', '[]');
SEED

PASS=0
FAIL=0
ERRORS=""

# Work from temp directory (tests use relative .taskmanager path)
cd "$WORK_DIR"

pass() {
    PASS=$((PASS + 1))
    echo "  PASS: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  FAIL: $1"
    echo "  FAIL: $1"
}

assert_eq() {
    local actual="$1"
    local expected="$2"
    local msg="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$msg"
    else
        fail "$msg (expected='$expected', got='$actual')"
    fi
}

assert_contains() {
    local actual="$1"
    local needle="$2"
    local msg="$3"
    if echo "$actual" | grep -qF "$needle"; then
        pass "$msg"
    else
        fail "$msg (output does not contain '$needle')"
    fi
}

assert_not_empty() {
    local actual="$1"
    local msg="$2"
    if [[ -n "$actual" ]]; then
        pass "$msg"
    else
        fail "$msg (output is empty)"
    fi
}

assert_gt() {
    local actual="$1"
    local threshold="$2"
    local msg="$3"
    if [[ "$actual" -gt "$threshold" ]]; then
        pass "$msg"
    else
        fail "$msg (expected > $threshold, got '$actual')"
    fi
}

echo "=============================================="
echo "  TASKMANAGER PLUGIN - COMPREHENSIVE TESTS"
echo "=============================================="
echo ""

# ====================================================================
# TEST 1: Schema / Init
# ====================================================================
echo "--- Test 1: Schema / Init ---"

# Check 8 tables exist (tasks, memories, memories_fts, state, schema_version, deferrals, milestones, plan_analyses)
TABLE_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('tasks','memories','memories_fts','state','schema_version','deferrals','milestones','plan_analyses');")
assert_eq "$TABLE_COUNT" "8" "All 8 tables exist"

# Check schema version
VERSION=$(sqlite3 "$DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
assert_eq "$VERSION" "4.2.0" "Schema version is 4.2.0"

# Negative test: sync_log table must NOT exist
SYNC_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sync_log';")
assert_eq "$SYNC_EXISTS" "0" "sync_log table does NOT exist"

# State table has only expected columns
STATE_COLS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('state');")
assert_eq "$STATE_COLS" "7" "State table has exactly 7 columns"

# Check state row exists
STATE_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM state WHERE id = 1;")
assert_eq "$STATE_COUNT" "1" "State singleton row exists"

# Check config.json exists
if [[ -f ".taskmanager/config.json" ]]; then
    pass "config.json exists"
else
    fail "config.json does not exist"
fi

# Check activity.log exists
if [[ -f ".taskmanager/logs/activity.log" ]]; then
    pass "activity.log exists"
else
    fail "activity.log does not exist"
fi

echo ""

# ====================================================================
# TEST 2: test_strategy column (P1 - new feature)
# ====================================================================
echo "--- Test 2: test_strategy column ---"

# Column exists
COL_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'test_strategy';")
assert_eq "$COL_EXISTS" "1" "test_strategy column exists in tasks table"

# Stores and retrieves correctly
STRATEGY=$(sqlite3 "$DB" "SELECT test_strategy FROM tasks WHERE id = '1.1';")
assert_contains "$STRATEGY" "valid/invalid credentials" "test_strategy stores content correctly"

# Can be updated
sqlite3 "$DB" "UPDATE tasks SET test_strategy = 'Updated test strategy' WHERE id = '1.1';"
UPDATED=$(sqlite3 "$DB" "SELECT test_strategy FROM tasks WHERE id = '1.1';")
assert_eq "$UPDATED" "Updated test strategy" "test_strategy can be updated"

# Restore original
sqlite3 "$DB" "UPDATE tasks SET test_strategy = 'Test valid/invalid credentials, token expiry' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 3: Tags (P2 - new command)
# ====================================================================
echo "--- Test 3: Tags command queries ---"

# tags list query
TAG_LIST=$(sqlite3 "$DB" "
SELECT tag.value as Tag, COUNT(DISTINCT t.id) as TaskCount
FROM tasks t, json_each(t.tags) tag
WHERE t.archived_at IS NULL
GROUP BY tag.value
ORDER BY COUNT(DISTINCT t.id) DESC;
")
assert_not_empty "$TAG_LIST" "tags list returns results"
assert_contains "$TAG_LIST" "security" "tags list includes 'security'"
assert_contains "$TAG_LIST" "auth" "tags list includes 'auth'"

# tags add - add 'sprint-3' to task 2.1
EXISTS_BEFORE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks t, json_each(t.tags) tag WHERE t.id = '2.1' AND tag.value = 'sprint-3';")
assert_eq "$EXISTS_BEFORE" "0" "sprint-3 not on task 2.1 before add"

sqlite3 "$DB" "UPDATE tasks SET tags = json_insert(tags, '\$[#]', 'sprint-3'), updated_at = datetime('now') WHERE id = '2.1';"
EXISTS_AFTER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks t, json_each(t.tags) tag WHERE t.id = '2.1' AND tag.value = 'sprint-3';")
assert_eq "$EXISTS_AFTER" "1" "sprint-3 added to task 2.1"

# tags remove - remove 'sprint-3' from task 2.1
sqlite3 "$DB" "
UPDATE tasks SET
    tags = (
        SELECT COALESCE(json_group_array(tag.value), '[]')
        FROM json_each(tags) tag
        WHERE tag.value != 'sprint-3'
    ),
    updated_at = datetime('now')
WHERE id = '2.1';
"
EXISTS_REMOVED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks t, json_each(t.tags) tag WHERE t.id = '2.1' AND tag.value = 'sprint-3';")
assert_eq "$EXISTS_REMOVED" "0" "sprint-3 removed from task 2.1"

# tags filter query
FILTERED=$(sqlite3 "$DB" "
SELECT t.id as ID, SUBSTR(t.title, 1, 40) as Title, t.status as Status
FROM tasks t, json_each(t.tags) tag
WHERE tag.value = 'security' AND t.archived_at IS NULL
ORDER BY t.id;
")
assert_not_empty "$FILTERED" "tags filter returns results for 'security'"

SECURITY_COUNT=$(sqlite3 "$DB" "
SELECT COUNT(DISTINCT t.id)
FROM tasks t, json_each(t.tags) tag
WHERE tag.value = 'security' AND t.archived_at IS NULL;
")
assert_gt "$SECURITY_COUNT" "3" "At least 4 tasks tagged 'security'"

# tags rename query - rename 'sprint-1' to 'sprint-1-done'
BEFORE_RENAME=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT t.id) FROM tasks t, json_each(t.tags) tag WHERE tag.value = 'sprint-1';")
sqlite3 "$DB" "
UPDATE tasks SET
    tags = (
        SELECT json_group_array(
            CASE WHEN tag.value = 'sprint-1' THEN 'sprint-1-done' ELSE tag.value END
        )
        FROM json_each(tags) tag
    ),
    updated_at = datetime('now')
WHERE id IN (
    SELECT t.id FROM tasks t, json_each(t.tags) tag
    WHERE tag.value = 'sprint-1'
);
"
AFTER_RENAME_OLD=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT t.id) FROM tasks t, json_each(t.tags) tag WHERE tag.value = 'sprint-1';")
AFTER_RENAME_NEW=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT t.id) FROM tasks t, json_each(t.tags) tag WHERE tag.value = 'sprint-1-done';")
assert_eq "$AFTER_RENAME_OLD" "0" "No tasks with old tag 'sprint-1' after rename"
assert_eq "$AFTER_RENAME_NEW" "$BEFORE_RENAME" "All tasks moved to 'sprint-1-done'"

# Restore: rename back
sqlite3 "$DB" "
UPDATE tasks SET
    tags = (
        SELECT json_group_array(
            CASE WHEN tag.value = 'sprint-1-done' THEN 'sprint-1' ELSE tag.value END
        )
        FROM json_each(tags) tag
    ),
    updated_at = datetime('now')
WHERE id IN (
    SELECT t.id FROM tasks t, json_each(t.tags) tag
    WHERE tag.value = 'sprint-1-done'
);
"

echo ""

# ====================================================================
# TEST 4: Dashboard tags query
# ====================================================================
echo "--- Test 4: Dashboard tag distribution ---"

DASH_TAGS=$(sqlite3 "$DB" "
SELECT
    tag.value as Tag,
    COUNT(DISTINCT t.id) as Tasks,
    SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as Done,
    SUM(CASE WHEN t.status NOT IN ('done', 'canceled', 'duplicate') THEN 1 ELSE 0 END) as Remaining
FROM tasks t, json_each(t.tags) tag
WHERE t.archived_at IS NULL
GROUP BY tag.value
ORDER BY COUNT(DISTINCT t.id) DESC
LIMIT 10;
")
assert_not_empty "$DASH_TAGS" "Dashboard tag distribution returns data"
assert_contains "$DASH_TAGS" "security" "Dashboard tags include 'security'"

echo ""

# ====================================================================
# TEST 5: Stats --tags query
# ====================================================================
echo "--- Test 5: Stats --tags ---"

STATS_TAGS=$(sqlite3 "$DB" "
SELECT
    tag.value as Tag,
    COUNT(DISTINCT t.id) as Total,
    SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as Done,
    SUM(CASE WHEN t.status NOT IN ('done', 'canceled', 'duplicate') THEN 1 ELSE 0 END) as Remaining,
    ROUND(100.0 * SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT t.id), 0), 1) || '%' as Complete
FROM tasks t, json_each(t.tags) tag
WHERE t.archived_at IS NULL
GROUP BY tag.value
ORDER BY COUNT(DISTINCT t.id) DESC;
")
assert_not_empty "$STATS_TAGS" "Stats --tags returns data"
assert_contains "$STATS_TAGS" "%" "Stats --tags includes completion percentages"

UNIQUE_TAGS=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT tag.value) FROM tasks t, json_each(t.tags) tag WHERE t.archived_at IS NULL;")
assert_gt "$UNIQUE_TAGS" "3" "More than 3 unique tags exist"

echo ""

# ====================================================================
# TEST 6: Scope (P3 - new command)
# ====================================================================
echo "--- Test 6: Scope command queries ---"

# Load task query
SCOPE_TASK=$(sqlite3 "$DB" "
SELECT id, title, description, details, test_strategy, priority, type,
       complexity_scale
FROM tasks
WHERE id = '1.2' AND archived_at IS NULL;
")
assert_not_empty "$SCOPE_TASK" "Scope: can load task 1.2"

# Update task fields (simulate scope up)
sqlite3 "$DB" "
UPDATE tasks SET
    description = 'Implement password reset via email with rate limiting',
    complexity_scale = 'M',
    estimate_seconds = 7200,
    updated_at = datetime('now')
WHERE id = '1.2';
"
UPDATED_SCALE=$(sqlite3 "$DB" "SELECT complexity_scale FROM tasks WHERE id = '1.2';")
assert_eq "$UPDATED_SCALE" "M" "Scope up: complexity_scale increased to M"

# Find dependent tasks (cascade query)
DEPENDENTS=$(sqlite3 "$DB" "
SELECT id, title, description
FROM tasks
WHERE archived_at IS NULL
  AND status NOT IN ('done', 'canceled', 'duplicate')
  AND EXISTS (
      SELECT 1 FROM json_each(tasks.dependencies) d
      WHERE d.value = '1.1'
  );
")
assert_not_empty "$DEPENDENTS" "Scope: found tasks depending on 1.1"
assert_contains "$DEPENDENTS" "1.2" "Task 1.2 depends on 1.1"

# Recompute parent estimate
sqlite3 "$DB" "
UPDATE tasks SET
    estimate_seconds = (
        SELECT COALESCE(SUM(COALESCE(estimate_seconds, 0)), 0)
        FROM tasks c WHERE c.parent_id = tasks.id
          AND c.status NOT IN ('canceled', 'duplicate')
    ),
    updated_at = datetime('now')
WHERE id = '1';
"
PARENT_EST=$(sqlite3 "$DB" "SELECT estimate_seconds FROM tasks WHERE id = '1';")
assert_gt "$PARENT_EST" "10000" "Parent estimate recomputed from children"

# Restore original values
sqlite3 "$DB" "UPDATE tasks SET description = 'Implement password reset via email', complexity_scale = 'S', estimate_seconds = 3600 WHERE id = '1.2';"

echo ""

# ====================================================================
# TEST 7: Expand (P4 - new command)
# ====================================================================
echo "--- Test 7: Expand command queries ---"

# Find expandable tasks (bulk mode query using complexity_scale)
EXPANDABLE=$(sqlite3 "$DB" "
SELECT id, title, complexity_scale
FROM tasks
WHERE archived_at IS NULL
  AND status NOT IN ('done', 'canceled', 'duplicate')
  AND CASE complexity_scale
      WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE -1
  END >= 2
  AND NOT EXISTS (
      SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id
  )
ORDER BY
  CASE complexity_scale WHEN 'XL' THEN 0 WHEN 'L' THEN 1 WHEN 'M' THEN 2 WHEN 'S' THEN 3 ELSE 4 END,
  id;
")
assert_not_empty "$EXPANDABLE" "Expand: found expandable tasks"

# Insert a subtask (simulate expansion)
sqlite3 "$DB" "
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority,
                   complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
VALUES ('2.1.1', '2.1', 'Line Chart Component', 'Build D3 line chart', 'SVG-based responsive line chart', 'Snapshot test', 'planned', 'feature', 'medium', 'XS', 'Simple D3 component', 1800, '[\"dashboard\"]', '[]');
"
CHILD_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE parent_id = '2.1';")
assert_eq "$CHILD_COUNT" "1" "Expand: subtask inserted under 2.1"

# Update parent estimate (rollup)
sqlite3 "$DB" "
UPDATE tasks SET
    estimate_seconds = (
        SELECT COALESCE(SUM(COALESCE(estimate_seconds, 0)), 0)
        FROM tasks c WHERE c.parent_id = '2.1'
    ),
    updated_at = datetime('now')
WHERE id = '2.1';
"
PARENT_EST_21=$(sqlite3 "$DB" "SELECT estimate_seconds FROM tasks WHERE id = '2.1';")
assert_eq "$PARENT_EST_21" "1800" "Expand: parent estimate rolled up from children"

# Check recursive expansion candidates
RECURSIVE_CHECK=$(sqlite3 "$DB" "
SELECT id, title, complexity_scale
FROM tasks
WHERE parent_id = '2.1'
  AND CASE complexity_scale
      WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE -1
  END >= 2
  AND NOT EXISTS (
      SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id
  );
")
# Should be empty since we inserted XS task
if [[ -z "$RECURSIVE_CHECK" ]]; then
    pass "Expand: no recursive expansion needed (subtasks below threshold)"
else
    fail "Expand: unexpected recursive expansion candidates"
fi

# Clean up: remove the test subtask
sqlite3 "$DB" "DELETE FROM tasks WHERE id = '2.1.1';"
sqlite3 "$DB" "UPDATE tasks SET estimate_seconds = 3600 WHERE id = '2.1';"

echo ""

# ====================================================================
# TEST 8: Dependencies (P5 - new command)
# ====================================================================
echo "--- Test 8: Dependencies command queries ---"

# Missing references detection
# First, add a bad dependency
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.1\", \"99.99\"]' WHERE id = '1.2';"
MISSING=$(sqlite3 "$DB" "
SELECT t.id as task_id, d.value as missing_dep
FROM tasks t, json_each(t.dependencies) d
WHERE t.archived_at IS NULL
  AND d.value NOT IN (SELECT id FROM tasks);
")
assert_contains "$MISSING" "99.99" "Dependencies: detected missing reference 99.99"

# Self-reference detection
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"2.2\"]' WHERE id = '2.2';"
SELF_REF=$(sqlite3 "$DB" "
SELECT t.id as task_id
FROM tasks t, json_each(t.dependencies) d
WHERE d.value = t.id;
")
assert_contains "$SELF_REF" "2.2" "Dependencies: detected self-reference on 2.2"

# Circular dependency detection (simple case)
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.3\"]' WHERE id = '1.2';"
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.2\"]' WHERE id = '1.3';"
CIRCULAR=$(sqlite3 "$DB" "
WITH RECURSIVE dep_chain AS (
    SELECT
        t.id as start_id,
        d.value as current_id,
        t.id || ' -> ' || d.value as path,
        1 as depth
    FROM tasks t, json_each(t.dependencies) d
    WHERE t.archived_at IS NULL
    UNION ALL
    SELECT
        dc.start_id,
        d.value as current_id,
        dc.path || ' -> ' || d.value,
        dc.depth + 1
    FROM dep_chain dc
    JOIN tasks t ON t.id = dc.current_id
    JOIN json_each(t.dependencies) d
    WHERE dc.depth < 20
      AND d.value != dc.current_id
)
SELECT DISTINCT start_id, path || ' -> ' || start_id as cycle
FROM dep_chain
WHERE current_id = start_id
LIMIT 5;
")
assert_not_empty "$CIRCULAR" "Dependencies: detected circular dependency"

# Auto-fix: remove missing references
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = (
        SELECT COALESCE(json_group_array(d.value), '[]')
        FROM json_each(tasks.dependencies) d
        WHERE d.value IN (SELECT id FROM tasks)
    ),
    updated_at = datetime('now')
WHERE id IN (
    SELECT t.id FROM tasks t, json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM tasks)
);
"
MISSING_AFTER=$(sqlite3 "$DB" "
SELECT COUNT(*)
FROM tasks t, json_each(t.dependencies) d
WHERE t.archived_at IS NULL AND d.value NOT IN (SELECT id FROM tasks);
")
assert_eq "$MISSING_AFTER" "0" "Dependencies fix: missing references removed"

# Auto-fix: remove self-references
# Note: must qualify 'tasks.id' to avoid ambiguity with json_each's 'id' column
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = (
        SELECT COALESCE(json_group_array(d.value), '[]')
        FROM json_each(tasks.dependencies) d
        WHERE d.value != tasks.id
    ),
    updated_at = datetime('now')
WHERE id IN (
    SELECT t.id FROM tasks t, json_each(t.dependencies) d
    WHERE d.value = t.id
);
"
SELF_AFTER=$(sqlite3 "$DB" "
SELECT COUNT(*)
FROM tasks t, json_each(t.dependencies) d
WHERE d.value = t.id;
")
assert_eq "$SELF_AFTER" "0" "Dependencies fix: self-references removed"

# Add dependency query
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = json_insert(dependencies, '\$[#]', '1.1'),
    updated_at = datetime('now')
WHERE id = '1.2';
"
DEP_ADDED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks t, json_each(t.dependencies) d WHERE t.id = '1.2' AND d.value = '1.1';")
assert_eq "$DEP_ADDED" "1" "Dependencies: add dependency works"

# Remove dependency query
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = (
        SELECT COALESCE(json_group_array(d.value), '[]')
        FROM json_each(tasks.dependencies) d
        WHERE d.value != '1.3'
    ),
    updated_at = datetime('now')
WHERE id = '1.2';
"

# Restore original dependencies
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.1\"]' WHERE id = '1.2';"
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.1\"]' WHERE id = '1.3';"
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"2.1\"]' WHERE id = '2.2';"

echo ""

# ====================================================================
# TEST 9: Move (P6 - new command)
# ====================================================================
echo "--- Test 9: Move command queries ---"

# Load task and siblings
TASK_INFO=$(sqlite3 "$DB" "SELECT id, parent_id, title, status FROM tasks WHERE id = '2.3' AND archived_at IS NULL;")
assert_not_empty "$TASK_INFO" "Move: can load task 2.3"

SIBLINGS=$(sqlite3 "$DB" "
SELECT id, title FROM tasks
WHERE parent_id = (SELECT parent_id FROM tasks WHERE id = '2.3')
  AND archived_at IS NULL
ORDER BY id;
")
assert_not_empty "$SIBLINGS" "Move: found siblings of 2.3"

# No-cycle check (moving under descendant)
CYCLE_CHECK=$(sqlite3 "$DB" "
WITH RECURSIVE descendants AS (
    SELECT id FROM tasks WHERE id = '1'
    UNION ALL
    SELECT t.id FROM tasks t JOIN descendants d ON t.parent_id = d.id
)
SELECT COUNT(*) FROM descendants WHERE id = '1.2';
")
assert_eq "$CYCLE_CHECK" "1" "Move: cycle check detects descendant correctly"

# Next available child number
NEXT_NUM=$(sqlite3 "$DB" "
SELECT COALESCE(
    MAX(CAST(SUBSTR(id, LENGTH('3') + 2) AS INTEGER)),
    0
) + 1 as next_num
FROM tasks
WHERE parent_id = '3';
")
assert_eq "$NEXT_NUM" "4" "Move: next child number under epic 3 is 4"

# Simulate reparent: move 2.3 under 3 as 3.4
sqlite3 "$DB" "
BEGIN TRANSACTION;
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority,
                   complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
SELECT '3.4', '3', title, description, details, test_strategy, status, type, priority,
       complexity_scale, complexity_reasoning, estimate_seconds, tags,
       REPLACE(dependencies, '\"2.1\"', '\"2.1\"')
FROM tasks WHERE id = '2.3';
DELETE FROM tasks WHERE id = '2.3';
COMMIT;
"
MOVED_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE id = '3.4';")
OLD_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE id = '2.3';")
assert_eq "$MOVED_EXISTS" "1" "Move: task exists at new location 3.4"
assert_eq "$OLD_EXISTS" "0" "Move: task removed from old location 2.3"

# Restore: move it back
sqlite3 "$DB" "
BEGIN TRANSACTION;
INSERT INTO tasks (id, parent_id, title, description, details, test_strategy, status, type, priority,
                   complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies)
SELECT '2.3', '2', title, description, details, test_strategy, status, type, priority,
       complexity_scale, complexity_reasoning, estimate_seconds, tags, dependencies
FROM tasks WHERE id = '3.4';
DELETE FROM tasks WHERE id = '3.4';
COMMIT;
"

echo ""

# ====================================================================
# TEST 10: Research (P7 - new command)
# ====================================================================
echo "--- Test 10: Research command queries ---"

# Check existing research via FTS5
FTS_SEARCH=$(sqlite3 "$DB" "
SELECT m.id, m.title, m.body, m.importance
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE m.status = 'active'
  AND memories_fts MATCH 'testing'
ORDER BY m.importance DESC
LIMIT 5;
")
assert_not_empty "$FTS_SEARCH" "Research: FTS5 search for 'testing' returns results"
assert_contains "$FTS_SEARCH" "Pest" "Research: found Pest testing memory"

# Insert research memory
sqlite3 "$DB" "
INSERT INTO memories (
    id, title, kind, why_important, body,
    source_type, source_name, source_via, auto_updatable,
    importance, confidence, status,
    scope, tags, links
) VALUES (
    'M-0004',
    'Research: JWT Best Practices 2024',
    'architecture',
    'Informs authentication implementation',
    'JWT tokens should use RS256 algorithm. Access tokens: 15 min TTL. Refresh tokens: 7 day TTL with rotation.',
    'agent', 'research-command', 'taskmanager:research', 1,
    4, 0.85, 'active',
    '{\"domains\": [\"auth\", \"security\"]}',
    '[\"jwt\", \"auth\", \"research\"]',
    '[]'
);
"
RESEARCH_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE id = 'M-0004';")
assert_eq "$RESEARCH_EXISTS" "1" "Research: memory inserted successfully"

# FTS5 search for research
FTS_JWT=$(sqlite3 "$DB" "
SELECT m.id, m.title
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'JWT'
ORDER BY rank
LIMIT 5;
")
assert_contains "$FTS_JWT" "M-0004" "Research: FTS5 finds new research memory"

# Scope search (within research memory scope)
SCOPE_SEARCH=$(sqlite3 "$DB" "
SELECT id, title FROM memories
WHERE status = 'active'
  AND json_extract(scope, '\$.domains') LIKE '%auth%';
")
assert_not_empty "$SCOPE_SEARCH" "Research: scope search for 'auth' domain works"

# Clean up
sqlite3 "$DB" "DELETE FROM memories WHERE id = 'M-0004';"

echo ""

# ====================================================================
# TEST 11: Config (P8)
# ====================================================================
echo "--- Test 11: Config validation ---"

# Valid JSON
if python3 -c "import json; json.load(open('.taskmanager/config.json'))" 2>/dev/null; then
    pass "Config: valid JSON"
else
    fail "Config: invalid JSON"
fi

# Check expected keys
CONFIG_KEYS=$(python3 -c "
import json
c = json.load(open('.taskmanager/config.json'))
keys = sorted(c.keys())
print(','.join(keys))
")
assert_contains "$CONFIG_KEYS" "version" "Config: has 'version' key"
assert_contains "$CONFIG_KEYS" "defaults" "Config: has 'defaults' key"
assert_contains "$CONFIG_KEYS" "dashboard" "Config: has 'dashboard' key"

# Verify config has expected v4.0.0 sections and no deprecated ones
if echo "$CONFIG_KEYS" | grep -qF "execution"; then
    fail "Config: should not have 'execution' key (deprecated)"
else
    pass "Config: no deprecated 'execution' key"
fi
if echo "$CONFIG_KEYS" | grep -qF "planning"; then
    pass "Config: has 'planning' key"
else
    fail "Config: missing 'planning' key"
fi
if echo "$CONFIG_KEYS" | grep -qF "milestones"; then
    pass "Config: has 'milestones' key"
else
    fail "Config: missing 'milestones' key"
fi

echo ""

# ====================================================================
# TEST 12: Update-task (P9 - new command)
# ====================================================================
echo "--- Test 12: Update-task command queries ---"

# Direct field update
sqlite3 "$DB" "
UPDATE tasks SET
    title = 'JWT Login/Logout Endpoints',
    priority = 'critical',
    updated_at = datetime('now')
WHERE id = '1.1';
"
UPDATED_TITLE=$(sqlite3 "$DB" "SELECT title FROM tasks WHERE id = '1.1';")
assert_eq "$UPDATED_TITLE" "JWT Login/Logout Endpoints" "Update-task: title updated"

UPDATED_PRIO=$(sqlite3 "$DB" "SELECT priority FROM tasks WHERE id = '1.1';")
assert_eq "$UPDATED_PRIO" "critical" "Update-task: priority updated"

# Cascade dependent query
CASCADE=$(sqlite3 "$DB" "
WITH RECURSIVE dep_chain AS (
    SELECT t.id, t.title, t.description, t.dependencies, 1 as depth
    FROM tasks t
    WHERE t.archived_at IS NULL
      AND t.status NOT IN ('done', 'canceled', 'duplicate')
      AND EXISTS (
          SELECT 1 FROM json_each(t.dependencies) d
          WHERE d.value = '1.1'
      )
    UNION ALL
    SELECT t.id, t.title, t.description, t.dependencies, dc.depth + 1
    FROM tasks t
    JOIN dep_chain dc ON EXISTS (
        SELECT 1 FROM json_each(t.dependencies) d
        WHERE d.value = dc.id
    )
    WHERE t.archived_at IS NULL
      AND t.status NOT IN ('done', 'canceled', 'duplicate')
      AND dc.depth < 5
)
SELECT DISTINCT id, depth FROM dep_chain ORDER BY depth, id;
")
assert_not_empty "$CASCADE" "Update-task: cascade finds dependent tasks"
assert_contains "$CASCADE" "1.2" "Update-task: cascade includes task 1.2"
assert_contains "$CASCADE" "1.3" "Update-task: cascade includes task 1.3"

# Restore original values
sqlite3 "$DB" "UPDATE tasks SET title = 'JWT Login/Logout', priority = 'high' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 13: Export --files (P10 - new command)
# ====================================================================
echo "--- Test 13: Export --files query ---"

EXPORT_DATA=$(sqlite3 "$DB" "
SELECT id, parent_id, title, description, details, test_strategy,
       status, type, priority,
       complexity_scale,
       estimate_seconds,
       tags, dependencies
FROM tasks
WHERE archived_at IS NULL
ORDER BY id;
")
assert_not_empty "$EXPORT_DATA" "Export: query returns all active tasks"

EXPORT_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL;")
assert_eq "$EXPORT_COUNT" "14" "Export: correct number of active tasks"

# Check export format for markdown (verify subtask listing)
SUBTASKS_OF_1=$(sqlite3 "$DB" "
SELECT id, title, status FROM tasks
WHERE parent_id = '1' AND archived_at IS NULL
ORDER BY id;
")
assert_not_empty "$SUBTASKS_OF_1" "Export: can list subtasks of epic 1"

echo ""

# ====================================================================
# TEST 14: Regression - stats --json
# ====================================================================
echo "--- Test 14: Stats --json ---"

JSON_OUTPUT=$(sqlite3 "$DB" "
SELECT json_object(
    'total', (SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL),
    'done', (SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL AND status = 'done'),
    'in_progress', (SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL AND status = 'in-progress'),
    'blocked', (SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL AND status = 'blocked'),
    'remaining', (SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL AND status NOT IN ('done', 'canceled', 'duplicate')),
    'by_status', (
        SELECT json_group_object(status, cnt)
        FROM (SELECT status, COUNT(*) as cnt FROM tasks WHERE archived_at IS NULL GROUP BY status)
    ),
    'by_priority', (
        SELECT json_group_object(priority, cnt)
        FROM (SELECT priority, COUNT(*) as cnt FROM tasks WHERE archived_at IS NULL GROUP BY priority)
    ),
    'estimated_remaining_seconds', (
        SELECT COALESCE(SUM(estimate_seconds), 0)
        FROM tasks
        WHERE archived_at IS NULL
          AND status NOT IN ('done', 'canceled', 'duplicate')
          AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id)
    )
);
")
assert_not_empty "$JSON_OUTPUT" "Stats --json: returns output"

# Validate it's valid JSON
if echo "$JSON_OUTPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    pass "Stats --json: output is valid JSON"
else
    fail "Stats --json: output is NOT valid JSON"
fi

# Check key values
TOTAL=$(echo "$JSON_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['total'])")
assert_eq "$TOTAL" "14" "Stats --json: total tasks = 14"

DONE=$(echo "$JSON_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['done'])")
assert_eq "$DONE" "1" "Stats --json: done tasks = 1"

BLOCKED=$(echo "$JSON_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['blocked'])")
assert_eq "$BLOCKED" "1" "Stats --json: blocked tasks = 1"

echo ""

# ====================================================================
# TEST 15: Regression - next-task
# ====================================================================
echo "--- Test 15: Next-task ---"

NEXT_TASK=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks
    WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT t.id, t.title, t.priority, t.complexity_scale
FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND (
      t.dependencies = '[]'
      OR NOT EXISTS (
          SELECT 1 FROM json_each(t.dependencies) d
          WHERE d.value NOT IN (SELECT id FROM done_ids)
      )
  )
ORDER BY
    CASE t.priority
        WHEN 'critical' THEN 0
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        ELSE 3
    END,
    CASE t.complexity_scale
        WHEN 'XS' THEN 0
        WHEN 'S' THEN 1
        WHEN 'M' THEN 2
        WHEN 'L' THEN 3
        WHEN 'XL' THEN 4
        ELSE 2
    END,
    t.id
LIMIT 1;
")
assert_not_empty "$NEXT_TASK" "Next-task: found a next task"

# The next task should be a leaf with no unmet deps, highest priority first
# Task 3.1 is critical priority, leaf, deps=[] -> should be first
NEXT_ID=$(echo "$NEXT_TASK" | cut -d'|' -f1)
assert_eq "$NEXT_ID" "3.1" "Next-task: recommends task 3.1 (critical priority, no deps)"

echo ""

# ====================================================================
# TEST 16: Regression - status propagation
# ====================================================================
echo "--- Test 16: Status propagation ---"

# Mark 1.3.1 as in-progress, propagate to ancestors
sqlite3 "$DB" "
UPDATE tasks SET status = 'in-progress', started_at = datetime('now'), updated_at = datetime('now')
WHERE id = '1.3.1';
"

# Propagate to ancestors using recursive CTE
sqlite3 "$DB" "
WITH RECURSIVE ancestors AS (
    SELECT parent_id as id
    FROM tasks
    WHERE id = '1.3.1' AND parent_id IS NOT NULL
    UNION ALL
    SELECT t.parent_id
    FROM tasks t
    JOIN ancestors a ON t.id = a.id
    WHERE t.parent_id IS NOT NULL
)
UPDATE tasks SET
    status = 'in-progress',
    updated_at = datetime('now')
WHERE id IN (SELECT id FROM ancestors);
"

STATUS_13=$(sqlite3 "$DB" "SELECT status FROM tasks WHERE id = '1.3';")
assert_eq "$STATUS_13" "in-progress" "Propagation: parent 1.3 became in-progress"

STATUS_1=$(sqlite3 "$DB" "SELECT status FROM tasks WHERE id = '1';")
assert_eq "$STATUS_1" "in-progress" "Propagation: grandparent 1 became in-progress"

# Now mark 1.3.1 done and propagate properly
sqlite3 "$DB" "
UPDATE tasks SET status = 'done', completed_at = datetime('now'), updated_at = datetime('now')
WHERE id = '1.3.1';
"

# Propagate with proper status calculation
sqlite3 "$DB" "
WITH RECURSIVE ancestors AS (
    SELECT parent_id as id
    FROM tasks
    WHERE id = '1.3.1' AND parent_id IS NOT NULL
    UNION ALL
    SELECT t.parent_id
    FROM tasks t
    JOIN ancestors a ON t.id = a.id
    WHERE t.parent_id IS NOT NULL
)
UPDATE tasks SET
    status = (
        SELECT CASE
            WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'in-progress')
                THEN 'in-progress'
            WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'blocked')
                THEN 'blocked'
            WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'needs-review')
                THEN 'needs-review'
            WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status IN ('planned', 'draft', 'paused'))
                THEN 'planned'
            WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'done')
                THEN 'done'
            ELSE 'canceled'
        END
    ),
    updated_at = datetime('now')
WHERE id IN (SELECT id FROM ancestors);
"

STATUS_13_AFTER=$(sqlite3 "$DB" "SELECT status FROM tasks WHERE id = '1.3';")
assert_eq "$STATUS_13_AFTER" "planned" "Propagation: parent 1.3 back to planned (other children still planned)"

# Restore original statuses
sqlite3 "$DB" "UPDATE tasks SET status = 'planned', started_at = NULL, completed_at = NULL WHERE id = '1.3.1';"
sqlite3 "$DB" "UPDATE tasks SET status = 'planned' WHERE id = '1.3';"
sqlite3 "$DB" "UPDATE tasks SET status = 'in-progress' WHERE id = '1';"

echo ""

# ====================================================================
# TEST 17: Regression - archive cascade
# ====================================================================
echo "--- Test 17: Archive cascade ---"

# Archive task 1.1 (done task)
sqlite3 "$DB" "
UPDATE tasks SET
    archived_at = datetime('now'),
    updated_at = datetime('now')
WHERE id = '1.1';
"
ARCHIVED=$(sqlite3 "$DB" "SELECT archived_at IS NOT NULL FROM tasks WHERE id = '1.1';")
assert_eq "$ARCHIVED" "1" "Archive: task 1.1 archived"

# Check parent NOT archived (other children still active)
PARENT_ARCHIVED=$(sqlite3 "$DB" "SELECT archived_at IS NULL FROM tasks WHERE id = '1';")
assert_eq "$PARENT_ARCHIVED" "1" "Archive: parent 1 NOT archived (has active children)"

# Cascade archive check query
SHOULD_ARCHIVE_PARENT=$(sqlite3 "$DB" "
SELECT NOT EXISTS (
    SELECT 1 FROM tasks c
    WHERE c.parent_id = '1'
      AND c.archived_at IS NULL
);
")
assert_eq "$SHOULD_ARCHIVE_PARENT" "0" "Archive: parent correctly not eligible (has unarchived children)"

# Restore
sqlite3 "$DB" "UPDATE tasks SET archived_at = NULL WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 18: Regression - Memory FTS5
# ====================================================================
echo "--- Test 18: Memory FTS5 search ---"

# Simple term search
FTS_RESULT=$(sqlite3 "$DB" "
SELECT m.id, m.title
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'Redis'
ORDER BY rank;
")
assert_not_empty "$FTS_RESULT" "FTS5: simple term 'Redis' returns results"
assert_contains "$FTS_RESULT" "M-0002" "FTS5: found Redis memory M-0002"

# Prefix search
FTS_PREFIX=$(sqlite3 "$DB" "
SELECT m.id, m.title
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'test*'
ORDER BY rank;
")
assert_not_empty "$FTS_PREFIX" "FTS5: prefix search 'test*' returns results"
assert_contains "$FTS_PREFIX" "M-0001" "FTS5: prefix search finds M-0001 (testing)"

# Search for a term that should match body text
FTS_BODY=$(sqlite3 "$DB" "
SELECT m.id
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'token bucket';
")
assert_not_empty "$FTS_BODY" "FTS5: body search 'token bucket' returns results"

# Search for tags
FTS_TAG=$(sqlite3 "$DB" "
SELECT m.id
FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'bugfix';
")
assert_not_empty "$FTS_TAG" "FTS5: tag search 'bugfix' returns results"
assert_contains "$FTS_TAG" "M-0003" "FTS5: tag search finds M-0003"

# Verify FTS sync triggers work: insert new memory, search, delete
sqlite3 "$DB" "
INSERT INTO memories (id, title, kind, why_important, body, source_type, importance, confidence, status, scope, tags, links)
VALUES ('M-9999', 'Temporary test memory', 'convention', 'Testing FTS sync', 'Unique keyword xyzzy123 for testing', 'user', 1, 0.5, 'active', '{}', '[]', '[]');
"
FTS_SYNC=$(sqlite3 "$DB" "
SELECT m.id FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'xyzzy123';
")
assert_contains "$FTS_SYNC" "M-9999" "FTS5: sync trigger works for INSERT"

sqlite3 "$DB" "DELETE FROM memories WHERE id = 'M-9999';"
FTS_AFTER_DEL=$(sqlite3 "$DB" "
SELECT COUNT(*) FROM memories m
JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'xyzzy123';
")
assert_eq "$FTS_AFTER_DEL" "0" "FTS5: sync trigger works for DELETE"

echo ""

# ====================================================================
# TEST 19: Deferrals
# ====================================================================
echo "--- Test 19: Deferrals ---"

# 19a: INSERT/SELECT CRUD
NEXT_DEF_ID=$(sqlite3 "$DB" "SELECT 'D-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1) FROM deferrals;")
assert_eq "$NEXT_DEF_ID" "D-0001" "Deferrals: next ID is D-0001 (empty table)"

sqlite3 "$DB" "
INSERT INTO deferrals (id, source_task_id, target_task_id, title, body, reason)
VALUES ('D-0001', '1.1', '3.1', 'Add OAuth support', 'Implement OAuth2 with Google and GitHub providers', 'Too complex for MVP');
INSERT INTO deferrals (id, source_task_id, target_task_id, title, body, reason)
VALUES ('D-0002', '2.1', '2.3', 'Chart animations', 'Add smooth transitions to chart updates', 'Non-critical, defer to polish phase');
INSERT INTO deferrals (id, source_task_id, title, body, reason)
VALUES ('D-0003', '1.2', 'Rate limiting edge cases', 'Handle burst traffic scenarios for API endpoints', 'Deferred to hardening phase');
"

DEF_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM deferrals;")
assert_eq "$DEF_COUNT" "3" "Deferrals: 3 records inserted"

# Read back a specific deferral
DEF_TITLE=$(sqlite3 "$DB" "SELECT title FROM deferrals WHERE id = 'D-0001';")
assert_eq "$DEF_TITLE" "Add OAuth support" "Deferrals: can read back deferral by ID"

# 19b: Query deferrals by target task
TARGET_DEFS=$(sqlite3 "$DB" "
SELECT d.id, d.title, d.body, d.reason, d.source_task_id,
       t.title as source_title
FROM deferrals d
LEFT JOIN tasks t ON t.id = d.source_task_id
WHERE d.target_task_id = '3.1' AND d.status = 'pending'
ORDER BY d.created_at;
")
assert_not_empty "$TARGET_DEFS" "Deferrals: query by target returns results"
assert_contains "$TARGET_DEFS" "D-0001" "Deferrals: target query finds D-0001"
assert_contains "$TARGET_DEFS" "OAuth" "Deferrals: target query includes title"

# 19c: Query deferrals by source task
SOURCE_DEFS=$(sqlite3 "$DB" "SELECT id, title FROM deferrals WHERE source_task_id = '1.1';")
assert_contains "$SOURCE_DEFS" "D-0001" "Deferrals: query by source finds D-0001"

# 19d: Unassigned deferral (target_task_id IS NULL)
UNASSIGNED=$(sqlite3 "$DB" "
SELECT d.id, d.title FROM deferrals d
WHERE d.status = 'pending' AND d.target_task_id IS NULL;
")
assert_contains "$UNASSIGNED" "D-0003" "Deferrals: D-0003 is unassigned (NULL target)"

# 19e: Dashboard aggregate query
DASH_DEF=$(sqlite3 "$DB" "
SELECT
    COUNT(*) as pending,
    SUM(CASE WHEN target_task_id IS NOT NULL THEN 1 ELSE 0 END) as assigned,
    SUM(CASE WHEN target_task_id IS NULL THEN 1 ELSE 0 END) as unassigned
FROM deferrals WHERE status = 'pending';
")
assert_contains "$DASH_DEF" "3" "Deferrals: dashboard shows 3 pending"

# 19f: Status transitions
# pending -> applied
sqlite3 "$DB" "UPDATE deferrals SET status = 'applied', applied_at = datetime('now'), updated_at = datetime('now') WHERE id = 'D-0001';"
APPLIED_STATUS=$(sqlite3 "$DB" "SELECT status FROM deferrals WHERE id = 'D-0001';")
assert_eq "$APPLIED_STATUS" "applied" "Deferrals: D-0001 status -> applied"

APPLIED_AT=$(sqlite3 "$DB" "SELECT applied_at IS NOT NULL FROM deferrals WHERE id = 'D-0001';")
assert_eq "$APPLIED_AT" "1" "Deferrals: applied_at is set after apply"

# pending -> canceled
sqlite3 "$DB" "UPDATE deferrals SET status = 'canceled', updated_at = datetime('now') WHERE id = 'D-0002';"
CANCELED_STATUS=$(sqlite3 "$DB" "SELECT status FROM deferrals WHERE id = 'D-0002';")
assert_eq "$CANCELED_STATUS" "canceled" "Deferrals: D-0002 status -> canceled"

# pending -> reassigned (with new deferral)
sqlite3 "$DB" "
UPDATE deferrals SET status = 'reassigned', updated_at = datetime('now') WHERE id = 'D-0003';
INSERT INTO deferrals (id, source_task_id, target_task_id, title, body, reason)
VALUES ('D-0004', '1.2', '3.2', 'Rate limiting edge cases', 'Handle burst traffic scenarios for API endpoints', 'Reassigned from unassigned to task 3.2');
"
REASSIGNED_STATUS=$(sqlite3 "$DB" "SELECT status FROM deferrals WHERE id = 'D-0003';")
assert_eq "$REASSIGNED_STATUS" "reassigned" "Deferrals: D-0003 status -> reassigned"

NEW_DEF_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM deferrals WHERE id = 'D-0004' AND target_task_id = '3.2';")
assert_eq "$NEW_DEF_EXISTS" "1" "Deferrals: reassignment created D-0004 targeting 3.2"

# 19g: CHECK constraint validation
INVALID_STATUS=$(sqlite3 "$DB" "UPDATE deferrals SET status = 'invalid' WHERE id = 'D-0004';" 2>&1 || true)
if echo "$INVALID_STATUS" | grep -qi "constraint\|check"; then
    pass "Deferrals: CHECK constraint rejects invalid status"
else
    # Verify status was not actually changed
    STILL_PENDING=$(sqlite3 "$DB" "SELECT status FROM deferrals WHERE id = 'D-0004';")
    if [[ "$STILL_PENDING" == "pending" ]]; then
        pass "Deferrals: CHECK constraint rejects invalid status"
    else
        fail "Deferrals: CHECK constraint did NOT reject invalid status"
    fi
fi

# 19h: FK constraint - ON DELETE RESTRICT (source)
RESTRICT_RESULT=$(sqlite3 "$DB" "PRAGMA foreign_keys = ON; DELETE FROM tasks WHERE id = '1.2';" 2>&1 || true)
TASK_STILL_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE id = '1.2';")
assert_eq "$TASK_STILL_EXISTS" "1" "Deferrals: FK RESTRICT prevents deleting source task 1.2"

# 19i: FK constraint - ON DELETE SET NULL (target)
# Create a temporary task to use as target, then delete it
sqlite3 "$DB" "INSERT INTO tasks (id, title, status) VALUES ('99', 'Temp target', 'planned');"
sqlite3 "$DB" "INSERT INTO deferrals (id, source_task_id, target_task_id, title, body, reason) VALUES ('D-0005', '1.1', '99', 'Temp deferral', 'Test SET NULL', 'Testing FK');"
sqlite3 "$DB" "PRAGMA foreign_keys = ON; DELETE FROM tasks WHERE id = '99';"
NULL_TARGET=$(sqlite3 "$DB" "SELECT target_task_id IS NULL FROM deferrals WHERE id = 'D-0005';")
assert_eq "$NULL_TARGET" "1" "Deferrals: FK SET NULL nullifies target when task deleted"

# 19j: Stale deferral validation (target task is terminal but deferral pending)
# D-0004 targets 3.2 (planned). Mark 3.2 as done to make D-0004 stale.
sqlite3 "$DB" "UPDATE tasks SET status = 'done' WHERE id = '3.2';"
STALE=$(sqlite3 "$DB" "
SELECT d.id, d.title, d.target_task_id, t.status as target_status
FROM deferrals d
JOIN tasks t ON t.id = d.target_task_id
WHERE d.status = 'pending'
  AND t.status IN ('done', 'canceled', 'duplicate');
")
assert_contains "$STALE" "D-0004" "Deferrals: stale validation finds D-0004 (target 3.2 is done)"

# Restore 3.2 status
sqlite3 "$DB" "UPDATE tasks SET status = 'blocked' WHERE id = '3.2';"

# 19k: Move integration - update source/target IDs
# Simulate task move: if 3.1 moves to 4.1, all deferral references should update
sqlite3 "$DB" "
UPDATE deferrals SET source_task_id = '4.1', updated_at = datetime('now')
WHERE source_task_id = '3.1';
UPDATE deferrals SET target_task_id = '4.1', updated_at = datetime('now')
WHERE target_task_id = '3.1';
"
MOVED_TARGET=$(sqlite3 "$DB" "SELECT target_task_id FROM deferrals WHERE id = 'D-0001';")
assert_eq "$MOVED_TARGET" "4.1" "Deferrals: move updates target_task_id from 3.1 to 4.1"

# Restore
sqlite3 "$DB" "
UPDATE deferrals SET target_task_id = '3.1', updated_at = datetime('now')
WHERE id = 'D-0001';
UPDATE deferrals SET source_task_id = '3.1', updated_at = datetime('now')
WHERE source_task_id = '4.1';
"

# 19l: Next deferral ID after inserts
NEXT_ID_AFTER=$(sqlite3 "$DB" "SELECT 'D-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1) FROM deferrals;")
assert_eq "$NEXT_ID_AFTER" "D-0006" "Deferrals: next ID after 5 records is D-0006"

# 19m: Deferral indexes exist
IDX_TARGET=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_deferrals_target';")
assert_eq "$IDX_TARGET" "1" "Deferrals: target index exists"

IDX_SOURCE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_deferrals_source';")
assert_eq "$IDX_SOURCE" "1" "Deferrals: source index exists"

IDX_STATUS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_deferrals_status';")
assert_eq "$IDX_STATUS" "1" "Deferrals: status index exists"

# Clean up test deferrals
sqlite3 "$DB" "DELETE FROM deferrals;"

echo ""

# ====================================================================
# TEST 20: Milestones (v4.0.0)
# ====================================================================
echo "--- Test 20: Milestones ---"

# 20a: Milestones table exists
MS_TABLE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='milestones';")
assert_eq "$MS_TABLE" "1" "Milestones: table exists"

# 20b: Insert milestones
sqlite3 "$DB" "
INSERT INTO milestones (id, title, description, phase_order, status)
VALUES ('MS-001', 'MVP - Core Features', 'Authentication and infrastructure', 1, 'active');
INSERT INTO milestones (id, title, description, phase_order, status)
VALUES ('MS-002', 'Enhancement Phase', 'Dashboard and monitoring', 2, 'planned');
INSERT INTO milestones (id, title, description, phase_order, status)
VALUES ('MS-003', 'Nice-to-have', 'Polish and optimization', 3, 'planned');
"
MS_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM milestones;")
assert_eq "$MS_COUNT" "3" "Milestones: 3 records inserted"

# 20c: Read milestone by ID
MS_TITLE=$(sqlite3 "$DB" "SELECT title FROM milestones WHERE id = 'MS-001';")
assert_eq "$MS_TITLE" "MVP - Core Features" "Milestones: read by ID works"

# 20d: Phase order ordering
FIRST_MS=$(sqlite3 "$DB" "SELECT id FROM milestones ORDER BY phase_order LIMIT 1;")
assert_eq "$FIRST_MS" "MS-001" "Milestones: phase_order ordering works"

# 20e: Active milestone query
ACTIVE_MS=$(sqlite3 "$DB" "SELECT id FROM milestones WHERE status IN ('active', 'planned') ORDER BY phase_order LIMIT 1;")
assert_eq "$ACTIVE_MS" "MS-001" "Milestones: active milestone is MS-001"

# 20f: Status CHECK constraint
INVALID_MS=$(sqlite3 "$DB" "INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-BAD', 'Bad', 99, 'invalid');" 2>&1 || true)
if echo "$INVALID_MS" | grep -qi "constraint\|check"; then
    pass "Milestones: CHECK constraint rejects invalid status"
else
    BAD_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM milestones WHERE id = 'MS-BAD';")
    if [[ "$BAD_EXISTS" == "0" ]]; then
        pass "Milestones: CHECK constraint rejects invalid status"
    else
        fail "Milestones: CHECK constraint did NOT reject invalid status"
        sqlite3 "$DB" "DELETE FROM milestones WHERE id = 'MS-BAD';"
    fi
fi

# 20g: Status transitions
sqlite3 "$DB" "UPDATE milestones SET status = 'completed', updated_at = datetime('now') WHERE id = 'MS-001';"
COMPLETED_STATUS=$(sqlite3 "$DB" "SELECT status FROM milestones WHERE id = 'MS-001';")
assert_eq "$COMPLETED_STATUS" "completed" "Milestones: status -> completed"
sqlite3 "$DB" "UPDATE milestones SET status = 'active' WHERE id = 'MS-001';"

# 20h: FK constraint - tasks.milestone_id references milestones
sqlite3 "$DB" "UPDATE tasks SET milestone_id = 'MS-001' WHERE id = '1';"
FK_VALUE=$(sqlite3 "$DB" "SELECT milestone_id FROM tasks WHERE id = '1';")
assert_eq "$FK_VALUE" "MS-001" "Milestones: FK assignment works"

# 20i: Milestone with task counts
MS_STATS=$(sqlite3 "$DB" "
SELECT m.id, m.title,
    COUNT(t.id) as total_tasks,
    SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as done_tasks
FROM milestones m
LEFT JOIN tasks t ON t.milestone_id = m.id AND t.archived_at IS NULL
GROUP BY m.id
ORDER BY m.phase_order;
")
assert_not_empty "$MS_STATS" "Milestones: task count query works"
assert_contains "$MS_STATS" "MS-001" "Milestones: task count includes MS-001"

# 20j: Indexes exist
IDX_MS_STATUS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_milestones_status';")
assert_eq "$IDX_MS_STATUS" "1" "Milestones: status index exists"

IDX_MS_ORDER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_milestones_order';")
assert_eq "$IDX_MS_ORDER" "1" "Milestones: order index exists"

IDX_TASKS_MS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_tasks_milestone';")
assert_eq "$IDX_TASKS_MS" "1" "Milestones: tasks milestone index exists"

# 20k: Generate next milestone ID
NEXT_MS_ID=$(sqlite3 "$DB" "SELECT 'MS-' || printf('%03d', COALESCE(MAX(CAST(SUBSTR(id, 4) AS INTEGER)), 0) + 1) FROM milestones;")
assert_eq "$NEXT_MS_ID" "MS-004" "Milestones: next ID is MS-004"

# Clean up: remove milestone assignment from task but keep milestones for later tests
sqlite3 "$DB" "UPDATE tasks SET milestone_id = NULL WHERE id = '1';"

echo ""

# ====================================================================
# TEST 21: Plan Analyses (v4.0.0)
# ====================================================================
echo "--- Test 21: Plan Analyses ---"

# 21a: Table exists
PA_TABLE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='plan_analyses';")
assert_eq "$PA_TABLE" "1" "Plan Analyses: table exists"

# 21b: Insert analysis
sqlite3 "$DB" "
INSERT INTO plan_analyses (id, prd_source, prd_hash, tech_stack, assumptions, risks, ambiguities, nfrs, scope_in, scope_out, cross_cutting)
VALUES (
    'PA-001',
    '.taskmanager/docs/prd.md',
    'abc123def456',
    '[\"laravel\", \"redis\", \"react\", \"chartjs\"]',
    '[{\"description\": \"Telemetry source is available\", \"confidence\": \"high\", \"impact\": \"critical\"}]',
    '[{\"description\": \"WebSocket scalability\", \"severity\": \"medium\", \"likelihood\": \"low\", \"mitigation\": \"Use Redis pub/sub\"}]',
    '[{\"requirement\": \"Update frequency\", \"question\": \"Is 5 seconds the minimum or target?\", \"resolution\": null}]',
    '[{\"category\": \"performance\", \"requirement\": \"API response < 200ms\", \"priority\": \"high\"}]',
    'Real-time bandwidth widget with chart and warnings',
    'Authentication changes, UI theming',
    '[{\"concern\": \"Error handling\", \"affected_epics\": [\"1\"], \"strategy\": \"Global error boundary\"}]'
);
"
PA_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM plan_analyses;")
assert_eq "$PA_COUNT" "1" "Plan Analyses: record inserted"

# 21c: Read analysis by ID
PA_SOURCE=$(sqlite3 "$DB" "SELECT prd_source FROM plan_analyses WHERE id = 'PA-001';")
assert_eq "$PA_SOURCE" ".taskmanager/docs/prd.md" "Plan Analyses: read by ID works"

# 21d: PRD hash lookup
HASH_LOOKUP=$(sqlite3 "$DB" "SELECT id FROM plan_analyses WHERE prd_hash = 'abc123def456' ORDER BY created_at DESC LIMIT 1;")
assert_eq "$HASH_LOOKUP" "PA-001" "Plan Analyses: hash lookup works"

# 21e: JSON column access
TECH_STACK=$(sqlite3 "$DB" "SELECT json_extract(tech_stack, '\$[0]') FROM plan_analyses WHERE id = 'PA-001';")
assert_eq "$TECH_STACK" "laravel" "Plan Analyses: JSON tech_stack accessible"

RISK_DESC=$(sqlite3 "$DB" "SELECT json_extract(risks, '\$[0].description') FROM plan_analyses WHERE id = 'PA-001';")
assert_eq "$RISK_DESC" "WebSocket scalability" "Plan Analyses: JSON risks accessible"

# 21f: Update decisions array
sqlite3 "$DB" "
UPDATE plan_analyses SET
    decisions = json_insert(decisions, '\$[#]', json_object('question', 'Queue driver?', 'answer', 'Redis', 'rationale', 'Already in stack', 'memory_id', 'M-0010')),
    updated_at = datetime('now')
WHERE id = 'PA-001';
"
DECISION_COUNT=$(sqlite3 "$DB" "SELECT json_array_length(decisions) FROM plan_analyses WHERE id = 'PA-001';")
assert_eq "$DECISION_COUNT" "1" "Plan Analyses: decision appended"

# 21g: Cross-cutting concern query
CROSS_CUT=$(sqlite3 "$DB" "SELECT json_each.value FROM plan_analyses pa, json_each(pa.cross_cutting) WHERE pa.id = 'PA-001';")
assert_contains "$CROSS_CUT" "Error handling" "Plan Analyses: cross-cutting concern accessible"

# 21h: Index exists
IDX_PA_HASH=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_plan_analyses_hash';")
assert_eq "$IDX_PA_HASH" "1" "Plan Analyses: hash index exists"

# 21i: Generate next analysis ID
NEXT_PA_ID=$(sqlite3 "$DB" "SELECT 'PA-' || printf('%03d', COALESCE(MAX(CAST(SUBSTR(id, 4) AS INTEGER)), 0) + 1) FROM plan_analyses;")
assert_eq "$NEXT_PA_ID" "PA-002" "Plan Analyses: next ID is PA-002"

# Clean up
sqlite3 "$DB" "DELETE FROM plan_analyses;"

echo ""

# ====================================================================
# TEST 22: MoSCoW + Business Value (v4.0.0)
# ====================================================================
echo "--- Test 22: MoSCoW + Business Value ---"

# 22a: moscow column exists
MOSCOW_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'moscow';")
assert_eq "$MOSCOW_COL" "1" "MoSCoW: column exists"

# 22b: business_value column exists
BV_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'business_value';")
assert_eq "$BV_COL" "1" "Business Value: column exists"

# 22c: Set moscow on tasks
sqlite3 "$DB" "
UPDATE tasks SET moscow = 'must', business_value = 5 WHERE id = '1';
UPDATE tasks SET moscow = 'must', business_value = 5 WHERE id = '1.1';
UPDATE tasks SET moscow = 'must', business_value = 4 WHERE id = '1.2';
UPDATE tasks SET moscow = 'should', business_value = 3 WHERE id = '2';
UPDATE tasks SET moscow = 'could', business_value = 2 WHERE id = '2.1';
UPDATE tasks SET moscow = 'must', business_value = 5 WHERE id = '3';
UPDATE tasks SET moscow = 'must', business_value = 5 WHERE id = '3.1';
"

# 22d: MoSCoW CHECK constraint
INVALID_MOSCOW=$(sqlite3 "$DB" "UPDATE tasks SET moscow = 'invalid' WHERE id = '1';" 2>&1 || true)
if echo "$INVALID_MOSCOW" | grep -qi "constraint\|check"; then
    pass "MoSCoW: CHECK constraint rejects invalid value"
else
    CURRENT_MOSCOW=$(sqlite3 "$DB" "SELECT moscow FROM tasks WHERE id = '1';")
    if [[ "$CURRENT_MOSCOW" == "must" ]]; then
        pass "MoSCoW: CHECK constraint rejects invalid value"
    else
        fail "MoSCoW: CHECK constraint did NOT reject invalid value"
        sqlite3 "$DB" "UPDATE tasks SET moscow = 'must' WHERE id = '1';"
    fi
fi

# 22e: Business Value CHECK constraint (range 1-5)
INVALID_BV=$(sqlite3 "$DB" "UPDATE tasks SET business_value = 6 WHERE id = '1';" 2>&1 || true)
if echo "$INVALID_BV" | grep -qi "constraint\|check"; then
    pass "Business Value: CHECK constraint rejects value > 5"
else
    CURRENT_BV=$(sqlite3 "$DB" "SELECT business_value FROM tasks WHERE id = '1';")
    if [[ "$CURRENT_BV" == "5" ]]; then
        pass "Business Value: CHECK constraint rejects value > 5"
    else
        fail "Business Value: CHECK constraint did NOT reject value > 5"
        sqlite3 "$DB" "UPDATE tasks SET business_value = 5 WHERE id = '1';"
    fi
fi

INVALID_BV_LOW=$(sqlite3 "$DB" "UPDATE tasks SET business_value = 0 WHERE id = '1';" 2>&1 || true)
if echo "$INVALID_BV_LOW" | grep -qi "constraint\|check"; then
    pass "Business Value: CHECK constraint rejects value < 1"
else
    CURRENT_BV_LOW=$(sqlite3 "$DB" "SELECT business_value FROM tasks WHERE id = '1';")
    if [[ "$CURRENT_BV_LOW" == "5" ]]; then
        pass "Business Value: CHECK constraint rejects value < 1"
    else
        fail "Business Value: CHECK constraint did NOT reject value < 1"
        sqlite3 "$DB" "UPDATE tasks SET business_value = 5 WHERE id = '1';"
    fi
fi

# 22f: MoSCoW distribution query
MOSCOW_DIST=$(sqlite3 "$DB" "
SELECT COALESCE(moscow, 'unset') as moscow, COUNT(*) as count
FROM tasks WHERE archived_at IS NULL
GROUP BY moscow
ORDER BY CASE moscow WHEN 'must' THEN 0 WHEN 'should' THEN 1 WHEN 'could' THEN 2 WHEN 'wont' THEN 3 ELSE 4 END;
")
assert_not_empty "$MOSCOW_DIST" "MoSCoW: distribution query returns data"
assert_contains "$MOSCOW_DIST" "must" "MoSCoW: distribution includes 'must'"

# 22g: Business value distribution query
BV_DIST=$(sqlite3 "$DB" "
SELECT business_value, COUNT(*) as count
FROM tasks WHERE archived_at IS NULL AND business_value IS NOT NULL
GROUP BY business_value ORDER BY business_value DESC;
")
assert_not_empty "$BV_DIST" "Business Value: distribution query returns data"

# Clean up
sqlite3 "$DB" "UPDATE tasks SET moscow = NULL, business_value = NULL;"

echo ""

# ====================================================================
# TEST 23: Acceptance Criteria (v4.0.0)
# ====================================================================
echo "--- Test 23: Acceptance Criteria ---"

# 23a: Column exists
AC_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'acceptance_criteria';")
assert_eq "$AC_COL" "1" "Acceptance Criteria: column exists"

# 23b: Default value is empty JSON array
AC_DEFAULT=$(sqlite3 "$DB" "SELECT acceptance_criteria FROM tasks WHERE id = '1';")
assert_eq "$AC_DEFAULT" "[]" "Acceptance Criteria: default is '[]'"

# 23c: Set acceptance criteria
sqlite3 "$DB" "
UPDATE tasks SET acceptance_criteria = json_array(
    'Users can log in with valid credentials',
    'Invalid credentials show error message',
    'JWT token expires after configured TTL'
) WHERE id = '1.1';
"
AC_VALUE=$(sqlite3 "$DB" "SELECT acceptance_criteria FROM tasks WHERE id = '1.1';")
assert_contains "$AC_VALUE" "JWT token expires" "Acceptance Criteria: stored correctly"

# 23d: JSON array length
AC_LENGTH=$(sqlite3 "$DB" "SELECT json_array_length(acceptance_criteria) FROM tasks WHERE id = '1.1';")
assert_eq "$AC_LENGTH" "3" "Acceptance Criteria: has 3 criteria"

# 23e: Access individual criterion
FIRST_AC=$(sqlite3 "$DB" "SELECT json_extract(acceptance_criteria, '\$[0]') FROM tasks WHERE id = '1.1';")
assert_eq "$FIRST_AC" "Users can log in with valid credentials" "Acceptance Criteria: first criterion accessible"

# 23f: Add a criterion
sqlite3 "$DB" "
UPDATE tasks SET
    acceptance_criteria = json_insert(acceptance_criteria, '\$[#]', 'Rate limiting enforced on login endpoint'),
    updated_at = datetime('now')
WHERE id = '1.1';
"
AC_LENGTH_AFTER=$(sqlite3 "$DB" "SELECT json_array_length(acceptance_criteria) FROM tasks WHERE id = '1.1';")
assert_eq "$AC_LENGTH_AFTER" "4" "Acceptance Criteria: criterion appended"

# 23g: Query tasks with acceptance criteria
TASKS_WITH_AC=$(sqlite3 "$DB" "
SELECT id, title FROM tasks
WHERE json_array_length(acceptance_criteria) > 0 AND archived_at IS NULL;
")
assert_contains "$TASKS_WITH_AC" "1.1" "Acceptance Criteria: query finds tasks with criteria"

# Clean up
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = '[]' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 24: Dependency Types (v4.0.0)
# ====================================================================
echo "--- Test 24: Dependency Types ---"

# 24a: Column exists
DT_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('tasks') WHERE name = 'dependency_types';")
assert_eq "$DT_COL" "1" "Dependency Types: column exists"

# 24b: Default value is empty JSON object
DT_DEFAULT=$(sqlite3 "$DB" "SELECT dependency_types FROM tasks WHERE id = '1';")
assert_eq "$DT_DEFAULT" "{}" "Dependency Types: default is '{}'"

# 24c: Set dependency types
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = '[\"1.1\", \"2.1\"]',
    dependency_types = json_object('1.1', 'hard', '2.1', 'soft')
WHERE id = '1.2';
"
DT_VALUE=$(sqlite3 "$DB" "SELECT dependency_types FROM tasks WHERE id = '1.2';")
assert_contains "$DT_VALUE" "hard" "Dependency Types: stored correctly"

# 24d: Access specific dependency type (use json_each for dotted keys)
DEP_TYPE_11=$(sqlite3 "$DB" "SELECT je.value FROM json_each((SELECT dependency_types FROM tasks WHERE id = '1.2')) je WHERE je.key = '1.1';")
assert_eq "$DEP_TYPE_11" "hard" "Dependency Types: 1.1 is hard"

DEP_TYPE_21=$(sqlite3 "$DB" "SELECT je.value FROM json_each((SELECT dependency_types FROM tasks WHERE id = '1.2')) je WHERE je.key = '2.1';")
assert_eq "$DEP_TYPE_21" "soft" "Dependency Types: 2.1 is soft"

# 24e: Hard dependency blocks (unmet hard dep = task not available)
# Task 1.1 is 'done', so its hard dep is met. Task 2.1 is 'planned', so soft dep is unmet but allowed.
HARD_BLOCK_QUERY=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
) as deps_met
FROM tasks t WHERE t.id = '1.2';
")
assert_eq "$HARD_BLOCK_QUERY" "1" "Dependency Types: hard deps met (1.1 is done)"

# 24f: Backward compatibility (missing type defaults to hard)
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = '[\"3.1\"]',
    dependency_types = '{}'
WHERE id = '1.2';
"
# 3.1 is 'planned' (not done), and its type defaults to 'hard', so task should be blocked
COMPAT_QUERY=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
) as deps_met
FROM tasks t WHERE t.id = '1.2';
")
assert_eq "$COMPAT_QUERY" "0" "Dependency Types: missing type defaults to hard (blocks)"

# 24g: Soft dependency does not block
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = '[\"3.1\"]',
    dependency_types = json_object('3.1', 'soft')
WHERE id = '1.2';
"
SOFT_QUERY=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
) as deps_met
FROM tasks t WHERE t.id = '1.2';
")
assert_eq "$SOFT_QUERY" "1" "Dependency Types: soft dep does not block"

# 24h: Informational dependency does not block
sqlite3 "$DB" "
UPDATE tasks SET
    dependencies = '[\"3.1\"]',
    dependency_types = json_object('3.1', 'informational')
WHERE id = '1.2';
"
INFO_QUERY=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
) as deps_met
FROM tasks t WHERE t.id = '1.2';
")
assert_eq "$INFO_QUERY" "1" "Dependency Types: informational dep does not block"

# Restore original dependencies
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.1\"]', dependency_types = '{}' WHERE id = '1.2';"

echo ""

# ====================================================================
# TEST 25: Milestone-scoped next task (v4.0.0)
# ====================================================================
echo "--- Test 25: Milestone-scoped next task ---"

# Setup: Assign milestones to specific leaf tasks
# MS-001 (active): Infrastructure tasks (critical priority)
# MS-002 (planned): Dashboard tasks (medium priority)
sqlite3 "$DB" "
UPDATE tasks SET milestone_id = 'MS-001', moscow = 'must', business_value = 5 WHERE id = '3.1';
UPDATE tasks SET milestone_id = 'MS-001', moscow = 'must', business_value = 4 WHERE id = '1.3.1';
UPDATE tasks SET milestone_id = 'MS-002', moscow = 'should', business_value = 3 WHERE id = '2.1';
UPDATE tasks SET milestone_id = 'MS-002', moscow = 'should', business_value = 5 WHERE id = '2.3';
"

# 25a: Milestone-scoped next task prefers active milestone
NEXT_MS=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
),
active_milestone AS (
    SELECT id FROM milestones WHERE status IN ('active', 'planned') ORDER BY phase_order LIMIT 1
)
SELECT t.id, t.title, t.milestone_id FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND NOT EXISTS (
      SELECT 1 FROM json_each(t.dependencies) d
      WHERE d.value NOT IN (SELECT id FROM done_ids)
        AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
  )
ORDER BY
  CASE WHEN t.milestone_id = (SELECT id FROM active_milestone) THEN 0
       WHEN t.milestone_id IS NOT NULL THEN 1
       ELSE 2 END,
  CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
  COALESCE(t.business_value, 3) DESC,
  CASE t.complexity_scale WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 2 END,
  t.id
LIMIT 1;
")
NEXT_MS_ID=$(echo "$NEXT_MS" | cut -d'|' -f1)
NEXT_MS_MILESTONE=$(echo "$NEXT_MS" | cut -d'|' -f3)
assert_eq "$NEXT_MS_MILESTONE" "MS-001" "Milestone-scoped: next task is from active milestone"
assert_eq "$NEXT_MS_ID" "3.1" "Milestone-scoped: 3.1 (MS-001, critical) preferred over 2.1 (MS-002)"

# 25b: With MS-001 leaf tasks done, falls back to MS-002
sqlite3 "$DB" "UPDATE tasks SET status = 'done' WHERE id IN ('3.1', '1.3.1');"

FALLBACK_MS=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
),
active_milestone AS (
    SELECT id FROM milestones WHERE status IN ('active', 'planned') ORDER BY phase_order LIMIT 1
)
SELECT t.id, t.milestone_id FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND NOT EXISTS (
      SELECT 1 FROM json_each(t.dependencies) d
      WHERE d.value NOT IN (SELECT id FROM done_ids)
        AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
  )
ORDER BY
  CASE WHEN t.milestone_id = (SELECT id FROM active_milestone) THEN 0
       WHEN t.milestone_id IS NOT NULL THEN 1
       ELSE 2 END,
  CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
  COALESCE(t.business_value, 3) DESC,
  CASE t.complexity_scale WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 2 END,
  t.id
LIMIT 1;
")
FALLBACK_MS_MILESTONE=$(echo "$FALLBACK_MS" | cut -d'|' -f2)
assert_eq "$FALLBACK_MS_MILESTONE" "MS-002" "Milestone-scoped: falls back to MS-002 when MS-001 tasks done"

# 25c: Business value tiebreaker within same milestone
# 2.1 (bv=3) vs 2.3 (bv=5) - both MS-002, same priority, 2.3 should win on bv
# Make 2.3's dep on 2.1 soft so it doesn't block
sqlite3 "$DB" "UPDATE tasks SET dependency_types = json_object('2.1', 'soft') WHERE id = '2.3';"

BV_TIEBREAK=$(sqlite3 "$DB" "
WITH done_ids AS (
    SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
)
SELECT t.id FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND NOT EXISTS (
      SELECT 1 FROM json_each(t.dependencies) d
      WHERE d.value NOT IN (SELECT id FROM done_ids)
        AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
  )
  AND t.milestone_id = 'MS-002'
ORDER BY
  COALESCE(t.business_value, 3) DESC,
  t.id
LIMIT 1;
")
assert_eq "$BV_TIEBREAK" "2.3" "Milestone-scoped: business_value=5 wins over business_value=3"

# Restore original statuses and values
sqlite3 "$DB" "
UPDATE tasks SET status = 'done' WHERE id = '1.1';
UPDATE tasks SET status = 'planned' WHERE id IN ('3.1', '1.3.1');
UPDATE tasks SET milestone_id = NULL, moscow = NULL, business_value = NULL, dependency_types = '{}';
"

# Clean up milestones
sqlite3 "$DB" "DELETE FROM milestones;"

echo ""

# ====================================================================
# TEST 26: Verifications CRUD (v4.1.0)
# ====================================================================
echo "--- Test 26: Verifications CRUD ---"

# 26a: Table exists
VER_TABLE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
assert_eq "$VER_TABLE" "1" "Verifications: table exists"

# 26b: Index exists
VER_IDX=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_verifications_target';")
assert_eq "$VER_IDX" "1" "Verifications: idx_verifications_target index exists"

# 26c: Generate next V- id (empty table)
NEXT_VER_ID=$(sqlite3 "$DB" "SELECT 'V-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1) FROM verifications;")
assert_eq "$NEXT_VER_ID" "V-0001" "Verifications: next ID is V-0001 (empty table)"

# 26d: Insert rows (self + adversarial methods, multiple criteria)
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, evidence, verified_by, attempt)
VALUES ('V-0001', 'task', '1.1', 'Users can log in with valid credentials', 0, 'met', 'self', 'PASS: 12 tests', 'run', 1);
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, evidence, verdict_reasoning, verified_by, attempt)
VALUES ('V-0002', 'task', '1.1', 'Users can log in with valid credentials', 0, 'failed', 'adversarial', 'login route 500s on empty body', 'No evidence the happy path was exercised', 'verifier', 1);
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, verified_by, attempt)
VALUES ('V-0003', 'task', '1.1', 'Invalid credentials show error message', 1, 'met', 'adversarial', 'verifier', 1);
"
VER_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications;")
assert_eq "$VER_COUNT" "3" "Verifications: 3 rows inserted"

# 26e: Read back a specific row
VER_METHOD=$(sqlite3 "$DB" "SELECT method FROM verifications WHERE id = 'V-0002';")
assert_eq "$VER_METHOD" "adversarial" "Verifications: can read back row by ID"

# 26f: Next V- id after inserts
NEXT_VER_AFTER=$(sqlite3 "$DB" "SELECT 'V-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1) FROM verifications;")
assert_eq "$NEXT_VER_AFTER" "V-0004" "Verifications: next ID after 3 rows is V-0004"

# 26g: CHECK constraint rejects invalid status
INVALID_VER=$(sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, status) VALUES ('V-BAD', 'task', '1.1', 'x', 'invalid');" 2>&1 || true)
BAD_VER_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-BAD';")
if echo "$INVALID_VER" | grep -qi "constraint\|check" || [[ "$BAD_VER_EXISTS" == "0" ]]; then
    pass "Verifications: CHECK constraint rejects invalid status"
else
    fail "Verifications: CHECK constraint did NOT reject invalid status"
    sqlite3 "$DB" "DELETE FROM verifications WHERE id = 'V-BAD';"
fi

# 26h: CHECK constraint rejects invalid target_type
INVALID_TT=$(sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion) VALUES ('V-BAD2', 'epic', '1.1', 'x');" 2>&1 || true)
BAD_TT_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-BAD2';")
if echo "$INVALID_TT" | grep -qi "constraint\|check" || [[ "$BAD_TT_EXISTS" == "0" ]]; then
    pass "Verifications: CHECK constraint rejects invalid target_type"
else
    fail "Verifications: CHECK constraint did NOT reject invalid target_type"
    sqlite3 "$DB" "DELETE FROM verifications WHERE id = 'V-BAD2';"
fi

# 26i: Latest-attempt-per-criterion query.
# For criterion_index 0 on task 1.1, two attempt=1 rows exist (V-0001 met, V-0002 failed).
# Latest is decided by (attempt DESC, created_at DESC, rowid DESC) -> V-0002 (inserted later) wins.
LATEST_C0=$(sqlite3 "$DB" "
SELECT v.status FROM verifications v
WHERE v.target_type = 'task' AND v.target_id = '1.1' AND v.criterion_index = 0
ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC
LIMIT 1;
")
assert_eq "$LATEST_C0" "failed" "Verifications: latest attempt for criterion 0 is 'failed' (V-0002 supersedes V-0001)"

# 26j: A later attempt (attempt=2) supersedes earlier attempts
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, verified_by, attempt)
VALUES ('V-0004', 'task', '1.1', 'Users can log in with valid credentials', 0, 'met', 'adversarial', 'verifier', 2);
"
LATEST_C0_V2=$(sqlite3 "$DB" "
SELECT v.status FROM verifications v
WHERE v.target_type = 'task' AND v.target_id = '1.1' AND v.criterion_index = 0
ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC
LIMIT 1;
")
assert_eq "$LATEST_C0_V2" "met" "Verifications: attempt=2 'met' supersedes attempt=1 'failed'"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"

echo ""

# ====================================================================
# TEST 27: v_task_verification rollup (v4.1.0)
# ====================================================================
echo "--- Test 27: v_task_verification rollup ---"

# 27a: View exists
VTV_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_task_verification';")
assert_eq "$VTV_VIEW" "1" "v_task_verification: view exists"

# Setup: give three tasks acceptance criteria.
#   1.1 -> 2 criteria, both latest 'met'                  => is_verified=1
#   1.2 -> 2 criteria, one latest 'failed'                => is_verified=0
#   1.3 -> 2 criteria, one 'met' + one pending/missing    => is_verified=0
sqlite3 "$DB" "
UPDATE tasks SET acceptance_criteria = json_array('login works', 'logout works') WHERE id = '1.1';
UPDATE tasks SET acceptance_criteria = json_array('reset email sent', 'token validated') WHERE id = '1.2';
UPDATE tasks SET acceptance_criteria = json_array('roles enforced', 'admin panel works') WHERE id = '1.3';
"

# 1.1: every criterion latest 'met'
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, attempt)
VALUES ('V-0001', 'task', '1.1', 'login works', 0, 'met', 'adversarial', 1),
       ('V-0002', 'task', '1.1', 'logout works', 1, 'met', 'adversarial', 1);
"

# 1.2: criterion 0 latest 'failed' (an earlier 'met' exists but is superseded), criterion 1 'met'
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, attempt)
VALUES ('V-0003', 'task', '1.2', 'reset email sent', 0, 'met', 'self', 1),
       ('V-0004', 'task', '1.2', 'reset email sent', 0, 'failed', 'adversarial', 1),
       ('V-0005', 'task', '1.2', 'token validated', 1, 'met', 'adversarial', 1);
"

# 1.3: criterion 0 'met', criterion 1 has NO verification row (missing => pending)
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, attempt)
VALUES ('V-0006', 'task', '1.3', 'roles enforced', 0, 'met', 'adversarial', 1);
"

# 27b: task 1.1 fully met => is_verified=1
TV_11=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, is_verified FROM v_task_verification WHERE task_id = '1.1';")
assert_eq "$TV_11" "2|2|0|0|1" "v_task_verification: 1.1 all criteria met => is_verified=1"

# 27c: task 1.2 has one latest 'failed' => is_verified=0
TV_12=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, is_verified FROM v_task_verification WHERE task_id = '1.2';")
assert_eq "$TV_12" "2|1|1|0|0" "v_task_verification: 1.2 one failed (latest) => is_verified=0"

# 27d: task 1.3 has a pending/missing criterion => is_verified=0
TV_13=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, is_verified FROM v_task_verification WHERE task_id = '1.3';")
assert_eq "$TV_13" "2|1|0|1|0" "v_task_verification: 1.3 missing criterion counts as pending => is_verified=0"

# 27e: 'overridden' counts as satisfied. Override the failing criterion on 1.2.
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-0007', 'task', '1.2', 'reset email sent', 0, 'overridden', 'self', 'Accepted as known limitation for MVP', 2);
"
TV_12_OVR=$(sqlite3 "$DB" "SELECT met, failed, is_verified FROM v_task_verification WHERE task_id = '1.2';")
assert_eq "$TV_12_OVR" "1|0|1" "v_task_verification: overridden latest row counts as satisfied => is_verified=1"

# 27f: tasks with empty acceptance_criteria ('[]') produce no rows in the view
TV_EMPTY=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_task_verification WHERE task_id = '2.1';")
assert_eq "$TV_EMPTY" "0" "v_task_verification: task with empty criteria returns no rows"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = '[]' WHERE id IN ('1.1','1.2','1.3');"

echo ""

# ====================================================================
# TEST 28: v_next_task view (v4.1.0)
# ====================================================================
echo "--- Test 28: v_next_task view ---"

# 28a: View exists
VNT_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_next_task';")
assert_eq "$VNT_VIEW" "1" "v_next_task: view exists"

# 28b: With no milestones, returns the correct next leaf task.
# 3.1 is critical priority, leaf, deps=[] -> should be first (matches Test 15 inline query).
VNT_FIRST=$(sqlite3 "$DB" "SELECT id FROM v_next_task LIMIT 1;")
assert_eq "$VNT_FIRST" "3.1" "v_next_task: recommends 3.1 (critical, leaf, no deps)"

# 28c: Blocked tasks are excluded (3.3 is 'blocked' in seed data)
VNT_NO_BLOCKED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '3.3';")
assert_eq "$VNT_NO_BLOCKED" "0" "v_next_task: blocked task 3.3 is excluded"

# 28d: Non-leaf (parent) tasks are excluded
VNT_NO_PARENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id IN ('1','2','3','1.3');")
assert_eq "$VNT_NO_PARENTS" "0" "v_next_task: non-leaf tasks excluded"

# 28e: Hard dependency on an unmet task blocks it; soft/informational do NOT block.
# 1.2 depends on 1.1 (done) -> available. Point it at an unfinished hard dep and confirm exclusion.
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"3.1\"]', dependency_types = json_object('3.1','hard') WHERE id = '1.2';"
VNT_HARD_BLOCKED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_HARD_BLOCKED" "0" "v_next_task: unmet HARD dependency excludes task 1.2"

# Soft dependency on the same unfinished task does NOT block
sqlite3 "$DB" "UPDATE tasks SET dependency_types = json_object('3.1','soft') WHERE id = '1.2';"
VNT_SOFT_OK=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_SOFT_OK" "1" "v_next_task: unmet SOFT dependency does NOT exclude task 1.2"

# Informational dependency on the same unfinished task does NOT block
sqlite3 "$DB" "UPDATE tasks SET dependency_types = json_object('3.1','informational') WHERE id = '1.2';"
VNT_INFO_OK=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_INFO_OK" "1" "v_next_task: unmet INFORMATIONAL dependency does NOT exclude task 1.2"

# Restore 1.2
sqlite3 "$DB" "UPDATE tasks SET dependencies = '[\"1.1\"]', dependency_types = '{}' WHERE id = '1.2';"

# 28f: Milestone preference + ordering.
# Set up active MS-001 and planned MS-002; verify active-milestone tasks come first,
# then ordering within is priority -> business_value -> complexity.
sqlite3 "$DB" "
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-001', 'Active phase', 1, 'active');
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-002', 'Later phase', 2, 'planned');
UPDATE tasks SET milestone_id = 'MS-002', priority = 'critical', business_value = 5, status = 'planned' WHERE id = '2.1';
UPDATE tasks SET milestone_id = 'MS-001', priority = 'medium', business_value = 1, status = 'planned', dependencies = '[]' WHERE id = '3.2';
"
# 3.2 (MS-001 active, even though only medium) must rank ahead of 2.1 (MS-002, critical)
VNT_MS_FIRST=$(sqlite3 "$DB" "SELECT id, milestone_id FROM v_next_task LIMIT 1;")
assert_eq "$VNT_MS_FIRST" "3.2|MS-001" "v_next_task: active-milestone task preferred over higher-priority non-active-milestone task"

# 28g: Ordering within active milestone: priority then business_value then complexity.
# Add two more MS-001 leaf tasks with same priority, differing business_value.
sqlite3 "$DB" "
INSERT INTO tasks (id, parent_id, title, status, type, priority, complexity_scale, milestone_id, business_value, dependencies)
VALUES ('4', NULL, 'MS-001 high A', 'planned', 'feature', 'high', 'S', 'MS-001', 2, '[]'),
       ('5', NULL, 'MS-001 high B', 'planned', 'feature', 'high', 'S', 'MS-001', 4, '[]');
"
# Among MS-001 high-priority leaves, business_value=4 (id 5) beats business_value=2 (id 4)
VNT_BV_ORDER=$(sqlite3 "$DB" "SELECT id FROM v_next_task WHERE milestone_id = 'MS-001' AND priority = 'high' LIMIT 1;")
assert_eq "$VNT_BV_ORDER" "5" "v_next_task: within milestone+priority, higher business_value ranks first"

# 28h: complexity tiebreaker (same priority + business_value -> lower complexity first)
sqlite3 "$DB" "
INSERT INTO tasks (id, parent_id, title, status, type, priority, complexity_scale, milestone_id, business_value, dependencies)
VALUES ('6', NULL, 'MS-001 low XS', 'planned', 'feature', 'low', 'XS', 'MS-001', 3, '[]'),
       ('7', NULL, 'MS-001 low L', 'planned', 'feature', 'low', 'L', 'MS-001', 3, '[]');
"
VNT_CX_ORDER=$(sqlite3 "$DB" "SELECT id FROM v_next_task WHERE milestone_id = 'MS-001' AND priority = 'low' LIMIT 1;")
assert_eq "$VNT_CX_ORDER" "6" "v_next_task: within milestone+priority+business_value, lower complexity (XS) ranks first"

# Restore: remove the synthetic tasks and milestone assignments,
# returning 2.1 and 3.2 to the state they had on entry to this test
# (3.2 was 'blocked' from Test 19's leftover; 2.1 was 'planned').
sqlite3 "$DB" "
DELETE FROM tasks WHERE id IN ('4','5','6','7');
UPDATE tasks SET milestone_id = NULL, business_value = NULL WHERE id IN ('2.1','3.2');
UPDATE tasks SET priority = 'medium', status = 'planned' WHERE id = '2.1';
UPDATE tasks SET priority = 'high', status = 'blocked' WHERE id = '3.2';
UPDATE tasks SET dependencies = '[\"3.1\"]' WHERE id = '3.2';
DELETE FROM milestones;
"

echo ""

# ====================================================================
# TEST 29: v_milestone_status view (v4.1.0)
# ====================================================================
echo "--- Test 29: v_milestone_status view ---"

# 29a: View exists
VMS_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_milestone_status';")
assert_eq "$VMS_VIEW" "1" "v_milestone_status: view exists"

# Setup milestones and scope tasks to them.
sqlite3 "$DB" "
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-001', 'Active', 1, 'planned');
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-002', 'Completed', 2, 'planned');
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-003', 'Planned', 3, 'planned');
"

# MS-001: at least one in-progress scoped task => derived 'active'
sqlite3 "$DB" "UPDATE tasks SET milestone_id = 'MS-001' WHERE id IN ('1.2','1.3.1');"
sqlite3 "$DB" "UPDATE tasks SET status = 'in-progress' WHERE id = '1.2';"

# MS-002: all scoped tasks terminal (done/canceled/duplicate) => derived 'completed'
sqlite3 "$DB" "UPDATE tasks SET milestone_id = 'MS-002' WHERE id IN ('2.1','2.2');"
sqlite3 "$DB" "UPDATE tasks SET status = 'done' WHERE id = '2.1';"
sqlite3 "$DB" "UPDATE tasks SET status = 'canceled' WHERE id = '2.2';"

# MS-003: scoped tasks present but not all terminal, none in-progress => derived 'planned'
sqlite3 "$DB" "UPDATE tasks SET milestone_id = 'MS-003' WHERE id IN ('3.2');"
sqlite3 "$DB" "UPDATE tasks SET status = 'planned' WHERE id = '3.2';"

# 29b: MS-001 derives 'active'
VMS_001=$(sqlite3 "$DB" "SELECT derived_status FROM v_milestone_status WHERE milestone_id = 'MS-001';")
assert_eq "$VMS_001" "active" "v_milestone_status: in-progress scoped task => derived 'active'"

# 29c: MS-002 derives 'completed'
VMS_002=$(sqlite3 "$DB" "SELECT derived_status, total_tasks, terminal_tasks FROM v_milestone_status WHERE milestone_id = 'MS-002';")
assert_eq "$VMS_002" "completed|2|2" "v_milestone_status: all scoped tasks terminal => derived 'completed'"

# 29d: MS-003 derives 'planned'
VMS_003=$(sqlite3 "$DB" "SELECT derived_status FROM v_milestone_status WHERE milestone_id = 'MS-003';")
assert_eq "$VMS_003" "planned" "v_milestone_status: scoped tasks present but not terminal => derived 'planned'"

# 29e: A milestone with no scoped tasks derives 'planned' (not 'completed')
sqlite3 "$DB" "INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-004', 'Empty', 4, 'planned');"
VMS_004=$(sqlite3 "$DB" "SELECT derived_status, total_tasks FROM v_milestone_status WHERE milestone_id = 'MS-004';")
assert_eq "$VMS_004" "planned|0" "v_milestone_status: milestone with no tasks => derived 'planned'"

# 29f: stored_status is surfaced independently of derived_status
VMS_STORED=$(sqlite3 "$DB" "SELECT stored_status FROM v_milestone_status WHERE milestone_id = 'MS-002';")
assert_eq "$VMS_STORED" "planned" "v_milestone_status: stored_status reflects milestones.status (not derived)"

# Restore: undo task scoping and statuses, drop milestones.
# 1.2/2.1/2.2 seed status is 'planned'; 3.2 was 'blocked' on entry (Test 19 leftover); 3.3 is 'blocked'.
sqlite3 "$DB" "
UPDATE tasks SET milestone_id = NULL WHERE milestone_id IN ('MS-001','MS-002','MS-003','MS-004');
UPDATE tasks SET status = 'planned' WHERE id IN ('1.2','2.1','2.2');
UPDATE tasks SET status = 'blocked' WHERE id IN ('3.2','3.3');
DELETE FROM milestones;
"

echo ""

# ====================================================================
# TEST 30: migrate-v4.0-to-v4.1.sh (v4.1.0)
# ====================================================================
echo "--- Test 30: migrate-v4.0-to-v4.1.sh ---"

MIGRATE_SCRIPT="$PLUGIN_DIR/schemas/migrate-v4.0-to-v4.1.sh"

# 30a: Migration script exists and is executable
if [[ -f "$MIGRATE_SCRIPT" ]]; then
    pass "Migration: migrate-v4.0-to-v4.1.sh exists"
else
    fail "Migration: migrate-v4.0-to-v4.1.sh does not exist"
fi

# Build a fresh v4.0.0 database: apply schema.sql but strip the v4.1.0 objects
# (verifications table + index, the three views) and force the version to 4.0.0.
# This faithfully reconstructs a pre-migration v4.0.0 DB from the single-source schema.
MIG_DIR="$WORK_DIR/.taskmanager-mig"
mkdir -p "$MIG_DIR/logs"
cp "$CONFIG_SRC" "$MIG_DIR/config.json"
touch "$MIG_DIR/logs/activity.log"
MIG_DB="$MIG_DIR/taskmanager.db"

# Derive a v4.0.0 schema from schema.sql:
#  - drop the verifications CREATE TABLE block and its index
#  - drop the three CREATE VIEW blocks
#  - replace the 4.1.0 version literal with 4.0.0
python3 - "$SCHEMA_FILE" "$MIG_DIR/schema-v4.0.sql" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
sql = open(src).read()

# Remove the verifications table + its index (from the CREATE TABLE up to the index line).
sql = re.sub(
    r"-- Verifications table.*?CREATE INDEX IF NOT EXISTS idx_verifications_target ON verifications\(target_type, target_id, status\);\n",
    "",
    sql, flags=re.DOTALL,
)

# Remove each CREATE VIEW ... ; block (views are terminated by the first ';' that ends the statement).
for view in ("v_next_task", "v_task_verification", "v_milestone_status"):
    sql = re.sub(
        r"CREATE VIEW IF NOT EXISTS " + re.escape(view) + r" AS.*?;\n",
        "",
        sql, flags=re.DOTALL,
    )

# Force version literal back to 4.0.0 (schema.sql now ships 4.2.0)
sql = sql.replace("VALUES ('4.2.0')", "VALUES ('4.0.0')")

open(dst, "w").write(sql)
PY

sqlite3 "$MIG_DB" < "$MIG_DIR/schema-v4.0.sql" >/dev/null

# 30b: Pre-migration sanity: it's a v4.0.0 DB without the v4.1.0 objects
PRE_VERSION=$(sqlite3 "$MIG_DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
assert_eq "$PRE_VERSION" "4.0.0" "Migration: pre-migration DB is at v4.0.0"

PRE_VER_TABLE=$(sqlite3 "$MIG_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
assert_eq "$PRE_VER_TABLE" "0" "Migration: pre-migration DB has no verifications table"

PRE_VIEWS=$(sqlite3 "$MIG_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name IN ('v_next_task','v_task_verification','v_milestone_status');")
assert_eq "$PRE_VIEWS" "0" "Migration: pre-migration DB has none of the 3 views"

# 30c: Run the migration script against the v4.0.0 DB
MIG_OUTPUT=$(bash "$MIGRATE_SCRIPT" "$MIG_DIR" 2>&1) && MIG_RC=0 || MIG_RC=$?
if [[ "$MIG_RC" -eq 0 ]]; then
    pass "Migration: script ran successfully (exit 0)"
else
    fail "Migration: script failed (exit $MIG_RC): $MIG_OUTPUT"
fi

# 30d: schema_version bumped to 4.1.0
POST_VERSION=$(sqlite3 "$MIG_DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
assert_eq "$POST_VERSION" "4.1.0" "Migration: schema_version is 4.1.0 after migration"

# 30e: verifications table now exists
POST_VER_TABLE=$(sqlite3 "$MIG_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
assert_eq "$POST_VER_TABLE" "1" "Migration: verifications table exists after migration"

# 30f: idx_verifications_target index now exists
POST_VER_IDX=$(sqlite3 "$MIG_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_verifications_target';")
assert_eq "$POST_VER_IDX" "1" "Migration: idx_verifications_target index exists after migration"

# 30g: all three views now exist
POST_VIEWS=$(sqlite3 "$MIG_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name IN ('v_next_task','v_task_verification','v_milestone_status');")
assert_eq "$POST_VIEWS" "3" "Migration: all 3 views exist after migration"

# 30h: migrated views are functional (query them without error)
MIG_VNT=$(sqlite3 "$MIG_DB" "INSERT INTO tasks (id, title, status, priority) VALUES ('m1','migrated leaf','planned','critical'); SELECT id FROM v_next_task LIMIT 1;")
assert_eq "$MIG_VNT" "m1" "Migration: v_next_task is queryable and returns the seeded leaf task"

# 30i: migration is idempotent (re-running on a 4.1.0 DB is a no-op success)
MIG_RERUN=$(bash "$MIGRATE_SCRIPT" "$MIG_DIR" 2>&1) && MIG_RERUN_RC=0 || MIG_RERUN_RC=$?
if [[ "$MIG_RERUN_RC" -eq 0 ]] && echo "$MIG_RERUN" | grep -qi "already at v4.1.0"; then
    pass "Migration: idempotent re-run is a no-op success"
else
    fail "Migration: re-run was not a clean no-op (rc=$MIG_RERUN_RC): $MIG_RERUN"
fi

echo ""

# ====================================================================
# TEST 31: v_next_task excludes non-actionable leaf statuses (#17)
# ====================================================================
echo "--- Test 31: v_next_task excludes needs-review/paused/draft ---"

# Seed three actionable leaf tasks with NO milestone, NO deps, distinct ids
# under a non-existent priority floor so they don't disturb other expectations.
# We toggle a single leaf task (1.2) through each excluded status and assert it
# is never returned by v_next_task, while remaining returnable when 'planned'.

# Baseline: 1.2 is 'planned', leaf, dep on 1.1 (done) -> SHOULD be in v_next_task.
sqlite3 "$DB" "UPDATE tasks SET status = 'planned', dependencies = '[\"1.1\"]', dependency_types = '{}', milestone_id = NULL WHERE id = '1.2';"
VNT_PLANNED_IN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_PLANNED_IN" "1" "v_next_task: planned leaf 1.2 is returned (baseline)"

# needs-review leaf must NOT be returned
sqlite3 "$DB" "UPDATE tasks SET status = 'needs-review' WHERE id = '1.2';"
VNT_NR=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_NR" "0" "v_next_task: needs-review leaf 1.2 is NOT returned (#17)"

# paused leaf must NOT be returned
sqlite3 "$DB" "UPDATE tasks SET status = 'paused' WHERE id = '1.2';"
VNT_PAUSED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_PAUSED" "0" "v_next_task: paused leaf 1.2 is NOT returned (#17)"

# draft leaf must NOT be returned
sqlite3 "$DB" "UPDATE tasks SET status = 'draft' WHERE id = '1.2';"
VNT_DRAFT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id = '1.2';")
assert_eq "$VNT_DRAFT" "0" "v_next_task: draft leaf 1.2 is NOT returned (#17)"

# Restore 1.2 to seed state
sqlite3 "$DB" "UPDATE tasks SET status = 'planned' WHERE id = '1.2';"

echo ""

# ====================================================================
# TEST 32: v_next_task_sequential only active-milestone tasks (#6)
# ====================================================================
echo "--- Test 32: v_next_task_sequential active-milestone gating ---"

# 32a: View exists
VNTS_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_next_task_sequential';")
assert_eq "$VNTS_VIEW" "1" "v_next_task_sequential: view exists"

# Setup: active MS-001 (phase 1) and planned MS-002 (phase 2).
# Put a ready leaf in the active milestone and a ready leaf in the non-active one.
sqlite3 "$DB" "
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-001', 'Active phase', 1, 'active');
INSERT INTO milestones (id, title, phase_order, status) VALUES ('MS-002', 'Later phase', 2, 'planned');
UPDATE tasks SET milestone_id = 'MS-001', status = 'planned', dependencies = '[]', dependency_types = '{}' WHERE id = '3.2';
UPDATE tasks SET milestone_id = 'MS-002', status = 'planned', dependencies = '[]', dependency_types = '{}' WHERE id = '2.1';
"

# 32b: The active-milestone ready task IS returned by the sequential view
SEQ_ACTIVE_IN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task_sequential WHERE id = '3.2';")
assert_eq "$SEQ_ACTIVE_IN" "1" "v_next_task_sequential: active-milestone ready task 3.2 is returned"

# 32c: A ready task in a NON-active milestone is EXCLUDED (#6)
SEQ_NONACTIVE_OUT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task_sequential WHERE id = '2.1';")
assert_eq "$SEQ_NONACTIVE_OUT" "0" "v_next_task_sequential: non-active-milestone ready task 2.1 is excluded (#6)"

# 32d: Every row returned by the sequential view belongs to the active milestone
SEQ_ALL_ACTIVE=$(sqlite3 "$DB" "
SELECT COUNT(*) FROM v_next_task_sequential
WHERE milestone_id IS NOT (SELECT id FROM milestones WHERE status IN ('active','planned') ORDER BY phase_order LIMIT 1);
")
assert_eq "$SEQ_ALL_ACTIVE" "0" "v_next_task_sequential: all returned rows belong to the active milestone"

# Restore (also leaves zero milestones, setting up the empty-milestone fallback check)
sqlite3 "$DB" "
UPDATE tasks SET milestone_id = NULL WHERE id IN ('3.2','2.1');
UPDATE tasks SET status = 'blocked', dependencies = '[\"3.1\"]' WHERE id = '3.2';
UPDATE tasks SET status = 'planned' WHERE id = '2.1';
DELETE FROM milestones;
"

# 32e: empty-milestone fallback (fixes the silent-stall edge case) — with NO milestones,
# sequential mode must NOT stall; it falls back to the same candidate set as flexible.
SEQ_CNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task_sequential;")
FLEX_CNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task;")
assert_eq "$SEQ_CNT" "$FLEX_CNT" "v_next_task_sequential: with no milestones, candidate set equals v_next_task (no stall)"
SEQ_TOP=$(sqlite3 "$DB" "SELECT COALESCE((SELECT id FROM v_next_task_sequential LIMIT 1),'<none>');")
FLEX_TOP=$(sqlite3 "$DB" "SELECT COALESCE((SELECT id FROM v_next_task LIMIT 1),'<none>');")
assert_eq "$SEQ_TOP" "$FLEX_TOP" "v_next_task_sequential: with no milestones, top pick matches v_next_task (flexible)"

echo ""

# ====================================================================
# TEST 33: verifications override_reason CHECK constraint (#3)
# ====================================================================
echo "--- Test 33: verifications override_reason CHECK ---"

# 33a: 'overridden' row with NULL override_reason is REJECTED
OVR_NULL=$(sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method) VALUES ('V-CHK1', 'task', '1.1', 'x', 0, 'overridden', 'self');" 2>&1 || true)
OVR_NULL_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-CHK1';")
if echo "$OVR_NULL" | grep -qi "constraint\|check" || [[ "$OVR_NULL_EXISTS" == "0" ]]; then
    pass "Verifications: overridden row with NULL override_reason is rejected (#3)"
else
    fail "Verifications: overridden row with NULL override_reason was NOT rejected (#3)"
    sqlite3 "$DB" "DELETE FROM verifications WHERE id = 'V-CHK1';"
fi

# 33b: non-'overridden' row with a non-NULL override_reason is REJECTED
NONOVR_REASON=$(sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason) VALUES ('V-CHK2', 'task', '1.1', 'x', 0, 'met', 'self', 'should not be here');" 2>&1 || true)
NONOVR_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-CHK2';")
if echo "$NONOVR_REASON" | grep -qi "constraint\|check" || [[ "$NONOVR_EXISTS" == "0" ]]; then
    pass "Verifications: non-overridden row with non-NULL override_reason is rejected (#3)"
else
    fail "Verifications: non-overridden row with non-NULL override_reason was NOT rejected (#3)"
    sqlite3 "$DB" "DELETE FROM verifications WHERE id = 'V-CHK2';"
fi

# 33c: valid override row (overridden + non-NULL reason) SUCCEEDS
sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason) VALUES ('V-CHK3', 'task', '1.1', 'x', 0, 'overridden', 'self', 'Accepted limitation');"
VALID_OVR=$(sqlite3 "$DB" "SELECT override_reason FROM verifications WHERE id = 'V-CHK3';")
assert_eq "$VALID_OVR" "Accepted limitation" "Verifications: valid override row (overridden + reason) succeeds (#3)"

# 33d: valid non-overridden row with NULL reason also succeeds (control)
sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method) VALUES ('V-CHK4', 'task', '1.1', 'x', 0, 'met', 'self');"
VALID_NONOVR=$(sqlite3 "$DB" "SELECT status FROM verifications WHERE id = 'V-CHK4';")
assert_eq "$VALID_NONOVR" "met" "Verifications: non-overridden row with NULL reason succeeds (control)"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"

echo ""

# ====================================================================
# TEST 34: verifications.method CHECK + NULL self row in rollup (#24)
# ====================================================================
echo "--- Test 34: verifications.method CHECK + NULL self row ---"

# 34a: method CHECK rejects an invalid method
INVALID_METHOD=$(sqlite3 "$DB" "INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method) VALUES ('V-M1', 'task', '1.1', 'x', 0, 'met', 'manual');" 2>&1 || true)
INVALID_METHOD_EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-M1';")
if echo "$INVALID_METHOD" | grep -qi "constraint\|check" || [[ "$INVALID_METHOD_EXISTS" == "0" ]]; then
    pass "Verifications: method CHECK rejects invalid method 'manual' (#24)"
else
    fail "Verifications: method CHECK did NOT reject invalid method (#24)"
    sqlite3 "$DB" "DELETE FROM verifications WHERE id = 'V-M1';"
fi

# 34b: A self row at criterion_index=NULL coexists with adversarial rows.
# The NULL self row must contribute NOTHING (it joins no enumerated criterion,
# because v.criterion_index = c.criterion_index is never true for NULL), and the
# adversarial verdict at the real index governs is_verified.
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = json_array('login works') WHERE id = '1.1';"

# self row with NULL criterion_index claiming 'met' (a global self-attestation),
# plus the per-criterion adversarial verdict 'failed' at index 0.
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-S1', 'task', '1.1', 'overall self-check', NULL, 'met', 'self', NULL, 1);
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-A1', 'task', '1.1', 'login works', 0, 'failed', 'adversarial', NULL, 1);
"

# The view enumerates exactly the 1 criterion; the NULL self row is invisible to it.
TV_NULLSELF=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, is_verified FROM v_task_verification WHERE task_id = '1.1';")
assert_eq "$TV_NULLSELF" "1|0|1|0|0" "v_task_verification: NULL self row ignored; adversarial 'failed' governs => is_verified=0 (#24)"

# Flip the adversarial verdict to 'met'; NULL self row still contributes nothing,
# and now the single enumerated criterion is met => is_verified=1.
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-A2', 'task', '1.1', 'login works', 0, 'met', 'adversarial', NULL, 2);
"
TV_NULLSELF2=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, is_verified FROM v_task_verification WHERE task_id = '1.1';")
assert_eq "$TV_NULLSELF2" "1|1|0|0|1" "v_task_verification: NULL self row still ignored; adversarial 'met' governs => is_verified=1 (#24)"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = '[]' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 35: v_task_verification overridden column accounting (#21)
# ====================================================================
echo "--- Test 35: v_task_verification overridden column ---"

# 35a: the view exposes an 'overridden' column
HAS_OVR_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('v_task_verification') WHERE name = 'overridden';")
assert_eq "$HAS_OVR_COL" "1" "v_task_verification: has an 'overridden' column (#21)"

# Setup: 1.1 gets 4 criteria, one in each of met / failed / pending(missing) / overridden.
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = json_array('c0 met', 'c1 failed', 'c2 pending', 'c3 overridden') WHERE id = '1.1';"
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-0001', 'task', '1.1', 'c0 met', 0, 'met', 'adversarial', NULL, 1),
       ('V-0002', 'task', '1.1', 'c1 failed', 1, 'failed', 'adversarial', NULL, 1),
       ('V-0003', 'task', '1.1', 'c3 overridden', 3, 'overridden', 'self', 'Accepted for MVP', 1);
"
# (criterion 2 intentionally has no verification row -> pending)

# 35b: each bucket has exactly one criterion, totals reconcile
TV_BUCKETS=$(sqlite3 "$DB" "SELECT total_criteria, met, failed, pending, overridden FROM v_task_verification WHERE task_id = '1.1';")
assert_eq "$TV_BUCKETS" "4|1|1|1|1" "v_task_verification: met/failed/pending/overridden each = 1 (#21)"

# 35c: met + failed + pending + overridden == total_criteria
TV_SUM_CHECK=$(sqlite3 "$DB" "
SELECT CASE WHEN (met + failed + pending + overridden) = total_criteria THEN 'ok' ELSE 'mismatch' END
FROM v_task_verification WHERE task_id = '1.1';
")
assert_eq "$TV_SUM_CHECK" "ok" "v_task_verification: met+failed+pending+overridden = total_criteria (#21)"

# 35d: overridden counts toward is_verified satisfaction (but here a failed+pending remain => 0)
TV_IV=$(sqlite3 "$DB" "SELECT is_verified FROM v_task_verification WHERE task_id = '1.1';")
assert_eq "$TV_IV" "0" "v_task_verification: failed+pending remain => is_verified=0 even with an override (#21)"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"
sqlite3 "$DB" "UPDATE tasks SET acceptance_criteria = '[]' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 36: v_milestone_verification + v_prd_verification rollups (#4, #20)
# ====================================================================
echo "--- Test 36: milestone + PRD verification rollups ---"

# 36a: both views exist
VMV_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_milestone_verification';")
assert_eq "$VMV_VIEW" "1" "v_milestone_verification: view exists (#4)"
VPV_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_prd_verification';")
assert_eq "$VPV_VIEW" "1" "v_prd_verification: view exists (#20)"

# Setup milestones with acceptance_criteria:
#   MS-A: 2 criteria, both satisfied (met + overridden) => is_verified=1
#   MS-B: 2 criteria, one failed                        => is_verified=0
#   MS-C: 2 criteria, one pending (missing row)         => is_verified=0
#   MS-D: empty criteria                                => no/zero row
sqlite3 "$DB" "
INSERT INTO milestones (id, title, phase_order, status, acceptance_criteria)
VALUES ('MS-A', 'All satisfied', 1, 'planned', json_array('a0','a1')),
       ('MS-B', 'One failed',    2, 'planned', json_array('b0','b1')),
       ('MS-C', 'One pending',   3, 'planned', json_array('c0','c1')),
       ('MS-D', 'Empty',         4, 'planned', '[]');
"
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-0001', 'milestone', 'MS-A', 'a0', 0, 'met',        'adversarial', NULL, 1),
       ('V-0002', 'milestone', 'MS-A', 'a1', 1, 'overridden', 'self', 'Accepted', 1),
       ('V-0003', 'milestone', 'MS-B', 'b0', 0, 'met',        'adversarial', NULL, 1),
       ('V-0004', 'milestone', 'MS-B', 'b1', 1, 'failed',     'adversarial', NULL, 1),
       ('V-0005', 'milestone', 'MS-C', 'c0', 0, 'met',        'adversarial', NULL, 1);
"

# 36b: MS-A all satisfied => is_verified=1
MV_A=$(sqlite3 "$DB" "SELECT total_criteria, satisfied, is_verified FROM v_milestone_verification WHERE milestone_id = 'MS-A';")
assert_eq "$MV_A" "2|2|1" "v_milestone_verification: all satisfied => is_verified=1 (#4)"

# 36c: MS-B one failed => is_verified=0
MV_B=$(sqlite3 "$DB" "SELECT total_criteria, satisfied, is_verified FROM v_milestone_verification WHERE milestone_id = 'MS-B';")
assert_eq "$MV_B" "2|1|0" "v_milestone_verification: one failed => is_verified=0 (#4)"

# 36d: MS-C one pending (missing) => is_verified=0
MV_C=$(sqlite3 "$DB" "SELECT total_criteria, satisfied, is_verified FROM v_milestone_verification WHERE milestone_id = 'MS-C';")
assert_eq "$MV_C" "2|1|0" "v_milestone_verification: one pending => is_verified=0 (#4)"

# 36e: MS-D empty criteria => no row in the view
MV_D=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_milestone_verification WHERE milestone_id = 'MS-D';")
assert_eq "$MV_D" "0" "v_milestone_verification: empty criteria => no row (#4)"

# Now the PRD-level rollup over plan_analyses.acceptance_criteria:
#   PA-A: all satisfied => 1 ; PA-B: one pending => 0 ; PA-C: empty => no row
sqlite3 "$DB" "
INSERT INTO plan_analyses (id, prd_source, acceptance_criteria)
VALUES ('PA-A', 'prd-a.md', json_array('p0','p1')),
       ('PA-B', 'prd-b.md', json_array('q0','q1')),
       ('PA-C', 'prd-c.md', '[]');
"
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, override_reason, attempt)
VALUES ('V-0006', 'prd', 'PA-A', 'p0', 0, 'met',        'adversarial', NULL, 1),
       ('V-0007', 'prd', 'PA-A', 'p1', 1, 'overridden', 'self', 'Accepted', 1),
       ('V-0008', 'prd', 'PA-B', 'q0', 0, 'met',        'adversarial', NULL, 1);
"
# 36f: PA-A all satisfied => is_verified=1
PV_A=$(sqlite3 "$DB" "SELECT total_criteria, satisfied, is_verified FROM v_prd_verification WHERE prd_id = 'PA-A';")
assert_eq "$PV_A" "2|2|1" "v_prd_verification: all satisfied => is_verified=1 (#20)"

# 36g: PA-B one pending => is_verified=0
PV_B=$(sqlite3 "$DB" "SELECT total_criteria, satisfied, is_verified FROM v_prd_verification WHERE prd_id = 'PA-B';")
assert_eq "$PV_B" "2|1|0" "v_prd_verification: one pending => is_verified=0 (#20)"

# 36h: PA-C empty criteria => no row
PV_C=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_prd_verification WHERE prd_id = 'PA-C';")
assert_eq "$PV_C" "0" "v_prd_verification: empty criteria => no row (#20)"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"
sqlite3 "$DB" "DELETE FROM plan_analyses;"
sqlite3 "$DB" "DELETE FROM milestones;"

echo ""

# ====================================================================
# TEST 37: verify --batch pending-verification selector (#22)
# ====================================================================
echo "--- Test 37: verify --batch pending-verification selector ---"

# The batch selector finds leaf tasks that have acceptance_criteria, are not yet
# verified (is_verified = 0 via v_task_verification), match a status filter
# (e.g. needs-review / in-progress), ordered deterministically by id.
#
# Setup:
#   1.2 -> leaf, needs-review, has criteria, NOT verified  => SHOULD be selected
#   1.1 -> leaf, needs-review, has criteria, fully verified => excluded (is_verified=1)
#   2.1 -> leaf, planned (wrong status), has criteria, not verified => excluded by status filter
#   1.3 -> parent (non-leaf), needs-review, has criteria => excluded (not a leaf)
sqlite3 "$DB" "
UPDATE tasks SET status = 'needs-review', acceptance_criteria = json_array('x0','x1') WHERE id = '1.2';
UPDATE tasks SET status = 'needs-review', acceptance_criteria = json_array('y0') WHERE id = '1.1';
UPDATE tasks SET status = 'planned', acceptance_criteria = json_array('z0') WHERE id = '2.1';
UPDATE tasks SET status = 'needs-review', acceptance_criteria = json_array('w0') WHERE id = '1.3';
"
# Make 1.1 fully verified
sqlite3 "$DB" "
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method, attempt)
VALUES ('V-0001', 'task', '1.1', 'y0', 0, 'met', 'adversarial', 1);
"

BATCH_SELECT=$(sqlite3 "$DB" "
SELECT t.id
FROM tasks t
LEFT JOIN v_task_verification vt ON vt.task_id = t.id
WHERE t.archived_at IS NULL
  AND t.status = 'needs-review'
  AND json_array_length(t.acceptance_criteria) > 0
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND COALESCE(vt.is_verified, 0) = 0
ORDER BY t.id;
")
assert_eq "$BATCH_SELECT" "1.2" "verify --batch: selects the unverified needs-review leaf 1.2 (#22)"

# 37b: with two eligible tasks, ordering by id is deterministic.
# Add 1.2.1 as a needs-review leaf with unverified criteria (and 1.2 is now a parent).
sqlite3 "$DB" "
INSERT INTO tasks (id, parent_id, title, status, type, priority, acceptance_criteria)
VALUES ('1.2.1', '1.2', 'sub of 1.2', 'needs-review', 'feature', 'medium', json_array('s0'));
"
BATCH_SELECT2=$(sqlite3 "$DB" "
SELECT group_concat(t.id, ',') FROM (
  SELECT t.id
  FROM tasks t
  LEFT JOIN v_task_verification vt ON vt.task_id = t.id
  WHERE t.archived_at IS NULL
    AND t.status = 'needs-review'
    AND json_array_length(t.acceptance_criteria) > 0
    AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
    AND COALESCE(vt.is_verified, 0) = 0
  ORDER BY t.id
) t;
")
# 1.2 is now a parent (has child 1.2.1) so it drops out; 1.2.1 is the leaf that remains.
assert_eq "$BATCH_SELECT2" "1.2.1" "verify --batch: parent drops out, leaf child 1.2.1 selected, ordered by id (#22)"

# Clean up
sqlite3 "$DB" "DELETE FROM verifications;"
sqlite3 "$DB" "DELETE FROM tasks WHERE id = '1.2.1';"
sqlite3 "$DB" "UPDATE tasks SET status = 'planned', acceptance_criteria = '[]' WHERE id IN ('1.2','1.3','2.1');"
sqlite3 "$DB" "UPDATE tasks SET status = 'done', acceptance_criteria = '[]' WHERE id = '1.1';"

echo ""

# ====================================================================
# TEST 38: FTS UPDATE trigger memories_au (#23)
# ====================================================================
echo "--- Test 38: memories_au FTS UPDATE trigger ---"

# Insert a memory with a unique OLD keyword in body and tags.
sqlite3 "$DB" "
INSERT INTO memories (id, title, kind, why_important, body, source_type, importance, confidence, status, scope, tags, links)
VALUES ('M-8888', 'FTS update trigger test', 'convention', 'Testing memories_au', 'Body has unique keyword alphazzz111', 'user', 1, 0.5, 'active', '{}', '[\"alphazzz111\"]', '[]');
"
# OLD keyword matches before update
FTS_OLD_BEFORE=$(sqlite3 "$DB" "
SELECT m.id FROM memories m JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'alphazzz111';
")
assert_contains "$FTS_OLD_BEFORE" "M-8888" "memories_au: OLD keyword matches before UPDATE (#23)"

# UPDATE body + tags to a NEW unique keyword.
sqlite3 "$DB" "
UPDATE memories SET
  body = 'Body now has unique keyword betazzz222',
  tags = '[\"betazzz222\"]',
  updated_at = datetime('now')
WHERE id = 'M-8888';
"

# After UPDATE: OLD keyword must NO LONGER match (trigger deleted the stale FTS row)
FTS_OLD_AFTER=$(sqlite3 "$DB" "
SELECT COUNT(*) FROM memories m JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'alphazzz111';
")
assert_eq "$FTS_OLD_AFTER" "0" "memories_au: OLD keyword no longer matches after UPDATE (#23)"

# After UPDATE: NEW keyword matches (trigger re-inserted the fresh FTS row)
FTS_NEW_AFTER=$(sqlite3 "$DB" "
SELECT m.id FROM memories m JOIN memories_fts fts ON m.rowid = fts.rowid
WHERE memories_fts MATCH 'betazzz222';
")
assert_contains "$FTS_NEW_AFTER" "M-8888" "memories_au: NEW keyword matches after UPDATE (#23)"

# Clean up
sqlite3 "$DB" "DELETE FROM memories WHERE id = 'M-8888';"

echo ""

# ====================================================================
# TEST 39: migration upgrades to FULL v4.1 end state (#4/#20/#21 wiring)
# ====================================================================
echo "--- Test 39: migration reaches full v4.1 end state ---"

# The existing Test 30 reconstructs a v4.0.0 DB by stripping only SOME v4.1
# objects. Here we build a STRICTER v4.0.0 baseline that also lacks the newer
# v4.1 objects (v_next_task_sequential, v_milestone_verification,
# v_prd_verification, plan_analyses.acceptance_criteria, and the verifications
# override CHECK) and assert the migration produces the COMPLETE v4.1 end state.

MIG2_DIR="$WORK_DIR/.taskmanager-mig2"
mkdir -p "$MIG2_DIR/logs"
cp "$CONFIG_SRC" "$MIG2_DIR/config.json"
touch "$MIG2_DIR/logs/activity.log"
MIG2_DB="$MIG2_DIR/taskmanager.db"

# Derive a strict v4.0.0 schema from schema.sql:
#  - drop the verifications table + index
#  - drop ALL six v4.1 views
#  - drop the plan_analyses.acceptance_criteria column line
#  - force the version literal to 4.0.0
python3 - "$SCHEMA_FILE" "$MIG2_DIR/schema-v4.0.sql" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
sql = open(src).read()

# Remove the verifications table + its index block.
sql = re.sub(
    r"-- Verifications table.*?CREATE INDEX IF NOT EXISTS idx_verifications_target ON verifications\(target_type, target_id, status\);\n",
    "",
    sql, flags=re.DOTALL,
)

# Remove every v4.1 view (terminated by the first ';' ending the CREATE VIEW statement).
for view in ("v_next_task_sequential", "v_next_task", "v_task_verification",
             "v_milestone_verification", "v_prd_verification", "v_milestone_status"):
    sql = re.sub(
        r"CREATE VIEW IF NOT EXISTS " + re.escape(view) + r" AS.*?;\n",
        "",
        sql, flags=re.DOTALL,
    )

# Remove the plan_analyses.acceptance_criteria column declaration (v4.1 addition).
sql = re.sub(
    r"[ \t]*acceptance_criteria TEXT DEFAULT '\[\]',[ \t]*--[^\n]*PRD-level[^\n]*\n",
    "",
    sql,
)

# Remove the v4.2 regression objects (table + index + view) so the baseline is a clean v4.0.0.
sql = re.sub(
    r"CREATE TABLE IF NOT EXISTS regression_checks.*?FROM \(SELECT DISTINCT target_id FROM regression_checks WHERE target_type = 'task'\) d;\n",
    "",
    sql, flags=re.DOTALL,
)

# Force version literal back to 4.0.0 (schema.sql now ships 4.2.0)
sql = sql.replace("VALUES ('4.2.0')", "VALUES ('4.0.0')")

open(dst, "w").write(sql)
PY

sqlite3 "$MIG2_DB" < "$MIG2_DIR/schema-v4.0.sql" >/dev/null

# 39a: strict pre-migration baseline really lacks the v4.1 objects
PRE2_VERSION=$(sqlite3 "$MIG2_DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
assert_eq "$PRE2_VERSION" "4.0.0" "Migration(full): strict baseline is v4.0.0"

PRE2_PA_AC=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM pragma_table_info('plan_analyses') WHERE name = 'acceptance_criteria';")
assert_eq "$PRE2_PA_AC" "0" "Migration(full): baseline lacks plan_analyses.acceptance_criteria"

PRE2_VIEWS=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name IN ('v_next_task','v_next_task_sequential','v_task_verification','v_milestone_verification','v_prd_verification','v_milestone_status');")
assert_eq "$PRE2_VIEWS" "0" "Migration(full): baseline has none of the 6 views"

PRE2_VER_TABLE=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
assert_eq "$PRE2_VER_TABLE" "0" "Migration(full): baseline has no verifications table"

# 39b: run the migration
MIG2_OUT=$(bash "$MIGRATE_SCRIPT" "$MIG2_DIR" 2>&1) && MIG2_RC=0 || MIG2_RC=$?
if [[ "$MIG2_RC" -eq 0 ]]; then
    pass "Migration(full): script ran successfully (exit 0)"
else
    fail "Migration(full): script failed (exit $MIG2_RC): $MIG2_OUT"
fi

# 39c: version bumped
POST2_VERSION=$(sqlite3 "$MIG2_DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
assert_eq "$POST2_VERSION" "4.1.0" "Migration(full): schema_version is 4.1.0"

# 39d: ALL SIX views now exist
POST2_VIEWS=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name IN ('v_next_task','v_next_task_sequential','v_task_verification','v_milestone_verification','v_prd_verification','v_milestone_status');")
assert_eq "$POST2_VIEWS" "6" "Migration(full): all 6 v4.1 views exist after migration"

# 39e: plan_analyses.acceptance_criteria column added
POST2_PA_AC=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM pragma_table_info('plan_analyses') WHERE name = 'acceptance_criteria';")
assert_eq "$POST2_PA_AC" "1" "Migration(full): plan_analyses.acceptance_criteria added"

# 39f: verifications table exists AND enforces the override CHECK constraint
POST2_VER_TABLE=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
assert_eq "$POST2_VER_TABLE" "1" "Migration(full): verifications table exists"

MIG2_CHK=$(sqlite3 "$MIG2_DB" "INSERT INTO verifications (id, target_type, target_id, criterion, status, method) VALUES ('V-X', 'task', 'x', 'x', 'overridden', 'self');" 2>&1 || true)
MIG2_CHK_EXISTS=$(sqlite3 "$MIG2_DB" "SELECT COUNT(*) FROM verifications WHERE id = 'V-X';")
if echo "$MIG2_CHK" | grep -qi "constraint\|check" || [[ "$MIG2_CHK_EXISTS" == "0" ]]; then
    pass "Migration(full): verifications override CHECK is enforced (overridden requires reason)"
else
    fail "Migration(full): verifications override CHECK NOT enforced"
    sqlite3 "$MIG2_DB" "DELETE FROM verifications WHERE id = 'V-X';"
fi

# 39g: the new rollup views are functional end-to-end on the migrated DB.
MIG2_PRD=$(sqlite3 "$MIG2_DB" "
INSERT INTO plan_analyses (id, prd_source, acceptance_criteria) VALUES ('PA-1', 'p.md', json_array('only'));
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method) VALUES ('V-1', 'prd', 'PA-1', 'only', 0, 'met', 'adversarial');
SELECT is_verified FROM v_prd_verification WHERE prd_id = 'PA-1';
")
assert_eq "$MIG2_PRD" "1" "Migration(full): v_prd_verification works on migrated DB (acceptance_criteria wired)"

MIG2_MV=$(sqlite3 "$MIG2_DB" "
INSERT INTO milestones (id, title, phase_order, status, acceptance_criteria) VALUES ('MS-1', 'm', 1, 'planned', json_array('only'));
INSERT INTO verifications (id, target_type, target_id, criterion, criterion_index, status, method) VALUES ('V-2', 'milestone', 'MS-1', 'only', 0, 'met', 'adversarial');
SELECT is_verified FROM v_milestone_verification WHERE milestone_id = 'MS-1';
")
assert_eq "$MIG2_MV" "1" "Migration(full): v_milestone_verification works on migrated DB"

# 39h: v_next_task_sequential is queryable on the migrated DB
MIG2_SEQ=$(sqlite3 "$MIG2_DB" "
INSERT INTO tasks (id, title, status, priority, milestone_id) VALUES ('mt1','seq leaf','planned','high','MS-1');
SELECT id FROM v_next_task_sequential LIMIT 1;
")
assert_eq "$MIG2_SEQ" "mt1" "Migration(full): v_next_task_sequential queryable and active-milestone gated"

echo ""

# ====================================================================
# TEST 40: memory conflicts — stale-memory detection query (skill §7)
# ====================================================================
echo "--- Test 40: memory stale-memory detection ---"

sqlite3 "$DB" "
INSERT INTO memories (id, title, kind, why_important, body, source_type, importance, use_count, created_at)
VALUES ('M-STALE','Old unused note','other','n/a','stale body','agent',3,0, datetime('now','-60 days'));
INSERT INTO memories (id, title, kind, why_important, body, source_type, importance, use_count, created_at)
VALUES ('M-FRESH','Recent unused note','other','n/a','fresh body','agent',3,0, datetime('now'));
INSERT INTO memories (id, title, kind, why_important, body, source_type, importance, use_count, created_at)
VALUES ('M-USEDOLD','Old but used note','other','n/a','used body','agent',3,4, datetime('now','-90 days'));
"
STALE=$(sqlite3 "$DB" "
SELECT id FROM memories
WHERE status='active' AND use_count=0 AND created_at < datetime('now','-30 days')
ORDER BY id;
")
assert_eq "$STALE" "M-STALE" "Stale-memory query returns only the old, unused, active memory (not fresh, not used)"
sqlite3 "$DB" "DELETE FROM memories WHERE id IN ('M-STALE','M-FRESH','M-USEDOLD');"

echo ""

# ====================================================================
# TEST 41: regression gate (v4.2.0) — regression_checks, v_task_regression,
#          and the done-gate condition that closes the empty-criteria hole
# ====================================================================
echo "--- Test 41: regression gate ---"

# Schema objects present
RC_TABLE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='regression_checks';")
assert_eq "$RC_TABLE" "1" "regression_checks table exists"
RC_VIEW=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_task_regression';")
assert_eq "$RC_VIEW" "1" "v_task_regression view exists"

# CHECK: invalid status rejected
RC_BAD=$(sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status) VALUES ('RC-BAD','task','1.1','bogus');" 2>&1 || true)
if echo "$RC_BAD" | grep -qi "constraint\|check"; then pass "regression_checks rejects an invalid status"; else fail "regression_checks accepted an invalid status"; fi

# CHECK: 'overridden' requires an override_reason
RC_OVR=$(sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status) VALUES ('RC-OVR','task','1.1','overridden');" 2>&1 || true)
if echo "$RC_OVR" | grep -qi "constraint\|check"; then pass "regression_checks 'overridden' requires an override_reason"; else fail "regression_checks allowed 'overridden' with no reason"; fi

# Latest-status: a newer fail supersedes an earlier pass for the same task
sqlite3 "$DB" "
INSERT INTO regression_checks (id,target_type,target_id,status,attempt,verified_by) VALUES ('RC-T1a','task','1.1','pass',1,'maestro:regression');
INSERT INTO regression_checks (id,target_type,target_id,status,attempt,verified_by) VALUES ('RC-T1b','task','1.1','fail',2,'maestro:regression');
"
RC_LATEST=$(sqlite3 "$DB" "SELECT latest_status FROM v_task_regression WHERE task_id='1.1';")
assert_eq "$RC_LATEST" "fail" "v_task_regression returns the latest verdict (fail supersedes earlier pass)"

# THE KEY FIX: an empty-criteria leaf task yields 0 verification rows (today it skips the
# criteria gate and reaches done unverified). The regression gate must still block it.
sqlite3 "$DB" "INSERT INTO tasks (id,title,status,acceptance_criteria) VALUES ('rg-empty','Empty-criteria leaf','in-progress','[]');"
VTV_ROWS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_task_verification WHERE task_id='rg-empty';")
assert_eq "$VTV_ROWS" "0" "empty-criteria task yields 0 verification rows (would skip the criteria gate)"

# fail verdict => BLOCK
sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status,verified_by) VALUES ('RC-E1','task','rg-empty','fail','maestro:regression');"
GATE_FAIL=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='rg-empty') IN ('pass','overridden') THEN 'allow' ELSE 'block' END;")
assert_eq "$GATE_FAIL" "block" "empty-criteria task with a FAILED regression is BLOCKED from done (hole closed)"

# missing verdict => BLOCK (fail-closed)
MISSING=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='no-such') IN ('pass','overridden') THEN 'allow' ELSE 'block' END;")
assert_eq "$MISSING" "block" "a task with NO regression verdict is BLOCKED (fail-closed)"

# pass verdict => ALLOW
sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status,attempt,verified_by) VALUES ('RC-E2','task','rg-empty','pass',2,'maestro:regression');"
GATE_PASS=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='rg-empty') IN ('pass','overridden') THEN 'allow' ELSE 'block' END;")
assert_eq "$GATE_PASS" "allow" "empty-criteria task with a PASS regression is allowed to done"

# logged override => ALLOW
sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status,attempt,override_reason) VALUES ('RC-E3','task','rg-empty','overridden',3,'accepted risk: documented hotfix');"
GATE_OVR=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='rg-empty') IN ('pass','overridden') THEN 'allow' ELSE 'block' END;")
assert_eq "$GATE_OVR" "allow" "a logged override lets a task pass the regression gate"

# Combined done-gate: eligible only if (criteria verified OR empty) AND (regression pass/overridden).
ELIGIBLE=$(sqlite3 "$DB" "
SELECT CASE
  WHEN COALESCE((SELECT is_verified FROM v_task_verification WHERE task_id='rg-empty'),1) = 1
   AND (SELECT latest_status FROM v_task_regression WHERE task_id='rg-empty') IN ('pass','overridden')
  THEN 'done-eligible' ELSE 'needs-review' END;
")
assert_eq "$ELIGIBLE" "done-eligible" "combined gate: criteria-OK + regression-OK => done-eligible"

# cleanup
sqlite3 "$DB" "DELETE FROM regression_checks WHERE id LIKE 'RC-%'; DELETE FROM tasks WHERE id='rg-empty';"

echo ""

# ====================================================================
# TEST 42: show --verification surfaces the regression verdict column
#          (the read path maestro:journey's "Regression-clean" stage uses)
# ====================================================================
echo "--- Test 42: show --verification regression column ---"

sqlite3 "$DB" "
INSERT INTO tasks (id,title,status,acceptance_criteria) VALUES
 ('rs-1','crit + passing regression','in-progress','[\"a\"]'),
 ('rs-2','crit + no regression','in-progress','[\"b\"]'),
 ('rs-3','empty crit + failing regression','in-progress','[]');
INSERT INTO regression_checks (id,target_type,target_id,status,verified_by) VALUES
 ('RC-rs1','task','rs-1','pass','maestro:regression'),
 ('RC-rs3','task','rs-3','fail','maestro:regression');
"

# The exact LEFT JOIN from show.md's all-tasks --verification query
RS1_REG=$(sqlite3 "$DB" "
SELECT COALESCE(tr.latest_status,'none')
FROM v_task_verification vt
LEFT JOIN v_task_regression tr ON tr.task_id = vt.task_id
WHERE vt.task_id='rs-1';")
assert_eq "$RS1_REG" "pass" "show --verification: task with a passing regression reads 'pass'"

RS2_REG=$(sqlite3 "$DB" "
SELECT COALESCE(tr.latest_status,'none')
FROM v_task_verification vt
LEFT JOIN v_task_regression tr ON tr.task_id = vt.task_id
WHERE vt.task_id='rs-2';")
assert_eq "$RS2_REG" "none" "show --verification: task with no regression check reads 'none'"

# The single-task regression read must report even for an empty-criteria task
# (which has NO v_task_verification row, so the LEFT JOIN above would never list it)
RS3_REG=$(sqlite3 "$DB" "SELECT COALESCE((SELECT latest_status FROM v_task_regression WHERE task_id='rs-3'),'none');")
assert_eq "$RS3_REG" "fail" "show --verification <id>: empty-criteria task still reports its regression verdict"

sqlite3 "$DB" "DELETE FROM regression_checks WHERE id LIKE 'RC-rs%'; DELETE FROM tasks WHERE id IN ('rs-1','rs-2','rs-3');"

echo ""

# ====================================================================
# TEST 43: --milestone-create captures acceptance_criteria, making the
#          milestone verifiable; an empty-criteria milestone is fail-closed
# ====================================================================
echo "--- Test 43: milestone-create captures acceptance criteria ---"

# NEW --milestone-create form (id, title, description, acceptance_criteria, target_date, phase_order, status)
sqlite3 "$DB" "
INSERT INTO milestones (id, title, description, acceptance_criteria, target_date, phase_order, status)
VALUES ('MS-mc1','Auth shipped','login works','[\"users can log in\",\"sessions persist\"]', NULL, 90, 'planned');
INSERT INTO milestones (id, title, phase_order, status)
VALUES ('MS-mc2','Vague milestone (no criteria)', 91, 'planned');
"

MC1_CRIT=$(sqlite3 "$DB" "SELECT total_criteria FROM v_milestone_verification WHERE milestone_id='MS-mc1';")
assert_eq "$MC1_CRIT" "2" "milestone-create stored 2 acceptance criteria (verifiable)"

# empty-criteria milestone produces NO verification row -> can never be is_verified (fail-closed)
MC2_ROWS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_milestone_verification WHERE milestone_id='MS-mc2';")
assert_eq "$MC2_ROWS" "0" "empty-criteria milestone yields 0 verification rows (fail-closed, unverifiable)"

# when both criteria are met, the milestone verifies
sqlite3 "$DB" "
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES
 ('Vmc1','milestone','MS-mc1',0,'users can log in','met','adversarial',1),
 ('Vmc2','milestone','MS-mc1',1,'sessions persist','met','adversarial',1);
"
MC1_VERIFIED=$(sqlite3 "$DB" "SELECT is_verified FROM v_milestone_verification WHERE milestone_id='MS-mc1';")
assert_eq "$MC1_VERIFIED" "1" "milestone with captured criteria verifies when all criteria are met"

sqlite3 "$DB" "DELETE FROM verifications WHERE id LIKE 'Vmc%'; DELETE FROM milestones WHERE id IN ('MS-mc1','MS-mc2');"

echo ""

# ====================================================================
# TEST 44: done-gate requires ADVERSARIAL verification (self-only is blocked)
# ====================================================================
echo "--- Test 44: done-gate adversarial requirement ---"

# am-1: a criterion met by SELF only -> is_verified=1 but adversarially_met=0 (blocked)
sqlite3 "$DB" "
INSERT INTO tasks (id,title,status,acceptance_criteria) VALUES ('am-1','self-only verified','in-progress','[\"does X\"]');
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt)
 VALUES ('AV1','task','am-1',0,'does X','met','self',1);
"
assert_eq "$(sqlite3 "$DB" "SELECT is_verified FROM v_task_verification WHERE task_id='am-1';")" "1" "self-met task is is_verified=1 (v_task_verification ignores method)"

# the adversarially_met check from run.md §4b
adv_met() {
  sqlite3 "$DB" "
  WITH crit AS (SELECT ac.key AS idx FROM tasks t, json_each(t.acceptance_criteria) ac WHERE t.id='$1'),
  latest AS (
    SELECT
      (SELECT v.status FROM verifications v WHERE v.target_type='task' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS status,
      (SELECT v.method FROM verifications v WHERE v.target_type='task' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS method
    FROM crit c)
  SELECT CASE WHEN COUNT(*)>0 AND SUM(CASE WHEN status='overridden' OR (status='met' AND method='adversarial') THEN 1 ELSE 0 END)=COUNT(*) THEN 1 ELSE 0 END FROM latest;"
}
assert_eq "$(adv_met am-1)" "0" "done-gate: self-only met -> adversarially_met=0 (BLOCKED from done)"

# a later adversarial 'met' flips it to allowed
sqlite3 "$DB" "INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('AV2','task','am-1',0,'does X','met','adversarial',2);"
assert_eq "$(adv_met am-1)" "1" "done-gate: an adversarial 'met' (latest attempt) -> adversarially_met=1 (allowed)"

# an overridden criterion also satisfies the requirement
sqlite3 "$DB" "
INSERT INTO tasks (id,title,status,acceptance_criteria) VALUES ('am-2','overridden','in-progress','[\"y\"]');
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt,override_reason) VALUES ('AV3','task','am-2',0,'y','overridden','adversarial',1,'accepted risk');
"
assert_eq "$(adv_met am-2)" "1" "done-gate: an overridden criterion satisfies adversarially_met"

sqlite3 "$DB" "DELETE FROM verifications WHERE id LIKE 'AV%'; DELETE FROM tasks WHERE id IN ('am-1','am-2');"

echo ""

# ====================================================================
# TEST 45: milestone/PRD done-gate — self can never supersede an adversarial verdict
#   The higher-stakes mirror of Test 44 (verify.md M3/P3). A NULL-index self row is
#   excluded from the per-criterion roll-up; a self-only 'met' at a real index fools the
#   method-blind view but is caught by the adversarially_met guard. (v0.2.4 fix.)
# ====================================================================
echo "--- Test 45: milestone/PRD adversarial guard (self cannot supersede adversarial) ---"

# 45a: a NULL-index self 'met' row must NOT rescue a 'failed' adversarial criterion.
sqlite3 "$DB" "
INSERT INTO milestones (id,title,phase_order,status,acceptance_criteria) VALUES ('mg-1','self vs adversarial',1,'planned',json_array('does X'));
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MG1','milestone','mg-1',0,'does X','failed','adversarial',1);
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MG2','milestone','mg-1',NULL,'smoke','met','self',2);
"
assert_eq "$(sqlite3 "$DB" "SELECT is_verified FROM v_milestone_verification WHERE milestone_id='mg-1';")" "0" "milestone: NULL self 'met' does NOT rescue a failed adversarial criterion => is_verified=0"

# the adversarially_met guard from verify.md M3 (mirror of run.md §8a 4b), keyed for a milestone
adv_met_ms() {
  sqlite3 "$DB" "
  WITH crit AS (SELECT ac.key AS idx FROM milestones m, json_each(m.acceptance_criteria) ac WHERE m.id='$1'),
  latest AS (
    SELECT
      (SELECT v.status FROM verifications v WHERE v.target_type='milestone' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS status,
      (SELECT v.method FROM verifications v WHERE v.target_type='milestone' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS method
    FROM crit c)
  SELECT CASE WHEN COUNT(*)>0 AND SUM(CASE WHEN status='overridden' OR (status='met' AND method='adversarial') THEN 1 ELSE 0 END)=COUNT(*) THEN 1 ELSE 0 END FROM latest;"
}

# 45b: a self-only 'met' at a REAL index fools the method-blind view, but the guard blocks it.
sqlite3 "$DB" "
INSERT INTO milestones (id,title,phase_order,status,acceptance_criteria) VALUES ('mg-2','self at real idx',1,'planned',json_array('does Y'));
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MG3','milestone','mg-2',0,'does Y','met','self',1);
"
assert_eq "$(sqlite3 "$DB" "SELECT is_verified FROM v_milestone_verification WHERE milestone_id='mg-2';")" "1" "milestone: self-met at real index makes the VIEW report is_verified=1 (method-blind) — the hazard"
assert_eq "$(adv_met_ms mg-2)" "0" "milestone guard: self-only met => adversarially_met=0 (BLOCKED — the v0.2.4 fix)"
sqlite3 "$DB" "INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MG4','milestone','mg-2',0,'does Y','met','adversarial',2);"
assert_eq "$(adv_met_ms mg-2)" "1" "milestone guard: a later adversarial 'met' => adversarially_met=1 (allowed)"

# 45c: the same guard for the PRD gate (P3) — the ultimate value-delivered gate.
adv_met_prd() {
  sqlite3 "$DB" "
  WITH crit AS (SELECT ac.key AS idx FROM plan_analyses p, json_each(p.acceptance_criteria) ac WHERE p.id='$1'),
  latest AS (
    SELECT
      (SELECT v.status FROM verifications v WHERE v.target_type='prd' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS status,
      (SELECT v.method FROM verifications v WHERE v.target_type='prd' AND v.target_id='$1' AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1) AS method
    FROM crit c)
  SELECT CASE WHEN COUNT(*)>0 AND SUM(CASE WHEN status='overridden' OR (status='met' AND method='adversarial') THEN 1 ELSE 0 END)=COUNT(*) THEN 1 ELSE 0 END FROM latest;"
}
sqlite3 "$DB" "
INSERT INTO plan_analyses (id,prd_source,acceptance_criteria) VALUES ('pg-1','p.md',json_array('goal Z'));
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('PG1','prd','pg-1',0,'goal Z','met','self',1);
"
assert_eq "$(adv_met_prd pg-1)" "0" "PRD guard: self-only met => adversarially_met=0 (BLOCKED — ultimate-value gate)"
sqlite3 "$DB" "INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('PG2','prd','pg-1',0,'goal Z','met','adversarial',2);"
assert_eq "$(adv_met_prd pg-1)" "1" "PRD guard: adversarial 'met' => adversarially_met=1 (allowed)"

# 45d: run the LITERAL guard SQL extracted from verify.md (NOT a paraphrase), so a broken
#      shipped query — e.g. the unqualified-`id` ambiguity that json_each() introduces —
#      fails THIS test instead of sliding past a correctly-rewritten copy. (v0.2.5 guard.)
VERIFY_MD="$PLUGIN_DIR/tests/fixtures/verify-guard-sql.md"
sqlite3 "$DB" "
INSERT INTO milestones (id,title,phase_order,status,acceptance_criteria) VALUES ('mg-lit','literal-sql',1,'planned',json_array('does L'));
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MGL1','milestone','mg-lit',0,'does L','met','self',1);
"
MS_GUARD_SQL=$(awk '/WITH c\(idx\) AS \(SELECT ac\.key FROM milestones m/{f=1} f{print} f&&/^FROM c;/{exit}' "$VERIFY_MD" | sed "s/<ms-id>/mg-lit/g")
MS_LIT=$(sqlite3 "$DB" "$MS_GUARD_SQL" 2>&1 || true)
assert_eq "$MS_LIT" "0" "literal verify.md M3 guard SQL parses + runs; self-only met => adversarially_met=0"
sqlite3 "$DB" "INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('MGL2','milestone','mg-lit',0,'does L','met','adversarial',2);"
MS_LIT2=$(sqlite3 "$DB" "$MS_GUARD_SQL" 2>&1 || true)
assert_eq "$MS_LIT2" "1" "literal verify.md M3 guard SQL: adversarial met => adversarially_met=1"

sqlite3 "$DB" "
INSERT INTO plan_analyses (id,prd_source,acceptance_criteria) VALUES ('pg-lit','p.md',json_array('goal L'));
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('PGL1','prd','pg-lit',0,'goal L','met','self',1);
"
PRD_GUARD_SQL=$(awk '/WITH c\(idx\) AS \(SELECT ac\.key FROM plan_analyses p/{f=1} f{print} f&&/^FROM c;/{exit}' "$VERIFY_MD" | sed "s/<PA-id>/pg-lit/g")
PRD_LIT=$(sqlite3 "$DB" "$PRD_GUARD_SQL" 2>&1 || true)
assert_eq "$PRD_LIT" "0" "literal verify.md P3 guard SQL parses + runs; self-only met => adversarially_met=0"

sqlite3 "$DB" "DELETE FROM verifications WHERE id LIKE 'MG%' OR id LIKE 'PG%'; DELETE FROM milestones WHERE id IN ('mg-1','mg-2','mg-lit'); DELETE FROM plan_analyses WHERE id IN ('pg-1','pg-lit');"

echo ""

# ====================================================================
# SUMMARY
# ====================================================================
echo "=============================================="
echo "  TEST RESULTS"
echo "=============================================="
echo ""
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo "  TOTAL:  $((PASS + FAIL))"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "  FAILURES:"
    echo -e "$ERRORS"
    echo ""
    exit 1
else
    echo "  ALL TESTS PASSED!"
    echo ""
    exit 0
fi
