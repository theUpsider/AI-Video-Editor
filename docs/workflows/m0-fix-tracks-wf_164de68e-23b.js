// Record of workflow run wf_164de68e-23b (2026-10-02), launched with args {base: '6736401'}.
// Relaunched once after 13 minutes with explicit model and effort settings; the first agents of
// both tracks continued from the interrupted agents' uncommitted edits. The session trailer lines
// and the tier aliases are redacted: repository files carry no model identifier.
export const meta = {
  name: 'm0-fix-tracks',
  description: 'M0 process fixes (4 sequential parts) in one worktree, media-core follow-ups with independent review in another',
  phases: [
    { title: 'Process fixes', detail: 'four sequential implementer parts, then the release-tier check' },
    { title: 'Media follow-ups', detail: 'implementer for items 1-13' },
    { title: 'Media review', detail: 'two independent lenses with mutation checks, fix rounds on blocking findings' },
    { title: 'Probe', detail: 'model override probe for the environment record' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
// Writing agents and reviewing agents run on the models and efforts the human chose (2026-10-02).
const IMPL = { model: '<tier alias>', effort: 'xhigh' }
const VERIFY = { model: '<tier alias>', effort: 'high' }
const RESUME_NOTE = `An earlier agent on this task was interrupted before committing. The worktree holds its uncommitted edits: start with \`git status --short\` and \`git diff\`, judge every hunk against the briefs (one hunk can be a temporary mutation that the interrupted agent had yet to revert: a deliberately broken behavior or assertion), keep what is right, repair what is wrong, and complete the rest. Rerun every mutation check yourself; treat nothing as verified.`
const BASE = args.base
const TRAILERS = '<the session's Co-Authored-By and Claude-Session trailer lines>'

const worktreeRules = (name, branch) => `
Host facts: Windows 11 with Git Bash. Repository checks run inside a Linux development container (ADR-009, docs/decisions/ADR-009-linux-development-container-for-other-hosts.md): \`./scripts/verify.sh\` enters it by itself; every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, pytest, bash scripts/tests/run.sh, flock).
Working directory: the Git worktree ${ROOT}/.claude/worktrees/${name} (branch ${branch}, created from commit ${BASE}). Your shell starts in the main checkout, which you must leave untouched: begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \`, and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Edit, Write, Grep and Glob. First confirm that \`git rev-parse --abbrev-ref HEAD\` in the worktree prints ${branch}; otherwise return BLOCKED.
Rules: keep LF line endings; give a new script its executable bit with \`git update-index --chmod=+x <path>\` after \`git add\`; never push, merge, rebase, switch branches or run \`git worktree prune\`; never amend. Long commands (media or release tier, about 6 to 10 minutes plus lock waiting) run in the background or with a 10-minute timeout. Mutation checks delete __pycache__ directories first (WF-004) and are reverted with the inverse edit or \`git checkout -- <file>\` inside the worktree. Repository text states things affirmatively (avoid "X, not Y", "rather than", "instead of") and never contains model identifiers.
Every commit message ends with these two trailer lines:
${TRAILERS}
`

const HANDBACK = {
  type: 'object',
  properties: {
    result: { type: 'string', enum: ['COMPLETE', 'PARTIAL', 'BLOCKED'] },
    commits: { type: 'array', items: { type: 'string' } },
    handbackFile: { type: 'string' },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string' },
          status: { type: 'string' },
          change: { type: 'string' },
          test: { type: 'string' },
          mutation: { type: 'string' },
        },
        required: ['item', 'status'],
      },
    },
    verification: { type: 'string' },
    leadUpdates: { type: 'string' },
    openQuestions: { type: 'string' },
  },
  required: ['result', 'commits', 'items', 'verification'],
}

const REVIEW = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    blocking: {
      type: 'array',
      items: {
        type: 'object',
        properties: { location: { type: 'string' }, defect: { type: 'string' }, evidence: { type: 'string' }, fix: { type: 'string' } },
        required: ['location', 'defect', 'evidence', 'fix'],
      },
    },
    nonBlocking: { type: 'array', items: { type: 'string' } },
    mutations: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
  required: ['verdict', 'blocking', 'summary'],
}

// ---------------------------------------------------------------- Track A: process fixes
const PARTS = [
  { n: 1, title: 'Baseline checker', items: '1, 2, 10', commit: 'AVE-REQ-093: pin the baseline outside the package and guard requirement descriptions' },
  { n: 2, title: 'Evidence tooling', items: '6, 7, 11, 19, 20, 21', commit: 'AVE-REQ-097: credit tooling evidence only from suites that ran and validate its tags' },
  { n: 3, title: 'Checker, hooks and probe', items: '3, 12, 13, 15, 22, 23, 24, 25', commit: 'AVE-REQ-094, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098: measure permissions and models, harden the checker, hooks and probe' },
  { n: 4, title: 'Procedures and concurrency', items: '4, 5, 8, 9, 14, 16, 17, 18, 26', commit: 'AVE-REQ-094, AVE-REQ-096, AVE-REQ-098: require persisted briefs and handbacks, enforce one heavy media job' },
]

const partPrompt = (part, modelProbe) => `Implement part ${part.n} ("${part.title}") of the M0 process fix work for AVE-REQ-093, AVE-REQ-094, AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098 (all in-progress).
Contract: docs/briefs/2026-10-02-m0-process-fixes-execution.md (execution plan, decisions, constraints) together with docs/briefs/2026-10-02-m0-process-verification-fixes.md (the findings with evidence and required fixes). Read both first. Do items ${part.items} only; every other item belongs to another part.
${part.n === 1 ? RESUME_NOTE : ''}
${part.n > 1 ? `Earlier parts are committed on this branch: read their handbacks under docs/briefs/handbacks/ and \`git log ${BASE}..HEAD --stat\` before you start, and build on their changes.` : ''}
${worktreeRules('m0-process-fixes', 'm0-process-fixes')}
Scope: the brief's Allowed paths override your default document boundary for this task (CLAUDE.md, .claude/**, the named docs and the named sections of the five requirement files are in scope where an item requires them). Requirement statements, acceptance criteria, statuses, Status logs, PROGRESS.md, TRACEABILITY.md, ROADMAP.md and ASSUMPTIONS.md stay the lead's: report proposed updates.
${part.n === 3 ? `Model override fact for item 3 (measured in this workflow run, ${modelProbe}): describe it in the Models row without naming any model.` : ''}
${part.n === 4 ? 'Item 5 follows the decision in the execution brief exactly (lock file path, AVE_HEAVY_LOCK_HELD, waiting line, fast tier unlocked), with a tiers-suite case that fails without the lock. After your commit, the final check of the whole task is run by a separate agent.' : ''}
Procedure per item: make the change, add the test or checker case the finding requires, confirm by mutation that the new test fails without the fix, then restore. When the part is complete: run \`./scripts/verify.sh\` (fast tier) and, because this part touches scripts or hooks, \`./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks\`; both must pass. Write the handback file docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-${part.n}.md (per item: change, test, mutation result; commands with results; proposed lead updates; open questions), inspect \`git status\` and \`git diff\`, and commit everything of this part in one commit with the subject "${part.commit}" (adjust the summary when your changes differ) plus the trailers.
Return the structured handback: result, the commit hash, the handback file path, one entry per item (status done, partial or open), the verification commands with their results, proposed updates for lead-owned documents, open questions.`

const finalPromptA = `Final check of the M0 process fix work on branch m0-process-fixes (four parts are committed; handbacks under docs/briefs/handbacks/).
Contract: docs/briefs/2026-10-02-m0-process-fixes-execution.md § Test commands and docs/briefs/2026-10-02-m0-process-verification-fixes.md.
${worktreeRules('m0-process-fixes', 'm0-process-fixes')}
Run, in the worktree: (1) \`./scripts/verify.sh --tier release\` (it takes the heavy-media lock by itself after item 5; it can wait while another agent renders); (2) \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097 AVE-REQ-098 --require-fresh\`; (3) \`./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks\`.
When a step fails because of this branch's changes, fix the root cause inside the brief's allowed paths (never weaken a check), commit with the subject "AVE-REQ-097: <imperative summary>" plus the trailers, and rerun until all three pass. Also walk items 1 to 26 of the fix brief against the branch (\`git diff ${BASE}..HEAD\`) and list every item that is open or only partly done, with the missing piece.
Write docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.final.md with the command results, the per-criterion evidence states and the open-item list, and commit it ("docs: record the final check of the M0 process fixes" plus the trailers).
Return the structured handback: result (COMPLETE only when all three commands pass on the final commit), commits you added, one entry per fix-brief item (status done, partial or open, with the evidence location), the verification results, proposed lead updates, open questions.`

const trackA = async (modelProbe) => {
  const out = []
  for (const part of PARTS) {
    const r = await agent(partPrompt(part, modelProbe), {
      label: `process:part-${part.n}`,
      phase: 'Process fixes',
      agentType: 'implementer',
      schema: HANDBACK,
      ...IMPL,
    })
    out.push({ part: part.n, handback: r })
    if (!r || r.result === 'BLOCKED') {
      log(`Process fixes: part ${part.n} returned ${r ? r.result : 'no result'}; stopping the track`)
      return { parts: out, final: null }
    }
  }
  const fin = await agent(finalPromptA, { label: 'process:final-check', phase: 'Process fixes', agentType: 'implementer', schema: HANDBACK, ...IMPL })
  return { parts: out, final: fin }
}

// ---------------------------------------------------------------- Track B: media follow-ups
const promptB = `Implement the media-core follow-ups for AVE-REQ-012 (AC-4), AVE-REQ-024 (AC-3), AVE-REQ-019 (AC-1) and AVE-REQ-020 (AC-3), all in-progress.
Contract: docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md (item 13, constraints, commands) together with docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md (items 1 to 12). Read both first. Items marked optional (5's anchor option, 9) are done when cheap and safe, else documented as the brief allows.
${RESUME_NOTE}
${worktreeRules('m0-media-follow-ups', 'm0-media-follow-ups')}
Scope: the briefs' Allowed paths; under docs/ you write only the handback file.
Every heavy media command holds the shared lock: \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock <command>\` (media tier, targeted media or slow pytest runs). Unit tests need no lock.
Procedure per item: make the change, add or strengthen the test, confirm by mutation that the test fails without the change, restore. Commit items 1 to 12 as "AVE-REQ-012, AVE-REQ-024: <imperative summary>" and item 13 on its own as "AVE-REQ-019, AVE-REQ-020: <imperative summary>", each with the trailers, after \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media\` passes. Write the handback file docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md and include it in the last commit.
Return the structured handback: result, commit hashes, the handback file path, one entry per item 1 to 13 (status, change, test, mutation result), the verification commands with results, proposed lead updates (the requirement text for item 11, assumption updates, the fixture-matrix finding), open questions.`

const lensPrompt = (lens, round, scratch) => `Independent review (${lens.name} lens, round ${round}) of the media-core follow-up work on branch m0-media-follow-ups: commits ${BASE}..m0-media-follow-ups in ${ROOT}.
Contract the work claims to satisfy: docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md and docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md (read them from the branch: \`git show m0-media-follow-ups:<path>\`), plus the handback docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md. The handback is a claim; verify it.
Host facts: Windows 11 with Git Bash; checks run in a Linux development container: prefix commands with \`./scripts/dev-container.sh\`. Work in your own scratch worktree so nothing you do touches the implementer's files: from the main checkout run \`cd /c/dev/AI-Video-Editor && git worktree add --detach .claude/worktrees/${scratch} m0-media-follow-ups\`, then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${scratch} && \`. Mutations happen only there. Remove it at the end with \`cd /c/dev/AI-Video-Editor && git worktree remove --force .claude/worktrees/${scratch}\`. Never run \`git worktree prune\`, never commit, never push.
Every heavy media command holds the shared lock: \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock <command>\`; it waits while another agent renders, so use the background or a 10-minute timeout. Delete __pycache__ directories before every mutation rerun (WF-004).
${lens.focus}
A finding is blocking when an item's required change is missing or wrong, a new or changed test passes without its fix (mutation survives), a tolerance or check was loosened, a forbidden path changed (\`git diff --stat ${BASE}..m0-media-follow-ups\`), or real media contradicts a claim. Everything else is non-blocking. Return verdict PASS only with zero blocking findings; list each blocking finding with location, defect, the evidence you measured and the required fix, and list the mutations you ran with their results.`

const LENSES = [
  {
    key: 'oracles',
    name: 'oracle strength and mutation',
    focus: 'Focus: items 1 to 4, 6, 10, 11 and 12. For each, check the change against the brief, then mutation-check the new or changed tests yourself (at least six mutations across the items, chosen by you: the rounding in the origin tie case, the error-text assertion, the exact-start guard, the gap filter threshold, the intra-only condition, a cut time). Run the unit suites and the targeted media tests.',
  },
  {
    key: 'real-media',
    name: 'real-media reconstruction',
    focus: 'Focus: items 5, 6, 9, 12 and 13. Rebuild the claims with your own constructions that the implementer has never seen: jittered MKV and MPEG-TS sources with other jitter amplitudes and seek points for the render placement bound; timestamp gaps of other sizes on both sides of 10 ms; an intra-only file with an offset origin; for item 13 at least four background colors of your choice (include saturated primaries and a dark gray) rendered as a pure-background segment and as contain bars, decoded with zscale and with the exact scaler path, compared with BT.709 limited-range spec math you compute yourself; mutation: restore the old background source and confirm the new test fails. Run the full media tier once at the end.',
  },
]

const fixPromptB = (round, findings) => `Fix the blocking review findings (round ${round}) on the media-core follow-up work, branch m0-media-follow-ups. AVE-REQ-012, AVE-REQ-024, AVE-REQ-019 and AVE-REQ-020 are in-progress.
Contract: docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md and docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md; the same allowed and forbidden paths apply.
${worktreeRules('m0-media-follow-ups', 'm0-media-follow-ups')}
Every heavy media command holds the shared lock: \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock <command>\`.
Blocking findings to fix, each with a test that fails without the fix (mutation-checked):
${JSON.stringify(findings, null, 2)}
When a finding is wrong, say so with measured evidence and leave the code unchanged for it. Run the media tier under the lock until it passes, append a "Review round ${round}" section to docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md, and commit as "AVE-REQ-012, AVE-REQ-024: fix review findings of the follow-ups (round ${round})" plus the trailers (name AVE-REQ-019, AVE-REQ-020 as well when item 13 changed).
Return the structured handback with one entry per finding.`

const reviewRound = async (round, lenses) => {
  const results = await parallel(lenses.map(lens => () =>
    agent(lensPrompt(lens, round, `review-media-${lens.key}-r${round}`), {
      label: `media-review:${lens.key}:r${round}`,
      phase: 'Media review',
      agentType: 'reviewer',
      schema: REVIEW,
      ...VERIFY,
    }).then(r => ({ lens: lens.key, review: r }))))
  return results.filter(Boolean)
}

const trackB = async () => {
  const impl = await agent(promptB, { label: 'media:follow-ups', phase: 'Media follow-ups', agentType: 'implementer', schema: HANDBACK, ...IMPL })
  if (!impl || impl.result === 'BLOCKED') {
    log(`Media follow-ups: implementer returned ${impl ? impl.result : 'no result'}; skipping the review`)
    return { implementer: impl, rounds: [] }
  }
  const rounds = []
  let lenses = LENSES
  for (let round = 1; round <= 3; round++) {
    const reviews = await reviewRound(round, lenses)
    const failed = reviews.filter(r => !r.review || r.review.verdict !== 'PASS')
    const entry = { round, reviews, fix: null }
    rounds.push(entry)
    if (reviews.length === lenses.length && failed.length === 0) break
    if (round === 3) { log('Media review: blocking findings remain after three rounds; handing them to the lead'); break }
    const findings = failed.flatMap(r => (r.review ? r.review.blocking.map(b => ({ lens: r.lens, ...b })) : [{ lens: r.lens, location: 'review', defect: 'the reviewer returned no result', evidence: 'none', fix: 'rerun the lens' }]))
    const real = findings.filter(f => f.location !== 'review')
    if (real.length > 0) {
      entry.fix = await agent(fixPromptB(round, real), { label: `media:fix-r${round}`, phase: 'Media follow-ups', agentType: 'implementer', schema: HANDBACK, ...IMPL })
    }
    lenses = LENSES.filter(l => failed.some(f => f.lens === l.key))
  }
  return { implementer: impl, rounds }
}

// ---------------------------------------------------------------- Run
phase('Probe')
const probe = await agent('Reply through the structured output with ok set to true. Do nothing else.', {
  label: 'model-override-probe',
  phase: 'Probe',
  model: '<tier alias>',
  effort: 'low',
  schema: { type: 'object', properties: { ok: { type: 'boolean' } }, required: ['ok'] },
})
const modelProbe = probe && probe.ok
  ? 'a workflow agent launched with an explicit model override from the tier-alias list completed and returned its structured result'
  : 'a workflow agent launched with an explicit model override returned no result'
log(`Model override probe: ${modelProbe}`)

const [a, b] = await parallel([() => trackA(modelProbe), () => trackB()])
return { base: BASE, modelProbe, processFixes: a, mediaFollowUps: b }
