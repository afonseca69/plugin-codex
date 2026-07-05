#!/usr/bin/env bash
# migrate-v4.1-to-v4.2.sh - Migrate taskmanager from SQLite v4.1.0 to v4.2.0
#
# Usage: migrate-v4.1-to-v4.2.sh [TASKMANAGER_DIR]
#   TASKMANAGER_DIR: Path to .taskmanager directory (default: .taskmanager)
#
# This migration is ADDITIVE ONLY (no data loss) and idempotent. It:
#   - Backs up the v4.1.0 database to backup-v4.1/
#   - Creates the regression_checks table + idx_regression_target index
#   - Creates the v_task_regression view
#   - Inserts schema version 4.2.0
#
# It does NOT touch the verifications table or its views (no CHECK rebuild,
# no view surgery) — the regression gate records change-level verdicts in a
# new, independent table.

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

TASKMANAGER_DIR="${1:-.taskmanager}"
DB_FILE="$TASKMANAGER_DIR/taskmanager.db"
BACKUP_DIR="$TASKMANAGER_DIR/backup-v4.1"
ACTIVITY_LOG="$TASKMANAGER_DIR/logs/activity.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ============================================================================
# Prerequisites
# ============================================================================

if ! command -v sqlite3 &>/dev/null; then
    error "sqlite3 is required but not found. Please install it."
    exit 1
fi

if [[ ! -f "$DB_FILE" ]]; then
    error "No database found at $DB_FILE. Run taskmanager:init first."
    exit 1
fi

CURRENT_VERSION=$(sqlite3 "$DB_FILE" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;" 2>/dev/null || echo "unknown")
if [[ "$CURRENT_VERSION" == "4.2.0" ]]; then
    info "Database is already at v4.2.0; nothing to do."
    exit 0
fi
if [[ "$CURRENT_VERSION" != "4.1.0" ]]; then
    error "Expected a v4.1.0 database but found '$CURRENT_VERSION'."
    error "If you are on v4.0.0, run migrate-v4.0-to-v4.1.sh first."
    exit 1
fi

# ============================================================================
# Backup
# ============================================================================

info "Backing up the v4.1.0 database to $BACKUP_DIR/ ..."
mkdir -p "$BACKUP_DIR"
# Use SQLite's online backup so WAL state is captured consistently.
sqlite3 "$DB_FILE" ".backup '$BACKUP_DIR/taskmanager.db'"

# ============================================================================
# Apply (additive, idempotent)
# ============================================================================

info "Starting migration v4.1.0 -> v4.2.0..."
sqlite3 "$DB_FILE" <<'SQL'
BEGIN;

CREATE TABLE IF NOT EXISTS regression_checks (
    id TEXT PRIMARY KEY,
    target_type TEXT NOT NULL CHECK (target_type IN ('task','milestone','commit')),
    target_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pass','fail','overridden')),
    suite_json TEXT,
    blast_radius_json TEXT,
    coverage_json TEXT,
    verdict_reasoning TEXT,
    verified_by TEXT,
    attempt INTEGER NOT NULL DEFAULT 1,
    override_reason TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    CHECK ((status = 'overridden') = (override_reason IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS idx_regression_target ON regression_checks(target_type, target_id);

CREATE VIEW IF NOT EXISTS v_task_regression AS
SELECT d.target_id AS task_id,
       (SELECT r.status FROM regression_checks r
         WHERE r.target_type = 'task' AND r.target_id = d.target_id
         ORDER BY r.attempt DESC, r.created_at DESC, r.rowid DESC
         LIMIT 1) AS latest_status
FROM (SELECT DISTINCT target_id FROM regression_checks WHERE target_type = 'task') d;

-- Keep exactly one current-version row (matches the v4.0->v4.1 pattern), so the
-- "latest version" query is unambiguous even when applied_at ties on the second.
DELETE FROM schema_version WHERE version = '4.1.0';
INSERT OR REPLACE INTO schema_version (version) VALUES ('4.2.0');

COMMIT;
SQL

# ============================================================================
# Update config version (best-effort; guarded)
# ============================================================================

CONFIG_FILE="$TASKMANAGER_DIR/config.json"
if [[ -f "$CONFIG_FILE" ]] && command -v python3 &>/dev/null; then
    python3 - "$CONFIG_FILE" <<'PY' || warn "Could not update config.json version (non-fatal)."
import json, sys
p = sys.argv[1]
with open(p) as f:
    c = json.load(f)
c['version'] = '4.2.0'
with open(p, 'w') as f:
    json.dump(c, f, indent=2)
    f.write('\n')
PY
fi

# ============================================================================
# Verify
# ============================================================================

NEW_VERSION=$(sqlite3 "$DB_FILE" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
if [[ "$NEW_VERSION" != "4.2.0" ]]; then
    error "Migration did not reach v4.2.0 (found '$NEW_VERSION'). The backup is at $BACKUP_DIR/."
    exit 1
fi

HAS_TABLE=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='regression_checks';")
HAS_VIEW=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_task_regression';")
if [[ "$HAS_TABLE" != "1" || "$HAS_VIEW" != "1" ]]; then
    error "Migration verification failed (regression_checks table or v_task_regression view missing)."
    exit 1
fi

if [[ -f "$ACTIVITY_LOG" ]]; then
    echo "$(date -Iseconds) [DECISION] [migrate-v4.1-to-v4.2] Migrated database from v4.1.0 to v4.2.0 (added regression_checks table + idx + v_task_regression view)" >> "$ACTIVITY_LOG"
fi

info "Migration complete: database is now at v4.2.0."
info "Backup of the v4.1.0 database is at $BACKUP_DIR/."
