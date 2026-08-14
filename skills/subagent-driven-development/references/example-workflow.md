# SDD v2 — Example Run

```
You: I'm using subagent-driven-development to execute this plan.

[Setup] worktree verified. Read plan once. sdd-workspace → fresh ledger.
[Base health] npm run build && npm run test:int:smoke → ok. Ledger: base health: ok.
[Todos created for all tasks]

Task 1: Add install-hook command  (risk=low — 1 file, complete spec)
[task-brief → task-1-brief.md; dispatch implementer, model=haiku]
Implementer → DONE. commit a1b2c3d. "5/5 passing, pristine". report: task-1-report.md
[risk=low: read the 6-line return + TDD RED/GREEN in report. Spec bullets all checked.
 No reviewer dispatch.]
[Ledger: Task 1: complete (a1b2c3d..a1b2c3d, low, self-gated)]

Task 2: Wire recovery across store + api + worker  (risk=high — 3 files, integration)
[task-brief → task-2-brief.md; dispatch implementer, model=sonnet]
Implementer → DONE. commits d4e..b7c. "8/8 passing".
[review-package PLAN BASE HEAD → pkg-2.diff; dispatch task-reviewer, model=sonnet,
 + verbatim Global Constraints]
Reviewer: Spec ❌ — missing progress report every 100 items. Important: magic number 100.
[Fix round 1: resume implementer with both findings]
Implementer → fixed, extracted PROGRESS_INTERVAL, 10/10 passing, fix report appended.
[scoped re-review of fix diff] → both ADDRESSED, no new breakage.
[Ledger: Task 2: fix round 1/2 (2 addressed, 0 open); Task 2: complete (d4e..e9f, high)]

Task 5: Payment reconciliation  (risk=high)
[... implementer BLOCKED: "integration DB container won't start — unrelated to task"]
[D: infra blocker → dispatch systematic-debugging subagent, model=sonnet.
 NOT running docker inline in controller.]
Debugger → root cause: stale ${cs_password_hash} placeholder in base .env.test. Fixed.
[re-dispatch implementer for Task 5]

[After all tasks]
[review-package PLAN MERGE_BASE HEAD → final.diff; dispatch code-reviewer, most-capable,
 pointed at ledger deferred-minors + parked]
Final reviewer: all requirements met, deferred minors don't block merge.
[rm -rf workspace]

Done. Using finishing-a-development-branch.
```
