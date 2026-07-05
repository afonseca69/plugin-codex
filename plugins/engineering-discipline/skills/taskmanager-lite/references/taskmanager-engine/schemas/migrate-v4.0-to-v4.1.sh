#!/usr/bin/env bash
# migrate-v4.0-to-v4.1.sh - Migrate taskmanager from SQLite v4.0.0 to v4.1.0
#
# Usage: migrate-v4.0-to-v4.1.sh [TASKMANAGER_DIR]
#   TASKMANAGER_DIR: Path to .taskmanager directory (default: .taskmanager)
#
# This migration is ADDITIVE ONLY (no data loss) and idempotent. It:
#   - Backs up the v4.0.0 database to backup-v4.0/
#   - Creates the verifications table + idx_verifications_target index
#   - Adds the plan_analyses.acceptance_criteria column (guarded)
#   - Creates the v_next_task, v_next_task_sequential, v_task_verification,
#     v_milestone_verification, v_prd_verification, and v_milestone_status views
#   - Inserts/updates schema version to 4.1.0

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

TASKMANAGER_DIR="${1:-.taskmanager}"
DB_FILE="$TASKMANAGER_DIR/taskmanager.db"
BACKUP_DIR="$TASKMANAGER_DIR/backup-v4.0"

# Colors
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
    error "Database not found at $DB_FILE"
    exit 1
fi

# Check current version
CURRENT_VERSION=$(sqlite3 "$DB_FILE" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;" 2>/dev/null || echo "unknown")
if [[ "$CURRENT_VERSION" == "4.1.0" ]]; then
    info "Database is already at v4.1.0; nothing to do."
    exit 0
fi
if [[ "$CURRENT_VERSION" != "4.0.0" ]]; then
    error "Expected schema version 4.0.0, found: $CURRENT_VERSION"
    error "This migration only works on v4.0.0 databases."
    exit 1
fi

# ============================================================================
# Backup
# ============================================================================

info "Backing up database to $BACKUP_DIR/"
mkdir -p "$BACKUP_DIR"
# Don't clobber an existing pre-migration backup on a re-run (e.g. after a partial/
# interrupted migration) — the original clean snapshot must survive.
if [[ -f "$BACKUP_DIR/taskmanager.db.bak" ]]; then
    info "Pre-migration backup already exists; keeping it (not overwriting)."
else
    cp "$DB_FILE" "$BACKUP_DIR/taskmanager.db.bak"
fi

if [[ -f "$TASKMANAGER_DIR/config.json" ]]; then
    cp "$TASKMANAGER_DIR/config.json" "$BACKUP_DIR/config.json.bak"
fi

info "Backup complete."

# ============================================================================
# Migration
# ============================================================================

info "Starting migration v4.0.0 -> v4.1.0..."

# Guarded column add: plan_analyses.acceptance_criteria (only if absent).
# Done outside the main transaction because v_prd_verification references this
# column at CREATE time, and ALTER TABLE ADD COLUMN cannot be made conditional
# inside a single SQL script. pragma_table_info gives us the existence check.
HAS_PA_AC=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM pragma_table_info('plan_analyses') WHERE name = 'acceptance_criteria';")
if [[ "$HAS_PA_AC" == "0" ]]; then
    info "Adding plan_analyses.acceptance_criteria column..."
    sqlite3 "$DB_FILE" "ALTER TABLE plan_analyses ADD COLUMN acceptance_criteria TEXT DEFAULT '[]';"
else
    info "plan_analyses.acceptance_criteria already present; skipping column add."
fi

sqlite3 "$DB_FILE" <<'SQL'
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- 1. Create verifications table (records per-criterion verification outcomes)
CREATE TABLE IF NOT EXISTS verifications (
  id TEXT PRIMARY KEY,
  target_type TEXT NOT NULL CHECK (target_type IN ('task','milestone','prd')),
  target_id TEXT NOT NULL,
  criterion TEXT NOT NULL,
  criterion_index INTEGER,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','met','failed','overridden')),
  method TEXT CHECK (method IN ('self','adversarial')),
  evidence TEXT,
  verdict_reasoning TEXT,
  verified_by TEXT,
  attempt INTEGER NOT NULL DEFAULT 1,
  override_reason TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  CHECK ((status = 'overridden') = (override_reason IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_verifications_target ON verifications(target_type, target_id, status);

-- 2. Create v_next_task view (canonical next-available-task selection)
CREATE VIEW IF NOT EXISTS v_next_task AS
WITH done_ids AS (SELECT id FROM tasks WHERE status IN ('done','canceled','duplicate')),
active_milestone AS (SELECT id FROM milestones WHERE status IN ('active','planned') ORDER BY CASE status WHEN 'active' THEN 0 ELSE 1 END, phase_order LIMIT 1)
SELECT t.* FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done','canceled','duplicate','blocked','needs-review','paused','draft')
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value),'hard') = 'hard')
ORDER BY
  CASE WHEN t.milestone_id = (SELECT id FROM active_milestone) THEN 0 WHEN t.milestone_id IS NOT NULL THEN 1 ELSE 2 END,
  CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
  COALESCE(t.business_value,3) DESC,
  CASE t.complexity_scale WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 2 END,
  t.id;

-- 2b. Create v_next_task_sequential view (execution_mode='sequential': gated to active milestone)
CREATE VIEW IF NOT EXISTS v_next_task_sequential AS
WITH done_ids AS (SELECT id FROM tasks WHERE status IN ('done','canceled','duplicate')),
active_milestone AS (SELECT id FROM milestones WHERE status IN ('active','planned') ORDER BY CASE status WHEN 'active' THEN 0 ELSE 1 END, phase_order LIMIT 1)
SELECT t.* FROM tasks t
WHERE t.archived_at IS NULL
  AND t.status NOT IN ('done','canceled','duplicate','blocked','needs-review','paused','draft')
  AND (t.milestone_id = (SELECT id FROM active_milestone)
       OR NOT EXISTS (SELECT 1 FROM milestones WHERE status IN ('active','planned')))
  AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
  AND NOT EXISTS (
    SELECT 1 FROM json_each(t.dependencies) d
    WHERE d.value NOT IN (SELECT id FROM done_ids)
      AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value),'hard') = 'hard')
ORDER BY
  CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
  COALESCE(t.business_value,3) DESC,
  CASE t.complexity_scale WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 2 END,
  t.id;

-- 3. Create v_task_verification view (per-task acceptance-criteria roll-up)
CREATE VIEW IF NOT EXISTS v_task_verification AS
WITH criteria AS (
    SELECT t.id AS task_id, ac.key AS criterion_index, ac.value AS criterion
    FROM tasks t, json_each(t.acceptance_criteria) ac
),
latest AS (
    SELECT
        c.task_id,
        c.criterion_index,
        (SELECT v.status FROM verifications v
         WHERE v.target_type = 'task'
           AND v.target_id = c.task_id
           AND v.criterion_index = c.criterion_index
         ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC
         LIMIT 1) AS status
    FROM criteria c
)
SELECT
    task_id,
    COUNT(*) AS total_criteria,
    SUM(CASE WHEN status = 'met' THEN 1 ELSE 0 END) AS met,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status IS NULL OR status = 'pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN status = 'overridden' THEN 1 ELSE 0 END) AS overridden,
    CASE
        WHEN COUNT(*) > 0
         AND SUM(CASE WHEN status IN ('met','overridden') THEN 1 ELSE 0 END) = COUNT(*)
        THEN 1 ELSE 0
    END AS is_verified
FROM latest
GROUP BY task_id;

-- 3b. Per-milestone verification roll-up over milestones.acceptance_criteria
CREATE VIEW IF NOT EXISTS v_milestone_verification AS
WITH criteria AS (
    SELECT m.id AS milestone_id, ac.key AS criterion_index, ac.value AS criterion
    FROM milestones m, json_each(m.acceptance_criteria) ac
),
latest AS (
    SELECT
        c.milestone_id,
        c.criterion_index,
        (SELECT v.status FROM verifications v
         WHERE v.target_type = 'milestone'
           AND v.target_id = c.milestone_id
           AND v.criterion_index = c.criterion_index
         ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC
         LIMIT 1) AS status
    FROM criteria c
)
SELECT
    milestone_id,
    COUNT(*) AS total_criteria,
    SUM(CASE WHEN status IN ('met','overridden') THEN 1 ELSE 0 END) AS satisfied,
    CASE
        WHEN COUNT(*) > 0
         AND SUM(CASE WHEN status IN ('met','overridden') THEN 1 ELSE 0 END) = COUNT(*)
        THEN 1 ELSE 0
    END AS is_verified
FROM latest
GROUP BY milestone_id;

-- 3c. Per-PRD verification roll-up over plan_analyses.acceptance_criteria
CREATE VIEW IF NOT EXISTS v_prd_verification AS
WITH criteria AS (
    SELECT pa.id AS prd_id, ac.key AS criterion_index, ac.value AS criterion
    FROM plan_analyses pa, json_each(pa.acceptance_criteria) ac
),
latest AS (
    SELECT
        c.prd_id,
        c.criterion_index,
        (SELECT v.status FROM verifications v
         WHERE v.target_type = 'prd'
           AND v.target_id = c.prd_id
           AND v.criterion_index = c.criterion_index
         ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC
         LIMIT 1) AS status
    FROM criteria c
)
SELECT
    prd_id,
    COUNT(*) AS total_criteria,
    SUM(CASE WHEN status IN ('met','overridden') THEN 1 ELSE 0 END) AS satisfied,
    CASE
        WHEN COUNT(*) > 0
         AND SUM(CASE WHEN status IN ('met','overridden') THEN 1 ELSE 0 END) = COUNT(*)
        THEN 1 ELSE 0
    END AS is_verified
FROM latest
GROUP BY prd_id;

-- 4. Create v_milestone_status view (per-milestone derived status for display)
CREATE VIEW IF NOT EXISTS v_milestone_status AS
SELECT
    m.id AS milestone_id,
    m.title,
    m.status AS stored_status,
    m.phase_order,
    COUNT(t.id) AS total_tasks,
    SUM(CASE WHEN t.status IN ('done','canceled','duplicate') THEN 1 ELSE 0 END) AS terminal_tasks,
    CASE
        WHEN SUM(CASE WHEN t.status = 'in-progress' THEN 1 ELSE 0 END) > 0 THEN 'active'
        WHEN COUNT(t.id) > 0
         AND SUM(CASE WHEN t.status IN ('done','canceled','duplicate') THEN 1 ELSE 0 END) = COUNT(t.id)
        THEN 'completed'
        ELSE 'planned'
    END AS derived_status
FROM milestones m
LEFT JOIN tasks t ON t.milestone_id = m.id AND t.archived_at IS NULL
GROUP BY m.id, m.title, m.status, m.phase_order;

-- 5. Update schema version (remove the old 4.0.0 row so the latest version is unambiguous)
DELETE FROM schema_version WHERE version = '4.0.0';
INSERT OR REPLACE INTO schema_version (version) VALUES ('4.1.0');

COMMIT;
SQL

info "Database migration complete."

# ============================================================================
# Log entry
# ============================================================================

ACTIVITY_LOG="$TASKMANAGER_DIR/logs/activity.log"
if [[ -f "$ACTIVITY_LOG" ]]; then
    echo "$(date -Iseconds) [DECISION] [migrate-v4.0-to-v4.1] Migrated database from v4.0.0 to v4.1.0 (added verifications table + plan_analyses.acceptance_criteria + 6 views)" >> "$ACTIVITY_LOG"
fi

# ============================================================================
# Config update
# ============================================================================

if [[ -f "$TASKMANAGER_DIR/config.json" ]] && command -v python3 &>/dev/null; then
    info "Updating config.json..."
    python3 -c "
import json
with open('$TASKMANAGER_DIR/config.json') as f:
    c = json.load(f)
c['version'] = '4.1.0'
with open('$TASKMANAGER_DIR/config.json', 'w') as f:
    json.dump(c, f, indent=2)
    f.write('\n')
"
    info "Config updated."
fi

# ============================================================================
# Verification
# ============================================================================

info "Verifying migration..."

NEW_VERSION=$(sqlite3 "$DB_FILE" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")
if [[ "$NEW_VERSION" != "4.1.0" ]]; then
    error "Version check failed: expected 4.1.0, got $NEW_VERSION"
    exit 1
fi

# Verify verifications table exists
TABLE_EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='verifications';")
if [[ "$TABLE_EXISTS" != "1" ]]; then
    error "verifications table not found"
    exit 1
fi

# Verify index exists
IDX_EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_verifications_target';")
if [[ "$IDX_EXISTS" != "1" ]]; then
    error "Index 'idx_verifications_target' not found"
    exit 1
fi

# Verify the plan_analyses.acceptance_criteria column exists
PA_AC_EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM pragma_table_info('plan_analyses') WHERE name = 'acceptance_criteria';")
if [[ "$PA_AC_EXISTS" != "1" ]]; then
    error "plan_analyses.acceptance_criteria column not found"
    exit 1
fi

# Verify views exist
for VIEW in v_next_task v_next_task_sequential v_task_verification v_milestone_verification v_prd_verification v_milestone_status; do
    EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='$VIEW';")
    if [[ "$EXISTS" != "1" ]]; then
        error "View '$VIEW' not found"
        exit 1
    fi
done

echo ""
info "Migration complete! v4.0.0 -> v4.1.0"
info "Backup saved to: $BACKUP_DIR/"
info ""
info "Changes:"
info "  - Added verifications table (per-criterion verification outcomes, history)"
info "  - Added idx_verifications_target index"
info "  - Added plan_analyses.acceptance_criteria column (PRD-level criteria)"
info "  - Added v_next_task view (canonical next-available-task selection)"
info "  - Added v_next_task_sequential view (sequential mode: active-milestone gated)"
info "  - Added v_task_verification view (per-task acceptance-criteria roll-up)"
info "  - Added v_milestone_verification view (per-milestone acceptance-criteria roll-up)"
info "  - Added v_prd_verification view (per-PRD acceptance-criteria roll-up)"
info "  - Added v_milestone_status view (per-milestone derived status)"
info "  - Updated schema version to 4.1.0"
