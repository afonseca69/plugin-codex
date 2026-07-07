#!/usr/bin/env bash
# Manual TaskManager SQLite engine wrapper for Codex plugin artifacts.

set -euo pipefail

EXIT_USAGE=2
EXIT_DEPENDENCY=127

resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
ENGINE_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
SCHEMA_FILE="$ENGINE_DIR/schemas/schema.sql"
CONFIG_SRC="$ENGINE_DIR/schemas/default-config.json"

die() {
    local message="$1"
    local code="${2:-1}"
    printf 'Error: %s\n' "$message" >&2
    exit "$code"
}

usage() {
    cat <<'USAGE'
TaskManager engine wrapper

Manual commands:
  init [PROJECT_DIR]        Create PROJECT_DIR/.taskmanager with schema/config/logs.
  status [PROJECT_DIR]      Print schema version and core table counts.
  next [PROJECT_DIR]        Show rows from v_next_task without mutating data.
  show PROJECT_DIR [view] [args...]
                            Read safe runtime visibility views without mutating data.
  task-add PROJECT_DIR TASK_ID TITLE [TYPE] [STATUS] [PARENT_ID]
                            Explicitly add one manual task row.
  task-set-status PROJECT_DIR TASK_ID STATUS
                            Explicitly update one task status.
  task-update-title PROJECT_DIR TASK_ID TITLE
                            Explicitly update one task title.
  task-archive PROJECT_DIR TASK_ID
                            Soft archive one task by setting archived_at.
  memory-list PROJECT_DIR [limit]
                            List memory id, type, importance, confidence, status, and title.
  memory-show PROJECT_DIR MEMORY_ID
                            Show one memory's useful fields without mutating data.
  memory-search PROJECT_DIR QUERY [limit]
                            Search memories with FTS when available, falling back to LIKE.
  memory-add PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]
                            Explicitly add one manual memory row.
  memory-deprecate PROJECT_DIR MEMORY_ID REASON
                            Mark one memory deprecated without deleting it.
  plan-validate PROJECT_DIR PLAN_JSON
                            Validate a reviewed plan payload without writing.
  plan-preview PROJECT_DIR PLAN_JSON
                            Preview reviewed plan artifacts without writing.
  plan-apply PROJECT_DIR PLAN_JSON
                            Insert reviewed plan artifacts in one transaction.
  export-json [PROJECT_DIR] Print a JSON export of core tables without mutating data.
  run-sql-tests             Run the copied SQL query and lifecycle test scripts.
  help                      Show this help.

Show views:
  overview                  Default. Schema version and core table counts.
  tasks [limit]             List task id, status, title, and parent_id. Default limit: 20.
  task TASK_ID              Show one task with core fields.
  milestones [limit]        List milestones if the table exists. Default limit: 20.
  memories [limit]          List memories if the table exists. Default limit: 20.
  verifications [TASK_ID]   List recent rows, or rows for one task. Default limit: 20.
  regressions [TARGET_ID]   List recent rows, or rows for one target. Default limit: 20.
  deferrals [limit]         List deferrals if the table exists. Default limit: 20.

Safety notes:
  - This is an explicit/manual wrapper around copied SQLite artifacts.
  - It does not enable hooks, auto-run tasks, start background jobs, or register Codex commands.
  - Writes are limited to PROJECT_DIR/.taskmanager for init, or temp directories used by tests.
  - init refuses to overwrite an existing PROJECT_DIR/.taskmanager/taskmanager.db.
  - Read-only commands require an initialized PROJECT_DIR/.taskmanager/taskmanager.db.
  - show requires an explicit PROJECT_DIR and uses sqlite3 read-only access.
  - task-add, task-set-status, task-update-title, and task-archive mutate only PROJECT_DIR/.taskmanager/taskmanager.db.
  - Task commands do not cascade parent statuses, execute work, or write verification rows.
  - memory-add and memory-deprecate mutate only PROJECT_DIR/.taskmanager/taskmanager.db.
  - Memory commands do not auto-classify, research, supersede, or reconcile conflicts.
  - plan-validate and plan-preview read an explicit PLAN_JSON and do not write.
  - plan-apply inserts only plan analyses, milestones, tasks, and optional memories.
  - Plan commands do not execute tasks, write verification rows, change current task state, run research, or enable hooks.

Exit codes:
  0    success
  1    runtime or validation failure
  2    usage error
  127  missing sqlite3 or python3 dependency
USAGE
}

require_sqlite() {
    command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required for TaskManager engine commands." "$EXIT_DEPENDENCY"
}

require_python3() {
    command -v python3 >/dev/null 2>&1 || die "python3 is required for TaskManager plan commands." "$EXIT_DEPENDENCY"
}

require_engine_files() {
    [[ -r "$SCHEMA_FILE" ]] || die "schema file not found: $SCHEMA_FILE"
    [[ -r "$CONFIG_SRC" ]] || die "default config not found: $CONFIG_SRC"
}

project_path() {
    local input="${1:-$PWD}"
    [[ -n "$input" ]] || die "PROJECT_DIR must not be empty." "$EXIT_USAGE"

    case "$input" in
        /*) printf '%s\n' "$input" ;;
        *) printf '%s/%s\n' "$PWD" "$input" ;;
    esac
}

taskmanager_dir_for() {
    local project="$1"
    printf '%s/.taskmanager\n' "$project"
}

db_for() {
    local project="$1"
    printf '%s/taskmanager.db\n' "$(taskmanager_dir_for "$project")"
}

require_initialized_db() {
    local project="$1"
    local db
    db="$(db_for "$project")"
    [[ -f "$db" ]] || die "TaskManager engine is not initialized for $project; run: taskmanager-engine.sh init \"$project\""
    printf '%s\n' "$db"
}

sqlite_has_json() {
    local db="$1"
    sqlite3 -readonly "$db" "SELECT json_object('ok', 1);" >/dev/null 2>&1
}

table_exists() {
    local db="$1"
    local table="$2"
    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='$table';")" == "1" ]]
}

view_exists() {
    local db="$1"
    local view="$2"
    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='$view';")" == "1" ]]
}

table_count() {
    local db="$1"
    local table="$2"

    if table_exists "$db" "$table"; then
        sqlite3 -readonly "$db" "SELECT COUNT(*) FROM \"$table\";"
    else
        printf 'n/a\n'
    fi
}

schema_version_for() {
    local db="$1"

    if table_exists "$db" "schema_version"; then
        sqlite3 -readonly "$db" "SELECT COALESCE((SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1), 'unknown');"
    else
        printf 'unknown\n'
    fi
}

validate_lookup_id() {
    local value="$1"
    local label="$2"

    [[ -n "$value" ]] || die "$label must not be empty." "$EXIT_USAGE"
    case "$value" in
        *[!A-Za-z0-9._:-]*)
            die "$label contains unsupported characters; allowed: A-Z a-z 0-9 . _ : -" "$EXIT_USAGE"
            ;;
    esac
}

sql_literal() {
    local value="$1"
    local escaped
    escaped="$(printf '%s' "$value" | sed "s/'/''/g")"
    printf "'%s'" "$escaped"
}

like_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//%/\\%}"
    value="${value//_/\\_}"
    printf '%s' "$value"
}

validate_required_text() {
    local value="$1"
    local label="$2"

    [[ -n "$value" ]] || die "$label must not be empty." "$EXIT_USAGE"
}

task_statuses() {
    printf 'draft planned in-progress blocked paused done canceled duplicate needs-review\n'
}

validate_task_status() {
    local value="$1"
    case "$value" in
        draft|planned|in-progress|blocked|paused|done|canceled|duplicate|needs-review)
            ;;
        *)
            die "STATUS must be one of: $(task_statuses)" "$EXIT_USAGE"
            ;;
    esac
}

task_types() {
    printf 'feature bug chore analysis spike task(alias for feature)\n'
}

normalize_task_type() {
    local value="$1"
    case "$value" in
        feature|bug|chore|analysis|spike)
            printf '%s\n' "$value"
            ;;
        task)
            printf 'feature\n'
            ;;
        *)
            die "TYPE must be one of: $(task_types)" "$EXIT_USAGE"
            ;;
    esac
}

validate_task_id() {
    local value="$1"
    local label="${2:-TASK_ID}"

    [[ -n "$value" ]] || die "$label must not be empty." "$EXIT_USAGE"
    if [[ ! "$value" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$ ]]; then
        die "$label contains unsupported characters; must start with A-Z a-z 0-9 and use only A-Z a-z 0-9 . _ : -" "$EXIT_USAGE"
    fi
}

require_tasks_table() {
    local db="$1"

    table_exists "$db" "tasks" || die "tasks table does not exist in $db."
}

task_exists() {
    local db="$1"
    local task_id="$2"
    local task_id_sql
    task_id_sql="$(sql_literal "$task_id")"

    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM tasks WHERE id = $task_id_sql;")" == "1" ]]
}

memory_types() {
    printf 'constraint decision bugfix workaround convention architecture process integration anti-pattern other\n'
}

validate_memory_type() {
    local value="$1"
    case "$value" in
        constraint|decision|bugfix|workaround|convention|architecture|process|integration|anti-pattern|other)
            ;;
        *)
            die "TYPE must be one of: $(memory_types)" "$EXIT_USAGE"
            ;;
    esac
}

validate_importance() {
    local value="$1"

    [[ "$value" =~ ^[0-9]+$ ]] || die "IMPORTANCE must be an integer between 1 and 5." "$EXIT_USAGE"
    (( value >= 1 && value <= 5 )) || die "IMPORTANCE must be between 1 and 5." "$EXIT_USAGE"
}

validate_confidence() {
    local value="$1"

    [[ "$value" =~ ^(0([.][0-9]+)?|1([.]0+)?)$ ]] || die "CONFIDENCE must be a number between 0 and 1." "$EXIT_USAGE"
}

require_memories_table() {
    local db="$1"

    table_exists "$db" "memories" || die "memories table does not exist in $db."
}

show_usage_error() {
    die "show requires PROJECT_DIR. Usage: taskmanager-engine.sh show PROJECT_DIR [overview|tasks [limit]|task TASK_ID|milestones [limit]|memories [limit]|verifications [TASK_ID]|regressions [TARGET_ID]|deferrals [limit]]" "$EXIT_USAGE"
}

cmd_init() {
    local project
    project="$(project_path "${1:-$PWD}")"
    local tm_dir
    tm_dir="$(taskmanager_dir_for "$project")"
    local db
    db="$(db_for "$project")"

    require_sqlite
    require_engine_files

    [[ ! -e "$db" ]] || die "TaskManager engine already initialized at $db; refusing to overwrite."

    mkdir -p "$tm_dir/logs"
    if [[ ! -f "$tm_dir/config.json" ]]; then
        cp "$CONFIG_SRC" "$tm_dir/config.json"
    fi

    sqlite3 "$db" < "$SCHEMA_FILE" >/dev/null

    printf 'Initialized TaskManager engine at %s\n' "$tm_dir"
    printf 'Database: %s\n' "$db"
}

cmd_status() {
    local project
    project="$(project_path "${1:-$PWD}")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"

    local version
    version="$(schema_version_for "$db")"

    printf 'TaskManager engine status\n'
    printf 'Project: %s\n' "$project"
    printf 'Database: %s\n' "$db"
    printf 'Schema version: %s\n' "$version"
    printf 'Counts:\n'

    local table
    for table in tasks milestones memories verifications regression_checks; do
        printf '  %s: %s\n' "$table" "$(table_count "$db" "$table")"
    done
}

parse_limit() {
    local value="${1:-20}"
    local label="${2:-limit}"

    [[ "$value" =~ ^[0-9]+$ ]] || die "$label must be a positive integer." "$EXIT_USAGE"
    (( value >= 1 )) || die "$label must be at least 1." "$EXIT_USAGE"
    (( value <= 100 )) || die "$label must be 100 or less." "$EXIT_USAGE"
    printf '%s\n' "$value"
}

show_overview() {
    local project="$1"
    local db="$2"
    local version
    version="$(schema_version_for "$db")"

    printf 'TaskManager engine overview\n'
    printf 'Project: %s\n' "$project"
    printf 'Database: %s\n' "$db"
    printf 'Schema version: %s\n' "$version"
    printf 'Counts:\n'

    local table
    for table in tasks milestones memories deferrals verifications regression_checks; do
        printf '  %s: %s\n' "$table" "$(table_count "$db" "$table")"
    done
}

show_tasks() {
    local db="$1"
    local limit
    limit="$(parse_limit "${2:-20}" "tasks limit")"

    table_exists "$db" "tasks" || { printf 'No tasks table found.\n'; return 0; }
    [[ "$(table_count "$db" "tasks")" != "0" ]] || { printf 'No tasks found.\n'; return 0; }

    printf 'Tasks\n'
    sqlite3 -readonly -header -column "$db" "
SELECT id, status, title, COALESCE(parent_id, '') AS parent_id
FROM tasks
WHERE archived_at IS NULL
ORDER BY id
LIMIT $limit;"
}

show_task() {
    local db="$1"
    local task_id="$2"

    validate_lookup_id "$task_id" "TASK_ID"
    table_exists "$db" "tasks" || die "tasks table does not exist in $db."
    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM tasks WHERE id = '$task_id';")" == "1" ]] || die "Task not found: $task_id"

    printf 'Task %s\n' "$task_id"
    sqlite3 -readonly -header -column "$db" "
SELECT
  id,
  COALESCE(parent_id, '') AS parent_id,
  title,
  COALESCE(description, '') AS description,
  COALESCE(details, '') AS details,
  COALESCE(test_strategy, '') AS test_strategy,
  status,
  type,
  priority,
  COALESCE(milestone_id, '') AS milestone_id,
  dependencies,
  acceptance_criteria
FROM tasks
WHERE id = '$task_id';"
}

show_milestones() {
    local db="$1"
    local limit
    limit="$(parse_limit "${2:-20}" "milestones limit")"

    table_exists "$db" "milestones" || { printf 'No milestones table found.\n'; return 0; }
    [[ "$(table_count "$db" "milestones")" != "0" ]] || { printf 'No milestones found.\n'; return 0; }

    printf 'Milestones\n'
    sqlite3 -readonly -header -column "$db" "
SELECT id, status, title, phase_order
FROM milestones
ORDER BY phase_order, id
LIMIT $limit;"
}

show_memories() {
    local db="$1"
    local limit
    limit="$(parse_limit "${2:-20}" "memories limit")"

    table_exists "$db" "memories" || { printf 'No memories table found.\n'; return 0; }
    [[ "$(table_count "$db" "memories")" != "0" ]] || { printf 'No memories found.\n'; return 0; }

    printf 'Memories\n'
    sqlite3 -readonly -header -column "$db" "
SELECT id, status, kind, importance, title
FROM memories
ORDER BY updated_at DESC, created_at DESC, id
LIMIT $limit;"
}

show_deferrals() {
    local db="$1"
    local limit
    limit="$(parse_limit "${2:-20}" "deferrals limit")"

    table_exists "$db" "deferrals" || { printf 'No deferrals table found.\n'; return 0; }
    [[ "$(table_count "$db" "deferrals")" != "0" ]] || { printf 'No deferrals found.\n'; return 0; }

    printf 'Deferrals\n'
    sqlite3 -readonly -header -column "$db" "
SELECT id, status, source_task_id, COALESCE(target_task_id, '') AS target_task_id, title
FROM deferrals
ORDER BY updated_at DESC, created_at DESC, id
LIMIT $limit;"
}

show_verifications() {
    local db="$1"
    local task_id="${2:-}"

    table_exists "$db" "verifications" || { printf 'No verifications table found.\n'; return 0; }
    [[ "$(table_count "$db" "verifications")" != "0" ]] || { printf 'No verifications found.\n'; return 0; }

    printf 'Verifications\n'
    if [[ -n "$task_id" ]]; then
        validate_lookup_id "$task_id" "TASK_ID"
        sqlite3 -readonly -header -column "$db" "
SELECT id, target_type, target_id, criterion_index, status, method, attempt
FROM verifications
WHERE target_type = 'task' AND target_id = '$task_id'
ORDER BY attempt DESC, created_at DESC, id
LIMIT 20;"
    else
        sqlite3 -readonly -header -column "$db" "
SELECT id, target_type, target_id, criterion_index, status, method, attempt
FROM verifications
ORDER BY created_at DESC, target_type, target_id, attempt DESC, id
LIMIT 20;"
    fi
}

show_regressions() {
    local db="$1"
    local target_id="${2:-}"

    table_exists "$db" "regression_checks" || { printf 'No regression checks table found.\n'; return 0; }
    [[ "$(table_count "$db" "regression_checks")" != "0" ]] || { printf 'No regression checks found.\n'; return 0; }

    printf 'Regression checks\n'
    if [[ -n "$target_id" ]]; then
        validate_lookup_id "$target_id" "TARGET_ID"
        sqlite3 -readonly -header -column "$db" "
SELECT id, target_type, target_id, status, verified_by, attempt
FROM regression_checks
WHERE target_id = '$target_id'
ORDER BY attempt DESC, created_at DESC, id
LIMIT 20;"
    else
        sqlite3 -readonly -header -column "$db" "
SELECT id, target_type, target_id, status, verified_by, attempt
FROM regression_checks
ORDER BY created_at DESC, target_type, target_id, attempt DESC, id
LIMIT 20;"
    fi
}

memory_list() {
    local db="$1"
    local limit
    limit="$(parse_limit "${2:-20}" "memory-list limit")"

    require_memories_table "$db"
    [[ "$(table_count "$db" "memories")" != "0" ]] || { printf 'No memories found.\n'; return 0; }

    printf 'Memories\n'
    sqlite3 -readonly -header -column "$db" "
SELECT id, kind AS type, importance, confidence, status, title
FROM memories
ORDER BY updated_at DESC, created_at DESC, id
LIMIT $limit;"
}

memory_show() {
    local db="$1"
    local memory_id="$2"

    validate_lookup_id "$memory_id" "MEMORY_ID"
    require_memories_table "$db"

    local memory_id_sql
    memory_id_sql="$(sql_literal "$memory_id")"
    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM memories WHERE id = $memory_id_sql;")" == "1" ]] || die "Memory not found: $memory_id"

    printf 'Memory %s\n' "$memory_id"
    sqlite3 -readonly -header -column "$db" "
SELECT
  id,
  title,
  kind AS type,
  status,
  importance,
  confidence,
  why_important,
  body,
  source_type,
  COALESCE(source_name, '') AS source_name,
  COALESCE(source_via, '') AS source_via,
  auto_updatable,
  COALESCE(superseded_by, '') AS superseded_by,
  scope,
  tags,
  links,
  use_count,
  COALESCE(last_used_at, '') AS last_used_at,
  COALESCE(last_conflict_at, '') AS last_conflict_at,
  conflict_resolutions,
  created_at,
  updated_at
FROM memories
WHERE id = $memory_id_sql;"
}

memory_search_like() {
    local db="$1"
    local query="$2"
    local limit="$3"
    local pattern_sql
    pattern_sql="$(sql_literal "%$(like_escape "$query")%")"

    sqlite3 -readonly -header -column "$db" "
SELECT id, kind AS type, importance, confidence, status, title
FROM memories
WHERE title LIKE $pattern_sql ESCAPE '\'
   OR body LIKE $pattern_sql ESCAPE '\'
   OR tags LIKE $pattern_sql ESCAPE '\'
ORDER BY updated_at DESC, created_at DESC, id
LIMIT $limit;"
}

memory_search_fts() {
    local db="$1"
    local query="$2"
    local limit="$3"
    local query_sql
    query_sql="$(sql_literal "$query")"

    sqlite3 -readonly -header -column "$db" "
SELECT m.id, m.kind AS type, m.importance, m.confidence, m.status, m.title
FROM memories_fts
JOIN memories m ON m.rowid = memories_fts.rowid
WHERE memories_fts MATCH $query_sql
ORDER BY bm25(memories_fts), m.updated_at DESC, m.created_at DESC, m.id
LIMIT $limit;"
}

memory_search() {
    local db="$1"
    local query="$2"
    local limit
    limit="$(parse_limit "${3:-20}" "memory-search limit")"

    validate_required_text "$query" "QUERY"
    require_memories_table "$db"
    [[ "$(table_count "$db" "memories")" != "0" ]] || { printf 'No memories found.\n'; return 0; }

    local output=""
    if table_exists "$db" "memories_fts"; then
        if output="$(memory_search_fts "$db" "$query" "$limit" 2>/dev/null)"; then
            if [[ -n "$output" ]]; then
                printf 'Memories\n%s\n' "$output"
            else
                printf 'No matching memories found.\n'
            fi
            return 0
        fi
    fi

    output="$(memory_search_like "$db" "$query" "$limit")"
    if [[ -n "$output" ]]; then
        printf 'Memories\n%s\n' "$output"
    else
        printf 'No matching memories found.\n'
    fi
}

memory_add() {
    local db="$1"
    local type="$2"
    local title="$3"
    local body="$4"
    local importance="${5:-3}"
    local confidence="${6:-0.8}"

    require_memories_table "$db"
    validate_memory_type "$type"
    validate_required_text "$title" "TITLE"
    validate_required_text "$body" "BODY"
    validate_importance "$importance"
    validate_confidence "$confidence"

    local type_sql title_sql body_sql why_sql source_name_sql source_via_sql
    type_sql="$(sql_literal "$type")"
    title_sql="$(sql_literal "$title")"
    body_sql="$(sql_literal "$body")"
    why_sql="$(sql_literal "Manual memory added explicitly through taskmanager-engine.sh memory-add.")"
    source_name_sql="$(sql_literal "taskmanager-engine.sh")"
    source_via_sql="$(sql_literal "memory-add")"

    local created_id
    created_id="$(sqlite3 "$db" <<SQL
.bail on
BEGIN IMMEDIATE;
CREATE TEMP TABLE created_memory_id(id TEXT);
INSERT INTO created_memory_id(id)
SELECT 'M-' || printf('%03d', COALESCE(MAX(CASE WHEN id GLOB 'M-[0-9]*' THEN CAST(SUBSTR(id, 3) AS INTEGER) END), 0) + 1)
FROM memories;
INSERT INTO memories (
  id,
  title,
  kind,
  why_important,
  body,
  source_type,
  source_name,
  source_via,
  auto_updatable,
  importance,
  confidence,
  status,
  scope,
  tags,
  links
)
SELECT
  id,
  $title_sql,
  $type_sql,
  $why_sql,
  $body_sql,
  'command',
  $source_name_sql,
  $source_via_sql,
  0,
  $importance,
  $confidence,
  'active',
  '{}',
  '[]',
  '[]'
FROM created_memory_id;
COMMIT;
SELECT id FROM created_memory_id;
SQL
)"

    printf 'Created memory: %s\n' "$created_id"
}

memory_deprecate() {
    local db="$1"
    local memory_id="$2"
    local reason="$3"

    validate_lookup_id "$memory_id" "MEMORY_ID"
    validate_required_text "$reason" "REASON"
    require_memories_table "$db"

    local memory_id_sql
    memory_id_sql="$(sql_literal "$memory_id")"
    [[ "$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM memories WHERE id = $memory_id_sql;")" == "1" ]] || die "Memory not found: $memory_id"

    sqlite3 "$db" <<SQL >/dev/null
.bail on
BEGIN IMMEDIATE;
UPDATE memories
SET status = 'deprecated',
    updated_at = datetime('now')
WHERE id = $memory_id_sql;
COMMIT;
SQL

    printf 'Deprecated memory: %s\n' "$memory_id"
    printf 'Note: deprecation reason is not stored; schema has status/superseded fields but no clean deprecation reason field.\n'
}

task_add() {
    local db="$1"
    local task_id="$2"
    local title="$3"
    local type="${4:-feature}"
    local status="${5:-planned}"
    local parent_id="${6:-}"

    require_tasks_table "$db"
    validate_task_id "$task_id" "TASK_ID"
    validate_required_text "$title" "TITLE"
    type="$(normalize_task_type "$type")"
    validate_task_status "$status"

    if [[ -n "$parent_id" ]]; then
        validate_task_id "$parent_id" "PARENT_ID"
    fi

    local task_id_sql
    task_id_sql="$(sql_literal "$task_id")"
    if task_exists "$db" "$task_id"; then
        die "Task already exists: $task_id"
    fi

    local parent_id_sql="NULL"
    if [[ -n "$parent_id" ]]; then
        if ! task_exists "$db" "$parent_id"; then
            die "Parent task not found: $parent_id"
        fi
        parent_id_sql="$(sql_literal "$parent_id")"
    fi

    local title_sql type_sql status_sql
    title_sql="$(sql_literal "$title")"
    type_sql="$(sql_literal "$type")"
    status_sql="$(sql_literal "$status")"

    sqlite3 "$db" <<SQL >/dev/null
.bail on
BEGIN IMMEDIATE;
INSERT INTO tasks (
  id,
  parent_id,
  title,
  status,
  type,
  priority
) VALUES (
  $task_id_sql,
  $parent_id_sql,
  $title_sql,
  $status_sql,
  $type_sql,
  'medium'
);
COMMIT;
SQL

    printf 'Created task: %s\n' "$task_id"
}

task_set_status() {
    local db="$1"
    local task_id="$2"
    local status="$3"

    require_tasks_table "$db"
    validate_task_id "$task_id" "TASK_ID"
    validate_task_status "$status"

    if ! task_exists "$db" "$task_id"; then
        die "Task not found: $task_id"
    fi

    local task_id_sql status_sql
    task_id_sql="$(sql_literal "$task_id")"
    status_sql="$(sql_literal "$status")"

    sqlite3 "$db" <<SQL >/dev/null
.bail on
BEGIN IMMEDIATE;
UPDATE tasks
SET status = $status_sql,
    updated_at = datetime('now'),
    started_at = CASE
        WHEN $status_sql = 'in-progress' AND started_at IS NULL THEN datetime('now')
        ELSE started_at
    END,
    completed_at = CASE
        WHEN $status_sql = 'done' AND completed_at IS NULL THEN datetime('now')
        ELSE completed_at
    END
WHERE id = $task_id_sql;
COMMIT;
SQL

    printf 'Updated task status: %s -> %s\n' "$task_id" "$status"
}

task_update_title() {
    local db="$1"
    local task_id="$2"
    local title="$3"

    require_tasks_table "$db"
    validate_task_id "$task_id" "TASK_ID"
    validate_required_text "$title" "TITLE"

    if ! task_exists "$db" "$task_id"; then
        die "Task not found: $task_id"
    fi

    local task_id_sql title_sql
    task_id_sql="$(sql_literal "$task_id")"
    title_sql="$(sql_literal "$title")"

    sqlite3 "$db" <<SQL >/dev/null
.bail on
BEGIN IMMEDIATE;
UPDATE tasks
SET title = $title_sql,
    updated_at = datetime('now')
WHERE id = $task_id_sql;
COMMIT;
SQL

    printf 'Updated task title: %s\n' "$task_id"
}

task_archive() {
    local db="$1"
    local task_id="$2"

    require_tasks_table "$db"
    validate_task_id "$task_id" "TASK_ID"

    if ! task_exists "$db" "$task_id"; then
        die "Task not found: $task_id"
    fi

    local task_id_sql
    task_id_sql="$(sql_literal "$task_id")"

    sqlite3 "$db" <<SQL >/dev/null
.bail on
BEGIN IMMEDIATE;
UPDATE tasks
SET archived_at = COALESCE(archived_at, datetime('now')),
    updated_at = datetime('now')
WHERE id = $task_id_sql;
COMMIT;
SQL

    printf 'Archived task: %s\n' "$task_id"
}

plan_payload() {
    local mode="$1"
    local db="$2"
    local payload="$3"

    python3 - "$mode" "$db" "$payload" <<'PY'
import json
import re
import sqlite3
import sys
from pathlib import Path

MODE = sys.argv[1]
DB_PATH = sys.argv[2]
PAYLOAD_PATH = sys.argv[3]

ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$")
TASK_STATUSES = {"draft", "planned", "in-progress", "blocked", "paused", "done", "canceled", "duplicate", "needs-review"}
TASK_TYPES = {"feature", "bug", "chore", "analysis", "spike"}
PRIORITIES = {"low", "medium", "high", "critical"}
MILESTONE_STATUSES = {"planned", "active", "completed", "canceled"}
MEMORY_KINDS = {"constraint", "decision", "bugfix", "workaround", "convention", "architecture", "process", "integration", "anti-pattern", "other"}
MEMORY_SOURCES = {"user", "agent", "command", "hook", "other"}
COMPLEXITY_SCALES = {"XS", "S", "M", "L", "XL"}
MOSCOW_VALUES = {"must", "should", "could", "wont"}
DEPENDENCY_TYPES = {"hard", "soft"}


def fail(message: str, code: int = 1) -> None:
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(code)


def read_payload(path: str) -> dict:
    try:
        raw = Path(path).read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read PLAN_JSON: {exc}")

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in PLAN_JSON: {exc}")

    if not isinstance(payload, dict):
        fail("PLAN_JSON root must be an object.")
    return payload


def connect_readonly(db_path: str) -> sqlite3.Connection:
    return sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)


def connect_writable(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    return conn.execute(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?",
        (table,),
    ).fetchone()[0] == 1


def require_table(conn: sqlite3.Connection, table: str) -> None:
    if not table_exists(conn, table):
        fail(f"{table} table does not exist in {DB_PATH}.")


def schema_version(conn: sqlite3.Connection) -> str:
    require_table(conn, "schema_version")
    row = conn.execute(
        "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1"
    ).fetchone()
    return row[0] if row else "unknown"


def validate_id(value: str, label: str) -> str:
    if not isinstance(value, str) or not value:
        fail(f"{label} must be a non-empty string.")
    if not ID_RE.match(value):
        fail(f"{label} contains unsupported characters.")
    return value


def require_text(value, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} must be a non-empty string.")
    return value


def json_text(value, label: str, default):
    if value is None:
        value = default
    if isinstance(value, str):
        try:
            json.loads(value)
        except json.JSONDecodeError as exc:
            fail(f"{label} must be valid JSON when provided as a string: {exc}")
        return value
    if isinstance(value, (list, dict)):
        return json.dumps(value, sort_keys=True, separators=(",", ":"))
    fail(f"{label} must be a JSON array or object.")


def optional_text(value, label: str):
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, (list, dict)):
        return json.dumps(value, sort_keys=True, separators=(",", ":"))
    fail(f"{label} must be text or JSON-compatible data.")


def optional_int(value, label: str, min_value=None, max_value=None):
    if value is None:
        return None
    if not isinstance(value, int) or isinstance(value, bool):
        fail(f"{label} must be an integer.")
    if min_value is not None and value < min_value:
        fail(f"{label} must be at least {min_value}.")
    if max_value is not None and value > max_value:
        fail(f"{label} must be {max_value} or less.")
    return value


def optional_float(value, label: str, default=None, min_value=None, max_value=None):
    if value is None:
        value = default
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        fail(f"{label} must be a number.")
    value = float(value)
    if min_value is not None and value < min_value:
        fail(f"{label} must be at least {min_value}.")
    if max_value is not None and value > max_value:
        fail(f"{label} must be {max_value} or less.")
    return value


def next_prefixed_id(conn: sqlite3.Connection, table: str, prefix: str) -> str:
    start = len(prefix) + 1
    row = conn.execute(
        f"SELECT COALESCE(MAX(CASE WHEN id GLOB ? THEN CAST(SUBSTR(id, ?) AS INTEGER) END), 0) FROM {table}",
        (f"{prefix}[0-9]*", start),
    ).fetchone()
    return f"{prefix}{(row[0] or 0) + 1:03d}"


def ensure_unique(items, label: str) -> None:
    seen = set()
    duplicates = []
    for item in items:
        if item in seen:
            duplicates.append(item)
        seen.add(item)
    if duplicates:
        fail(f"duplicate {label}: {', '.join(sorted(set(duplicates)))}")


def existing_ids(conn: sqlite3.Connection, table: str, ids) -> list[str]:
    values = sorted(set(ids))
    if not values:
        return []
    placeholders = ",".join("?" for _ in values)
    rows = conn.execute(
        f"SELECT id FROM {table} WHERE id IN ({placeholders}) ORDER BY id",
        values,
    ).fetchall()
    return [row[0] for row in rows]


def active_task_ids(conn: sqlite3.Connection, ids) -> set[str]:
    values = sorted(set(ids))
    if not values:
        return set()
    placeholders = ",".join("?" for _ in values)
    rows = conn.execute(
        f"""
        SELECT id
        FROM tasks
        WHERE id IN ({placeholders})
          AND archived_at IS NULL
          AND status NOT IN ('canceled', 'duplicate')
        """,
        values,
    ).fetchall()
    return {row[0] for row in rows}


def normalize_payload(conn: sqlite3.Connection, payload: dict) -> dict:
    for table in ("plan_analyses", "milestones", "tasks", "memories", "state", "verifications", "regression_checks"):
        require_table(conn, table)

    version = schema_version(conn)
    if version != "4.2.0":
        fail(f"unsupported TaskManager schema version: {version}")

    payload_version = payload.get("payload_version", payload.get("format_version"))
    if str(payload_version) != "1":
        fail("payload_version must be 1.")
    if payload.get("review_status") != "reviewed":
        fail("review_status must be reviewed before plan commands persist payloads.")

    plan_raw = payload.get("plan_analyses", payload.get("plan_analysis", {}))
    if not isinstance(plan_raw, dict):
        fail("plan_analyses must be an object.")

    milestones_raw = payload.get("milestones", [])
    if milestones_raw is None:
        milestones_raw = []
    if not isinstance(milestones_raw, list):
        fail("milestones must be a list.")

    tasks_raw = payload.get("tasks")
    if not isinstance(tasks_raw, list) or len(tasks_raw) == 0:
        fail("tasks must be a non-empty task list.")

    memories_raw = payload.get("memories", [])
    if memories_raw is None:
        memories_raw = []
    if not isinstance(memories_raw, list):
        fail("memories must be a list when provided.")

    plan_id = validate_id(plan_raw.get("id") or next_prefixed_id(conn, "plan_analyses", "PA-"), "plan_analyses.id")

    milestones = []
    milestone_ids = []
    for index, raw in enumerate(milestones_raw, start=1):
        if not isinstance(raw, dict):
            fail(f"milestones[{index}] must be an object.")
        milestone_id = validate_id(raw.get("id"), f"milestones[{index}].id")
        status = raw.get("status", "planned")
        if status not in MILESTONE_STATUSES:
            fail(f"milestones[{index}].status must be one of: {', '.join(sorted(MILESTONE_STATUSES))}")
        phase_order = raw.get("phase_order", index)
        if not isinstance(phase_order, int) or isinstance(phase_order, bool):
            fail(f"milestones[{index}].phase_order must be an integer.")
        milestone_ids.append(milestone_id)
        milestones.append({
            "id": milestone_id,
            "title": require_text(raw.get("title"), f"milestones[{index}].title"),
            "description": optional_text(raw.get("description"), f"milestones[{index}].description"),
            "acceptance_criteria": json_text(raw.get("acceptance_criteria"), f"milestones[{index}].acceptance_criteria", []),
            "target_date": optional_text(raw.get("target_date"), f"milestones[{index}].target_date"),
            "status": status,
            "phase_order": phase_order,
        })

    ensure_unique(milestone_ids, "milestone ids")
    payload_milestone_ids = set(milestone_ids)
    existing_milestones = set(existing_ids(conn, "milestones", milestone_ids))

    tasks = []
    task_ids = []
    parent_refs = {}
    dependency_refs = []
    for index, raw in enumerate(tasks_raw, start=1):
        if not isinstance(raw, dict):
            fail(f"tasks[{index}] must be an object.")
        task_id = validate_id(raw.get("id"), f"tasks[{index}].id")
        task_type = raw.get("type", "feature")
        if task_type == "task":
            task_type = "feature"
        if task_type not in TASK_TYPES:
            fail(f"tasks[{index}].type must be one of: {', '.join(sorted(TASK_TYPES))}")
        status = raw.get("status", "planned")
        if status not in TASK_STATUSES:
            fail(f"tasks[{index}].status must be one of: {', '.join(sorted(TASK_STATUSES))}")
        priority = raw.get("priority", "medium")
        if priority not in PRIORITIES:
            fail(f"tasks[{index}].priority must be one of: {', '.join(sorted(PRIORITIES))}")

        parent_id = raw.get("parent_id")
        if parent_id is not None:
            parent_id = validate_id(parent_id, f"tasks[{index}].parent_id")
            parent_refs[task_id] = parent_id

        milestone_id = raw.get("milestone_id")
        if milestone_id is not None:
            milestone_id = validate_id(milestone_id, f"tasks[{index}].milestone_id")
            if milestone_id not in payload_milestone_ids and milestone_id not in existing_milestones:
                fail(f"tasks[{index}].milestone_id references missing milestone: {milestone_id}")

        dependencies = raw.get("dependencies", [])
        if dependencies is None:
            dependencies = []
        if not isinstance(dependencies, list):
            fail(f"tasks[{index}].dependencies must be a list.")
        for dependency in dependencies:
            dependency_refs.append(validate_id(dependency, f"tasks[{index}].dependencies item"))

        dependency_types = raw.get("dependency_types", {})
        if dependency_types is None:
            dependency_types = {}
        if not isinstance(dependency_types, dict):
            fail(f"tasks[{index}].dependency_types must be an object.")
        for dep_id, dep_type in dependency_types.items():
            validate_id(dep_id, f"tasks[{index}].dependency_types key")
            if dep_type not in DEPENDENCY_TYPES:
                fail(f"tasks[{index}].dependency_types[{dep_id}] must be hard or soft.")

        complexity_scale = raw.get("complexity_scale")
        if complexity_scale is not None and complexity_scale not in COMPLEXITY_SCALES:
            fail(f"tasks[{index}].complexity_scale must be one of: {', '.join(sorted(COMPLEXITY_SCALES))}")

        moscow = raw.get("moscow")
        if moscow is not None and moscow not in MOSCOW_VALUES:
            fail(f"tasks[{index}].moscow must be one of: {', '.join(sorted(MOSCOW_VALUES))}")

        business_value = optional_int(raw.get("business_value"), f"tasks[{index}].business_value", 1, 5)
        task_ids.append(task_id)
        tasks.append({
            "id": task_id,
            "parent_id": parent_id,
            "title": require_text(raw.get("title"), f"tasks[{index}].title"),
            "description": optional_text(raw.get("description"), f"tasks[{index}].description"),
            "details": optional_text(raw.get("details"), f"tasks[{index}].details"),
            "test_strategy": optional_text(raw.get("test_strategy"), f"tasks[{index}].test_strategy"),
            "status": status,
            "type": task_type,
            "priority": priority,
            "complexity_scale": complexity_scale,
            "complexity_reasoning": optional_text(raw.get("complexity_reasoning"), f"tasks[{index}].complexity_reasoning"),
            "complexity_expansion_prompt": optional_text(raw.get("complexity_expansion_prompt"), f"tasks[{index}].complexity_expansion_prompt"),
            "estimate_seconds": optional_int(raw.get("estimate_seconds"), f"tasks[{index}].estimate_seconds", 0),
            "duration_seconds": optional_int(raw.get("duration_seconds"), f"tasks[{index}].duration_seconds", 0),
            "owner": optional_text(raw.get("owner"), f"tasks[{index}].owner"),
            "tags": json_text(raw.get("tags"), f"tasks[{index}].tags", []),
            "dependencies": json.dumps(dependencies, sort_keys=True, separators=(",", ":")),
            "dependency_types": json.dumps(dependency_types, sort_keys=True, separators=(",", ":")),
            "milestone_id": milestone_id,
            "acceptance_criteria": json_text(raw.get("acceptance_criteria"), f"tasks[{index}].acceptance_criteria", []),
            "moscow": moscow,
            "business_value": business_value,
        })

    ensure_unique(task_ids, "task ids")
    payload_task_ids = set(task_ids)
    existing_tasks = active_task_ids(conn, set(parent_refs.values()) | set(dependency_refs))

    for child_id, parent_id in parent_refs.items():
        if parent_id not in payload_task_ids and parent_id not in existing_tasks:
            fail(f"task parent reference is missing or inactive: {child_id} -> {parent_id}")

    for dependency_id in dependency_refs:
        if dependency_id not in payload_task_ids and dependency_id not in existing_tasks:
            fail(f"task dependency reference is missing or inactive: {dependency_id}")

    for task_id in task_ids:
        seen = set()
        current = task_id
        while current in parent_refs:
            current = parent_refs[current]
            if current in seen or current == task_id:
                fail(f"cyclic parent relationship detected for task: {task_id}")
            seen.add(current)

    memories = []
    memory_ids = []
    for index, raw in enumerate(memories_raw, start=1):
        if not isinstance(raw, dict):
            fail(f"memories[{index}] must be an object.")
        memory_id = raw.get("id")
        if memory_id is None:
            numeric = int(next_prefixed_id(conn, "memories", "M-")[2:])
            while True:
                memory_id = f"M-{numeric:03d}"
                if memory_id not in memory_ids:
                    break
                numeric += 1
        memory_id = validate_id(memory_id, f"memories[{index}].id")
        kind = raw.get("kind", raw.get("type", "decision"))
        if kind not in MEMORY_KINDS:
            fail(f"memories[{index}].kind must be one of: {', '.join(sorted(MEMORY_KINDS))}")
        source_type = raw.get("source_type", "command")
        if source_type not in MEMORY_SOURCES:
            fail(f"memories[{index}].source_type must be one of: {', '.join(sorted(MEMORY_SOURCES))}")
        importance = optional_int(raw.get("importance", 3), f"memories[{index}].importance", 1, 5)
        confidence = optional_float(raw.get("confidence", 0.8), f"memories[{index}].confidence", 0.8, 0, 1)
        memory_ids.append(memory_id)
        memories.append({
            "id": memory_id,
            "title": require_text(raw.get("title"), f"memories[{index}].title"),
            "kind": kind,
            "why_important": require_text(raw.get("why_important", "Manual plan memory persisted by plan-apply."), f"memories[{index}].why_important"),
            "body": require_text(raw.get("body"), f"memories[{index}].body"),
            "source_type": source_type,
            "source_name": optional_text(raw.get("source_name", "taskmanager-engine.sh"), f"memories[{index}].source_name"),
            "source_via": optional_text(raw.get("source_via", "plan-apply"), f"memories[{index}].source_via"),
            "auto_updatable": 0,
            "importance": importance,
            "confidence": confidence,
            "status": "active",
            "scope": json_text(raw.get("scope"), f"memories[{index}].scope", {}),
            "tags": json_text(raw.get("tags"), f"memories[{index}].tags", []),
            "links": json_text(raw.get("links"), f"memories[{index}].links", []),
        })

    ensure_unique(memory_ids, "memory ids")

    plan = {
        "id": plan_id,
        "prd_source": require_text(
            plan_raw.get("prd_source")
            or payload.get("source_description")
            or payload.get("source")
            or "prompt",
            "plan_analyses.prd_source",
        ),
        "prd_hash": optional_text(plan_raw.get("prd_hash", payload.get("source_hash")), "plan_analyses.prd_hash"),
        "tech_stack": json_text(plan_raw.get("tech_stack"), "plan_analyses.tech_stack", []),
        "assumptions": json_text(plan_raw.get("assumptions"), "plan_analyses.assumptions", []),
        "risks": json_text(plan_raw.get("risks"), "plan_analyses.risks", []),
        "ambiguities": json_text(plan_raw.get("ambiguities"), "plan_analyses.ambiguities", []),
        "nfrs": json_text(plan_raw.get("nfrs"), "plan_analyses.nfrs", []),
        "scope_in": optional_text(plan_raw.get("scope_in"), "plan_analyses.scope_in"),
        "scope_out": optional_text(plan_raw.get("scope_out"), "plan_analyses.scope_out"),
        "cross_cutting": json_text(plan_raw.get("cross_cutting"), "plan_analyses.cross_cutting", []),
        "decisions": json_text(plan_raw.get("decisions"), "plan_analyses.decisions", []),
        "milestone_ids": json.dumps(milestone_ids, sort_keys=True, separators=(",", ":")),
        "acceptance_criteria": json_text(plan_raw.get("acceptance_criteria"), "plan_analyses.acceptance_criteria", []),
    }

    duplicate_messages = []
    plan_duplicates = existing_ids(conn, "plan_analyses", [plan_id])
    if plan_duplicates:
        duplicate_messages.append("plan_analyses " + ", ".join(plan_duplicates))
    milestone_duplicates = existing_ids(conn, "milestones", milestone_ids)
    if milestone_duplicates:
        duplicate_messages.append("milestones " + ", ".join(milestone_duplicates))
    task_duplicates = existing_ids(conn, "tasks", task_ids)
    if task_duplicates:
        duplicate_messages.append("tasks " + ", ".join(task_duplicates))
    memory_duplicates = existing_ids(conn, "memories", memory_ids)
    if memory_duplicates:
        duplicate_messages.append("memories " + ", ".join(memory_duplicates))
    if duplicate_messages:
        fail("duplicate persisted id(s): " + "; ".join(duplicate_messages))

    return {"plan": plan, "milestones": milestones, "tasks": tasks, "memories": memories}


def print_validation(normalized: dict) -> None:
    print("Plan payload valid")
    print(f"Plan analysis: {normalized['plan']['id']}")
    print(f"Milestones: {len(normalized['milestones'])}")
    print(f"Tasks: {len(normalized['tasks'])}")
    print(f"Memories: {len(normalized['memories'])}")
    print("Apply mode: clean insert")


def print_preview(normalized: dict) -> None:
    print("Plan preview")
    print(f"Plan analysis: {normalized['plan']['id']} source={normalized['plan']['prd_source']}")
    print(f"Milestones ({len(normalized['milestones'])})")
    for milestone in normalized["milestones"]:
        print(f"  {milestone['id']} [{milestone['status']}] {milestone['title']}")
    print(f"Tasks ({len(normalized['tasks'])})")
    for task in normalized["tasks"]:
        parent = f" parent={task['parent_id']}" if task["parent_id"] else ""
        milestone = f" milestone={task['milestone_id']}" if task["milestone_id"] else ""
        print(f"  {task['id']} [{task['status']}/{task['type']}] {task['title']}{parent}{milestone}")
    print(f"Memories ({len(normalized['memories'])})")
    for memory in normalized["memories"]:
        print(f"  {memory['id']} [{memory['kind']}] {memory['title']}")
    print("Apply mode: clean insert")


def apply_plan(conn: sqlite3.Connection, normalized: dict) -> None:
    plan = normalized["plan"]
    milestones = normalized["milestones"]
    tasks = normalized["tasks"]
    memories = normalized["memories"]

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.execute(
            """
            INSERT INTO plan_analyses (
              id, prd_source, prd_hash, tech_stack, assumptions, risks,
              ambiguities, nfrs, scope_in, scope_out, cross_cutting, decisions,
              milestone_ids, acceptance_criteria
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                plan["id"], plan["prd_source"], plan["prd_hash"], plan["tech_stack"],
                plan["assumptions"], plan["risks"], plan["ambiguities"], plan["nfrs"],
                plan["scope_in"], plan["scope_out"], plan["cross_cutting"],
                plan["decisions"], plan["milestone_ids"], plan["acceptance_criteria"],
            ),
        )
        for milestone in milestones:
            conn.execute(
                """
                INSERT INTO milestones (
                  id, title, description, acceptance_criteria, target_date,
                  status, phase_order
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    milestone["id"], milestone["title"], milestone["description"],
                    milestone["acceptance_criteria"], milestone["target_date"],
                    milestone["status"], milestone["phase_order"],
                ),
            )
        for task in tasks:
            conn.execute(
                """
                INSERT INTO tasks (
                  id, parent_id, title, description, details, test_strategy,
                  status, type, priority, complexity_scale, complexity_reasoning,
                  complexity_expansion_prompt, estimate_seconds, duration_seconds,
                  owner, tags, dependencies, dependency_types, milestone_id,
                  acceptance_criteria, moscow, business_value
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    task["id"], task["parent_id"], task["title"], task["description"],
                    task["details"], task["test_strategy"], task["status"], task["type"],
                    task["priority"], task["complexity_scale"], task["complexity_reasoning"],
                    task["complexity_expansion_prompt"], task["estimate_seconds"],
                    task["duration_seconds"], task["owner"], task["tags"],
                    task["dependencies"], task["dependency_types"], task["milestone_id"],
                    task["acceptance_criteria"], task["moscow"], task["business_value"],
                ),
            )
        for memory in memories:
            conn.execute(
                """
                INSERT INTO memories (
                  id, title, kind, why_important, body, source_type, source_name,
                  source_via, auto_updatable, importance, confidence, status,
                  scope, tags, links
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    memory["id"], memory["title"], memory["kind"], memory["why_important"],
                    memory["body"], memory["source_type"], memory["source_name"],
                    memory["source_via"], memory["auto_updatable"], memory["importance"],
                    memory["confidence"], memory["status"], memory["scope"],
                    memory["tags"], memory["links"],
                ),
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise

    print("Plan apply inserted")
    print("plan_analyses inserted: 1")
    print(f"milestones inserted: {len(milestones)}")
    print(f"tasks inserted: {len(tasks)}")
    print(f"memories inserted: {len(memories)}")
    print(f"Plan analysis: {plan['id']}")


payload = read_payload(PAYLOAD_PATH)
readonly = MODE in {"validate", "preview"}
conn = connect_readonly(DB_PATH) if readonly else connect_writable(DB_PATH)

try:
    normalized = normalize_payload(conn, payload)
    if MODE == "validate":
        print_validation(normalized)
    elif MODE == "preview":
        print_preview(normalized)
    elif MODE == "apply":
        apply_plan(conn, normalized)
    else:
        fail(f"unknown plan mode: {MODE}", 2)
except sqlite3.Error as exc:
    fail(f"SQLite failure: {exc}")
finally:
    conn.close()
PY
}

cmd_plan_validate() {
    [[ $# -eq 2 ]] || die "plan-validate requires PROJECT_DIR PLAN_JSON." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"
    local plan_json="$2"

    require_sqlite
    require_python3
    local db
    db="$(require_initialized_db "$project")"
    plan_payload validate "$db" "$plan_json"
}

cmd_plan_preview() {
    [[ $# -eq 2 ]] || die "plan-preview requires PROJECT_DIR PLAN_JSON." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"
    local plan_json="$2"

    require_sqlite
    require_python3
    local db
    db="$(require_initialized_db "$project")"
    plan_payload preview "$db" "$plan_json"
}

cmd_plan_apply() {
    [[ $# -eq 2 ]] || die "plan-apply requires PROJECT_DIR PLAN_JSON." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"
    local plan_json="$2"

    require_sqlite
    require_python3
    local db
    db="$(require_initialized_db "$project")"
    plan_payload apply "$db" "$plan_json"
}

cmd_task_add() {
    [[ $# -ge 3 ]] || die "task-add requires PROJECT_DIR TASK_ID TITLE [TYPE] [STATUS] [PARENT_ID]." "$EXIT_USAGE"
    [[ $# -le 6 ]] || die "task-add accepts PROJECT_DIR, TASK_ID, TITLE, optional TYPE, optional STATUS, and optional PARENT_ID." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    local parent_id=""
    if [[ $# -eq 6 ]]; then
        parent_id="$6"
        validate_task_id "$parent_id" "PARENT_ID"
    fi

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    task_add "$db" "$2" "$3" "${4:-feature}" "${5:-planned}" "$parent_id"
}

cmd_task_set_status() {
    [[ $# -eq 3 ]] || die "task-set-status requires PROJECT_DIR TASK_ID STATUS." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    task_set_status "$db" "$2" "$3"
}

cmd_task_update_title() {
    [[ $# -eq 3 ]] || die "task-update-title requires PROJECT_DIR TASK_ID TITLE." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    task_update_title "$db" "$2" "$3"
}

cmd_task_archive() {
    [[ $# -eq 2 ]] || die "task-archive requires PROJECT_DIR TASK_ID." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    task_archive "$db" "$2"
}

cmd_memory_list() {
    [[ $# -ge 1 ]] || die "memory-list requires PROJECT_DIR [limit]." "$EXIT_USAGE"
    [[ $# -le 2 ]] || die "memory-list accepts PROJECT_DIR and optional limit." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    memory_list "$db" "${2:-20}"
}

cmd_memory_show() {
    [[ $# -eq 2 ]] || die "memory-show requires PROJECT_DIR MEMORY_ID." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    memory_show "$db" "$2"
}

cmd_memory_search() {
    [[ $# -ge 2 ]] || die "memory-search requires PROJECT_DIR QUERY [limit]." "$EXIT_USAGE"
    [[ $# -le 3 ]] || die "memory-search accepts PROJECT_DIR, QUERY, and optional limit." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    memory_search "$db" "$2" "${3:-20}"
}

cmd_memory_add() {
    [[ $# -ge 4 ]] || die "memory-add requires PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]." "$EXIT_USAGE"
    [[ $# -le 6 ]] || die "memory-add accepts PROJECT_DIR, TYPE, TITLE, BODY, optional IMPORTANCE, and optional CONFIDENCE." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    memory_add "$db" "$2" "$3" "$4" "${5:-3}" "${6:-0.8}"
}

cmd_memory_deprecate() {
    [[ $# -eq 3 ]] || die "memory-deprecate requires PROJECT_DIR MEMORY_ID REASON." "$EXIT_USAGE"

    local project
    project="$(project_path "$1")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"
    memory_deprecate "$db" "$2" "$3"
}

cmd_show() {
    [[ $# -ge 1 ]] || show_usage_error

    local project
    project="$(project_path "$1")"
    shift

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"

    local view="${1:-overview}"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$view" in
        overview)
            [[ $# -eq 0 ]] || die "show overview does not accept extra arguments." "$EXIT_USAGE"
            show_overview "$project" "$db"
            ;;
        tasks)
            [[ $# -le 1 ]] || die "show tasks accepts at most one limit argument." "$EXIT_USAGE"
            show_tasks "$db" "${1:-20}"
            ;;
        task)
            [[ $# -eq 1 ]] || die "show task requires TASK_ID." "$EXIT_USAGE"
            show_task "$db" "$1"
            ;;
        milestones)
            [[ $# -le 1 ]] || die "show milestones accepts at most one limit argument." "$EXIT_USAGE"
            show_milestones "$db" "${1:-20}"
            ;;
        memories)
            [[ $# -le 1 ]] || die "show memories accepts at most one limit argument." "$EXIT_USAGE"
            show_memories "$db" "${1:-20}"
            ;;
        verifications)
            [[ $# -le 1 ]] || die "show verifications accepts at most one TASK_ID argument." "$EXIT_USAGE"
            show_verifications "$db" "${1:-}"
            ;;
        regressions)
            [[ $# -le 1 ]] || die "show regressions accepts at most one TARGET_ID argument." "$EXIT_USAGE"
            show_regressions "$db" "${1:-}"
            ;;
        deferrals)
            [[ $# -le 1 ]] || die "show deferrals accepts at most one limit argument." "$EXIT_USAGE"
            show_deferrals "$db" "${1:-20}"
            ;;
        *)
            die "unknown show view: $view" "$EXIT_USAGE"
            ;;
    esac
}

cmd_next() {
    local project
    project="$(project_path "${1:-$PWD}")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"

    view_exists "$db" "v_next_task" || die "v_next_task view does not exist in $db."

    local available
    available="$(sqlite3 -readonly "$db" "SELECT COUNT(*) FROM v_next_task;")"
    if [[ "$available" == "0" ]]; then
        printf 'No next tasks available.\n'
        return 0
    fi

    sqlite3 -readonly -header -column "$db" "
SELECT id, title, status, priority, COALESCE(milestone_id, '') AS milestone_id
FROM v_next_task
LIMIT 10;"
}

cmd_export_json() {
    local project
    project="$(project_path "${1:-$PWD}")"

    require_sqlite
    local db
    db="$(require_initialized_db "$project")"

    sqlite_has_json "$db" || die "sqlite3 JSON functions are required for export-json; this sqlite3 build does not provide them."

    sqlite3 -readonly "$db" <<'SQL'
SELECT json_object(
  'schema_version', COALESCE((SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1), 'unknown'),
  'tasks', json(COALESCE((
      SELECT json_group_array(json_object(
        'id', id,
        'parent_id', parent_id,
        'title', title,
        'status', status,
        'type', type,
        'priority', priority,
        'milestone_id', milestone_id,
        'dependencies', dependencies,
        'acceptance_criteria', acceptance_criteria,
        'created_at', created_at,
        'updated_at', updated_at
      ))
      FROM (SELECT * FROM tasks ORDER BY id)
    ), '[]')),
  'milestones', json(COALESCE((
      SELECT json_group_array(json_object(
        'id', id,
        'title', title,
        'status', status,
        'phase_order', phase_order,
        'acceptance_criteria', acceptance_criteria,
        'created_at', created_at,
        'updated_at', updated_at
      ))
      FROM (SELECT * FROM milestones ORDER BY phase_order, id)
    ), '[]')),
  'memories', json(COALESCE((
      SELECT json_group_array(json_object(
        'id', id,
        'title', title,
        'kind', kind,
        'importance', importance,
        'confidence', confidence,
        'status', status,
        'tags', tags,
        'created_at', created_at,
        'updated_at', updated_at
      ))
      FROM (SELECT * FROM memories ORDER BY id)
    ), '[]')),
  'verifications', json(COALESCE((
      SELECT json_group_array(json_object(
        'id', id,
        'target_type', target_type,
        'target_id', target_id,
        'criterion_index', criterion_index,
        'status', status,
        'method', method,
        'attempt', attempt,
        'created_at', created_at
      ))
      FROM (SELECT * FROM verifications ORDER BY target_type, target_id, attempt, id)
    ), '[]')),
  'regression_checks', json(COALESCE((
      SELECT json_group_array(json_object(
        'id', id,
        'target_type', target_type,
        'target_id', target_id,
        'status', status,
        'verified_by', verified_by,
        'attempt', attempt,
        'created_at', created_at
      ))
      FROM (SELECT * FROM regression_checks ORDER BY target_type, target_id, attempt, id)
    ), '[]'))
);
SQL
}

cmd_run_sql_tests() {
    require_sqlite
    require_engine_files

    (
        cd "$ENGINE_DIR"
        printf 'Running copied TaskManager SQL query tests...\n'
        bash tests/test_sql_queries.sh
        printf '\nRunning copied TaskManager lifecycle E2E tests...\n'
        bash tests/test_lifecycle_e2e.sh
    )
}

main() {
    local command="${1:-help}"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$command" in
        init)
            [[ $# -le 1 ]] || die "init accepts at most one PROJECT_DIR argument." "$EXIT_USAGE"
            cmd_init "${1:-$PWD}"
            ;;
        status)
            [[ $# -le 1 ]] || die "status accepts at most one PROJECT_DIR argument." "$EXIT_USAGE"
            cmd_status "${1:-$PWD}"
            ;;
        next)
            [[ $# -le 1 ]] || die "next accepts at most one PROJECT_DIR argument." "$EXIT_USAGE"
            cmd_next "${1:-$PWD}"
            ;;
        show)
            [[ $# -ge 1 ]] || show_usage_error
            cmd_show "$@"
            ;;
        task-add)
            cmd_task_add "$@"
            ;;
        task-set-status)
            cmd_task_set_status "$@"
            ;;
        task-update-title)
            cmd_task_update_title "$@"
            ;;
        task-archive)
            cmd_task_archive "$@"
            ;;
        memory-list)
            cmd_memory_list "$@"
            ;;
        memory-show)
            cmd_memory_show "$@"
            ;;
        memory-search)
            cmd_memory_search "$@"
            ;;
        memory-add)
            cmd_memory_add "$@"
            ;;
        memory-deprecate)
            cmd_memory_deprecate "$@"
            ;;
        plan-validate)
            cmd_plan_validate "$@"
            ;;
        plan-preview)
            cmd_plan_preview "$@"
            ;;
        plan-apply)
            cmd_plan_apply "$@"
            ;;
        export-json)
            [[ $# -le 1 ]] || die "export-json accepts at most one PROJECT_DIR argument." "$EXIT_USAGE"
            cmd_export_json "${1:-$PWD}"
            ;;
        run-sql-tests)
            [[ $# -eq 0 ]] || die "run-sql-tests does not accept arguments." "$EXIT_USAGE"
            cmd_run_sql_tests
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            usage >&2
            die "unknown command: $command" "$EXIT_USAGE"
            ;;
    esac
}

main "$@"
