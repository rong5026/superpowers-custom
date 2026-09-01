# SDD v2 — Rationalizations

| Excuse | Reality |
|--------|---------|
| "This task looks simple, tag it low to skip review" | Risk tag is about surface, not vibe. Multi-file / money / security / auth / migration = high, always. Wrong tag skips the gate that catches the expensive bug. |
| "risk=low, so I'll skip reading even the report" | Low skips the *reviewer dispatch*, not your check. You still confirm every spec bullet + TDD RED/GREEN from the 6-line return. A gap there re-tags the task high. |
| "Just omit the model, it'll pick something" | Omitting inherits the session's most expensive tier for every dispatch — the exact cost sink v2 exists to kill. Set it every time. |
| "One more fix round will converge" | Past round 2, rounds don't converge — the failure is structural (plan defect or wrong tier). Adjudicate and route, don't grind to 5. |
| "The container's down, I'll just fix it in the controller real quick" | Inline infra debugging was the largest measured hidden time sink. Dispatch a systematic-debugging subagent; keep your context clean. |
| "I'll fix this finding myself, dispatching is overhead" | Controller fixes pollute context and skip review. Resume the implementer. |
| "The base was already broken, I'll work around it per task" | Pre-existing breakage gets rediscovered every task. Catch it once in Setup base-health; if broken, STOP and report — it's not your plan's task. |
| "Skip the base pre-flight, the branch is probably fine" | "Probably fine" is how 8 tasks get blocked by one stale placeholder. One smoke run up front is cheaper than N mid-loop detours. |
| "Reviews slow the loop" | The loop without gates is unverified churn. Risk-tiering already removed the reviews that didn't pay for themselves; the ones left are load-bearing. |
| "The implementer spawned its own reviewer — free extra assurance" | Duplicate seat on the same diff; the controller's gate is the review. A worker-spawned reviewer is a defect to flag, not rigor. |
| "This conflict needs a human ruling" | Only four things stop you (destructive op, security action, out-of-worktree side effect, every-path-a-guess) plus a failed base pre-flight. Everything else: rule it, ledger the `Ruling:`, keep going. A parked session costs a whole day. |
| "I ruled on it, no need to write it down" | An unlogged ruling never reaches your human partner — the Finish step's "Rulings I made" list is built from ledger `Ruling:` lines only. A decision made in secret can't be undone. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed task sequences. |
