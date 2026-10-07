// Third round of the final M0 review, from docs/briefs/2026-10-07-m0-final-review-3.md: one reviewer per
// requirement following verify-requirement in a private clone, and a skeptic for each PASS; two lanes at a
// time, so at most two clones exist at once (develop § 4 Concurrency limits).
// Launch arguments: {commit: '<full hash of the brief commit on m0-final-integration>', model: '<tier alias>',
// effort: '<effort level>', only: ['AVE-REQ-NNN', ...] (optional)}. The model alias arrives as an argument, so
// this file names no model.
export const meta = {
  name: 'm0-final-review-3',
  description: 'Third round of the final M0 review: verify-requirement and a skeptic per PASS for the five M0 requirements, two lanes at a time',
  phases: [
    { title: 'Verify', detail: 'one reviewer per requirement, following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute each PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const BRIEF = 'docs/briefs/2026-10-07-m0-final-review-3.md'
const COMMIT = args.commit
const ONLY = args.only || null
const AGENT = { model: args.model, effort: args.effort }

const REQS = [
  { id: 'AVE-REQ-093', last: 'docs/briefs/handbacks/2026-10-06-m0-final-review-2b.part-1.md', fixes: 'part 1 (track A)' },
  { id: 'AVE-REQ-097', last: 'docs/briefs/handbacks/2026-10-06-m0-final-review-2b.part-4.md', fixes: 'parts 3 and 4 (tracks B1 and B2)' },
  { id: 'AVE-REQ-096', last: 'docs/briefs/handbacks/2026-10-06-m0-final-review-2b.part-3.md', fixes: 'part 4 (track B2, the cases of check 11) and the Status log of the requirement (the lead closed the other items)' },
  { id: 'AVE-REQ-098', last: 'docs/briefs/handbacks/2026-10-06-m0-final-review-2b.part-5.md', fixes: 'parts 4 and 3 (tracks B2 and B1)' },
  { id: 'AVE-REQ-094', last: 'docs/briefs/handbacks/2026-10-06-m0-final-review-2b.part-2.md', fixes: 'part 2 (track C)' },
].filter((r) => !ONLY || ONLY.includes(r.id))

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
    statement_samples: { type: 'string', description: 'the rows of the statement-audit table you sampled and the sentences you checked from scratch, each with its result' },
    test_quality: { type: 'string' },
    test_evidence_lines: { type: 'string', description: 'on PASS: the lines for the Test evidence section as the brief states; on FAIL: "None — verdict FAIL."' },
  },
  required: ['verdict', 'requirement', 'acceptance_criteria', 'verification_runs', 'blocking', 'non_blocking', 'statement_samples', 'test_quality', 'test_evidence_lines'],
}
const CHALLENGE = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean', description: 'true when at least one criterion judged PASS is in fact unmet or unevidenced' },
    disputed_acs: { type: 'array', items: AC_ROW },
    reasoning: { type: 'string' },
  },
  required: ['refuted', 'disputed_acs', 'reasoning'],
}

const setup = (name) => `Private clone: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\` (the commit lies on branch m0-final-integration, which the clone receives as a remote branch), then confirm that \`git -C .claude/worktrees/${name} rev-parse HEAD\` prints exactly ${COMMIT}; otherwise report BLOCKED with both hashes. Begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Never write into the main checkout ${ROOT} or another worktree. At the end run, in the clone, \`./scripts/dev-container.sh bash -c 'rm -rf "$UV_PROJECT_ENVIRONMENT"'\` and \`./scripts/dev-container.sh --stop\`, and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`.`

const verifyPrompt = (r) => `You are the reviewer of ${r.id} in the review run briefed in ${BRIEF} (read the brief first, in your clone; it states your inputs, limits, commands and report). Verify ${r.id} at commit ${COMMIT} by following .claude/skills/verify-requirement/SKILL.md step by step.
${setup(`verify-${r.id.toLowerCase()}`)}
The second round's report on this requirement is ${r.last}; the dispositions of its findings and the statement-audit tables are in handback ${r.fixes} of docs/briefs/2026-10-07-m0-review-2-fixes.md.
Return the report fields of the schema.`

const challengePrompt = (r, report) => `You are the skeptic for ${r.id} in the review run briefed in ${BRIEF} (read the brief first, in your clone). A reviewer returned PASS for ${r.id} at commit ${COMMIT}; try to refute that verdict as develop § 6 and the brief describe: one criterion judged PASS that is unmet, unevidenced, evidenced only by a check that cannot fail, or by an inspection that shows something else. Set refuted=true only with evidence from a run or a file at this commit.
${setup(`challenge-${r.id.toLowerCase()}`)}
The second round's report on this requirement is ${r.last}.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const one = async (r) => {
  const report = await agent(verifyPrompt(r), { label: `verify:${r.id}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...AGENT })
  let challenge = null
  if (report && report.verdict === 'PASS') {
    challenge = await agent(challengePrompt(r, report), { label: `challenge:${r.id}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer', ...AGENT })
  }
  log(`${r.id} at ${COMMIT.slice(0, 7)}: ${report ? report.verdict : 'missing'}${challenge ? (challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`)
  return { id: r.id, commit: COMMIT, report, challenge }
}

// Two lanes: the requirements of a lane run one after the other, so two reviewers work at a time.
const lanes = [[], []]
REQS.forEach((r, index) => lanes[index % 2].push(r))
const lane = async (items) => {
  const done = []
  for (const r of items) done.push(await one(r))
  return done
}
const results = (await parallel(lanes.filter((items) => items.length).map((items) => () => lane(items)))).flat().filter(Boolean)
return { commit: COMMIT, requirements: results }
