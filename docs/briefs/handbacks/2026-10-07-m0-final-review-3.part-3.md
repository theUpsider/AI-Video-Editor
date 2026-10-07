# Handback — M0 final review, third round, part 3: AVE-REQ-096

Report of the reviewer for AVE-REQ-096 from workflow run `wf_268ea4f6-bad` at `d7d5604`, briefed in [the review brief](../2026-10-07-m0-final-review-3.md). The verdict is FAIL, so no skeptic ran. The lead filed the report as returned, with local paths shortened to repository paths.

## Review

Verdict: **FAIL** — AVE-REQ-096 — Isolated bounded tasks and independent review (reviewed at d7d56049c98254192201b85cdcfce323adff024f in the private clone .claude/worktrees/verify-ave-req-096; `git rev-parse HEAD` printed exactly that hash before any work)

### AC-1 — PASS

```text
Criterion met and evidenced; blocking finding 2 concerns statements tagged AC-1/AC-2, not the criterion. Tests: scripts/tests/test-checker.sh lines 294-379, 65 cases under the AVE-REQ-096 AC-1 and AC-1/AC-2 tags per awk, four awks (260 ok lines, CHECKER TOTAL pass=1477 fail=0) in my release run; evidence.py show: AC-1 passed, FRESH at d7d56049c982. All 32 check 11 mutants of the audit table fail their named cases in my rerun; 5 of my own fail too. In a scratch copy of the tree the real checker rejected this review's brief without '## Test commands', the same brief without its self-reference, and a handback named after a brief that does not exist. Inspection: the 14 briefs in docs/briefs/ each hold the seven sections, a requirement ID, a commit and exactly one commit in `git log`; 13 name criteria by AC number or edge case and one (2026-10-02-m0-process-fixes-execution.md) through its linked fix brief, as § Edge cases states. CLAUDE.md § Delegation, develop § 3-6 and all five agent definitions require and read the committed brief. My prompt equals the template of docs/workflows/m0-final-review-3.js and names the brief that d7d5604 adds. The seven review runs without a brief (WF-008) are exactly the seven rows without a brief link in docs/workflows/README.md.
```

### AC-2 — PASS

```text
Tests: the 16 input-revision cases per awk under the AVE-REQ-096 AC-1/AC-2 tag (test-checker.sh:346-366) ran on four awks; evidence.py show: AC-2 passed. Mutants B-NO-COMMIT, B-MIN, B-MAX, B-LEFT, B-RIGHT, B-SELFREF, B-SELF-WORD/DOT/SLASH and B-COMMIT-SECTION each fail their named cases. Inspection: .claude/settings.json sets worktree.baseRef to head; develop § 4 and § Worktrees of implementer.md:45-48, tester.md:70-72 and architect.md:75-77 hold the equality rule. The three scripts before 2026-10-06 confirm the branch name (`rev-parse --abbrev-ref`), m0-final-review-fixes.js:41 and m0-review-2-fixes.js:44 carry the equality line, and all seven fix handbacks report the confirmed hash. `git rev-parse <commit>^` gives the briefed commit for all 13 first commits the strategy lists. In a scratch repository a worktree added from HEAD~2 passed the branch-name check and failed the equality check. The commit forms K03/K04 of blocking finding 2 touch the sentence 'check 11 requires a commit'; the criterion itself rests on the equality check and the Git record.
```

### AC-3 — PASS

```text
Inspection, with the reason the strategy states. verify-requirement/SKILL.md and reviewer.md start the reviewer from the requirement and its own location of the change and treat every claim as unverified; the brief calls the lead's statements claims; my prompt matches docs/workflows/m0-final-review-3.js:65-70 and placed me in a private clone at the commit. I wrote my expectations from the requirement before opening code. Media-critical tests decode real renders: backend/tests/media/*.py measure decoded pixels and samples (ave.render.validate decode_video_frames/decode_audio) against tests/oracles.py with fixed expected values (test_at02_render.py:173-195 read in full); 84 media and population tests passed in my release run (331.56 s). evidence.py reports AC-3 as missing until the inspection line stands in § Test evidence, as expected. Non-blocking finding 4: 'three review rounds' against the four reviews WF-001 lists.
```

### AC-4 — FAIL

```text
The tests pass: scripts/tests/test-verify-tiers.sh:478-526, 15 lock cases ok in my release run (VERIFY TIERS TOTAL pass=133 fail=0), evidence.py show: AC-4 passed; my own probes agree (three runs at once gave two waiting lines and step intervals 0.34-3.34 s, 4.14-7.14 s, 8.09-11.09 s; a claim with a free lock exited 1 with no step; the stated limit of a claim beside a stranger reproduced). The refutation of round two is closed: ENVIRONMENT_CAPABILITIES § Limits item 5 states the measured footprint and the limit of two clones, develop § 4 counts clones and the lead's own code work, and two reviewer clones existed during this review. The inspection of the records fails: § Edge cases and the strategy state one overlap of three code writers, and the records hold a second (blocking finding 1).
```

### Verification runs

```text
- Clone: `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/verify-ave-req-096` and checkout of d7d5604; `git rev-parse HEAD` printed d7d56049c98254192201b85cdcfce323adff024f. `git status --porcelain` was empty before and after the release run and before removal (`--ignored` showed var/ only).
- `./scripts/verify.sh --tier release`: exit 0, 'verify.sh: PASS — tier release (13 of 13 steps passed)', no waiting line. 40 tooling unit tests; backend 132 passed (fast) and 84 passed (media and population, 331.56 s); CHECKER 1477/0 on mawk, gawk, original-awk and busybox; BASELINE 424/0; STOP HOOK 174/0; SESSION START 77/0; VERIFY TIERS 133/0; PROBE 256/0. The 24 log lines holding 'FAIL' are case names or expected output.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-096 --require-fresh --tier release`: exit 0; latest-release.json, PASS, commit d7d56049c982, recorded 2026-10-07T07:49:09Z, FRESH; AC-1 passed, AC-2 passed, AC-3 missing (inspection only), AC-4 passed.
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py`: exit 0, 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files'; no note names AVE-REQ-096; the four criteria equal the baseline text.
- Mutants, in a `git archive HEAD` copy under the container's /tmp, one replacement each, against test-checker.sh on the system awk filtered to the check 11 cases (control pass=69 fail=0). All 32 mutants of handback part 4 failed (failed cases in brackets): B-REPEAT (1), B-ORDER (3), B-PART0 (2), B-PARTX (1), B-SELF-WORD (2), B-SELF-DOT (1), B-SELF-SLASH (1), B-SELFREF (1), B-LEFT (1), B-RIGHT (1), B-MIN (1), B-MAX (1), B-FOREIGN (2), B-H1 (1), B-COMMIT-SECTION (1), B-ID-SECTION (1), B-NO-ID (3), B-NO-COMMIT (13), B-EMPTY (12), B-MISSING (9), B-COMMENTS (7), B-FENCE (1), B-ENTRIES (5), B-HIDDEN (1), B-DRAFTS-FILE (1), B-DIR-BRIEF (1), B-FOLDER-FILES (1), HB-HIDDEN (2), HB-NO-BRIEF (2), HB-README (1), HB-MD (1), HB-DIR (1). The failing case names equal those the handback lists.
- Own mutants, 14 in the same harness. Killed, 5: blank lines fill a section (9 cases), `last_rank` never updated (3), self-reference to any brief (1), fences read inside comments (1), comments read inside code spans (1). Survived with pass=69 fail=0, 9: an ID of one digit; uppercase hex; the `..?*` glob removed for docs/briefs/ and for handbacks/; CRLF tolerance removed; fenced text no longer counted as section text; and three with the same tree verdict through another rule (a handback of a directory named like a brief, README.md as a directory, an empty slug).
- Check 11 probes, 119 runs of the real checker in a make-fixture.sh fixture or the tree copy. Rejected as documented: comment-only sections, an ID or commit in a plain comment, uppercase and mixed-case hashes, HEAD, a tag, three real branch names, the self-reference with `./`, `%H` or a line wrap, extensions .MD and .txt, `..x.md`, a broken link, a named pipe, README.md as a directory, handback forms part-+1, `part-1 .md`, part-, PART-1, .md.md, of a draft, hidden, in a subdirectory. Accepted as stated limits: a no-break space, a thematic break, a link reference definition, an empty fenced block. Accepted and stated nowhere: the forms of blocking finding 2 and non-blocking finding 2.
- Renderer comparison: markdown-it-py (CommonMark preset) installed with `uv pip install --target` into the container's /tmp; 22 constructions parsed and compared with the checker's verdict (results under blocking finding 2).
- Lock probes in a fixture with the byte-identical verify.sh, a 3 s media step of my own and a private lock: the results quoted under AC-4; a fast run beside a holder ran with no waiting line; a media run beside a `flock` holder printed one waiting line and started 0.36 s after the release.
- Run-level probe: an untracked file in docs/briefs/Thumbs.db/ fails the step 'No file outside the fingerprint and the listed paths' (exit 1); the same file tracked with `git add -f` passes the fast tier 5 of 5.
- Record inspection with Git: `git log --all --since='2026-10-02T19:51:00+09:00' --until='2026-10-02T20:09:00+09:00'` (four commits, quoted in blocking finding 1); author times of every lead commit against the writer windows of all six writer runs; `git show --stat` of a55605b and 5afa701.
- Live state during the review: `ls .claude/worktrees` showed two clones (verify-ave-req-096, verify-ave-req-098) beside two worktrees; three containers; C: 16 GiB free; this clone 43 MiB on the host.
- Cleanup: probe directories removed from the container's /tmp; `./scripts/dev-container.sh bash -c 'rm -rf "$UV_PROJECT_ENVIRONMENT"'` exit 0; `./scripts/dev-container.sh --stop` exit 0; clone removed; `git status --porcelain` of the main checkout empty; my scratch files deleted; no commit, no push.
```

### Blocking findings (2)

1.

```text
location: docs\requirements\AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:73-77 (§ Edge cases, 'they hold one overlap') and :99 (§ Verification strategy AC-4, 'one overlap of three code writers'); docs/WORKFLOW_LOG.md:296 and :309-310 (WF-011)
defect: The inspection of the records that carries AC-4 states one overlap of three code writers (b4f503f on 2026-10-06). By the same reading, the records hold a second one that no document names: the lead changed a script while both writers of the first launch of wf_164de68e-23b worked. The count in the Edge case and in the strategy is therefore false at this commit, and the baseline limit of two concurrent code-writing tasks was exceeded twice.
evidence: `git log --all --since='2026-10-02T19:51:00+09:00' --until='2026-10-02T20:09:00+09:00'` prints 6736401 19:51:22 (the brief, base of both worktrees), 28d241b 19:54:07 (persists the script under the run's ID, so the run was launched by then), a55605b 20:04:15 (lead, session trailer, `scripts/dev-container.sh`, 8 insertions and 5 deletions: the key of the backend environment and the exported lock path) and bf35085 20:08:08 (the relaunch recorded). docs/workflows/m0-fix-tracks-wf_164de68e-23b.js:2 says 'Relaunched ... once after 13 minutes', so the relaunch came no earlier than 20:04:22; line 220 starts both tracks together (`parallel([trackA, trackB])`). Both first handbacks say they resumed the uncommitted edits of an interrupted agent (handbacks/2026-10-02-m0-process-fixes-execution.part-1.md:9, handbacks/2026-10-02-m0-media-core-follow-ups-execution.md:10), so both implementers wrote in that window. No record says the run was stopped before the lead's edit. I found no further case: the other lead code commits fall beside at most one writer (a681e4d, a10e2df and 442f68c on 2026-10-03) or beside reviewers only, and 5afa701 during the second fix round holds documents and agent definitions only.
fix: Record the 2026-10-02 overlap in WF-011 and write the count the records hold in § Edge cases and in the AC-4 strategy ('two overlaps: a55605b on 2026-10-02 in the first thirteen minutes of wf_164de68e-23b, and b4f503f'); or, if the run had been stopped before the edit, record that fact with its source. Name the command of the inspection in the Edge case (the commit window of each writer run against the lead's commits on code paths), so the next reader can repeat the count.
```

2.

```text
location: docs\requirements\AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:52-54 and :55-60 (§ Edge cases), :96 (§ Verification strategy AC-1), :97 ('check 11 requires a commit'), :103 (§ Implementation evidence); docs/ASSUMPTIONS.md:287-304 (ASM-018); scripts/check-project-control.sh:527 (heading test `t ~ /^##? /`) and :232-262 (strip_comments_outside_spans)
defect: Two classes of forms on which a renderer and check 11 disagree are stated in no Edge case and make sentences of the file false. (a) Heading forms: check 11 reads a heading only as a line at column 0 with one or two hashes and one space. A setext underline, an ATX heading indented one to three spaces, a tab or two spaces behind the hashes, a closing hash sequence, `##` alone and a heading inside a quote are text or a foreign heading for it. A brief that renders with a repeated template heading, a template heading out of order or an empty template section passes, against 'rejects a task brief that ... repeats one or breaks their order, leaves a section empty'. (b) Code spans: check 11 reads a code span per line and sees no backslash. An ID or a commit inside a comment that a renderer hides counts when the comment stands between two backslash-escaped backticks or behind a code span that began on the line above, against 'a requirement ID, a commit ... inside an HTML comment → absent for check 11'. The stated limits cover content that renders as nothing and the fence rule; requirement files got this treatment in track A (docs/requirements/README.md § Canonical form), briefs did not.
evidence: Fixture from scripts/tests/make-fixture.sh, the suite's stub brief with one replacement, real checker; each exits 0 with no ERROR line, and markdown-it-py (CommonMark) renders as noted. `## Allowed paths`/`Notes`/`-----`/`src/` renders h2[Allowed paths] h2[Notes] p[src/]. `src/` followed by `---` renders h2[Allowed paths] h2[src/]; `None.` followed by `---` empties Dependencies and constraints the same way. `Later`/`=====` renders an h1. `Allowed paths`/`-------------`/`lib/` after the section renders a second h2[Allowed paths]. `Handback schema`/`---------------` before Requirements passes out of order. ` ## Notes` and `   ## Notes` render h2[Notes] with the section empty. ` ## Allowed paths`, `## Allowed paths ##`, `##  Allowed paths` and `> ## Allowed paths` each render a second h2[Allowed paths]. `##<TAB>Notes` renders h2[Notes]; `##` alone renders an empty h2 before `src/`. In the tree copy, 'Nothing.' and '---' below '## Forbidden paths' of 2026-10-07-m0-final-review-3.md exit 0. Code spans: 'Fix \` <!-- AVE-REQ-001 --> \` the findings.' renders '<p>Fix ` <!-- AVE-REQ-001 --> ` the findings.</p>' and exits 0; 'Fix ` the' / 'findings ` <!-- AVE-REQ-001 --> `now`.' renders '<code>the findings</code> <!-- AVE-REQ-001 --> <code>now</code>' and exits 0; the same two forms with abc1234 under Input revision exit 0. Controls: the ID or the hash in a plain comment beside text exits 1 with the rule's line. Related, inside the stated raw-HTML limit: a template heading only inside a `<div>` block counts as the heading.
fix: Either state both limits in § Edge cases and ASM-018 with the reader who judges them (check 11 reads a heading as an exact line at column 0, and a code span as a backtick run up to the next run of equal length on the same line, a backslash unseen), and narrow line 96 to 'exact heading lines'. Or close them by allow-list, as track A did for requirement files: in a brief outside fenced blocks fail a line of only `=` or `-` directly below a non-blank line, a line whose text behind one to three spaces or a `>` opens with `#`, a hash run of one or two followed by anything but one space and text, a heading with a closing hash run, a backslash before a backtick, and a line with an unpaired backtick run. Each rule gets a suite case and a mutant; the 14 briefs must still pass.
```

### Non-blocking findings (7)

1.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:81 ('three runs used two') and :99 ('a clone limit that three runs exceeded'); docs/workflows/README.md rows wf_7d9d015c-906, wf_5cd13360-464, wf_b18a5f3e-54e; docs/ENVIRONMENT_CAPABILITIES.md:142-145
defect: Two of the three runs used two reviewer clones at a time. The third, wf_5cd13360-464, is the fix run: its three writers worked in worktrees of the main checkout, two at a time, and it held no clone. The sentence also reads as the highest count, while earlier runs held five and six private clones at a time before any clone limit stood.
evidence: docs/workflows/m0-final-review-fixes.js:39-42 places each writer in `.claude/worktrees/<dir>` created by the lead and names no clone; its README row says 'each in a worktree the lead created'. The item 5 text at d4147d8 limited 'reviewer clones and release-tier runs'. WF-005 records four reviewer clones queued on the lock in wf_ed1f5104-63a (five reviewers); the red-team rows name six finders in private clones, and item 7 names 'six clone containers'.
fix: Write 'two review runs used two clones at a time, and the fix run between them two worktrees, each with a backend environment of its own', and add that runs before 2026-10-06 held up to six clones while no clone limit stood. Align WF-011 line 309 ('3 of 3 runs above the stated clone limit').
```

2.

```text
location: scripts/check-project-control.sh:1268 and :1295; docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:61-64
defect: The folder-file exception passes over any entry of that name, a directory included. A directory `docs/briefs/Thumbs.db/` or `.DS_Store/` holding a brief, or such a directory in `handbacks/`, passes check 11, although the sentence says another subdirectory and a directory in `handbacks/` fail. The run's own step catches the untracked form only.
evidence: Fixture: `docs/briefs/Thumbs.db/2026-10-02-later.md` and `docs/briefs/.DS_Store/2026-10-02-later.md` without sections exit 0; `docs/briefs/handbacks/Thumbs.db/x.md` exits 0; in the tree copy `docs/briefs/handbacks/.DS_Store/anything.md` exits 0. In a Git fixture the untracked file fails 'No file outside the fingerprint and the listed paths'; after `git add -f` the fast tier passes 5 of 5.
fix: Pass over regular files only: `.DS_Store | Thumbs.db) [ ! -f "$file" ] || continue ;;` in both loops (the suite passes 69 of 69 with the first loop changed), with one case per loop for a directory of that name.
```

3.

```text
location: scripts/tests/test-checker.sh:294-379; scripts/check-project-control.sh:524, :539, :566, :1264, :1289
defect: Five sub-rules of check 11 have no suite case that fails without them: an ID needs three digits, the hash is lowercase, names that open with two dots are read in `docs/briefs/` and in `handbacks/`, and a CRLF brief is read. The checker is correct for each today.
evidence: Each one-replacement mutant ended with pass=69 fail=0: `AVE-REQ-[0-9]` under Requirements, `[0-9a-fA-F]+` for the hex token, the `..?*` glob removed from either loop, `sub(/\r$/, "")` removed. On the real checker `AVE-REQ-01`, `ABC1234F`, `..2026-10-02-x.md` and a handback `..2026-10-02-stub.md` exit 1, and a brief with CRLF on every line exits 0.
fix: Add five cases: a two-digit ID (expect the 'names no requirement ID' line), an uppercase hash (expect 'names no commit'), a brief and a handback whose names open with two dots (expect 'is no task brief' and 'a hidden file is none'), and a complete CRLF brief (expect OK).
```

4.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:98 ('three review rounds, WF-001'); docs/WORKFLOW_LOG.md:59-66
defect: WF-001 lists four independent reviews of the media core (24499a6, 548c8ca, 90a1f2e, dc89da2; blocking findings 4, 4, 1, 0). 'Three review rounds' matches the three fix briefs, not the count of reviews the entry holds.
evidence: WF-001 'Independent review result' and 'blocking findings per round 4 → 4 → 1 → 0'.
fix: Write 'four reviews across three fix rounds, WF-001'.
```

5.

```text
location: .claude/skills/develop/SKILL.md:133-134; docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:83-84
defect: The rule counts the lead's own code work as one of the two writers and says a writing task uses the main working tree only while no other agent writes. It does not say where the lead writes code beside one worktree writer, which the records show several times.
evidence: Lead code commits on the working branch while one writer worked in a worktree: a681e4d (2026-10-03 14:13, tester of wf_d57d9cab-829 until 14:23), a10e2df and 442f68c (15:06, its implementer until 15:11), and a55605b of blocking finding 1.
fix: Add one sentence to develop § 4 and to the Edge case: the lead's own code work is the one writing task of the main working tree and runs there beside at most one writer in a worktree; or require a worktree for it.
```

6.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:99 ('the recorded deviations: WF-005 ... and WF-011'); docs/ENVIRONMENT_CAPABILITIES.md:142-145; docs/WORKFLOW_LOG.md:314-331
defect: The list reads as complete, and two recorded incidents of concurrency and resources stand outside it: the Docker engine that stopped under six clone containers and a ten-loop stress run on eight cores (item 7), and the writer whose cleanup stopped another writer's process in the shared container (WF-012).
evidence: Text of the lines named; both led to rules (stress below the core count; stop a process by its ID only).
fix: Name item 7 and WF-012 in the strategy, or write 'the recorded breaches of the three limits' so the list claims no more than it holds.
```

7.

```text
location: docs/requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md:12 and :93, :112
defect: Document state for the done transition: the dependency AVE-REQ-094 is in `verification`, and evidence.py reports AC-3 as missing until § Test evidence holds its inspection line. Both are the planned state of this run.
evidence: `grep '^status:'` on the AVE-REQ-094 file prints verification; the evidence.py show output above. Frontmatter status, the newest Status-log line, the parent's list, the TRACEABILITY row and ADR-001 (Accepted) agree.
fix: Keep the order 093, 094, then 096 for the done transition and paste the inspection lines after a PASS.
```

### Statement-audit samples

```text
The audit table of AVE-REQ-096 in handback part 4 holds six rows, so I took all six and ran every mutant they name (32), plus 14 of my own. Table line numbers are those of 07eceb1; current lines in brackets.

Rows of the table:
1. 43-44 [48-49], input revision without a commit fails, a draft waits: B-NO-COMMIT (13 cases fail), B-MIN, B-MAX, B-LEFT, B-RIGHT, B-SELFREF, B-SELF-WORD (2), B-SELF-DOT, B-SELF-SLASH, B-COMMIT-SECTION all killed. Holds; a draft without sections passes.
2. 45-46 [50-51], a handback named after no brief fails: HB-NO-BRIEF (2), HB-README, HB-MD, HB-DIR, B-PART0 (2), B-PARTX killed. Holds for 18 handback names of my own.
3. 47-49 [52-54], a heading, ID, commit or only text inside a comment is absent: B-COMMENTS (7) killed. The sentence fails for a comment between backslash-escaped backticks and behind a code span begun on the line above (blocking finding 2).
4. 50-53 [61-64], other entries fail, hidden or directory handbacks fail, folder files pass: B-ENTRIES (5), B-HIDDEN, B-DRAFTS-FILE, B-DIR-BRIEF, HB-HIDDEN (2), HB-DIR, B-FOLDER-FILES killed. Holds for 16 entry forms; a directory named like a folder file passes (non-blocking finding 2).
5. 73 [96], what check 11 rejects and what the suite covers: B-MISSING (9), B-EMPTY (12), B-ORDER (3), B-REPEAT, B-NO-ID (3), B-ID-SECTION, B-FENCE, B-FOREIGN (2), B-H1 killed; every case the sentence lists exists at test-checker.sh:299-379. The half 'rejects a brief that repeats a heading, breaks the order, leaves a section empty' fails for the heading forms of blocking finding 2.
6. 80 [103], implementation evidence of check 11: as rows 1 to 5.

Sentences checked from scratch:
- [42-44] seven review runs without a brief between 2026-10-03 and 2026-10-06: true; exactly seven README rows link no brief, four on 10-03 and three on 10-06; the rule that names review workflows dates from a5c81d3.
- [45-47] one brief of 2026-10-02 names its criteria through the linked fix brief: true; 13 of 14 Requirements sections hold AC numbers or edge cases, 2026-10-02-m0-process-fixes-execution.md holds none.
- [68-71] and [97] three runs confirmed the branch name, Git confirms every base: true; 13 of 13 parents match.
- [73-77] the records hold one overlap: false; a second on 2026-10-02 (blocking finding 1).
- [78-82] item 5 let one clone at a time and three runs used two: two runs used clones, the third worktrees (non-blocking finding 1).
- [85-86] a second heavy job waits with one waiting line; the fast tier takes no lock: true in my probes.
- [87-90] a claim beside a stranger overlaps: true as stated; the run's media step ran 2.18-5.18 s inside a hold that ended at 6.01 s.
- [99] the list of lock cases: true; each of the 15 exists at test-verify-tiers.sh:480-526.
- [98] three review rounds, WF-001: WF-001 lists four reviews (non-blocking finding 4).

Round-two dispositions sampled: finding 1 closed (lines 38-44 and 104 name both kinds of task without a brief); finding 2 stated as a limit for content that renders as nothing and for fences, with heading forms and code spans left open; finding 3 closed (all seven mutants fail); finding 4 stated (lines 87-90, ARCHITECTURE item 6); finding 5 closed (Status log names brief 2b, 13 first commits listed); finding 6 closed (lines 45-47, architect.md § Worktrees).
```

### Test quality

```text
AC-1 and AC-2 (scripts/tests/test-checker.sh:294-379). Each case builds a fresh fixture, applies one change and asserts the exit code with one specific ERROR line, or the OK line for an accepted form; the expected lines are written in the suite. The unit under test is the repository's own checker, copied into the fixture. Executed: 65 cases per awk on four awks in the release run, none skipped. Tagged by comment lines 294, 321, 337, 346 and 367. Fails without the behavior: 32 of 32 mutants of the audit table and 5 of my own. Gaps: five sub-rules without a case (non-blocking finding 3), and no case for any form of blocking finding 2, where the checker and a renderer disagree. No test can show that a launch had a brief or that a prompt carried the base check; those parts rest on the inspections I made on the records and on Git.

AC-3: inspection only, with a stated reason; no tagged test, as expected. The media tests it points to assert decoded pixels and samples against fixed values and an independent oracle module, and 84 ran and passed.

AC-4 (scripts/tests/test-verify-tiers.sh:478-526). The lock state is judged by a child process with a fresh `flock -n`, so no check reads verify.sh's own report. The waiting case reads the first line through a FIFO, requires 2 s of silence with the process alive and no second waiting line. 15 cases ok in the release run. I ran no lock mutants; round two killed 8 of 8, and verify.sh's lock code is unchanged in what those mutants touch. My own constructions (three concurrent runs, a claim with a free lock, a claim beside a stranger, a fast run and a media run beside a `flock` holder) agree with the suite. The inspection half of AC-4 is where the verdict falls: no test can count writers, and the record that does so is incomplete.

Scenarios AT-29 and AT-30: nothing else in the tree contradicts them; the evidence is tied to the current tree (FRESH).
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
