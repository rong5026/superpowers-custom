---
name: subagent-driven-development
description: Use when executing an implementation plan with mostly-independent tasks in a fresh controller session
---

# Subagent-Driven Development (v2)

Execute a plan by dispatching one implementer subagent per task, gating each
task with a risk-scaled review, and running one whole-branch review at the end.

**Announce:** "I'm using subagent-driven-development to execute this plan."

**Upstream base: v6.3.0.** Its rulings-not-stalls model, task batching,
bounded waits and no-subagents contract are carried in below.

**v2 vs upstream — what changed and why (measured on real sessions):**
- **Risk-tiered review** — low-risk tasks skip the separate reviewer dispatch.
  Most tasks were 3–11 min mechanical edits paying a full review each.
- **Hard model defaults** — implementers default to the cheapest tier in the
  template, not "choose per policy" prose that silently inherited the top tier.
- **3-round fix cap** (was 5) — a task needing more is a plan defect; rule on
  it and carry the ruling forward, don't grind.
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

**Continuous execution:** do not check in between tasks, and do not stop to
ask a question the ledger can answer.

**Rulings, not stalls (6.3.0).** A running plan does not wait on a human.
Conflicts, ambiguities, plan defects, a cap you would have asked to exceed —
decide them. The spec is the binding authority, the plan is its argument, and
your judgment settles what neither answers. Record every decision as
`Ruling: <what you decided> — <why> — <what it costs if wrong>` and keep going.
A wrong ruling costs rework the human can see and undo; a session parked on a
question costs their whole day and buys nothing.

**Only these stop you:** an irreversible or destructive operation; a
security-sensitive action; a side effect outside this worktree that norms say
you ask about first (a merge, a push to a shared branch, a publish); a plan so
broken that every path forward is a guess; and — v2 only — a base that fails
pre-flight health, since that breakage is not this plan's to rule on.

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
4. Read the plan ONCE. Note Global Constraints. One todo per task. If the plan
   names a **Spec**, read it too — it is the authority the plan argues from, and
   in-plan conflicts resolve against it. No reachable spec → ledger that fact;
   rulings made without one are provisional.
5. **Pre-flight scan (plan) — the output is a table, not a verdict (6.3.0).**
   One row per task pair sharing a file or interface (what one produces vs what
   the other consumes, what you found), plus one row per task for self-agreement
   (the tests it specifies vs the code it specifies, files it creates vs files it
   later touches). "Clean" without those rows is not a scan you ran. Write the
   table to the ledger, **rule on every conflict before Task 1** and record the
   ruling beside its row, then dispatch. Clean → proceed without comment. The
   review loop remains the net for conflicts that only emerge from
   implementation.
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
| Implementer, risk=high — integration / judgment | mid tier (sonnet) | most-capable at fix round 3 |
| Implementer, risk=high — money / security / auth / data-migration surface | most-capable | — |
| Task reviewer (only runs for risk=high) | mid tier (sonnet) | — |
| Debugger subagent | mid tier (sonnet) | most-capable if stuck |
| Final whole-branch review | most-capable | — |

Sonnet is enough for ordinary multi-file integration. The money / security /
auth / data-migration subset starts on the most-capable tier — a subtle bug
there is expensive and these tasks are rare, so the cost is bounded.
Implementers otherwise run on the top tier only at a round-3 fix escalation.

## The Task Loop

Record `BASE = git rev-parse HEAD` before each dispatch (review packages need it).

**Batch small same-shape work (6.3.0).** When the plan lists several tasks that
are each a small, independent edit of the same kind — the same one-line fix,
constant change, or field addition repeated across files — compose ONE brief
listing every file and its change, send the batch to a single subagent, review
its diff as one unit. One-dispatch-per-task is for work that needs its own
judgment, tests, or review surface.

**Waiting on subagents (6.3.0).** Never poll a wait interface with short
timeouts, and never sit in one silent open-ended wait either. While you have
local work — ledger updates, packaging the next review, reading reports — keep
working. Genuinely idle → wait in bounded 5–10 minute stretches; between
stretches post one status line and reconcile live children: list them, chase any
that finished without reporting.

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
- **No-subagents contract (6.3.0)** — the template binds the implementer to
  dispatch nothing: no helpers, and above all no reviewer. Review comes from you,
  after the report. Every worker-spawned reviewer measured upstream was a
  duplicate seat on the same diff.
- If an earlier task parked a finding in the area this task touches, carry a
  pointer to that ledger entry in the dispatch.
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
  wrong → **rule on the correction, ledger it, and re-dispatch with the ruling
  carried in the brief** (6.3.0 — do not park the run on a question). Never
  retry the same model unchanged.

### 4. Review — risk-scaled (A)

- **risk=low:** the implementer's self-review + TDD RED/GREEN evidence in the
  report IS the gate. Controller reads only the ≤6-line return + spec bullets;
  confirm every spec requirement is checked off. No separate reviewer dispatch.
  **Both verdicts still required, as a controller checklist:** every spec bullet
  checked AND TDD RED/GREEN evidence present AND the self-review's quality items
  (YAGNI, naming, tests verify behavior not mocks) all passed. If any of the
  three is missing or unconvincing, escalate this task to high and run the full
  reviewer.
- **risk=high:** `scripts/review-package PLAN_FILE BASE HEAD` → diff file.
  Dispatch [task-reviewer-prompt.md](task-reviewer-prompt.md) with brief path,
  report path, diff path, and the verbatim Global Constraints that bind this
  task. Reviewer returns spec verdict + quality verdict (both required).
- A `⚠️ Cannot verify from diff` item: you resolve it yourself (you hold cross-
  task context); a confirmed gap enters the fix loop.

### 5. Fix loop — 3-round cap (C)

Triggers on spec ❌, any Critical/Important finding, or a confirmed ⚠️ gap.
Minor findings never enter the loop — log `Task N: minor (deferred): …` for the
final review. A plan-mandated / plan-conflicting finding is **yours to rule on**
(6.3.0): weigh the finding against the plan text, decide with the spec as binding
authority, ledger the `Ruling:` before acting on it. Do not dismiss the finding
because the plan mandates it, and do not dispatch a contradicting fix without a
recorded ruling.

- **Rounds 1–2:** resume the original implementer with findings verbatim — its
  context is intact (it knows the task, the code, its own choices).
- **Round 3:** fresh implementer, one model tier up, given brief + report +
  findings + "a prior implementer attempted this N times; read the report."
- Each round: implementer fixes, re-runs covering tests, appends fix report.
  Then one scoped re-review (`review-package PLAN_FILE FIX_BASE HEAD`,
  [re-review-prompt.md](re-review-prompt.md)).
- **Cap at round 3.** Still open → adjudicate each finding: contestable or
  real-but-not-load-bearing → park as `Task N: parked — <finding> — Ruling: …`;
  real AND load-bearing (a later task builds on it, or it's a plan defect) →
  **rule on the smallest change that unblocks the dependent work**, ledger
  `Task N: Ruling: <finding> — <what you decided and why>`, and carry it into the
  next task's dispatch (6.3.0 — was STOP/BLOCKED). Stop only when every path
  forward is a guess. Never fix findings in the controller.

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
one scoped re-review → adjudicate residuals as in the loop (rule and ledger;
only the stop-list above halts you). No second fix wave.

## Finish

**Before deleting anything (6.3.0):** collect every ledger line containing
`Ruling:` — pre-flight rulings, parked findings, breaker adjudications — into
your final message under "Rulings I made", in the order you made them, each with
what it costs if wrong. The list is exhaustive. It is the only place decisions
you took on your human partner's behalf reach them. A ruling that dies with the
workspace was made in secret.

Clean final review → `rm -rf <workspace>` (git is the record). Leave sibling
plan directories alone. Use finishing-a-development-branch.

## References

- [references/workflow.md](references/workflow.md) — decision + execution
  diagrams (explanatory; the contracts above govern).
- [references/example-workflow.md](references/example-workflow.md) — a worked run.
- [references/rationalizations.md](references/rationalizations.md) — the excuses
  you'll be tempted by, and the reality.
