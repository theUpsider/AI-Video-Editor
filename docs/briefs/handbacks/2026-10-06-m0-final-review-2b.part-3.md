# Handback — M0 final review, second round, part 3: AVE-REQ-096

Report of the reviewer (and of the skeptic, when the reviewer returned PASS) for AVE-REQ-096 from workflow run `wf_b18a5f3e-54e` at `f996c17`, briefed in [the review brief](../2026-10-06-m0-final-review-2b.md). The lead filed the report as returned, with local paths shortened to repository paths.

## Review

Verdict: **PASS** — AVE-REQ-096 — Isolated bounded tasks and independent review

### AC-1 — PASS

```text
Tests: scripts/tests/test-checker.sh, the 53 cases under the AVE-REQ-096 AC-1 tags (lines 223-286), ran on four awks in my release run (212 ok lines, no FAIL; CHECKER TOTAL pass=1090 fail=0). evidence.py show reports AC-1 passed, FRESH at f996c170a4e7. About 110 constructions of my own against the real checker matched every documented rule of check 11, and a real brief broken in a scratch copy of the tree was rejected (heading removed, branch-only input revision, handback named after no brief). Inspection: the twelve briefs in docs/briefs/ each hold the seven sections with requirement IDs and criteria in scope, allowed and forbidden paths, constraints, a commit, test commands and a handback schema (one, 2026-10-02-m0-process-fixes-execution.md, names its criteria through the linked fix brief); git log shows exactly one commit per brief. CLAUDE.md § Delegation and develop § 3-6 require the committed brief for every task the develop loop delegates, scripted review runs included, and all five agent definitions read it first. My own prompt named brief 2b, which f996c17 added before the launch, and it matches docs/workflows/m0-final-review-2.js. Round-1 blocking finding 2 is closed: the Edge case now states the rule and the seven deviations (WF-008), I counted exactly those seven rows without a brief in docs/workflows/README.md, and every run ID named anywhere in the documents has a row.
```

### AC-2 — PASS

```text
Tests: the 9 input-revision cases under the AVE-REQ-096 AC-2 tag (scripts/tests/test-checker.sh:265-276) ran on four awks; evidence.py show reports AC-2 passed. Inspection: .claude/settings.json sets worktree.baseRef to head. develop § 4, implementer.md:47-48 and tester.md:70-72 require a writer in a linked worktree to confirm that git rev-parse HEAD equals the base commit of its prompt, and develop § 4 states that a branch name confirms nothing. docs/workflows/m0-final-review-fixes.js:41 carries that line, and handback parts 1 to 3 of the fix brief each report the confirmed hash 41973c5. The three earlier scripts confirm the branch name only, as the requirement now states. Git shows the briefed commit as the parent of the first commit of all nine task branches (the six the strategy lists, plus 6ee69da, faa9efb and 9da0ea9 on 41973c5). In a scratch clone a worktree added from HEAD~3 passed the branch-name check and failed the equality check. This review's clone printed exactly f996c170a4e75ad25b06f36babf8699843012c92 before any work. Round-1 blocking finding 1 is closed.
```

### AC-3 — PASS

```text
Inspection, with the reason the strategy gives (a reviewer's inputs exist only in the review workflow and its recorded prompts). .claude/skills/verify-requirement/SKILL.md and .claude/agents/reviewer.md start the reviewer from the requirement and its own location of the change and treat every claim as unverified. Brief 2b calls the lead's statements and the fix handbacks claims, and the recorded prompts (docs/workflows/m0-final-review-2.js, verify-m0-final-wf_7d9d015c-906.js, review-media-core-round3-wf_1a23bf0d-2a0.js) place each reviewer in a private clone or scratch copy at the commit. In this review I wrote my expectations from the requirement before opening code and read the change through git diff 2df637f f996c17. Media-critical tests decode real renders: backend/tests/media/*.py measure pixels and samples from ave.render.validate decode_video_frames and decode_audio against the independent oracles of backend/tests/oracles.py, and 84 media and population tests passed in my release run (396 s). WF-001 records the three review rounds on real media. No tagged test exists, as the strategy states; evidence.py reports AC-3 as missing until the inspection line stands in § Test evidence.
```

### AC-4 — PASS

```text
Tests: scripts/tests/test-verify-tiers.sh:289-337, 15 cases under the AVE-REQ-096 AC-4 tag, all ok in my release run (VERIFY TIERS TOTAL pass=65 fail=0); evidence.py show reports AC-4 passed. Eight mutants of the lock in scripts/verify.sh each failed named cases. Own probes with a private lock file and my own 3 s step: two media runs started together gave one waiting line and disjoint step intervals (0-3.0 s and 3.7-6.7 s); three runs gave two waiting lines and three disjoint intervals; AVE_HEAVY_LOCK_HELD=1 with a free lock exited 1 with no step and no run directory, for media and release; a fast run under a held lock ran 5 of 5 steps with the variable unset; a waiting run started its steps after its holder was killed with SIGKILL; a lock path that is a directory failed before any step. Live: my release run printed exactly one waiting line while another reviewer's run held /state/ave-heavy-media.lock and started its steps afterwards. Inspection: develop § 4 Concurrency limits, the WORKFLOW_LOG operating baseline and WF-005, ENVIRONMENT_CAPABILITIES § Limits; every recorded writer workflow runs at most two lanes, each writer in its own worktree; no agent definition lists an agent-spawning tool and this session had none. Round-1 non-blocking finding 1 is closed: the variable without flock, with an unopenable lock and with an untestable lock each fail before any step. Non-blocking finding 4 describes what the confirmation still takes on trust.
```

### Verification runs

```text
- Paths in this report are relative to the repository root the main checkout at commit f996c17 (branch m0-final-integration); line numbers are those of that commit. Logs of every run below: <session scratchpad>\r096\
- Private clone .claude/worktrees/verify-ave-req-096, checkout of f996c170a4e75ad25b06f36babf8699843012c92: git rev-parse HEAD printed exactly that hash; git log -1 --format=%H -- docs/briefs/2026-10-06-m0-final-review-2b.md printed the same hash; git status --porcelain was empty before the release run, after it and after the last probe.
- ./scripts/verify.sh --tier release: exit 0, 'verify.sh: PASS — tier release (13 of 13 steps passed)'. It first printed one waiting line for the shared heavy-media lock. 37 tooling unit tests; 125 backend unit tests passed; 84 media and population tests passed in 396 s; CHECKER 1090/0 on four awks, BASELINE 305/0, STOP HOOK 145/0, SESSION START 56/0, VERIFY TIERS 65/0, PROBE 155/0; no FAIL line in the log.
- ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-096 --require-fresh --tier release: exit 0; latest-release.json, PASS, commit f996c170a4e7, recorded 2026-10-06T13:55:22Z, FRESH; AC-1 passed (scripts/tests/test-checker.sh), AC-2 passed (scripts/tests/test-checker.sh), AC-3 missing (inspection only), AC-4 passed (scripts/tests/test-verify-tiers.sh).
- ./scripts/dev-container.sh ./scripts/check-project-control.sh on the clone: exit 0, 'OK: 51 required files, 15 executable scripts, 5 agents, 9 skills, 2581 links in 215 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)'.
- Tagged suites alone, in a scratch copy of the tree under the container's /tmp (git archive HEAD): bash scripts/tests/test-checker.sh gave CHECKER TOTAL pass=278 fail=0; bash scripts/tests/test-verify-tiers.sh gave VERIFY TIERS TOTAL pass=65 fail=0.
- Check 11 probes, about 110 constructions in a fixture from scripts/tests/make-fixture.sh with the real checker. Rejected as documented: a section holding only one comment, two comments or a multi-line comment over its text; an ID, a hash or the self-reference only inside a comment; a comment that hides a heading; entries .markdown, .MD, .txt, a subdirectory, .x.md, ..x.md, a file named handbacks, a broken symbolic link; handbacks that are hidden, a directory, part-0, part-01, part- without a number, part-1.part-2, or named after a brief that is only a draft; input revisions HEAD, HEAD~1, a tag, an uppercase hash, six digits, abc1234_wip, wip-abc1234, the branch names ccr-af7078da-q8r8mf, worktree-agent-ace5eb07e8aecbfbf and m0-final-fixes-b1, the self-reference with .bak, x, /x or -old appended or to another brief; a heading with closing hashes or one leading space; a heading repeated directly; a section emptied by a foreign H2 or an H1; lowercase and two-digit IDs. Accepted as documented: text beside a comment, an ID in a code span, a comment marker in a code span, a CRLF brief, a draft without sections, part-10, and the forms ASM-018 lists (feature/abcdef1, deadbeef, effaced, 20261006, 0000000, a 7-digit number, AVE-REQ-999). Accepted and stated nowhere: the forms of non-blocking finding 2.
- Real briefs in the scratch copy of the tree: the checker passed unchanged; with '## Handback schema' removed from 2026-10-06-m0-final-review-2b.md it reported the missing heading; with that brief's input revision reduced to the branch name it reported 'names no commit'; an added handback 2026-10-06-m0-final-review-2b.part-1.md passed and 2026-10-06-m0-final-review-2c.part-1.md failed as named after no brief.
- Mutants of check 11 in scripts/check-project-control.sh, one replacement each in a fresh copy, against test-checker.sh on the system awk (control pass=278 fail=0). Killed, 4 of 11: comments kept (7 cases fail), no upper bound on the hash length (1), a file named drafts passes (1), an ID in any section counts (1). Survived, 7 of 11, each with pass=278 fail=0: a heading repeated directly is accepted; handback part numbers 0 and 01 are accepted; the self-reference followed by further path characters counts; no delimiter needed on the left of the hash; none needed on the right; a foreign H2 ends no section; a commit named in any section counts. For each survivor I ran one input against the real and the mutated checker: the real one exits 1, the mutant exits 0 (non-blocking finding 3).
- Mutants of the heavy-media lock in scripts/verify.sh against test-verify-tiers.sh (control pass=65 fail=0), 8 of 8 killed: no lock taken (16 cases fail), the inherited claim never tested (1), steps inherit descriptor 9 (1), the media tier unlocked (13), the waiting line printed without waiting (2), an untestable lock counted as held (1), the variable not exported (9), the fast tier takes the lock (2).
- Lock probes in a fixture with the byte-identical verify.sh, my own step file and a private AVE_HEAVY_LOCK: the results quoted under AC-4, plus the case of non-blocking finding 4 (AVE_HEAVY_LOCK_HELD=1 set by a process that holds nothing while a stranger held the lock from 0 to 8.0 s: exit 0, 6 of 6 steps, no waiting line, media step from 1.3 to 4.3 s).
- Worktree probe in a scratch clone under the container's /tmp: git worktree add -b task-x ../wt HEAD~3; git rev-parse --abbrev-ref HEAD printed task-x; git rev-parse HEAD printed c15c0df3 against the base f996c170, so the equality check returns BLOCKED where the branch-name check passes.
- Git and record inspection: one commit per brief for all twelve briefs (git log -- <brief>); parents of the first commit of nine task branches equal the briefed commits; git diff 2df637f f996c17 on the files this requirement relies on matches the dispositions in handback parts 2 and 3; grep rev-parse over docs/workflows/*.js gives three branch-name checks in the scripts before 2026-10-06 and equality checks in m0-final-review-fixes.js and m0-final-review-2.js; all 17 run IDs named anywhere in the documents have a row in docs/workflows/README.md; no agent definition lists an agent-spawning tool.
- Cleanup: ./scripts/dev-container.sh --stop exit 0; the clone .claude/worktrees/verify-ave-req-096 removed; git status --porcelain of the main checkout empty; no commit, no push.
```

### Blocking findings (0)

### Non-blocking findings (6)

1.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:38-40 (§ Edge cases), :73 (§ Verification strategy AC-1, inspection clause), :81 (§ Implementation evidence); CLAUDE.md:111; docs/briefs/README.md:8-9; .claude/skills/product-definition/SKILL.md:110-111 and :173; .claude/skills/technical-foundation/SKILL.md:57 and :60
defect: The requirement describes the brief rule as covering every delegated task, with the skills that fork their own agent as the only tasks that take none. CLAUDE.md § Delegation scopes the rule to the tasks the develop loop delegates and adds a second class: product-definition and technical-foundation give their agents the task text the skill defines. product-definition step 14, which amendment step 9 repeats for every product change, spawns the reviewer with such a text and no brief. A reader of the Edge case would count that critique as against the rule, while CLAUDE.md and docs/briefs/README.md allow it.
evidence: Text of the files at the lines named. No such task has run since the brief rule exists (docs/PRODUCT.md reads 'defined — 2026-10-01' and docs/product-inputs/ holds one file), so no record contradicts the requirement. I classify it as non-blocking because no criterion, gate or record depends on it and the cited documents carry the full rule; it is the first thing to settle, since the first product amendment would turn it into a disagreement between two canonical documents.
fix: Add to the Edge case and to line 81 the clause 'the one-time setup skills product-definition and technical-foundation give their agents the task text the skill defines (CLAUDE.md § Delegation)', and write 'before every task the develop loop delegates' in line 73. The other consistent choice is to require a brief for those agents too and to remove the clause from CLAUDE.md and docs/briefs/README.md.
```

2.

```text
location: scripts/check-project-control.sh:427-445 (AWK_BRIEF), :190-207 (in_fence), :230-260 (strip_comments_outside_spans); docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:47-49; docs/ASSUMPTIONS.md:285-294 (ASM-018); docs/briefs/README.md:23-24
defect: Check 11 removes HTML comments and nothing else that a Markdown renderer shows as nothing. Such content counts as the text of a section, as the requirement ID or as the commit, and neither § Edge cases nor ASM-018 states it. Inside a raw HTML block the checker's code-span and fence exemptions also keep the content of a comment that a renderer hides. These are residuals of the same class as the comment-only section of round 1; every rule as documented holds.
evidence: Fixture probes, each exit 0. Allowed paths holding only an empty fenced block, only `[later]: https://example.com`, only a no-break space, only `<br>`, only `<span></span>`, only `&nbsp;`, only a thematic break, or only a subheading. Requirements holding only `[r]: #AVE-REQ-001`, only `<a name=AVE-REQ-001></a>`, only `<?x AVE-REQ-001 ?>` or only `<!X AVE-REQ-001>`. Input revision holding only `<a name=abc1234></a>` or only `<?c abc1234 ?>`. Requirements holding a `<div>` line, then a line whose comment markers stand between backticks around AVE-REQ-001, then `</div>`: a renderer reads a raw HTML block with a real comment, the checker reads code spans and counts the ID. A `## Handback schema` heading after a fence opened at indent 2 and a fence line at indent 5: the checker closes the fence there, CommonMark keeps it open, so the heading is code for the reader and a heading for the rule.
fix: State the limit in § Edge cases and ASM-018 (the rule removes HTML comments; other raw HTML, link reference definitions, empty fenced blocks and characters that render blank are judged by the reader of the brief), or tighten check 11: fail raw HTML (`<` before a letter, `/`, `!` or `?`) outside code spans and fenced blocks in a brief, as scripts/reqfile.py does for requirement files, pass over link reference definitions, and count a section line as text only when it holds a letter or a digit. Each new rule gets its suite case.
```

3.

```text
location: scripts/tests/test-checker.sh:223-286; scripts/check-project-control.sh:432-434, :444, :466, :474, :1122
defect: Seven sub-rules of check 11 have no suite case that fails without them. The checker is correct for each today; a regression of any one would pass the suite on every awk. Four of them belong to the input-revision rule that carries the AC-2 tag.
evidence: Seven one-replacement mutants each ended with CHECKER TOTAL pass=278 fail=0, and for each an input exists that the real checker rejects and the mutant accepts: (1) `rank[current] < last_rank` accepts '## Allowed paths' repeated directly; the suite's repeated heading stands after the last heading, so the order rule catches it. (2) Without `0*` in the part-number pattern, 2026-10-02-stub.part-0.md is accepted. (3) Without the test of the character after the self-reference, the self-reference to <this brief>.bak counts. (4) Without the left delimiter, 'Branch `worktree-agent-ace5eb07e8aecbfbf` only.' counts as a commit; that is a real branch name of this repository, and the suite's branch name holds its hex token between two hyphens. (5) Without the right delimiter, abc1234_wip counts. (6) When a foreign H2 ends no section, '## Allowed paths', '## Notes', 'src/' passes. (7) When a commit counts in any section, a hash under Requirements with 'The prompt names it.' under Input revision passes.
fix: Add seven cases to scripts/tests/test-checker.sh: a heading repeated directly (expect "heading '## Allowed paths' follows '## Allowed paths'"); handbacks part-0 and part-01 (expect the '(n = 1, 2, …)' line); the self-reference with a suffix, a branch name that ends in hex, and a hash with a `_wip` suffix (each expect the 'names no commit' line); a template section followed directly by a foreign H2 (expect "section '## Allowed paths' is empty"); a hash only under Requirements (expect 'names no commit').
```

4.

```text
location: scripts/verify.sh:202-220 (hold_heavy_lock); docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:66-67 and :76; docs/ARCHITECTURE.md:266-269
defect: A run started with AVE_HEAVY_LOCK_HELD=1 confirms that somebody holds the lock; that the holder is its caller rests on the caller's word. With the variable set by a process that holds nothing, the run starts while another job holds the lock, so two heavy media jobs overlap. § Edge cases states the waiting behavior without this limit. The path needs the variable set by hand inside the container (scripts/dev-container.sh passes none from the host, and verify.sh exports it to its own steps only), so it stands beside the rule that every other heavy command runs under flock, which also rests on the caller.
evidence: Fixture with the real verify.sh and a private lock: a stranger process held the lock from 0 to 8.0 s; `AVE_HEAVY_LOCK_HELD=1 ./scripts/verify.sh --tier media` started at 1.0 s and ended with exit 0, 6 of 6 steps, no waiting line; its media step ran from 1.3 to 4.3 s, inside the stranger's hold.
fix: State the limit in § Edge cases and in ARCHITECTURE item 6 (the run confirms that the lock is held; the caller answers for holding it), or close it: the caller passes the descriptor on which it holds the lock, and the run requires that `flock -n` succeeds on that descriptor while `flock -n` on a fresh open of the lock file fails, which only the holder's descriptor satisfies. A suite case starts a run with the variable while a third process holds the lock.
```

5.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:103 (§ Status), :74 (§ Verification strategy AC-2), :12 and :70 (dependencies), :89 (§ Test evidence)
defect: Document consistency. The newest Status-log line says verification was requested from 2026-10-06-m0-final-review-2.md, the brief that no run used; this review started from 2026-10-06-m0-final-review-2b.md. The AC-2 strategy lists the base of six task branches while nine exist at this commit. The dependency AVE-REQ-094 is in verification, so this requirement moves to done after it. evidence.py reports AC-3 as missing until § Test evidence holds its inspection line.
evidence: Requirement file at f996c17; brief 2b § Input revision states the replacement; git log gives 6ee69da, faa9efb and 9da0ea9 each with parent 41973c5; grep '^status:' on the AVE-REQ-094 file prints verification; the evidence.py show output above.
fix: Name brief 2b in the Status-log line that records this verdict. Add '`6ee69da`, `faa9efb` and `9da0ea9` on `41973c5`' to the list in the AC-2 strategy. Keep the order 094 before 096 for the done transition, as docs/PROGRESS.md plans. Paste the inspection lines below into § Test evidence.
```

6.

```text
location: scripts/check-project-control.sh:443; docs/briefs/2026-10-02-m0-process-fixes-execution.md:4-7; .claude/agents/architect.md; .claude/skills/develop/SKILL.md:133
defect: Two small gaps between a rule and what carries it. Check 11 requires a requirement ID under Requirements and no criterion, although AC-1 names acceptance criteria; one brief of the twelve names its criteria only through the linked fix brief. The architect counts as a writing agent in develop § 4, and concurrent writers run in worktrees, yet architect.md holds no Worktrees section; for it the equality check rests on the prompt line of develop § 4 alone.
evidence: The Requirements section of 2026-10-02-m0-process-fixes-execution.md holds five IDs and 'items 1–26 of the fix brief' with no AC number; the checker passes it. grep for worktree or rev-parse in .claude/agents/architect.md finds nothing, while implementer.md:45-48 and tester.md:70-72 hold the rule.
fix: Either require a criterion or an edge case under Requirements in check 11 (a token `AC-<n>` or the words 'edge case', with a suite case), or say in the AC-1 strategy that the criteria in scope are judged by the inspection of each brief. Add the Worktrees paragraph of tester.md to architect.md.
```

### Test quality

```text
AC-1 and AC-2 (scripts/tests/test-checker.sh:223-286). Assertion strength: each case builds a fresh fixture, applies one mutation and asserts the exit code together with one specific ERROR line, or the OK line for an accepted form; the expected lines are written out in the suite and are independent of the checker. Real unit under test: the repository's own check-project-control.sh, copied into the fixture. Executed: 53 cases per awk on mawk, gawk, original-awk and busybox in the release run (212 ok lines, no FAIL), counted through the suite result (1090 checks, 0 failed). Tagged with comment lines 223, 240, 256, 265 and 277, the convention for shell suites. Fails without the behavior: for the primary rules yes; my mutants for kept comments, a missing upper bound, a file named drafts and an ID in any section each failed named cases, and the rules the fix round added (comment removal, the entries of docs/briefs/, hidden handbacks) are all pinned. Coverage gaps: seven sub-rules are unpinned (non-blocking finding 3): a heading repeated directly, part numbers 0 and 01, a suffix after the self-reference, the left and the right delimiter of the hash taken singly, a foreign H2 ending a section, and the scoping of the commit to the Input revision section. The checker behaves correctly in all seven, which I showed with inputs of my own; no criterion rests on a test that cannot fail. No test can show that a launch had a brief or that a prompt carried the base check; those parts rest on the inspections recorded under AC-1 and AC-2, which I performed on the records and on Git.

AC-3: inspection only, with a stated reason in § Verification strategy. No tagged test, as expected. The inspection shows the criterion: skill, agent definition, brief and recorded prompts agree, this review received the requirement and the commit and treated the handbacks as claims, and the media tests decode real renders and ran (84 passed).

AC-4 (scripts/tests/test-verify-tiers.sh:289-337). The lock state is judged by an independent probe in a child process (the variable in its environment and a fresh `flock -n` on the lock file), so no check reads verify.sh's own report. The waiting case reads the first output line through a FIFO, requires 2 s of silence with the process alive, and requires no second waiting line after the release; the 2 s wait depends on timing in the conservative direction, since a run that started steps prints at once. Executed: 15 cases ok in the release run. Fails without the behavior: 8 of 8 mutants killed, the three fail-closed cases of the fix round among them. Own constructions (private lock, own steps with logged intervals, two and three concurrent runs, a holder killed with SIGKILL) and the live wait on the shared lock agree with the suite. Coverage gap: the variable set while a third process holds the lock (non-blocking finding 4), which no suite case exercises because the run cannot tell that case from its documented use.

Scenarios AT-29 and AT-30: nothing in the tree contradicts them. Evidence is tied to the current tree (FRESH), the FAIL verdicts of the first round are recorded as failures, and this review run has a brief whose handback parts will hold its reports.
```

### Evidence for the requirement file

```text
- verify-requirement: PASS — 2026-10-06 — no blocking findings (review run of docs/briefs/2026-10-06-m0-final-review-2b.md at `f996c17`)
- ./scripts/verify.sh: PASS — 2026-10-06 (tier release, 13 of 13 steps, commit `f996c170a4e7`, evidence FRESH)
- AC-1 → `scripts/tests/test-checker.sh` (53 cases under the AVE-REQ-096 AC-1 tags per awk, four awks; suite 1090 checks, 0 failed) — pass
- AC-1 → inspection: the twelve briefs of `docs/briefs/` each hold the seven sections with requirement IDs, the criteria in scope, paths, constraints, a commit, test commands and a handback schema, and `git log` shows one commit per brief; `CLAUDE.md` § Delegation, `develop` § 3–6 and the five agent definitions require and read the committed brief; the prompt of this review named its brief, which `f996c17` added before the launch — pass
- AC-2 → `scripts/tests/test-checker.sh` (9 input-revision cases under the AVE-REQ-096 AC-2 tag per awk, four awks) — pass
- AC-2 → inspection: `.claude/settings.json` sets `worktree.baseRef: "head"`; `develop` § 4, `implementer.md` and `tester.md` § Worktrees hold the equality rule; `docs/workflows/m0-final-review-fixes.js` carries the equality line and handback parts 1 to 3 report the confirmed hash; Git shows the briefed commit as the parent of the first commit of all nine task branches; in a scratch clone a worktree made from another commit passed the branch-name check and failed the equality check — pass
- AC-3 → inspection: `verify-requirement` and `reviewer.md` start the reviewer from the requirement and its own reading of the change; the brief and the recorded prompt (`docs/workflows/m0-final-review-2.js`) call the lead's statements and the handbacks claims; the media tests decode real renders (`backend/tests/media/`, 84 media and population tests passed in the release run) — pass
- AC-4 → `scripts/tests/test-verify-tiers.sh` (15 cases under the AVE-REQ-096 AC-4 tag; suite 65 checks, 0 failed) — pass
- AC-4 → inspection: `develop` § 4 Concurrency limits, the WORKFLOW_LOG operating baseline and WF-005, ENVIRONMENT_CAPABILITIES § Limits; every recorded writer run holds at most two writers, each in its own worktree; no agent definition lists an agent-spawning tool; the reviewer's lock probes gave one waiting line per waiting run and disjoint step intervals for two and for three concurrent runs — pass
- Non-blocking findings: (1) the requirement's wording of the brief rule omits the class CLAUDE.md § Delegation names for the one-time setup skills; (2) check 11 counts content that renders as nothing (link reference definitions, raw HTML other than comments, an empty fenced block, a no-break space), stated nowhere; (3) seven sub-rules of check 11 have no suite case that fails without them; (4) a run with `AVE_HEAVY_LOCK_HELD=1` confirms that somebody holds the lock and takes on trust that it is its caller; (5) the Status log names the brief that no run used, and the AC-2 strategy lists six of nine task branches; (6) check 11 requires no criterion under Requirements, and `architect.md` holds no Worktrees section.
```

## Challenge

Outcome: **REFUTED**

### Reasoning

```text
Refuted on AC-4: the capability record the reviewer cites as inspected support states a limit that this review run exceeds. AC-1, AC-2, AC-3 and the tagged tests of AC-4 stand on my own checks.

**Why AC-4 falls**
- AC-4 reads "Respect actual concurrency and resource limits". The project's record of those limits says reviewer clones go one at a time while `C:` is at 98 %.
- The brief and the script committed at f996c17 plan two reviewer clones at a time, and I observed two at once with the disk still at 98 %.
- The reviewer checked the two-writer and one-heavy-job limits against the records and listed "ENVIRONMENT_CAPABILITIES § Limits" as agreeing, without checking item 5 of that section.
- The counter-argument is that a clone and its environment take under 100 MB, so capacity was never at risk. Then item 5 is the wrong statement, and the AC-4 inspection line that cites the section cannot stand as written. Either way something must change before `done`.

**Fix, either of two**
- Run reviewer and skeptic clones one lane at a time until the space is freed.
- Or replace the last sentence of item 5 with the measured footprint and the limit that holds (for example at most two reviewer clones; release-tier runs serialize on the heavy-media lock), and state the clone count in `develop` § 4 Concurrency limits and in § Edge cases so the lead counts clones before a launch. Backend environments also accumulate: 31 sit on the state volume, since `--stop` keeps them.

**What I upheld**
- AC-1: the cases the strategy lists exist in `scripts/tests/test-checker.sh:223-286`, each asserting an exit code and a specific error line. All twelve briefs hold the seven sections with requirement IDs, and each has exactly one commit. One brief names its criteria only through the linked fix brief, as the reviewer reported.
- AC-2: `.claude/settings.json` sets `baseRef` to `head`. `docs/workflows/m0-final-review-fixes.js:41` carries the equality line, and handback parts 1 to 3 each report the confirmed hash 41973c5. `git rev-parse <commit>^` gives the briefed commit for all nine first commits of task branches.
- AC-3: the skill, the reviewer definition and the recorded prompt agree, and the media tests call `decode_video_frames` and `decode_audio`.
- AC-4 tests: `scripts/tests/test-verify-tiers.sh` gave pass=65 fail=0 in my container run, with all 15 lock cases ok. A mutant that never tests the inherited claim failed 2 named cases. A second mutant (a busy lock neither waited for nor taken) ran on top of the first because my restore step failed; together they failed 13.

**Not run**
I did not run the release tier in my clone. The dispute does not need it, and it would add another heavy job and environment on a disk at 98 %. I read the reviewer's `release.log` instead: 13 of 13 steps, CHECKER 1090/0, VERIFY TIERS 65/0, as reported.

**Two observations that do not carry the verdict**
- The lead's repair commit b4f503f on the AVE-REQ-094 task branch (18:56:46) falls between track A's commits (18:43:51, 19:13:08) and before track B1's (19:53:18). The baseline (`ai-video-editor-requirements/spec/AGENT_WORKFLOW.md:41`) limits "concurrent code-writing tasks" to two, while `develop` § 4 counts only agents the lead launched. The rule should say whether the lead's own code work counts.
- The reviewer's non-blocking finding 1 (the requirement omits the setup-skill exemption of `CLAUDE.md:111`) is, by the letter of the brief, a requirement-file statement that disagrees with the canonical rule. I left AC-1 upheld because no record contradicts it and the fix is already reported.

**Housekeeping**
- The clone printed f996c170a4e75ad25b06f36babf8699843012c92 before any work, and `git status --porcelain` was empty before removal.
- Probe fixtures and the mutant copy lived in the container's `/tmp` and were deleted.
- One `docker run` of my own, meant to read the state volume, named an image tag that does not exist locally. Docker refused the pull and nothing was created; I used `scripts/dev-container.sh` afterwards.
- `./scripts/dev-container.sh --stop` exited 0 and the clone is removed. The main checkout is clean at 8a7ed2a; no commit, no push.
```

### AC-4 — FAIL

```text
The inspection the reviewer cites for AC-4 ("ENVIRONMENT_CAPABILITIES § Limits") shows a resource limit that the review run briefed at this commit exceeds. Paths are relative to the main checkout, content at f996c17.

1. The limit. docs/ENVIRONMENT_CAPABILITIES.md:130-132, § Limits that shape the plan, item 5: "Disk: 5.2 GiB free on the host on 2026-10-06 ... Each private clone gets its own backend environment on the state volume, so reviewer clones and release-tier runs go one at a time until the human frees space on `C:`." The requirement file names this section as Implementation evidence for AC-4 (line 84), and the reviewer's AC-4 row and proposed Test-evidence line list it as inspected support.

2. The plan at the same commit. docs/briefs/2026-10-06-m0-final-review-2b.md:46-48: "A private clone has its own container and backend environment ... Two reviewers work at a time". docs/workflows/m0-final-review-2.js:87-95 runs two lanes through parallel(), each reviewer and skeptic in a private clone.

3. The condition has not lapsed. `df -h /c` during this challenge: 237G size, 5.4G available, 98% used.

4. Two reviewer clones were live at once. At 2026-10-06T14:14:49Z and 14:17:58Z, `ls .claude/worktrees` listed challenge-ave-req-096 and verify-ave-req-098 together, and `docker ps` showed both clone containers up (ave-dev-3084842326-2748825813 and ave-dev-3084842326-3724733988) beside the main checkout's. The reviewer's own release log (session scratchpad, r096/release.log, line 1) opens with the waiting line for /state/ave-heavy-media.lock, so another reviewer clone was running then too. The lock keeps release-tier runs one at a time; nothing keeps reviewer clones one at a time.

5. The limit was never applied. `git blame` dates item 5 to d4147d8 (2026-10-06 14:39:06). Three runs followed, each with two clones or worktrees at a time, each with its own container and backend environment:
- wf_7d9d015c-906, launch recorded at d309ca4 (14:42:21), "two lanes at a time" (docs/workflows/README.md row); its AVE-REQ-094 lane reviewed d4147d8 itself.
- wf_5cd13360-464, the fix run (docs/workflows/m0-final-review-fixes.js:43 and :53-60).
- The present run.

6. No file at f996c17 withdraws or rewords the limit. docs/PROGRESS.md:58-60 (written at d309ca4) says a clone takes about 60 MB and its backend environment 24 MB, "so reviews proceed", and names no count. My measurements agree on size: /state/venvs holds 31 environments of about 24 MB each, /state is 961 MB, and the clone verify-ave-req-098 is 42 MB.

So either the limit is the actual one and three of three runs since it was written broke it, or the footprint measurement makes it obsolete and the section named as AC-4 evidence states a limit that is not the actual one. In both readings the inspection line "ENVIRONMENT_CAPABILITIES § Limits ... pass" does not show what it is credited with. This is the same class as the two blocking findings of round 1: a rule in the documents and records that show otherwise.

Supporting, not the basis of the verdict: I reproduced the reviewer's non-blocking finding 4 in a container fixture with the byte-identical scripts/verify.sh and a private lock. A stranger held the lock from 0.01 s to 8.01 s. `AVE_HEAVY_LOCK_HELD=1 ./scripts/verify.sh --tier media`, started by a process holding nothing, exited 0 with 6 of 6 steps and no waiting line; its media step ran from 1.22 s to 4.23 s, inside the stranger's hold. The control run without the variable printed one waiting line and started its media step 0.18 s after the release. § Edge cases (lines 66-67) states the waiting behavior without this limit. The Status log (line 99) records the mirror case, the variable set while nobody holds the lock, as a defect that was fixed.
```
