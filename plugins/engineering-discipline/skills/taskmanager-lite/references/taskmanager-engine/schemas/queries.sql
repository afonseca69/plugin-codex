-- Taskmanager Common SQL Queries
-- Reference file for commands to use via sqlite3

-- ============================================================================
-- TASK QUERIES
-- ============================================================================

-- Get task by ID
-- Usage: sqlite3 .taskmanager/taskmanager.db "SELECT * FROM tasks WHERE id = '1.2.3'"

-- Get all active (non-archived) tasks
-- SELECT * FROM tasks WHERE archived_at IS NULL;

-- Get task with subtasks count
-- SELECT t.*, (SELECT COUNT(*) FROM tasks c WHERE c.parent_id = t.id) as subtask_count
-- FROM tasks t WHERE t.id = ?;

-- Get all descendants of a task (recursive)
-- WITH RECURSIVE descendants AS (
--     SELECT * FROM tasks WHERE id = ?
--     UNION ALL
--     SELECT t.* FROM tasks t JOIN descendants d ON t.parent_id = d.id
-- )
-- SELECT * FROM descendants;

-- Get all ancestors of a task (for status propagation)
-- WITH RECURSIVE ancestors AS (
--     SELECT id, parent_id FROM tasks WHERE id = ?
--     UNION ALL
--     SELECT t.id, t.parent_id FROM tasks t JOIN ancestors a ON t.id = a.parent_id
-- )
-- SELECT id FROM ancestors WHERE id != ?;

-- ============================================================================
-- NEXT TASK SELECTION
-- ============================================================================

-- CANONICAL: the milestone-aware, dependency-type-aware "next available task"
-- selection now lives in the v_next_task VIEW (defined in schema.sql).
-- Callers should use the view instead of pasting the CTE:
--   sqlite3 .taskmanager/taskmanager.db "SELECT * FROM v_next_task LIMIT 5;"
-- The view applies the full ordering (active-milestone preference -> priority ->
-- business_value -> complexity -> id) and honors hard vs soft dependency types.
-- v_next_task excludes terminal statuses plus blocked/needs-review/paused/draft
-- (in-progress is intentionally retained so the current task can be re-selected).
-- The two commented queries below are kept for REFERENCE only (do not paste them
-- into commands); v_next_task is the single source of truth.
--
-- SEQUENTIAL MODE: when config milestones.execution_mode = 'sequential', use the
-- v_next_task_sequential VIEW instead. It is identical to v_next_task but strictly
-- gates rows to the active/first-planned milestone (t.milestone_id = active_milestone),
-- and drops the milestone-preference tier from ORDER BY (all rows share one milestone):
--   sqlite3 .taskmanager/taskmanager.db "SELECT * FROM v_next_task_sequential LIMIT 5;"

-- Find next available task (leaf, not done, dependencies satisfied)
-- WITH done_ids AS (
--     SELECT id FROM tasks
--     WHERE status IN ('done', 'canceled', 'duplicate')
-- )
-- SELECT t.* FROM tasks t
-- WHERE t.archived_at IS NULL
--   AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
--   AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
--   AND (
--       t.dependencies = '[]'
--       OR NOT EXISTS (
--           SELECT 1 FROM json_each(t.dependencies) d
--           WHERE d.value NOT IN (SELECT id FROM done_ids)
--       )
--   )
-- ORDER BY
--     CASE t.priority
--         WHEN 'critical' THEN 0
--         WHEN 'high' THEN 1
--         WHEN 'medium' THEN 2
--         ELSE 3
--     END,
--     CASE t.complexity_scale
--         WHEN 'XS' THEN 0
--         WHEN 'S' THEN 1
--         WHEN 'M' THEN 2
--         WHEN 'L' THEN 3
--         WHEN 'XL' THEN 4
--         ELSE 2
--     END
-- LIMIT 1;

-- ============================================================================
-- STATISTICS
-- ============================================================================

-- Task counts by status
-- SELECT status, COUNT(*) as count FROM tasks WHERE archived_at IS NULL GROUP BY status;

-- Task counts by priority
-- SELECT priority, COUNT(*) as count FROM tasks WHERE archived_at IS NULL GROUP BY priority;

-- Completion stats
-- SELECT
--     COUNT(*) as total,
--     SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) as done,
--     SUM(CASE WHEN status = 'in-progress' THEN 1 ELSE 0 END) as in_progress,
--     SUM(CASE WHEN status = 'blocked' THEN 1 ELSE 0 END) as blocked,
--     SUM(CASE WHEN status NOT IN ('done', 'canceled', 'duplicate') THEN 1 ELSE 0 END) as remaining
-- FROM tasks WHERE archived_at IS NULL;

-- Time remaining (sum of leaf task estimates)
-- SELECT COALESCE(SUM(estimate_seconds), 0) as remaining_seconds
-- FROM tasks
-- WHERE archived_at IS NULL
--   AND status NOT IN ('done', 'canceled', 'duplicate')
--   AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id);

-- ============================================================================
-- STATUS PROPAGATION
-- ============================================================================

-- Propagate status to a single parent based on children
-- UPDATE tasks SET
--     status = (
--         SELECT CASE
--             WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'in-progress') THEN 'in-progress'
--             WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'blocked') THEN 'blocked'
--             WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status = 'needs-review') THEN 'needs-review'
--             WHEN EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status IN ('planned', 'draft', 'paused')) THEN 'planned'
--             WHEN NOT EXISTS(SELECT 1 FROM tasks c WHERE c.parent_id = tasks.id AND c.status NOT IN ('done','canceled','duplicate')) THEN 'done'
--             ELSE 'canceled'
--         END
--     ),
--     updated_at = datetime('now')
-- WHERE id = ?;

-- ============================================================================
-- MEMORY QUERIES
-- ============================================================================

-- Full-text search in memories
-- SELECT m.* FROM memories m
-- JOIN memories_fts fts ON m.rowid = fts.rowid
-- WHERE memories_fts MATCH ?
-- ORDER BY rank;

-- Get active memories by importance
-- SELECT * FROM memories WHERE status = 'active' AND importance >= 3 ORDER BY importance DESC;

-- ============================================================================
-- DEFERRAL QUERIES
-- ============================================================================

-- Get pending deferrals targeting a task (for pre-execution loading)
-- SELECT d.id, d.title, d.body, d.reason, d.source_task_id,
--        t.title as source_title
-- FROM deferrals d
-- LEFT JOIN tasks t ON t.id = d.source_task_id
-- WHERE d.target_task_id = ? AND d.status = 'pending'
-- ORDER BY d.created_at;

-- Get all deferrals originating from a task
-- SELECT * FROM deferrals WHERE source_task_id = ? ORDER BY created_at;

-- Pending deferral counts for dashboard
-- SELECT
--     COUNT(*) as 'Pending',
--     SUM(CASE WHEN target_task_id IS NOT NULL THEN 1 ELSE 0 END) as 'Assigned',
--     SUM(CASE WHEN target_task_id IS NULL THEN 1 ELSE 0 END) as 'Unassigned'
-- FROM deferrals WHERE status = 'pending';

-- Generate next deferral ID
-- SELECT 'D-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1)
-- FROM deferrals;

-- Validate: orphaned deferrals (target task deleted, deferral unassigned)
-- SELECT d.id, d.title, d.source_task_id, d.target_task_id
-- FROM deferrals d
-- WHERE d.status = 'pending' AND d.target_task_id IS NULL;

-- Validate: stale deferrals (target task is terminal but deferral still pending)
-- SELECT d.id, d.title, d.target_task_id, t.status as target_status
-- FROM deferrals d
-- JOIN tasks t ON t.id = d.target_task_id
-- WHERE d.status = 'pending'
--   AND t.status IN ('done', 'canceled', 'duplicate');

-- Update deferral source/target on task move
-- UPDATE deferrals SET source_task_id = '<new-id>', updated_at = datetime('now')
-- WHERE source_task_id = '<old-id>';
-- UPDATE deferrals SET target_task_id = '<new-id>', updated_at = datetime('now')
-- WHERE target_task_id = '<old-id>';

-- ============================================================================
-- MILESTONE QUERIES
-- ============================================================================

-- Get all milestones with task counts
-- SELECT m.id, m.title, m.status, m.phase_order,
--     COUNT(t.id) as total_tasks,
--     SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as done_tasks,
--     ROUND(100.0 * SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) / NULLIF(COUNT(t.id), 0), 1) as pct_complete
-- FROM milestones m
-- LEFT JOIN tasks t ON t.milestone_id = m.id AND t.archived_at IS NULL
-- GROUP BY m.id
-- ORDER BY m.phase_order;

-- Get active milestone
-- SELECT * FROM milestones WHERE status = 'active' ORDER BY phase_order LIMIT 1;

-- Get first planned milestone (fallback when none active)
-- SELECT * FROM milestones WHERE status IN ('active', 'planned') ORDER BY phase_order LIMIT 1;

-- Create milestone
-- INSERT INTO milestones (id, title, description, phase_order, status)
-- VALUES ('<id>', '<title>', '<desc>', <order>, 'planned');

-- Generate next milestone ID
-- SELECT 'MS-' || printf('%03d', COALESCE(MAX(CAST(SUBSTR(id, 4) AS INTEGER)), 0) + 1)
-- FROM milestones;

-- ============================================================================
-- PLAN ANALYSES QUERIES
-- ============================================================================

-- Check for existing analysis by PRD hash
-- SELECT * FROM plan_analyses WHERE prd_hash = ? ORDER BY created_at DESC LIMIT 1;

-- Insert new analysis
-- INSERT INTO plan_analyses (id, prd_source, prd_hash, tech_stack, assumptions, risks, ambiguities, nfrs, scope_in, scope_out, cross_cutting)
-- VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
-- (acceptance_criteria is a JSON array of strings; defaults to '[]' and feeds v_prd_verification.)

-- Generate next analysis ID
-- SELECT 'PA-' || printf('%03d', COALESCE(MAX(CAST(SUBSTR(id, 4) AS INTEGER)), 0) + 1)
-- FROM plan_analyses;

-- Update analysis with decisions
-- UPDATE plan_analyses SET
--     decisions = json_insert(decisions, '$[#]', json_object('question', ?, 'answer', ?, 'rationale', ?, 'memory_id', ?)),
--     updated_at = datetime('now')
-- WHERE id = ?;

-- ============================================================================
-- MILESTONE-SCOPED NEXT TASK (dependency-type-aware)
-- ============================================================================

-- REFERENCE ONLY: this is the exact query now encapsulated by the v_next_task
-- VIEW (schema.sql). Use `SELECT * FROM v_next_task LIMIT N` instead.

-- Find next available task preferring active milestone (flexible mode)
-- WITH done_ids AS (
--     SELECT id FROM tasks WHERE status IN ('done', 'canceled', 'duplicate')
-- ),
-- active_milestone AS (
--     SELECT id FROM milestones
--     WHERE status IN ('active', 'planned')
--     ORDER BY phase_order
--     LIMIT 1
-- )
-- SELECT t.* FROM tasks t
-- WHERE t.archived_at IS NULL
--   AND t.status NOT IN ('done', 'canceled', 'duplicate', 'blocked')
--   AND NOT EXISTS (SELECT 1 FROM tasks c WHERE c.parent_id = t.id)
--   AND NOT EXISTS (
--       SELECT 1 FROM json_each(t.dependencies) d
--       WHERE d.value NOT IN (SELECT id FROM done_ids)
--         AND COALESCE((SELECT je.value FROM json_each(t.dependency_types) je WHERE je.key = d.value), 'hard') = 'hard'
--   )
-- ORDER BY
--   CASE WHEN t.milestone_id = (SELECT id FROM active_milestone) THEN 0
--        WHEN t.milestone_id IS NOT NULL THEN 1
--        ELSE 2 END,
--   CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
--   COALESCE(t.business_value, 3) DESC,
--   CASE t.complexity_scale WHEN 'XS' THEN 0 WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 2 END,
--   t.id
-- LIMIT 1;

-- ============================================================================
-- MOSCOW & BUSINESS VALUE QUERIES
-- ============================================================================

-- MoSCoW distribution
-- SELECT COALESCE(moscow, 'unset') as moscow, COUNT(*) as count
-- FROM tasks WHERE archived_at IS NULL
-- GROUP BY moscow
-- ORDER BY CASE moscow WHEN 'must' THEN 0 WHEN 'should' THEN 1 WHEN 'could' THEN 2 WHEN 'wont' THEN 3 ELSE 4 END;

-- Business value distribution
-- SELECT business_value, COUNT(*) as count
-- FROM tasks WHERE archived_at IS NULL AND business_value IS NOT NULL
-- GROUP BY business_value ORDER BY business_value DESC;

-- Tasks by milestone with MoSCoW breakdown
-- SELECT m.id, m.title,
--     SUM(CASE WHEN t.moscow = 'must' THEN 1 ELSE 0 END) as must_count,
--     SUM(CASE WHEN t.moscow = 'should' THEN 1 ELSE 0 END) as should_count,
--     SUM(CASE WHEN t.moscow = 'could' THEN 1 ELSE 0 END) as could_count
-- FROM milestones m
-- LEFT JOIN tasks t ON t.milestone_id = m.id AND t.archived_at IS NULL
-- GROUP BY m.id ORDER BY m.phase_order;

-- ============================================================================
-- CROSS-CUTTING CONCERN QUERIES
-- ============================================================================

-- Get cross-cutting concerns from latest analysis
-- SELECT json_each.value FROM plan_analyses pa, json_each(pa.cross_cutting)
-- ORDER BY pa.created_at DESC LIMIT 20;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verification outcomes live in the `verifications` table (criteria themselves
-- stay in tasks.acceptance_criteria as a JSON array of strings). The per-task
-- roll-up is exposed by the v_task_verification VIEW (defined in schema.sql).
--
-- v_task_verification columns: task_id, total_criteria, met, failed, pending,
-- overridden, is_verified. The met/failed/pending counts EXCLUDE overrides;
-- overrides are surfaced separately in the `overridden` column. is_verified
-- still treats 'overridden' as satisfying a criterion (met+overridden = total).
--
-- MILESTONE and PRD roll-ups have the same shape via dedicated views:
--   v_milestone_verification(milestone_id, total_criteria, satisfied, is_verified)
--     over milestones.acceptance_criteria, verifications.target_type='milestone'.
--   v_prd_verification(prd_id, total_criteria, satisfied, is_verified)
--     over plan_analyses.acceptance_criteria, verifications.target_type='prd'.
-- In both, satisfied = count of latest-attempt rows with status met/overridden,
-- and is_verified = 1 only when total_criteria > 0 AND satisfied = total_criteria.
--   SELECT * FROM v_milestone_verification WHERE milestone_id = ?;
--   SELECT * FROM v_prd_verification WHERE prd_id = ?;

-- Read a task's verification roll-up (total criteria, met/failed/pending/overridden, is_verified)
-- Returns 0 rows for tasks whose acceptance_criteria is empty ('[]').
-- SELECT * FROM v_task_verification WHERE task_id = ?;

-- Gate check: is a task fully verified? (every criterion's latest attempt met/overridden)
-- SELECT is_verified FROM v_task_verification WHERE task_id = ?;
-- (No row -> the task has no acceptance_criteria; treat per command policy.)

-- List the failing criteria for a task (most recent attempt per criterion)
-- SELECT v.criterion_index, v.criterion, v.status, v.verdict_reasoning
-- FROM verifications v
-- WHERE v.target_type = 'task' AND v.target_id = ?
--   AND v.attempt = (
--       SELECT MAX(v2.attempt) FROM verifications v2
--       WHERE v2.target_type = 'task' AND v2.target_id = v.target_id
--         AND v2.criterion_index = v.criterion_index)
--   AND v.status = 'failed'
-- ORDER BY v.criterion_index;

-- Generate next verification ID (mirrors deferrals: V- + zero-padded counter)
-- SELECT 'V-' || printf('%04d', COALESCE(MAX(CAST(SUBSTR(id, 3) AS INTEGER)), 0) + 1)
-- FROM verifications;

-- Determine the next attempt number for a (target, criterion) pair
-- SELECT COALESCE(MAX(attempt), 0) + 1 FROM verifications
-- WHERE target_type = 'task' AND target_id = ? AND criterion_index = ?;

-- Insert a verification row (adversarial verdict)
-- INSERT INTO verifications
--   (id, target_type, target_id, criterion, criterion_index, status, method,
--    evidence, verdict_reasoning, verified_by, attempt)
-- VALUES (?, 'task', ?, ?, ?, ?, 'adversarial', ?, ?, ?, ?);

-- Insert a self (executed-test) evidence row.
-- IMPORTANT: a self row ALWAYS uses criterion_index = NULL (whole-suite evidence) so it
-- never competes in v_task_verification's per-criterion latest-attempt resolution.
-- INSERT INTO verifications
--   (id, target_type, target_id, criterion, criterion_index, status, method,
--    evidence, verified_by, attempt)
-- VALUES (?, 'task', ?, ?, NULL, ?, 'self', ?, 'run', ?);

-- Record an override (status='overridden' + reason; only path past a failure).
-- An override is a human action, not self/adversarial evidence, so method is NULL.
-- INSERT INTO verifications
--   (id, target_type, target_id, criterion, criterion_index, status, method,
--    override_reason, verified_by, attempt)
-- VALUES (?, 'task', ?, ?, ?, 'overridden', NULL, ?, ?, ?);

-- ============================================================================
-- ARCHIVAL
-- ============================================================================

-- Archive completed tasks
-- UPDATE tasks SET archived_at = datetime('now'), updated_at = datetime('now')
-- WHERE status IN ('done', 'canceled', 'duplicate') AND archived_at IS NULL;
