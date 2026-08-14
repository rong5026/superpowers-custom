---
name: subagent-driven-development
description: Use when executing an implementation plan with mostly-independent tasks in a fresh controller session
---

# Subagent-Driven Development (v2)

Execute a plan by dispatching one implementer subagent per task, gating each
task with a risk-scaled review, and running one whole-branch review at the end.

**Announce:** "I'm using subagent-driven-development to execute this plan."

**v2 vs upstream — what changed and why (measured on real sessions):**
- **Risk-tiered review** — low-risk tasks skip the separate reviewer dispatch.
  Most tasks were 3–11 min mechanical edits paying a full review each.
- **Hard model defaults** — implementers default to the cheapest tier in the
  template, not "choose per policy" prose that silently inherited the top tier.
- **2-round fix cap** (was 5) — a task needing 3+ rounds is a plan defect;
  escalate, don't grind.
- **Debugger dispatch, never controller inline** — infra/base failures go to a
  systematic-debugging subagent. Controller doing Docker/integration runs inline
  was the largest invisible time sink.
- **Base pre-flight** — verify the branch base compiles + smoke-passes ONCE
  before the loop, instead of rediscovering pre-existing breakage per task.
- **Slim controller context** — contracts only here; explanation lives in
  `references/`. Controller prose is re-read on every turn = cost.

**Core rule:** everything pasted into a dispatch, and everything a subagent
returns, stays resident in controller context for the whole session and is
re-read every turn. Hand artifacts over as **files**. Subagents return ≤6 lines.

**Continuous execution:** do not check in between tasks. Stop only on
unresolvable BLOCKED, genuine ambiguity, or all-tasks-done.

## Setup

1. **Fresh controller session.** If this conversation contains the planning /
   design discussion, stop and tell the human to start execution in a new
   session with just the plan path. Do not continue in the planning session.
2. Ensure an isolated workspace (using-git-worktrees). Never start on
   main/master without explicit consent.
3. `scripts/sdd-workspace PLAN_FILE` → the plan's workspace dir. Check
   `<workspace>/progress.md`: tasks with a `complete` line are DONE — resume at
   the first without one. Trust the ledger + `git log` over memory after any
   compaction. Create the ledger first line: `# SDD ledger — plan: <path>`.
4. Read the plan ONCE. Note Global Constraints. One todo per task.
5. **Pre-flight scan (plan):** batch any task↔task or task↔constraint conflicts
   to the human as one question before Task 1. Clean → proceed silently.
6. **Pre-flight health (base) — E.** Before Task 1, on the base commit run the
   project's compile + fast integration smoke (the plan's Global Constraints
   name the commands; if absent, ask once). If the base is already broken
   (won't compile, smoke fails), STOP and report — those failures are NOT this
   plan's tasks and will otherwise be rediscovered task after task. Record
   `base health: ok (<cmd>)` or `base health: BROKEN — <what>` in the ledger.

## Model Defaults (B — hard, not advisory)

Set `model:` on **every** dispatch. Omitting it inherits the session model
(usually the most expensive). Defaults:

| Role | Default | Escalate to |
|------|---------|-------------|
| Implementer, risk=low | cheapest tier (haiku) | — |
| Implementer, risk=high | mid tier (sonnet) | most-capable at fix round 2 |
| Task reviewer (only runs for risk=high) | mid tier (sonnet) | — |
| Debugger subagent | mid tier (sonnet) | most-capable if stuck |
| Final whole-branch review | most-capable | — |

Implementers never run on the most-capable tier except a round-2 fix escalation.

## The Task Loop

Record `BASE = git rev-parse HEAD` before each dispatch (review packages need it).

### 1. Risk-tag the task (A)

Tag from the plan text, before dispatching:
- **low** — 1–2 files, complete/verbatim spec, no cross-module integration,
  no money/security/auth/data-migration surface.
- **high** — anything else: multi-file integration, judgment, or a
  money/security/auth/migration surface.

Record the tag in the dispatch and the ledger.

### 2. Dispatch the implementer

- `scripts/task-brief PLAN_FILE N` → brief file. The brief is the single source
  of requirements (exact values live there). Never make the subagent read the
  whole plan.
- Dispatch [implementer-prompt.md](implementer-prompt.md) with: one line on where
  the task fits; the brief path ("read first — your requirements"); interfaces/
  decisions from earlier tasks the brief can't know; your resolution of any
  ambiguity; the report-file path (`…/task-N-report.md`); the model per the table.
- Never paste prior-task history or accumulated summaries. Never dispatch two
  implementers in parallel.
- Record the implementer's agent id — fix round 1 resumes it.

### 3. Handle the report

- **DONE** → go to review (step 4).
- **DONE_WITH_CONCERNS** → read concerns; correctness/scope → treat as findings;
  observations → note and proceed.
- **NEEDS_CONTEXT** → provide it, re-dispatch (same model).
- **BLOCKED** → **D. If the blocker is infra / environment / a pre-existing
  base defect (won't compile, container down, unrelated failing test), dispatch
  a systematic-debugging subagent to root-cause it — do NOT run Docker /
  integration suites / root-cause hunts inline in the controller.** If the
  blocker is task-sizing → split. If reasoning → escalate model. If the plan is
  wrong → escalate to human. Never retry the same model unchanged.

### 4. Review — risk-scaled (A)

- **risk=low:** the implementer's self-review + TDD RED/GREEN evidence in the
  report IS the gate. Controller reads only the ≤6-line return + spec bullets;
  confirm every spec requirement is checked off. No separate reviewer dispatch.
  If the return reveals a spec gap or missing test evidence, escalate this task
  to high and run the full reviewer.
- **risk=high:** `scripts/review-package PLAN_FILE BASE HEAD` → diff file.
  Dispatch [task-reviewer-prompt.md](task-reviewer-prompt.md) with brief path,
  report path, diff path, and the verbatim Global Constraints that bind this
  task. Reviewer returns spec verdict + quality verdict (both required).
- A `⚠️ Cannot verify from diff` item: you resolve it yourself (you hold cross-
  task context); a confirmed gap enters the fix loop.

### 5. Fix loop — 2-round cap (C)

Triggers on spec ❌, any Critical/Important finding, or a confirmed ⚠️ gap.
Minor findings never enter the loop — log `Task N: minor (deferred): …` for the
final review. A plan-mandated / plan-conflicting finding is the human's call.

- **Round 1:** resume the original implementer with findings verbatim.
- **Round 2:** fresh implementer, one model tier up, given brief + report +
  findings + "a prior implementer attempted this N times; read the report."
- Each round: implementer fixes, re-runs covering tests, appends fix report.
  Then one scoped re-review (`review-package PLAN_FILE FIX_BASE HEAD`,
  [re-review-prompt.md](re-review-prompt.md)).
- **Cap at round 2.** Still open → adjudicate each finding: contestable or
  real-but-not-load-bearing → park with a ruling in the ledger; real AND
  load-bearing (a later task builds on it, or it's a plan defect) → STOP,
  `Task N: BLOCKED — …`, report to human. Never fix findings in the controller.

### 6. Complete

Append `Task N: complete (commits <base7>..<head7>, review clean)` (or `…, K
parked`), mark the todo done, next task. Never advance with unaddressed,
unparked Critical/Important findings.

## Final Review

`scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = `git merge-base
main HEAD`). Dispatch requesting-code-review's
[code-reviewer.md](../requesting-code-review/code-reviewer.md) on the
most-capable model, pointed at the ledger's deferred-minor + parked lines.
Findings → ONE fix subagent with the full list (not one-per-finding) → exactly
one scoped re-review → adjudicate residuals as in the loop. No second fix wave.

## Finish

Clean final review → `rm -rf <workspace>` (git is the record). Leave sibling
plan directories alone. Use finishing-a-development-branch.

## References

- [references/workflow.md](references/workflow.md) — decision + execution
  diagrams (explanatory; the contracts above govern).
- [references/example-workflow.md](references/example-workflow.md) — a worked run.
- [references/rationalizations.md](references/rationalizations.md) — the excuses
  you'll be tempted by, and the reality.
