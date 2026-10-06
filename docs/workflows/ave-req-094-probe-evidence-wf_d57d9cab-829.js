// Workflow run wf_d57d9cab-829, launched 2026-10-03 with {base: '4e607de59c62fb84d75e16ec887674368d3e60f5'} from docs/briefs/2026-10-03-ave-req-094-probe-evidence.md: researcher in parallel with the tester, implementer from both handoffs, verify-requirement with a skeptic.
// Model tier aliases and the session trailers are redacted in this copy (repository files name no model).
export const meta = {
  name: 'ave-req-094-probe-evidence',
  description: 'AVE-REQ-094 repair: researcher in parallel with the tester, then the implementer from both handoffs, then independent review with a skeptic',
  phases: [
    { title: 'Investigate and test', detail: 'researcher (read-only, main checkout) in parallel with the tester (worktree)' },
    { title: 'Implement', detail: 'implementer in the worktree from the research findings and the test handback' },
    { title: 'Verify', detail: 'verify-requirement in a private clone at the implementation commit; a skeptic challenges a PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const BASE = args.base
const BRIEF = 'docs/briefs/2026-10-03-ave-req-094-probe-evidence.md'
const WT = 'ave-req-094-probe-evidence'
const WRITE = { model: '<tier alias>', effort: 'xhigh' }
const VERIFY = { model: '<tier alias>', effort: 'high' }
const TRAILERS = '<the Co-Authored-By and Claude-Session trailer lines of the session>'

const hostFacts = `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check, test or probe command takes the prefix \`./scripts/dev-container.sh\` (bash scripts/tests/<suite>.sh, bash scripts/tests/run.sh, ./scripts/probe-environment.sh, curl, python3). Repository text states things affirmatively (avoid "X, not Y", "rather than", "instead of") and never contains model identifiers.`

const worktreeRules = `Working directory: the Git worktree ${ROOT}/.claude/worktrees/${WT} (branch ${WT}, created from commit ${BASE}). Your shell starts in the main checkout, which you must leave untouched: begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${WT} && \`, and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${WT}\\ with Read, Edit, Write, Grep and Glob. First confirm that \`git rev-parse --abbrev-ref HEAD\` in the worktree prints ${WT}; otherwise return BLOCKED.
${hostFacts} Rules: keep LF line endings; never push, merge, rebase, switch branches or run \`git worktree prune\`; never amend. Mutation copies live under the container's /tmp (for example \`./scripts/dev-container.sh bash -c 'rm -rf /tmp/m && mkdir -p /tmp/m && cp -R scripts /tmp/m/ && cd /tmp/m && <edit> && bash scripts/tests/test-probe-environment.sh'\`), never in the worktree. Commit messages end with these two trailer lines:
${TRAILERS}`

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
  required: ['result', 'commits', 'handbackFile', 'items', 'verification', 'leadUpdates', 'openQuestions'],
}

const RESEARCH = {
  type: 'object',
  properties: {
    result: { type: 'string', enum: ['COMPLETE', 'PARTIAL', 'BLOCKED'] },
    commits: { type: 'array', items: { type: 'string' } },
    handbackFile: { type: 'string' },
    hosts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          host: { type: 'string' },
          requestForm: { type: 'string' },
          statusCode: { type: 'string' },
          responseTime: { type: 'string' },
          bodyBytesFetched: { type: 'string' },
        },
        required: ['host', 'requestForm', 'statusCode', 'responseTime', 'bodyBytesFetched'],
      },
    },
    curlCommand: { type: 'string' },
    oracles: { type: 'string' },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: { item: { type: 'string' }, status: { type: 'string' }, change: { type: 'string' } },
        required: ['item', 'status'],
      },
    },
    verification: { type: 'string' },
    sources: { type: 'array', items: { type: 'string' } },
    confidence: { type: 'string' },
    unknowns: { type: 'string' },
    leadUpdates: { type: 'string' },
    openQuestions: { type: 'string' },
  },
  required: ['result', 'commits', 'handbackFile', 'hosts', 'curlCommand', 'oracles', 'items', 'verification', 'sources', 'confidence', 'unknowns', 'leadUpdates', 'openQuestions'],
}

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

const researchPrompt = `Research part 1 of ${BRIEF} as briefed; read the brief first (main checkout ${ROOT}, commit ${BASE}). ${hostFacts} Modify no repository file. Run the live probes only from the container, only against the seven hosts the brief names, anonymously, with at most 10 s per request: begin every Bash command with \`cd /c/dev/AI-Video-Editor && \` and run \`./scripts/dev-container.sh curl …\` (for example \`./scripts/dev-container.sh curl -sS -o /dev/null -m 10 -I -w '%{http_code} %{time_total} %{size_download}\\n' https://pypi.org/simple/\`; compare HEAD, a byte range and a bounded GET per host; repeat each measurement twice). For the oracles, read scripts/probe-environment.sh and scripts/tests/test-probe-environment.sh and measure \`/proc/meminfo\`, \`df -h .\` and the cgroup limit files inside the container (\`./scripts/dev-container.sh bash -c '…'\`). Return the structured findings; the lead persists them as the part-1 handback, so write them as the brief's handback schema describes (commits empty; handbackFile is the path the brief names for part 1).`

const testerPrompt = `Write the tests of part 2 of ${BRIEF} as briefed; read the brief first.
${worktreeRules}
Commit: yes, after \`./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh\` and \`./scripts/verify.sh\` ran (the new checks that need part 3 stay failing and the handback lists them; the fast tier passes), message \`test: measure every AVE-REQ-094 AC-1 probe line in the probe suite\`. Write the handback file the brief names for part 2 and commit it with the tests. Return the structured handback.`

const implementerPrompt = (research, tests) => `Implement part 3 of ${BRIEF} as briefed; read the brief first.
${worktreeRules}
The worktree holds the part-2 commits ${JSON.stringify((tests && tests.commits) || [])} with the tests and the part-2 handback. The part-1 findings and the part-2 handback follow as the structured handoffs the brief names; verify them against the files and the live container before relying on them.
Commit: yes, after every test command of the brief passes, message \`AVE-REQ-094: measure every probe line and check reachability without a body\`. Write the handback file the brief names for part 3 and commit it with the work. Return the structured handback.

Part 1 findings (researcher):
${JSON.stringify(research, null, 2)}

Part 2 handback (tester):
${JSON.stringify(tests, null, 2)}`

const cloneSetup = (name, commit) => `Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${commit}\` (the LF settings matter: this host's global Git config converts line endings, which changes every hashed baseline file); the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

const verifyPrompt = (commit, research) => `Verify requirement AVE-REQ-094 independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${ROOT}). ${hostFacts} ${cloneSetup('verify-ave-req-094', commit)}

Specifics for this run:
- History: the requirement failed its first review at 4d9ef9a; its re-review at d4d3883 returned PASS, and the skeptic refuted it with evidence the lead accepted: the probe suite checked only headings for the Media tools, Toolchains, Browsers and Git sections and only a number format for memory and disk (two mutations of scripts/probe-environment.sh survived 28/28: memory and disk hard-coded; the section bodies deleted); the pypi check downloaded the 46 MB simple index and reported "unreachable" on this link while the host answered, so the verdict depended on bandwidth; no session observation of browser tools existed at that commit; no completed run composed the investigation and testing stages AC-2 names. The repair task is ${BRIEF} (read it): a researcher (part 1, structured result below; the lead persists it as handback part 1 after this run) ran in parallel with a tester (part 2, handback docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-2.md), then an implementer (part 3, handback …part-3.md) made the tests pass from both handoffs, and this review is the Verify stage of the same run. Handbacks and commit messages are claims: verify each against the code, the suite and your own runs.
- Run \`./scripts/verify.sh\` (fast tier), \`./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh\`, \`./scripts/dev-container.sh bash scripts/tests/run.sh\`, \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-094 --require-fresh\` (the tooling suites run in the release tier, so the fast manifest reports AC-1 as missing: judge the suite run directly) and the live probe \`./scripts/dev-container.sh ./scripts/probe-environment.sh\` (every Network line must read HTTP <code>; note the time it takes).
- AC-1: for every measured line the suite now checks (memory, disk, media tools, toolchains, browsers, Git, network through a fake curl), mutate scripts/probe-environment.sh in your clone (hard-code the value, delete the line, send an unbounded GET) and confirm the suite fails; confirm the test oracles are measured by the test with their own commands (no value read from the probe's output). Perform the AC-1 inspections the requirement's § Verification strategy states (the Claude Code rows of docs/ENVIRONMENT_CAPABILITIES.md against .claude/settings.json, the recorded handbacks and this session's harness; the Browser tools row).
- AC-2: judge whether the repository and this run show a composition of investigation, implementation, testing and independent review with structured handoffs and dependency-aware parallelism: the brief's parts, the two handbacks with their commits in the clone, the fact that this review runs as the Verify stage after the implementation stage, and the earlier runs in docs/workflows/. Inspect AC-3 and AC-4 as the strategy states.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
Return the report fields as specified by the schema; test_evidence_lines on PASS include one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.

Part 1 findings (researcher), for your inspection:
${JSON.stringify(research, null, 2)}`

const challengePrompt = (commit, report) => `A reviewer returned PASS for AVE-REQ-094 at commit ${commit}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${hostFacts} ${cloneSetup('challenge-ave-req-094', commit)}

Read docs/requirements/AVE-REQ-094-*.md in the clone (Acceptance criteria, Verification strategy, Implementation evidence), ${BRIEF} and its handbacks, and the reviewer's report below; check the strongest claims yourself (run the cited suites, mutate scripts/probe-environment.sh in the clone to see whether the suite fails, run the live probe, inspect the cited documents). Set refuted=true only with concrete evidence; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const [research, tests] = await parallel([
  () => agent(researchPrompt, { label: 'research:probe-network-oracles', phase: 'Investigate and test', schema: RESEARCH, agentType: 'researcher', ...WRITE }),
  () => agent(testerPrompt, { label: 'test:probe-suite', phase: 'Investigate and test', schema: HANDBACK, agentType: 'tester', ...WRITE }),
])
if (!tests || tests.result === 'BLOCKED') {
  log('tester blocked or missing; stopping before implementation')
  return { research, tests, implementation: null, review: null, challenge: null }
}
const implementation = await agent(implementerPrompt(research, tests), { label: 'implement:probe', phase: 'Implement', schema: HANDBACK, agentType: 'implementer', ...WRITE })
if (!implementation || implementation.result === 'BLOCKED' || !implementation.commits || implementation.commits.length === 0) {
  log('implementer blocked or without commits; stopping before review')
  return { research, tests, implementation, review: null, challenge: null }
}
const commit = implementation.commits[implementation.commits.length - 1]
const review = await agent(verifyPrompt(commit, research), { label: 'verify:AVE-REQ-094', phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...VERIFY })
let challenge = null
if (review && review.verdict === 'PASS') {
  challenge = await agent(challengePrompt(commit, review), { label: 'challenge:AVE-REQ-094', phase: 'Verify', schema: CHALLENGE, agentType: 'reviewer', ...VERIFY })
}
log(`AVE-REQ-094 at ${commit}: ${review ? review.verdict : 'missing'}${challenge ? (challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`)
return { research, tests, implementation, commit, review, challenge }
