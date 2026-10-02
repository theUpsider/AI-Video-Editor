export const meta = {
  name: 'verify-m0-process-requirements',
  description: 'Independent verify-requirement reviews of AVE-REQ-093/094/096/097/098 at 4d9ef9a, each PASS challenged by a skeptic',
  phases: [
    { title: 'Verify', detail: 'one reviewer per requirement, following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute each PASS' },
  ],
}

const REPO = '/home/user/AI-Video-Editor'
const COMMIT = '4d9ef9a'
const REQS = [
  { id: 'AVE-REQ-093', release: false },
  { id: 'AVE-REQ-094', release: false },
  { id: 'AVE-REQ-096', release: false },
  { id: 'AVE-REQ-097', release: true },
  { id: 'AVE-REQ-098', release: false },
]

const SETUP = `Work in a private clone, never in ${REPO}: \`tmp=$(mktemp -d); git clone -q --no-hardlinks ${REPO} "$tmp/repo" && git -C "$tmp/repo" checkout -q ${COMMIT}\`, then \`cd "$tmp/repo"\` and \`uv sync --frozen --directory backend\` (set AVE_VAR_DIR="$tmp/var" for every command). Paths below are relative to that clone. Delete $tmp when done. The clone is a Git repository, so verify.sh fingerprints and \`python3 scripts/evidence.py show <ID> --require-fresh\` work there. Another reviewer runs concurrently: run at most one heavy command (a verify.sh tier or the tooling suites) at a time.`

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
    test_evidence_lines: { type: 'string', description: 'on PASS: ready-to-paste ## Test evidence lines per docs/requirements/README.md; on FAIL: "None — verdict FAIL."' },
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

const verifyPrompt = (r) => `Verify requirement ${r.id} independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${REPO}). ${SETUP}

Specifics for this run:
- Run \`./scripts/verify.sh\` (fast tier)${r.release ? ' and `./scripts/verify.sh --tier release` once (this requirement covers the tiers and the evidence gates)' : ''}, then \`python3 scripts/evidence.py show ${r.id} --require-fresh\`, plus every test suite or command that evidences the ACs (the tooling suites live in scripts/tests/; run individual suites rather than all of them when only some are relevant).
- The requirement's § Verification strategy states, per AC, whether evidence is a test or an inspection; perform every stated inspection yourself (read the documents, Git history, workflow logs, settings) and judge whether it really shows the AC. An AC whose only evidence is an inspection that does not show the behavior is FAIL.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
- Hunt false positives per section 8 of the skill (mutate in your clone to confirm a critical test fails without its behavior; delete __pycache__ before rerunning mutated Python).
Return the report fields as specified by the schema.`

const challengePrompt = (r, report) => `A reviewer returned PASS for ${r.id} at commit ${COMMIT}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${SETUP}

Read docs/requirements/${r.id}-*.md in the clone (Acceptance criteria, Verification strategy, Implementation evidence) and the reviewer's report below; check the strongest claims yourself (run the cited tests, mutate the behavior to see whether they fail, inspect the cited documents). Set refuted=true only with concrete evidence; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const results = await pipeline(
  REQS,
  (r) => agent(verifyPrompt(r), { label: `verify:${r.id}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer' }),
  async (report, r) => {
    if (!report) return { id: r.id, report: null, challenge: null }
    if (report.verdict !== 'PASS') return { id: r.id, report, challenge: null }
    const challenge = await agent(challengePrompt(r, report), { label: `challenge:${r.id}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer' })
    return { id: r.id, report, challenge }
  },
)

const out = results.filter(Boolean)
log(out.map((x) => `${x.id}: ${x.report ? x.report.verdict : 'missing'}${x.challenge ? (x.challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`).join('; '))
return out
