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

Exit codes:
  0    success
  1    runtime or validation failure
  2    usage error
  127  missing sqlite3 dependency
USAGE
}

require_sqlite() {
    command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required for TaskManager engine commands." "$EXIT_DEPENDENCY"
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
