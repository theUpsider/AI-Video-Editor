// Workflow run wf_b5fa6671-c21, launched 2026-10-03 with {commit: '442f68c'}: fifth independent review of AVE-REQ-093 (after the supersession fix 442f68c) and second review of AVE-REQ-097 (after the check-count fix a10e2df), each PASS challenged by a skeptic.
// Model tier aliases are redacted in this copy (repository files name no model).
export const meta = {
  name: 'verify-093-097',
  description: 'Independent verify-requirement reviews of AVE-REQ-093 (fifth) and AVE-REQ-097 (second) at the given commit, each PASS challenged by a skeptic',
  phases: [
    { title: 'Verify', detail: 'one reviewer per requirement, following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute each PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const VERIFY = { model: '<tier alias>', effort: 'high' }

const setup = (name) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, pytest, bash scripts/tests/run.sh). A private clone gets its own container; the heavy-media lock is shared through the state volume, so a media or release tier can wait for another agent's run (use the background or a 10-minute timeout).
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\`; the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

const AC_ROW = {
  type: 'object',
  properties: { ac: { type: 'string' }, verdict: { type: 'string', enum: ['PASS', 'FAIL'] }, evidence: { type: 'string' } },
  required: ['ac', 'verdict', 'evidence'],
}
const FINDING = {
  type: 'object',
  properties: { location: { type: 'string' }, defect: { type: 'string' }, evidence: { type: 'string' }, fix: { type: 'string' } },
  required: ['location', 'defect', 'evidence', 'fix'],
}
const REPORT = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    requirement: { type: 'string' },
    acceptance_criteria: { type: 'array', items: AC_ROW },
    verification_runs: { type: 'array', items: { type: 'string' } },
    blocking: { type: 'array', items: FINDING },
    non_blocking: { type: 'array', items: FINDING },
    test_quality: { type: 'string' },
    test_evidence_lines: { type: 'string', description: 'on PASS: ready-to-paste ## Test evidence lines per docs/requirements/README.md, including "- AC-n → inspection: …" lines for inspected criteria; on FAIL: "None — verdict FAIL."' },
  },
  required: ['verdict', 'requirement', 'acceptance_criteria', 'verification_runs', 'blocking', 'non_blocking', 'test_quality', 'test_evidence_lines'],
}
const CHALLENGE = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean', description: 'true when at least one AC judged PASS is in fact unmet or unevidenced' },
    disputed_acs: { type: 'array', items: AC_ROW },
    reasoning: { type: 'string' },
  },
  required: ['refuted', 'disputed_acs', 'reasoning'],
}

const REQS = [
  {
    id: 'AVE-REQ-093',
    release: false,
    history: `History: review 1 at 4d9ef9a FAILED (fix brief docs/briefs/2026-10-02-m0-process-verification-fixes.md, executed per docs/briefs/2026-10-02-m0-process-fixes-execution.md); review 2 at d4d3883 FAILED (the per-file hash check lived in the package's own validator; fixed in 0e4f8d9: check_baseline.py verifies the manifest's inventory and every hash itself); review 3 at 97a8d20 PASSED and its skeptic refuted AC-3 (a continuation line, fenced block or sub-heading inside § Acceptance criteria could qualify a criterion unnoticed; fixed in a681e4d: the section holds criterion lines only, symbolic links in the package are rejected, an edited validator is never run); review 4 at 08237ac PASSED and its skeptic refuted AC-3 again: a version-one human requirement set to \`status: superseded\` with \`superseded_by\` naming a weaker derived requirement that carries none of its criteria passed check_baseline.py, check-project-control.sh and the whole fast tier. The fix commit after 08237ac claims: check_supersession in scripts/check_baseline.py requires a \`superseded\` Status-log line and a replacement (the end of any superseded_by chain) that exists; for a version-one baseline requirement the replacement keeps scope v1, is not deferred, has a priority not below the baseline's and carries every baseline criterion verbatim unless the old file logs \`AC-n changed: <reason>\` for the dropped one; an added criterion needs \`AC-n added: <reason>\`; a ticked criterion needs status done or superseded or a done line in the log; twelve new suite cases (98 in total); README § Superseding and § Baseline import state the rules. These are claims: repeat the skeptic's supersession probe yourself in the clone (the human must v1 requirement AVE-REQ-001 superseded by the proposed should AVE-REQ-102; then by a must v1 successor that carries every criterion; then one that drops a criterion with and without the log line; restore afterwards), repeat the earlier probes (neutered validator, notes inside § Acceptance criteria, symlinks, an added criterion line that waives another, a tick on a ready requirement), read check_baseline.py for a remaining way to demote or rewrite a version-one requirement without a logged reason (a chain of supersessions, a successor that is itself superseded, text differences such as trailing spaces, a criterion carried with a different tick state), and judge whether every earlier blocking finding is closed.`,
    runs: `Run \`./scripts/verify.sh\` (fast tier), then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 --require-fresh\`, plus \`./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh\` (the tooling suites run in the release tier, so the fast manifest reports their criteria as missing: judge the suite run directly). Perform the inspections § Verification strategy states (AC-2: the Git history of the six documents since f605c6c; AC-4: scripts/evidence.py check-done and scripts/verify.d/95-evidence.sh).`,
  },
  {
    id: 'AVE-REQ-097',
    release: true,
    history: `History: review 1 at 4d9ef9a FAILED (fix brief docs/briefs/2026-10-02-m0-process-verification-fixes.md, executed per docs/briefs/2026-10-02-m0-process-fixes-execution.md with handbacks under docs/briefs/handbacks/); review 2 at d4d3883 PASSED and its skeptic refuted AC-4 with a reproduced placeholder: scripts/tests/test-verify-tiers.sh replaced by a seven-line script whose body is \`exit 0\` and whose comments carry the AVE-REQ-097 tags was credited as passed evidence for every tag, the release tier passed 12 of 12, check-done certified a forced done requirement and \`show --require-fresh --require-complete\` exited 0, because scripts/tests/run.sh recorded the exit status only. The fix commit after 12dbb9d claims: run.sh captures each suite's output, reads its \`<NAME> TOTAL: pass=N fail=M\` line and records \`--checks N\`; a listed suite that exits 0 without such a line (N >= 1) fails run.sh with "no check ran"; scripts/evidence.py stores the check count, credits a suite only with exit status 0 and at least one check (a missing count counts as none), and the Python unit runner records how many tests ran; scripts/tests/test_evidence.py covers the no-op suite through the real run.sh and the collect rule. These are claims: repeat the skeptic's placeholder probe yourself in the clone (replace a listed suite by a tagged \`exit 0\` script, force a requirement to done, run \`./scripts/dev-container.sh bash scripts/tests/run.sh\` with AVE_EVIDENCE_DIR set to a run directory and \`python3 -B scripts/evidence.py check-done\`; also a suite that prints \`TOTAL: pass=0 fail=0\` and exits 0, one that prints a TOTAL line with N >= 1 but exits 1, and a Python unit file with no test; restore afterwards), mutate run.sh and evidence.py to confirm the new cases fail without the behavior, and judge whether every earlier blocking finding is closed. Note the AVE-REQ-098 reviewer's observation that one release run's manifest vanished from the bind mount in its clone (ENVIRONMENT_CAPABILITIES § Limits item 6, ASM-022): report whether you observe it.`,
    runs: `Run \`./scripts/verify.sh\` (fast tier) and \`./scripts/verify.sh --tier release\` once (this requirement covers the tiers and the evidence gates; it waits for the shared heavy-media lock), then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --tier release\`, plus every test suite or command that evidences the ACs (\`./scripts/dev-container.sh python3 -B scripts/evidence.py unittest\`, \`./scripts/dev-container.sh bash scripts/tests/run.sh\`, the backend evidence-plugin tests through the fast tier). Perform the inspections § Verification strategy states (AC-3: the Stop hook and the smoke-test records).`,
  },
]

const verifyPrompt = (r) => `Verify requirement ${r.id} independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${ROOT}). ${setup(`verify-${r.id.toLowerCase()}`)}

Specifics for this run:
- ${r.history}
- ${r.runs}
- The requirement's § Verification strategy states, per AC, whether evidence is a test or an inspection; perform every stated inspection yourself and judge whether it really shows the AC. An AC whose only evidence is an inspection that does not show the behavior is FAIL.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
- Hunt false positives per section 8 of the skill (mutate in your clone to confirm a critical test fails without its behavior; delete __pycache__ before each run of mutated Python).
Return the report fields as specified by the schema; test_evidence_lines on PASS include one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.`

const challengePrompt = (r, report) => `A reviewer returned PASS for ${r.id} at commit ${COMMIT}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${setup(`challenge-${r.id.toLowerCase()}`)}

Read docs/requirements/${r.id}-*.md in the clone (Acceptance criteria, Verification strategy, Implementation evidence) and the reviewer's report below; check the strongest claims yourself (run the cited tests, mutate the behavior to see whether they fail, inspect the cited documents). Earlier skeptics of this requirement refuted PASS verdicts with concrete probes that the reviewers had missed; look for the next such path with the same rigor, and set refuted=true only with concrete evidence; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const results = await pipeline(
  REQS,
  (r) => agent(verifyPrompt(r), { label: `verify:${r.id}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...VERIFY }),
  async (report, r) => {
    if (!report) return { id: r.id, report: null, challenge: null }
    if (report.verdict !== 'PASS') return { id: r.id, report, challenge: null }
    const challenge = await agent(challengePrompt(r, report), { label: `challenge:${r.id}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer', ...VERIFY })
    return { id: r.id, report, challenge }
  },
)
const out = results.filter(Boolean)
log(out.map((x) => `${x.id}: ${x.report ? x.report.verdict : 'missing'}${x.challenge ? (x.challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`).join('; '))
return { requirements: out }
