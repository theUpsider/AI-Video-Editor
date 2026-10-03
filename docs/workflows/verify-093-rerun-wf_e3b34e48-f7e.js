// Workflow run wf_e3b34e48-f7e, launched 2026-10-03 with {commit: '97a8d20'}: independent re-review of AVE-REQ-093 after the hash-check fix (0e4f8d9), its PASS challenged by a skeptic.
// Model tier aliases are redacted in this copy (repository files name no model).
export const meta = {
  name: 'verify-093-rerun',
  description: 'Independent verify-requirement review of AVE-REQ-093 at the given commit after the hash-check fix, its PASS challenged by a skeptic',
  phases: [
    { title: 'Verify', detail: 'one reviewer following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute a PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const VERIFY = { model: '<tier alias>', effort: 'high' }
const REQ = { id: 'AVE-REQ-093' }

const setup = (name) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, pytest, bash scripts/tests/run.sh). A private clone gets its own container; the heavy-media lock is shared through the state volume, so a media or release tier can wait for another agent's run (use the background or a 10-minute timeout).
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\` (the LF settings matter: this host's global Git config converts line endings, which changes every hashed baseline file); the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

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

const verifyPrompt = (r) => `Verify requirement ${r.id} independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${ROOT}). ${setup(`verify-${r.id.toLowerCase()}`)}

Specifics for this run:
- History: the requirement failed its first review at 4d9ef9a (fix brief docs/briefs/2026-10-02-m0-process-verification-fixes.md, items 1 to 26, executed per docs/briefs/2026-10-02-m0-process-fixes-execution.md with handbacks under docs/briefs/handbacks/) and its re-review at d4d3883 with one blocking finding: the per-file hash check of the baseline lived in ai-video-editor-requirements/tools/validate_package.py, a package file, so inserting \`sys.exit(0)\` before \`def validate(\` in it made \`python3 -B scripts/check_baseline.py\` print "OK: baseline intact" even with a baseline criterion weakened in spec/requirements/AVE-REQ-001.md, spec/requirements.json and the working file (manifest untouched). The fix commit 0e4f8d9 claims: scripts/check_baseline.py verifies the manifest's inventory and every file's size and SHA-256 itself before it runs the validator, runs the validator only when the validator's own bytes verified, exits 1 for a removed baseline file, and scripts/tests/test-check-baseline.sh gained four cases (edited validator, weakened baseline behind an edited validator, file added behind an edited validator, removed file). These are claims: repeat both earlier probes yourself in the clone (restore the files afterwards), read the new checker code for gaps (a path the inventory walk misses, a manifest entry the checker trusts, a way to pass with a changed package), and judge whether every earlier blocking finding is closed.
- Run \`./scripts/verify.sh\` (fast tier), then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show ${r.id} --require-fresh\`, plus every test suite or command that evidences the ACs (\`./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh\`; the tooling suites run in the release tier, so the fast manifest reports their criteria as missing: judge the suite run directly).
- The requirement's § Verification strategy states, per AC, whether evidence is a test or an inspection; perform every stated inspection yourself (AC-2: the Git history of the six documents since f605c6c; AC-4: scripts/evidence.py check-done and scripts/verify.d/95-evidence.sh) and judge whether it really shows the AC.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
- Hunt false positives per section 8 of the skill (mutate the new checker code in your clone to confirm the new cases fail without the behavior; delete __pycache__ before each run).
Return the report fields as specified by the schema; test_evidence_lines on PASS include one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.`

const challengePrompt = (r, report) => `A reviewer returned PASS for ${r.id} at commit ${COMMIT}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${setup(`challenge-${r.id.toLowerCase()}`)}

Read docs/requirements/${r.id}-*.md in the clone (Acceptance criteria, Verification strategy, Implementation evidence) and the reviewer's report below; check the strongest claims yourself (run the cited tests, mutate the behavior to see whether they fail, inspect the cited documents). Try in particular to change the baseline package in a way scripts/check_baseline.py still accepts (an edited or added file, a manifest entry, a path trick, the validator) without touching BASELINE_MANIFEST_SHA256; restore the files afterwards. Set refuted=true only with concrete evidence; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const report = await agent(verifyPrompt(REQ), { label: `verify:${REQ.id}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...VERIFY })
let challenge = null
if (report && report.verdict === 'PASS') {
  challenge = await agent(challengePrompt(REQ, report), { label: `challenge:${REQ.id}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer', ...VERIFY })
}
log(`${REQ.id}: ${report ? report.verdict : 'missing'}${challenge ? (challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`)
return { requirements: [{ id: REQ.id, report, challenge }] }
