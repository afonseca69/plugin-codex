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
  export-json [PROJECT_DIR] Print a JSON export of core tables without mutating data.
  run-sql-tests             Run the copied SQL query and lifecycle test scripts.
  help                      Show this help.

Safety notes:
  - This is an explicit/manual wrapper around copied SQLite artifacts.
  - It does not enable hooks, auto-run tasks, start background jobs, or register Codex commands.
  - Writes are limited to PROJECT_DIR/.taskmanager for init, or temp directories used by tests.
  - init refuses to overwrite an existing PROJECT_DIR/.taskmanager/taskmanager.db.
  - Read-only commands require an initialized PROJECT_DIR/.taskmanager/taskmanager.db.

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

    local version="unknown"
    if table_exists "$db" "schema_version"; then
        version="$(sqlite3 -readonly "$db" "SELECT COALESCE((SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1), 'unknown');")"
    fi

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
