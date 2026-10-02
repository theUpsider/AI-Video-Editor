# Workflow runs

Copies of the workflow scripts and the task contracts of delegated runs, kept so that later reviews (milestone
reviews, AT-30 "task handoffs") can inspect what each run was asked to do after the session that ran it is gone
([AVE-REQ-094](../requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md),
[AVE-REQ-096](../requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)). Task briefs for
bounded implementation work live in [docs/briefs/](../briefs/README.md); [WORKFLOW_LOG.md](../WORKFLOW_LOG.md)
records measured process changes. The scripts reference the session scratchpad and absolute paths of the cloud
container that ran them; the copies here are the record of those inputs.

| Run | Date (UTC) | Script | Inputs | Agents | Outcome |
|---|---|---|---|---|---|
| `wf_5493b930-f7c` | 2026-10-01 | [m0-parallel-streams](m0-parallel-streams-wf_5493b930-f7c.js) | [docs-import contract](m0-build-contract-docs-import.md), [media-core contract](m0-build-contract-media-core.md) | 2 writers in the main tree (disjoint paths), 56 min | Completed; the lead integrated and committed `486b3a0` and `24499a6` |
| `wf_1a23bf0d-2a0` | 2026-10-02 | [review-media-core-round3](review-media-core-round3-wf_1a23bf0d-2a0.js) | [round-3 brief](../briefs/2026-10-02-m0-media-core-review-fixes-round-3.md), commit `dc89da2` | 3 review lenses, 2 skeptics per blocking finding, 53 min | PASS on every lens, 0 blocking; `dc89da2` merged; non-blocking items in [the follow-up brief](../briefs/2026-10-02-m0-media-core-round-3-follow-ups.md) |
| `wf_b0c34bba-a20` | 2026-10-02 | [verify-m0-process-requirements](verify-m0-process-requirements-wf_b0c34bba-a20.js) | AVE-REQ-093/094/096/097/098 at `4d9ef9a` | 5 reviewers (verify-requirement), skeptic stage for PASS verdicts, 37 min | All five FAIL; findings in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) |
