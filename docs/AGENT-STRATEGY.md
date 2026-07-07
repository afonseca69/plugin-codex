# Codex Agent Strategy

The original `mwguerra/plugins` repository includes agent prompt files for
architecture, implementation, PRD interviews, docs curation, docs verification,
and TaskManager verification. This Codex port represents those roles as
skill-local reference and persona guides.

They are passive guidance files. Codex should read them when a selected skill
needs the fuller role stance, but the plugin does not claim automatic subagent
execution or direct compatibility with the original agent runtime.

## Mapping

| Upstream agent file | Codex reference |
|---|---|
| `architect/agents/architect.md` | `plugins/engineering-discipline/skills/architect-design/references/agent-architect.md` |
| `architect/agents/design-adversary.md` | `plugins/engineering-discipline/skills/architect-review/references/agent-design-adversary.md` |
| `maestro/agents/implementer.md` | `plugins/engineering-discipline/skills/maestro-implement/references/agent-implementer.md` |
| `prd-builder/agents/prd-interviewer.md` | `plugins/engineering-discipline/skills/prd-builder-prd/references/agent-prd-interviewer.md` |
| `scribe/agents/doc-curator.md` | `plugins/engineering-discipline/skills/scribe-docs-discipline/references/agent-doc-curator.md` |
| `scribe/agents/doc-verifier.md` | `plugins/engineering-discipline/skills/scribe-verify/references/agent-doc-verifier.md` |
| `taskmanager/agents/taskmanager.md` | `plugins/engineering-discipline/skills/taskmanager-lite/references/agent-taskmanager.md` |
| `taskmanager/agents/verifier.md` | `plugins/engineering-discipline/skills/taskmanager-lite/references/agent-verifier.md` |

## What This Provides

- Reusable stance and procedure guidance for existing Codex skills.
- Clear adaptation from upstream agent prompts to `AGENTS.md`, skill
  references, docs, evidence, and verification language.
- A safe way to preserve upstream workflow intent without enabling hooks,
  adding commands, or porting the TaskManager engine.

## What This Does Not Provide

- No automatic subagent dispatch.
- No new hook behavior.
- No changes to `hooks/hooks.json`.
- No strict hook enablement.
- No automatic TaskManager agent runtime.
- No broad mutating TaskManager runtime commands beyond explicitly documented
  manual memory operations.
- No full upstream TaskManager dashboard, memory engine, or command parity.
- No external integrations, background jobs, or unrelated tooling.

## Usage

When a skill needs the fuller upstream persona, load the matching reference file
after reading the skill's `SKILL.md`. Keep the skill itself authoritative for
Codex behavior, and treat the persona guide as supporting context.

If Codex adds a stable automatic agent mechanism later, it should be designed as
a separate phase with live verification evidence. This phase makes no such
claim.
