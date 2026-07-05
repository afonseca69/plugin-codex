# Passive TaskManager Verify SQL Fixture

This fixture contains the upstream `taskmanager/commands/verify.md` milestone and
PRD adversarial guard SQL snippets used by `test_sql_queries.sh`.

It is a test fixture only. It is not a Codex command, runtime wrapper, or slash
command port.

## Milestone Guard

```sql
WITH c(idx) AS (SELECT ac.key FROM milestones m, json_each(m.acceptance_criteria) ac WHERE m.id='<ms-id>')
SELECT CASE WHEN COUNT(*) > 0 AND SUM(CASE WHEN
    (SELECT status FROM verifications v WHERE v.target_type='milestone' AND v.target_id='<ms-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='overridden'
 OR ((SELECT status FROM verifications v WHERE v.target_type='milestone' AND v.target_id='<ms-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='met'
   AND (SELECT method FROM verifications v WHERE v.target_type='milestone' AND v.target_id='<ms-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='adversarial')
  THEN 1 ELSE 0 END) = COUNT(*) THEN 1 ELSE 0 END AS adversarially_met
FROM c;
```

## PRD Guard

```sql
WITH c(idx) AS (SELECT ac.key FROM plan_analyses p, json_each(p.acceptance_criteria) ac WHERE p.id='<PA-id>')
SELECT CASE WHEN COUNT(*) > 0 AND SUM(CASE WHEN
    (SELECT status FROM verifications v WHERE v.target_type='prd' AND v.target_id='<PA-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='overridden'
 OR ((SELECT status FROM verifications v WHERE v.target_type='prd' AND v.target_id='<PA-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='met'
   AND (SELECT method FROM verifications v WHERE v.target_type='prd' AND v.target_id='<PA-id>'
       AND v.criterion_index=c.idx ORDER BY v.attempt DESC, v.created_at DESC, v.rowid DESC LIMIT 1)='adversarial')
  THEN 1 ELSE 0 END) = COUNT(*) THEN 1 ELSE 0 END AS adversarially_met
FROM c;
```
