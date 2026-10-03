// Record of workflow run wf_ed1f5104-63a (2026-10-03), launched with args {commit: 'd4d3883'}:
// verify-requirement reviews of AVE-REQ-093/094/096/097/098 in private clones under
// .claude/worktrees/, a skeptic per PASS, plus an independent review of WORKFLOW_LOG.md entries
// WF-001 to WF-005. The tier aliases are redacted: repository files carry no model identifier.
export const meta = {
  name: 'verify-m0-process-requirements-2',
  description: 'Independent verify-requirement reviews of AVE-REQ-093/094/096/097/098 at the given commit, each PASS challenged by a skeptic',
  phases: [
    { title: 'Verify', detail: 'one reviewer per requirement, following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute each PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const VERIFY = { model: '<tier alias>', effort: 'high' }
const REQS = [
  { id: 'AVE-REQ-093', release: false },
  { id: 'AVE-REQ-094', release: false },
  { id: 'AVE-REQ-096', release: false },
  { id: 'AVE-REQ-097', release: true },
  { id: 'AVE-REQ-098', release: false },
]

const setup = (name) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, pytest, bash scripts/tests/run.sh). A private clone gets its own container; the heavy-media lock is shared through the state volume, so a media or release tier can wait for another agent's run (use the background or a 10-minute timeout).
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\`; the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

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
- The requirement failed its first review at 4d9ef9a; the fix brief docs/briefs/2026-10-02-m0-process-verification-fixes.md (items 1 to 26) and the execution brief docs/briefs/2026-10-02-m0-process-fixes-execution.md with the handbacks under docs/briefs/handbacks/ describe what changed. They are claims: verify each item that concerns ${r.id} yourself, and judge whether the earlier blocking findings are closed.
- Run \`./scripts/verify.sh\` (fast tier)${r.release ? ' and `./scripts/verify.sh --tier release` once (this requirement covers the tiers and the evidence gates; it waits for the shared heavy-media lock)' : ''}, then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show ${r.id} --require-fresh\`, plus every test suite or command that evidences the ACs (the tooling suites live in scripts/tests/; run individual suites when only some are relevant: \`./scripts/dev-container.sh bash scripts/tests/<suite>.sh\`).
- The requirement's § Verification strategy states, per AC, whether evidence is a test or an inspection; perform every stated inspection yourself (read the documents, Git history, workflow logs, settings) and judge whether it really shows the AC. An AC whose only evidence is an inspection that does not show the behavior is FAIL.
- The repository now verifies on a Windows host through a development container (ADR-009: scripts/dev-container.sh, the re-execution at the end of scripts/verify.sh, .devcontainer/Dockerfile). Judge whether that preserves the gates the ACs require (one entry point with identical behavior for humans, the coding agent, the Stop hook and CI; nothing weakened or skipped).
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
- Hunt false positives per section 8 of the skill (mutate in your clone to confirm a critical test fails without its behavior).
Return the report fields as specified by the schema; test_evidence_lines on PASS include one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.`

const challengePrompt = (r, report) => `A reviewer returned PASS for ${r.id} at commit ${COMMIT}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${setup(`challenge-${r.id.toLowerCase()}`)}

Read docs/requirements/${r.id}-*.md in the clone (Acceptance criteria, Verification strategy, Implementation evidence) and the reviewer's report below; check the strongest claims yourself (run the cited tests, mutate the behavior to see whether they fail, inspect the cited documents). Set refuted=true only with concrete evidence; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const WF_REVIEW = {
  type: 'object',
  properties: {
    entries: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, verdict: { type: 'string', enum: ['SUPPORTED', 'UNSUPPORTED'] }, evidence: { type: 'string' }, correction: { type: 'string' } },
        required: ['id', 'verdict', 'evidence'],
      },
    },
    summary: { type: 'string' },
  },
  required: ['entries', 'summary'],
}

const wfLogPrompt = `Independent review of the workflow log docs/WORKFLOW_LOG.md at commit ${COMMIT}: entries WF-001 to WF-005 (AVE-REQ-095; acceptance scenario AT-29 needs a reviewed log of workflow changes). ${setup('review-workflow-log')}

For each entry, check every factual claim against the repository: the observed failure and its evidence (briefs, handbacks, commits, workflow records under docs/workflows/, test files), the change it proposes (does the named skill, script or prompt text contain it?), the evaluation set (do the named tests or suites exist and run?), and the measured before/after result (is it recorded anywhere you can read, or only asserted?). Run the named test suites where they exist (\`./scripts/dev-container.sh bash scripts/tests/<suite>.sh\`). Judge each entry SUPPORTED when every claim has repository evidence and the keep/revert decision follows from it, else UNSUPPORTED with the claim that lacks evidence and the exact correction the entry needs. Modify nothing.`

const wfReview = agent(wfLogPrompt, { label: 'review:workflow-log', phase: 'Verify', schema: WF_REVIEW, agentType: 'reviewer', ...VERIFY })

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
const workflowLog = await wfReview
log(out.map((x) => `${x.id}: ${x.report ? x.report.verdict : 'missing'}${x.challenge ? (x.challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`).join('; '))
return { requirements: out, workflowLog }
