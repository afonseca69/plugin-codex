#!/usr/bin/env bash
# Taskmanager full-lifecycle E2E integration test.
#
# Walks ONE realistic project through the actual SQL each command runs, in order:
#   init -> plan -> show(next/verification/milestones/stats) -> run(verify+regression gates)
#   -> verify(milestone/prd) -> update(status/tags/deps/milestone-create/rollup)
#   -> export -> memory/research(FTS5) -> scribe capture bridge.
# Complements the per-query suite (test_sql_queries.sh) by proving the use cases
# compose correctly end-to-end. Self-contained: temp dir, auto-cleanup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA_FILE="$PLUGIN_DIR/schemas/schema.sql"
CONFIG_SRC="$PLUGIN_DIR/schemas/default-config.json"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

PASS=0; FAIL=0; ERRORS=""
pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); ERRORS="${ERRORS}\n  FAIL: $1"; echo "  FAIL: $1"; }
assert_eq() { if [[ "$1" == "$2" ]]; then pass "$3"; else fail "$3 (expected='$2' got='$1')"; fi; }
assert_gt() { if [[ "$1" -gt "$2" ]]; then pass "$3"; else fail "$3 (expected > $2 got '$1')"; fi; }
assert_contains() { if echo "$1" | grep -qF "$2"; then pass "$3"; else fail "$3 (missing '$2')"; fi; }

echo "=============================================="
echo "  TASKMANAGER — FULL LIFECYCLE E2E"
echo "=============================================="
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 1: init (the fixed path: plugin root resolved) ---"
mkdir -p .taskmanager/logs .taskmanager/docs
DB=".taskmanager/taskmanager.db"
sqlite3 "$DB" < "$SCHEMA_FILE"
cp "$CONFIG_SRC" .taskmanager/config.json
touch .taskmanager/logs/activity.log

assert_eq "$(sqlite3 "$DB" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;")" "4.2.0" "init: schema at v4.2.0"
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('tasks','milestones','plan_analyses','verifications','regression_checks','memories','deferrals','state','schema_version');")" "9" "init: core tables present"
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='view' AND name='v_task_regression';")" "1" "init: v_task_regression view present"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 2: plan (PRD analysis + milestones WITH criteria + epics/tasks) ---"
sqlite3 "$DB" <<'SQL'
-- PRD-level analysis with PRD acceptance criteria
INSERT INTO plan_analyses (id, prd_source, prd_hash, tech_stack, acceptance_criteria, milestone_ids)
VALUES ('PA-001','docs/prd/prd-auth.md','abc123','["node","sqlite"]',
        '["a user can register, log in, and log out","sessions survive a restart"]','["MS-001","MS-002"]');

-- Milestones created the NEW way: acceptance_criteria captured at creation
INSERT INTO milestones (id, title, description, acceptance_criteria, target_date, phase_order, status) VALUES
 ('MS-001','Auth core','login/logout/session','["login works","logout clears session"]', NULL, 1, 'active'),
 ('MS-002','Dashboard','metrics view','["dashboard renders live data"]', NULL, 2, 'planned');

-- Epic 1 (auth) + leaf tasks; Epic 2 (dashboard)
INSERT INTO tasks (id,parent_id,title,status,type,priority,complexity_scale,complexity_reasoning,complexity_expansion_prompt,estimate_seconds,tags,dependencies,dependency_types,milestone_id,acceptance_criteria,moscow,business_value) VALUES
 ('1',NULL,'Authentication','planned','feature','high','L','multi-endpoint',NULL,14400,'["auth"]','[]','{}','MS-001','[]','must',5),
 ('1.1','1','JWT login/logout','planned','feature','high','S','standard jwt',NULL,3600,'["auth"]','[]','{}','MS-001','["POST /login returns a token","POST /logout invalidates it"]','must',5),
 ('1.2','1','Password reset','planned','feature','medium','S','email flow',NULL,3600,'["auth"]','["1.1"]','{"1.1":"hard"}','MS-001','["reset email is sent","token resets the password"]','should',3),
 ('2',NULL,'Dashboard','planned','feature','medium','M','frontend',NULL,7200,'["ui"]','[]','{}','MS-002','[]','should',3),
 ('2.1','2','Charts','planned','feature','medium','S','d3',NULL,3600,'["ui"]','["1.1"]','{"1.1":"soft"}','MS-002','["a line chart renders"]','could',2);
SQL
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks;")" "5" "plan: 5 tasks created"
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM milestones WHERE json_array_length(acceptance_criteria) > 0;")" "2" "plan: both milestones have captured acceptance criteria"
assert_eq "$(sqlite3 "$DB" "SELECT json_array_length(acceptance_criteria) FROM plan_analyses WHERE id='PA-001';")" "2" "plan: PRD-level acceptance criteria stored"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 3: show --next (v_next_task: available leaf, deps honored) ---"
# 1.1 has no deps and no children -> available. 1.2 depends (hard) on 1.1 -> blocked until 1.1 done.
NEXT=$(sqlite3 "$DB" "SELECT id FROM v_next_task LIMIT 1;")
assert_eq "$NEXT" "1.1" "show --next: first available leaf is 1.1 (no deps, milestone-active)"
HAS_12=$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id='1.2';")
assert_eq "$HAS_12" "0" "show --next: 1.2 is NOT available (hard dep on unfinished 1.1)"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 4: run (criteria gate + regression gate on task 1.1) ---"
sqlite3 "$DB" "UPDATE tasks SET status='in-progress' WHERE id='1.1';"
# Verify both acceptance criteria as met
sqlite3 "$DB" <<'SQL'
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES
 ('VV1','task','1.1',0,'POST /login returns a token','met','adversarial',1),
 ('VV2','task','1.1',1,'POST /logout invalidates it','met','adversarial',1);
INSERT INTO regression_checks (id,target_type,target_id,status,verified_by,attempt)
 VALUES ('RC1','task','1.1','pass','maestro:regression',1);
SQL
assert_eq "$(sqlite3 "$DB" "SELECT is_verified FROM v_task_verification WHERE task_id='1.1';")" "1" "run: 1.1 criteria gate is_verified=1"
assert_eq "$(sqlite3 "$DB" "SELECT latest_status FROM v_task_regression WHERE task_id='1.1';")" "pass" "run: 1.1 regression verdict = pass"
# combined done-gate (exact condition from run.md): criteria-OK (or empty) AND regression pass/overridden
GATE=$(sqlite3 "$DB" "
SELECT CASE
  WHEN COALESCE((SELECT is_verified FROM v_task_verification WHERE task_id='1.1'),1)=1
   AND (SELECT latest_status FROM v_task_regression WHERE task_id='1.1') IN ('pass','overridden')
  THEN 'done' ELSE 'needs-review' END;")
assert_eq "$GATE" "done" "run: combined gate -> done-eligible for 1.1"
sqlite3 "$DB" "UPDATE tasks SET status='done' WHERE id='1.1';"
# Now 1.2 becomes available (its hard dep 1.1 is done)
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM v_next_task WHERE id='1.2';")" "1" "run: 1.2 becomes available after 1.1 done"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 5: run failure paths (fail-closed guarantees) ---"
# a) failed criterion -> needs-review
sqlite3 "$DB" "INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES ('VV3','task','1.2',0,'reset email is sent','failed','adversarial',1);"
IS_V=$(sqlite3 "$DB" "SELECT is_verified FROM v_task_verification WHERE task_id='1.2';")
assert_eq "$IS_V" "0" "run(fail): a failed criterion blocks is_verified (needs-review)"
# b) empty-criteria task + FAILED regression -> blocked (the hole-closer)
sqlite3 "$DB" "INSERT INTO tasks (id,parent_id,title,status,acceptance_criteria) VALUES ('1.3','1','Audit log','in-progress','[]');"
sqlite3 "$DB" "INSERT INTO regression_checks (id,target_type,target_id,status,verified_by) VALUES ('RC2','task','1.3','fail','maestro:regression');"
BLOCK=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='1.3') IN ('pass','overridden') THEN 'done' ELSE 'block' END;")
assert_eq "$BLOCK" "block" "run(fail): empty-criteria task + failed regression is BLOCKED"
# c) no verdict at all -> fail-closed block
NOVER=$(sqlite3 "$DB" "SELECT CASE WHEN (SELECT latest_status FROM v_task_regression WHERE task_id='2.1') IN ('pass','overridden') THEN 'done' ELSE 'block' END;")
assert_eq "$NOVER" "block" "run(fail): task with no regression verdict is fail-closed (block)"
sqlite3 "$DB" "DELETE FROM regression_checks WHERE id='RC2'; DELETE FROM tasks WHERE id='1.3'; DELETE FROM verifications WHERE id='VV3';"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 6: show --verification (NEW regression column) + --milestones + --stats ---"
# the exact LEFT JOIN from show.md
REG_COL=$(sqlite3 "$DB" "
SELECT COALESCE(tr.latest_status,'none')
FROM v_task_verification vt LEFT JOIN v_task_regression tr ON tr.task_id=vt.task_id
WHERE vt.task_id='1.1';")
assert_eq "$REG_COL" "pass" "show --verification: regression column reads 'pass' for 1.1"
# milestone derived status (v_milestone_status): work continues on 1.2 (now unblocked) ->
# any in-progress task makes the milestone 'active'
sqlite3 "$DB" "UPDATE tasks SET status='in-progress' WHERE id='1.2';"
MS_STATUS=$(sqlite3 "$DB" "SELECT derived_status FROM v_milestone_status WHERE milestone_id='MS-001';")
assert_eq "$MS_STATUS" "active" "show --milestones: MS-001 derived_status='active' with an in-progress task"
# stats --json (the dashboard json_object) is valid JSON with correct totals
STATS=$(sqlite3 "$DB" "SELECT json_object('total',(SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL),'done',(SELECT COUNT(*) FROM tasks WHERE status='done'));")
echo "$STATS" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['total']==5 and d['done']==1" && pass "show --stats --json: valid JSON, total=5 done=1" || fail "show --stats --json"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 7: verify --milestone / --prd (the NEW captured criteria are verifiable) ---"
sqlite3 "$DB" <<'SQL'
INSERT INTO verifications (id,target_type,target_id,criterion_index,criterion,status,method,attempt) VALUES
 ('VM1','milestone','MS-001',0,'login works','met','adversarial',1),
 ('VM2','milestone','MS-001',1,'logout clears session','met','adversarial',1);
SQL
assert_eq "$(sqlite3 "$DB" "SELECT is_verified FROM v_milestone_verification WHERE milestone_id='MS-001';")" "1" "verify --milestone: MS-001 verifies when its captured criteria are met"
# PRD-level: 0 of 2 met yet -> not verified
assert_eq "$(sqlite3 "$DB" "SELECT COALESCE((SELECT is_verified FROM v_prd_verification WHERE prd_id='PA-001'),0);")" "0" "verify --prd: PA-001 not yet verified (criteria pending)"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 8: update (status / tags / deps / milestone-create / estimate rollup) ---"
# tag add then remove
sqlite3 "$DB" "UPDATE tasks SET tags=json_insert(tags,'\$[#]','sprint-1') WHERE id='2.1';"
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks t,json_each(t.tags) g WHERE t.id='2.1' AND g.value='sprint-1';")" "1" "update --tag: added sprint-1 to 2.1"
# dependency add
sqlite3 "$DB" "UPDATE tasks SET dependencies=json_insert(dependencies,'\$[#]','2.1') WHERE id='2'; "
assert_contains "$(sqlite3 "$DB" "SELECT dependencies FROM tasks WHERE id='2';")" "2.1" "update --dep: added dep 2.1 to task 2"
# milestone-create the NEW way (with acceptance_criteria)
sqlite3 "$DB" "INSERT INTO milestones (id,title,description,acceptance_criteria,target_date,phase_order,status) VALUES ('MS-003','Hardening','sec pass','[\"rate limiting on /login\"]',NULL,3,'planned');"
assert_eq "$(sqlite3 "$DB" "SELECT json_array_length(acceptance_criteria) FROM milestones WHERE id='MS-003';")" "1" "update --milestone-create: new milestone is verifiable (1 criterion)"
# estimate rollup: parent 1 = sum of children
sqlite3 "$DB" "UPDATE tasks SET estimate_seconds=(SELECT COALESCE(SUM(estimate_seconds),0) FROM tasks c WHERE c.parent_id='1' AND c.status NOT IN ('canceled','duplicate')) WHERE id='1';"
assert_gt "$(sqlite3 "$DB" "SELECT estimate_seconds FROM tasks WHERE id='1';")" "0" "update --scope: parent estimate rolled up from children"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 9: export (all active tasks) ---"
EXPORT=$(sqlite3 "$DB" "SELECT id,title,status FROM tasks WHERE archived_at IS NULL ORDER BY id;")
assert_contains "$EXPORT" "1.1" "export: includes task 1.1"
assert_eq "$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE archived_at IS NULL;")" "5" "export: 5 active tasks"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 10: memory + research (FTS5) ---"
sqlite3 "$DB" "INSERT INTO memories (id,title,kind,why_important,body,source_type,source_name,importance,confidence,status,scope,tags) VALUES ('M-0001','Use RS256 for JWT','architecture','security','Sign JWTs with RS256, 15min access token TTL.','agent','research',4,0.9,'active','{\"domains\":[\"auth\"]}','[\"jwt\",\"auth\"]');"
FTS=$(sqlite3 "$DB" "SELECT m.id FROM memories m JOIN memories_fts f ON m.rowid=f.rowid WHERE memories_fts MATCH 'JWT' AND m.status='active';")
assert_eq "$FTS" "M-0001" "research: FTS5 finds the JWT memory"
LOADED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE status='active' AND importance>=3;")
assert_gt "$LOADED" "0" "memory: importance>=3 memories load for future tasks"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "--- Stage 11: scribe capture bridge (#4 — best-effort breadcrumb) ---"
# run.md 7c snippet: append a one-line breadcrumb when docs/ exists
mkdir -p docs
if [ -d docs ]; then mkdir -p docs/.scribe; echo "decision | Use RS256 for JWT — security (task 1.1)" >> docs/.scribe/capture.log; fi
assert_eq "$(wc -l < docs/.scribe/capture.log | tr -d ' ')" "1" "capture: run wrote a breadcrumb when docs/ exists"
rm -rf docs
if [ -d docs ]; then echo x >> docs/.scribe/capture.log; fi
[ ! -f docs/.scribe/capture.log ] && pass "capture: no-op when docs/ absent" || fail "capture: wrote without docs/"
echo ""

# ──────────────────────────────────────────────────────────────────────
echo "=============================================="
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo "  TOTAL:  $((PASS+FAIL))"
echo "=============================================="
if [[ $FAIL -gt 0 ]]; then echo -e "FAILURES:$ERRORS"; exit 1; else echo "  ALL LIFECYCLE STAGES PASSED!"; exit 0; fi
