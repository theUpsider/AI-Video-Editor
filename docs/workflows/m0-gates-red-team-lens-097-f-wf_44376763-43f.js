// Run wf_44376763-43f (2026-10-06): lens 097-F of docs/briefs/2026-10-03-m0-gates-red-team.md at 35f99c5, run again after a connection error ended it in wf_98f469f7-ec5.
// Copied from the session's script with the agents' tier alias redacted (repository files name no model).
export const meta = {
  name: 'm0-gates-red-team-lens-097-f',
  description: 'Lens 097-F of the M0 gates red-team pass, run again after a connection error',
  phases: [{ title: 'Find', detail: 'lens 097-F in a private clone' }],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const BRIEF = 'docs/briefs/2026-10-03-m0-gates-red-team.md'
const VERIFY = { model: '<tier alias>', effort: 'xhigh' }

const LENSES = [
  { key: '097-F', req: 'AVE-REQ-097', name: 'the pytest plugin, the hooks and CI' },
]

const setup = (name) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check, test or probe command takes the prefix \`./scripts/dev-container.sh\` (python3, bash scripts/tests/<suite>.sh, bash -c '...').
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\`; the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Probes happen only in that clone; restore it (\`git status --short\` empty) before the next probe. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

const FINDING = {
  type: 'object',
  properties: {
    title: { type: 'string' },
    criterion: { type: 'string', description: 'requirement and AC, e.g. AVE-REQ-093 AC-3' },
    class: { type: 'string', enum: ['blocking', 'boundary'] },
    reproduction: { type: 'string', description: 'exact commands run in the clone' },
    observed: { type: 'string', description: 'the output that shows the gate passing or the evidence credited' },
    expected: { type: 'string' },
    fix: { type: 'string', description: 'smallest change and the suite case that holds it' },
  },
  required: ['title', 'criterion', 'class', 'reproduction', 'observed', 'expected', 'fix'],
}
const RESULT = {
  type: 'object',
  properties: {
    lens: { type: 'string' },
    findings: { type: 'array', items: FINDING },
    held: { type: 'array', items: { type: 'string' }, description: 'probes the gates rejected, one line each' },
    baseline: { type: 'string' },
    cleanup: { type: 'string' },
  },
  required: ['lens', 'findings', 'held', 'baseline', 'cleanup'],
}

const finderPrompt = (l) => `Red-team lens ${l.key} (${l.name}) of ${BRIEF} as briefed; read the brief first in your clone (it holds the history of earlier findings, the lens definitions, the scope rule that separates blocking findings from boundary notes, the constraints and the handback schema), then docs/requirements/${l.req}-*.md (Acceptance criteria, Edge cases, Verification strategy, Implementation evidence) and the gate code your lens names. You are a read-only reviewer: your job is to find every remaining way to make a gate pass, or evidence credit a criterion, while the behavior the criterion states is violated, within your lens. ${setup(`redteam-${l.key.toLowerCase()}`)}

Work through your lens systematically: list the inputs the gate reads and the decisions it takes, then try to move each decision with a change outside the gate's own code. Every finding carries the exact reproduction and the observed output from a run in your clone; a probe the gate rejected goes into \`held\` as one line (what you changed, how the gate answered), so the lead sees your coverage. Aim for breadth first (at least a dozen distinct probes), then depth on anything that passed. Report nothing you did not run.`

const criticPrompt = (req, results) => `Completeness critic for ${req} in the red-team pass of ${BRIEF}; read the brief first in your clone, then docs/requirements/${req}-*.md and the gate code it names. Three finders have probed the gates of ${req}; their results follow. Your job: name what they left out (an input the gate reads that nobody varied, a decision nobody tried to move, a claim of the requirement's Edge cases or Verification strategy nobody tested, a combination of two changes), and probe those gaps yourself. Repeat none of the probes listed under findings or held. ${setup(`redteam-critic-${req.toLowerCase()}`)}

Return the same structure as a finder (lens: "critic ${req}"): findings with exact reproductions and observed output from runs in your clone, and \`held\` lines for the new probes the gates rejected. Report nothing you did not run.

Finder results:
${JSON.stringify(results, null, 2)}`

const found = (await parallel(LENSES.map((l) => () =>
  agent(finderPrompt(l), { label: `find:${l.key}`, phase: 'Find', schema: RESULT, agentType: 'reviewer', ...VERIFY })
    .then((r) => (r ? { ...r, key: l.key, req: l.req } : null))
))).filter(Boolean)
log(`finders: ${found.map((r) => `${r.key} ${r.findings.length} finding(s), ${r.held.length} held`).join('; ')}`)
const missing = LENSES.filter((l) => !found.some((r) => r.key === l.key)).map((l) => l.key)
if (missing.length) log(`no result from: ${missing.join(', ')}`)

return { commit: COMMIT, finders: found, missing }
