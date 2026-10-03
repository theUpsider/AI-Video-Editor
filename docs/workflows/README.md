# Workflow runs

Copies of the workflow scripts and the task contracts of delegated runs, kept so that later reviews (milestone
reviews, AT-30 "task handoffs") can inspect what each run was asked to do after the session that ran it is gone
([AVE-REQ-094](../requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md),
[AVE-REQ-096](../requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)). Since 2026-10-02
every run starts from a committed brief in [docs/briefs/](../briefs/README.md) (`CLAUDE.md` § Delegation), its
script is copied here, and its row links both; `wf_5493b930-f7c`, `wf_1a23bf0d-2a0` and `wf_b0c34bba-a20`
predate that rule.
[WORKFLOW_LOG.md](../WORKFLOW_LOG.md) records measured process changes. The scripts reference the session
scratchpad and absolute paths of the cloud container that ran them; the copies here are the record of those
inputs.

| Run | Date (UTC) | Script | Inputs | Agents | Outcome |
|---|---|---|---|---|---|
| `wf_5493b930-f7c` | 2026-10-01 | [m0-parallel-streams](m0-parallel-streams-wf_5493b930-f7c.js) | [docs-import contract](m0-build-contract-docs-import.md), [media-core contract](m0-build-contract-media-core.md) | 2 writers in the main tree (disjoint paths), 56 min | Completed; the lead integrated and committed `486b3a0` and `24499a6` |
| `wf_1a23bf0d-2a0` | 2026-10-02 | [review-media-core-round3](review-media-core-round3-wf_1a23bf0d-2a0.js) | [round-3 brief](../briefs/2026-10-02-m0-media-core-review-fixes-round-3.md), commit `dc89da2` | 3 review lenses, 2 skeptics per blocking finding, 53 min | PASS on every lens, 0 blocking; `dc89da2` merged; non-blocking items in [the follow-up brief](../briefs/2026-10-02-m0-media-core-round-3-follow-ups.md) |
| `wf_b0c34bba-a20` | 2026-10-02 | [verify-m0-process-requirements](verify-m0-process-requirements-wf_b0c34bba-a20.js) | AVE-REQ-093/094/096/097/098 at `4d9ef9a` | 5 reviewers (verify-requirement), skeptic stage for PASS verdicts, 37 min | All five FAIL; findings in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) |
| `wf_164de68e-23b` | 2026-10-02/03 | [m0-fix-tracks](m0-fix-tracks-wf_164de68e-23b.js) | [process-fixes execution brief](../briefs/2026-10-02-m0-process-fixes-execution.md), [media follow-ups execution brief](../briefs/2026-10-02-m0-media-core-follow-ups-execution.md), base `6736401` | model-override probe; process fixes parts 1–3 (one writer, sequential); media follow-ups implementer; review round 1 (two lenses); relaunched once for model settings and stopped by a session restart | Parts 1–3 committed (`fb61875`, `3f7c44d`, `a62e197`); media items 1–13 committed (`9be8ef5`, `b6a3e98`); round 1: oracle lens PASS, real-media lens FAIL (jitter bound) |
| `wf_df2de811-039` | 2026-10-03 | [m0-fix-tracks-continue](m0-fix-tracks-continue-wf_df2de811-039.js) | the same briefs; the completed stages of `wf_164de68e-23b` embedded as facts | process fixes part 4 and final check; media fix round 1; review round 2 (two lenses); 5 agents, 158 min | Part 4 `a5c81d3`, final check `529deda` (release tier PASS); media fix `b832b01`; round 2 both lenses PASS; integrated as `31e22f7` and the following merge |
| `wf_ed1f5104-63a` | 2026-10-03 | [verify-m0-process-requirements-2](verify-m0-process-requirements-2-wf_ed1f5104-63a.js) | AVE-REQ-093/094/096/097/098 at `d4d3883`; WORKFLOW_LOG.md WF-001–WF-005 | 5 reviewers (verify-requirement, private clones), a skeptic per PASS, 1 workflow-log reviewer | launched 2026-10-03; verdict not recorded — on resume without a recorded verdict, re-run the script with `{commit: 'd4d3883'}` |
