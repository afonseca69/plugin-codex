-- Taskmanager SQLite Schema v4.2.0
-- This file defines the complete database structure

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Milestones table
CREATE TABLE IF NOT EXISTS milestones (
    id TEXT PRIMARY KEY,                -- "MS-001", "MS-002"
    title TEXT NOT NULL,
    description TEXT,
    acceptance_criteria TEXT DEFAULT '[]',  -- JSON: what "done" means for this milestone
    target_date TEXT,                   -- ISO 8601 (optional)
    status TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN ('planned', 'active', 'completed', 'canceled')),
    phase_order INTEGER NOT NULL,       -- 1, 2, 3... determines execution sequence
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_milestones_status ON milestones(status);
CREATE INDEX IF NOT EXISTS idx_milestones_order ON milestones(phase_order);

-- Plan analyses table
CREATE TABLE IF NOT EXISTS plan_analyses (
    id TEXT PRIMARY KEY,                -- "PA-001", "PA-002"
    prd_source TEXT NOT NULL,           -- file path, folder path, or "prompt"
    prd_hash TEXT,                      -- SHA-256 for change detection
    tech_stack TEXT DEFAULT '[]',       -- JSON: detected technologies
    assumptions TEXT DEFAULT '[]',      -- JSON: [{description, confidence, impact}]
    risks TEXT DEFAULT '[]',            -- JSON: [{description, severity, likelihood, mitigation}]
    ambiguities TEXT DEFAULT '[]',      -- JSON: [{requirement, question, resolution}]
    nfrs TEXT DEFAULT '[]',             -- JSON: [{category, requirement, priority}]
    scope_in TEXT,
    scope_out TEXT,
    cross_cutting TEXT DEFAULT '[]',    -- JSON: [{concern, affected_epics, strategy}]
    decisions TEXT DEFAULT '[]',        -- JSON: [{question, answer, rationale, memory_id}]
    milestone_ids TEXT DEFAULT '[]',    -- JSON: milestone IDs created from this analysis
    acceptance_criteria TEXT DEFAULT '[]',  -- JSON: PRD-level acceptance criteria (what "done" means for the whole PRD)
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_plan_analyses_hash ON plan_analyses(prd_hash);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    parent_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    details TEXT,
    test_strategy TEXT,
    status TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN ('draft', 'planned', 'in-progress', 'blocked', 'paused', 'done', 'canceled', 'duplicate', 'needs-review')),
    type TEXT NOT NULL DEFAULT 'feature'
        CHECK (type IN ('feature', 'bug', 'chore', 'analysis', 'spike')),
    priority TEXT NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    complexity_scale TEXT CHECK (complexity_scale IN ('XS', 'S', 'M', 'L', 'XL')),
    complexity_reasoning TEXT,
    complexity_expansion_prompt TEXT,
    estimate_seconds INTEGER,
    duration_seconds INTEGER,
    owner TEXT,

    -- Timestamps
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    started_at TEXT,
    completed_at TEXT,
    archived_at TEXT,

    -- Flexible storage (JSON)
    tags TEXT DEFAULT '[]',
    dependencies TEXT DEFAULT '[]',
    dependency_analysis TEXT,                -- reserved/unused (not currently written or read)
    meta TEXT DEFAULT '{}',                  -- reserved/unused (not currently written or read)

    -- v4.0.0 additions
    milestone_id TEXT REFERENCES milestones(id),
    acceptance_criteria TEXT DEFAULT '[]',   -- JSON: what "done" means (product perspective)
    moscow TEXT CHECK (moscow IN ('must', 'should', 'could', 'wont')),
    business_value INTEGER CHECK (business_value BETWEEN 1 AND 5),
    dependency_types TEXT DEFAULT '{}'       -- JSON: {"1.1": "hard", "1.2": "soft"}
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_parent ON tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_archived ON tasks(archived_at);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_milestone ON tasks(milestone_id);

-- Memories table
CREATE TABLE IF NOT EXISTS memories (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    kind TEXT NOT NULL
        CHECK (kind IN ('constraint', 'decision', 'bugfix', 'workaround', 'convention', 'architecture', 'process', 'integration', 'anti-pattern', 'other')),
    why_important TEXT NOT NULL,
    body TEXT NOT NULL,

    -- Ownership
    source_type TEXT NOT NULL CHECK (source_type IN ('user', 'agent', 'command', 'hook', 'other')),
    source_name TEXT,
    source_via TEXT,
    auto_updatable INTEGER DEFAULT 1,

    -- Scoring
    importance INTEGER NOT NULL DEFAULT 3 CHECK (importance BETWEEN 1 AND 5),
    confidence REAL NOT NULL DEFAULT 0.8 CHECK (confidence BETWEEN 0 AND 1),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deprecated', 'superseded', 'draft')),
    superseded_by TEXT REFERENCES memories(id),

    -- Scope (JSON)
    scope TEXT DEFAULT '{}',
    tags TEXT DEFAULT '[]',
    links TEXT DEFAULT '[]',

    -- Usage
    use_count INTEGER DEFAULT 0,
    last_used_at TEXT,
    last_conflict_at TEXT,
    conflict_resolutions TEXT DEFAULT '[]',

    -- Timestamps
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

-- Full-text search for memories
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
    title, body, tags,
    content='memories',
    content_rowid='rowid'
);

-- FTS sync triggers
CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
    INSERT INTO memories_fts(rowid, title, body, tags)
    VALUES (NEW.rowid, NEW.title, NEW.body, NEW.tags);
END;

CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, title, body, tags)
    VALUES('delete', OLD.rowid, OLD.title, OLD.body, OLD.tags);
END;

CREATE TRIGGER IF NOT EXISTS memories_au AFTER UPDATE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, title, body, tags)
    VALUES('delete', OLD.rowid, OLD.title, OLD.body, OLD.tags);
    INSERT INTO memories_fts(rowid, title, body, tags)
    VALUES (NEW.rowid, NEW.title, NEW.body, NEW.tags);
END;

-- Deferrals table
CREATE TABLE IF NOT EXISTS deferrals (
    id TEXT PRIMARY KEY,                -- Format: D-0001, D-0002, ...
    source_task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE RESTRICT,
    target_task_id TEXT REFERENCES tasks(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'applied', 'reassigned', 'canceled')),
    applied_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_deferrals_target ON deferrals(target_task_id, status);
CREATE INDEX IF NOT EXISTS idx_deferrals_source ON deferrals(source_task_id);
CREATE INDEX IF NOT EXISTS idx_deferrals_status ON deferrals(status);

-- Verifications table (v4.1.0): records per-criterion verification outcomes (history)
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

-- State table (single row)
CREATE TABLE IF NOT EXISTS state (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    current_task_id TEXT REFERENCES tasks(id),
    task_memory TEXT DEFAULT '[]',
    debug_enabled INTEGER DEFAULT 0,
    session_id TEXT,
    started_at TEXT,
    last_update TEXT
);

-- Initialize state with single row
INSERT OR IGNORE INTO state (id) VALUES (1);

-- ============================================================================
-- Views (v4.1.0)
-- ============================================================================

-- Canonical "next available task" selection: milestone-aware, dependency-type-aware.
-- Callers should use: SELECT * FROM v_next_task LIMIT N;
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

-- Sequential execution mode (execution_mode='sequential'): identical to v_next_task
-- but strictly gated to the active/first-planned milestone. Since all rows share the
-- same milestone, the milestone-preference CASE is dropped from the ORDER BY.
-- Callers should use: SELECT * FROM v_next_task_sequential LIMIT N;
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

-- Per-task verification roll-up over the task's acceptance_criteria (JSON array of strings).
-- Enumerates each criterion by index, then LEFT JOINs the latest-attempt verifications row
-- per (target_id, criterion_index). Tasks with empty acceptance_criteria ('[]') return 0 rows.
-- is_verified = 1 only when EVERY criterion's latest-attempt row has status in ('met','overridden').
-- NOTE: the met/failed/pending columns EXCLUDE overrides; overrides are counted separately
-- in the `overridden` column. is_verified still counts overridden as satisfying a criterion.
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

-- Per-milestone verification roll-up over milestones.acceptance_criteria (JSON array of strings).
-- Enumerates each criterion by index, then LEFT JOINs the latest-attempt verifications row
-- per (target_type='milestone', target_id=milestone.id, criterion_index). Milestones with
-- empty acceptance_criteria ('[]') return 0 rows. satisfied counts met/overridden;
-- is_verified = 1 only when total_criteria > 0 AND satisfied = total_criteria.
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

-- Per-PRD verification roll-up over plan_analyses.acceptance_criteria (JSON array of strings).
-- Same shape as v_milestone_verification, keyed by plan_analyses.id with target_type='prd'.
-- Plan analyses with empty acceptance_criteria ('[]') return 0 rows.
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

-- Per-milestone status roll-up. derived_status is for display only and does NOT
-- mutate milestones.status: 'active' if any scoped task is in-progress, 'completed'
-- if all scoped tasks are terminal (done/canceled/duplicate) and there is at least one,
-- else 'planned'.
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

-- ============================================================================
-- Regression checks (v4.2.0)
-- ============================================================================
-- Change-level "did this break existing work?" verdicts produced by
-- maestro:regression (run the suite + a bounded blast-radius probe vs
-- docs/architecture/ contracts + honest coverage). Distinct from the
-- per-criterion `verifications` table: a regression verdict is about a CHANGE,
-- not an acceptance criterion, so it has no criterion_index and its own rollup.
-- The done-gate reads v_task_regression and blocks `done` on a non-pass verdict.
CREATE TABLE IF NOT EXISTS regression_checks (
    id TEXT PRIMARY KEY,                                  -- RC-NNNN
    target_type TEXT NOT NULL CHECK (target_type IN ('task','milestone','commit')),
    target_id TEXT NOT NULL,                              -- task id / milestone id / commit-or-diff hash
    status TEXT NOT NULL CHECK (status IN ('pass','fail','overridden')),
    suite_json TEXT,                                      -- {ran, passed, failed, output_ref}
    blast_radius_json TEXT,                               -- [{contract, risk, evidence}]
    coverage_json TEXT,                                   -- {changed_untested: [...], characterized: [...]}
    verdict_reasoning TEXT,
    verified_by TEXT,                                     -- 'maestro:regression' (or 'taskmanager' degraded suite-only)
    attempt INTEGER NOT NULL DEFAULT 1,                   -- max+1 per (target_type, target_id)
    override_reason TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    -- override_reason is present iff status is 'overridden' (mirrors verifications)
    CHECK ((status = 'overridden') = (override_reason IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS idx_regression_target ON regression_checks(target_type, target_id);

-- Latest regression verdict per task. The done-gate treats latest_status IN
-- ('pass','overridden') as satisfied; 'fail' or NULL (never run) blocks `done`.
-- There is no criterion_index to key on, so "latest" = most recent attempt,
-- then created_at, then rowid (same tiebreak the verification views use).
CREATE VIEW IF NOT EXISTS v_task_regression AS
SELECT d.target_id AS task_id,
       (SELECT r.status FROM regression_checks r
         WHERE r.target_type = 'task' AND r.target_id = d.target_id
         ORDER BY r.attempt DESC, r.created_at DESC, r.rowid DESC
         LIMIT 1) AS latest_status
FROM (SELECT DISTINCT target_id FROM regression_checks WHERE target_type = 'task') d;

-- Schema version tracking
CREATE TABLE IF NOT EXISTS schema_version (
    version TEXT PRIMARY KEY,
    applied_at TEXT DEFAULT (datetime('now'))
);

INSERT OR IGNORE INTO schema_version (version) VALUES ('4.2.0');
