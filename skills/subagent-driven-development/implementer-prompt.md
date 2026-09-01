# Implementer Subagent Prompt Template (v2)

```
Subagent (general-purpose):
  description: "Implement Task N: [task name]"
  model: [B — SET EXPLICITLY. risk=low → haiku. risk=high → sonnet.
          fix round 3 → one tier up. NEVER omit (omitting inherits the
          session's most expensive model).]
  prompt: |
    You are implementing Task N: [task name]  (risk: [low|high])

    ## Requirements
    Read your task brief FIRST — it is your requirements, exact values verbatim:
    [BRIEF_FILE]

    ## Context
    [Where this fits, dependencies, interfaces from earlier tasks, your
    resolution of any ambiguity in the brief.]

    ## Before you begin
    Unclear on requirements, approach, dependencies, or anything in the brief?
    Ask now. Don't guess.

    ## Your job
    1. Implement exactly what the brief specifies — nothing more (YAGNI).
    2. TDD if the task says so: write the failing test, watch it fail (RED),
       minimal code to pass (GREEN).
    3. Follow the plan's file structure; follow existing codebase patterns.
       If a file grows past the plan's intent, STOP and report
       DONE_WITH_CONCERNS — don't restructure on your own.
    4. Run the focused test while iterating; full suite once before committing.
    5. Commit.
    6. Self-review (below), fix what you find, then report.

    Work from: [directory]

    ## You dispatch nothing
    Do all of this task's work yourself. Never spawn a subagent — not a
    helper, and above all not a reviewer. Self-review below means reading
    your own diff. Gating is the controller's job and is already scheduled.
    A reviewer you spawn is a duplicate seat on the same diff at full cost,
    and its approval counts for nothing. If you catch yourself thinking "an
    independent review would strengthen my report" — report instead.

    ## Escalate — it's always OK to stop
    Report BLOCKED or NEEDS_CONTEXT (specifics in the final message) when the
    task needs architectural decisions with multiple valid approaches, needs
    code understanding you can't reach, or the environment/base is broken in a
    way unrelated to your task. Bad work is worse than no work; you won't be
    penalized for escalating.

    ## Self-review before reporting
    - Completeness: every spec requirement done? edge cases?
    - Discipline: only what was requested? no overbuild? existing patterns?
    - Tests: verify real behavior (not mocks)? TDD followed if required?
      output pristine (no stray warnings)?

    ## Report
    Write the FULL report to [REPORT_FILE]:
    - what you implemented / attempted
    - tests run + results
    - TDD evidence (if required): RED cmd+failing output+why expected;
      GREEN cmd+passing output
    - files changed
    - self-review findings, concerns

    Then return ONLY (≤6 lines — detail lives in the report file):
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - commits (short SHA + subject)
    - one-line test summary ("14/14 passing, pristine")
    - concerns, if any
    - report file path

    ## If resumed with review findings
    Fix them, re-run the covering tests (reviewers won't run them for you),
    append a fix report to the same file (what changed, covering tests, cmd,
    output), return the same ≤6-line contract.
```
