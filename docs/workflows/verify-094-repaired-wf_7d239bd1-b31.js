// Workflow run wf_7d239bd1-b31, launched 2026-10-06 with commit 1768892: independent review of AVE-REQ-094 at the repaired task-branch commit, its PASS challenged by a skeptic.
// Model tier aliases are redacted in this copy (repository files name no model).
export const meta = {
  name: 'verify-094-repaired',
  description: 'Independent verify-requirement review of AVE-REQ-094 at the repaired task-branch commit, its PASS challenged by a skeptic',
  phases: [
    { title: 'Verify', detail: 'one reviewer following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute a PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const AGENT = { model: '<tier alias>', effort: 'xhigh' }
const REQ = 'AVE-REQ-094'

const setup = (name) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check, test or probe command takes the prefix \`./scripts/dev-container.sh\` (python3, bash scripts/tests/<suite>.sh, ./scripts/probe-environment.sh, bash -c '...'). The heavy-media lock is shared through the state volume, so a media or release tier can wait for another agent's run (use the background or a 10-minute timeout). Other agents run on this host at the same time: keep CPU stress below four parallel busy processes.
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${COMMIT}\` (the commit lies on the task branch ave-req-094-probe-evidence, which the clone receives as a remote branch); the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone or in the container's /tmp. At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

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

const HISTORY = `History of ${REQ}, each finding reproduced by its reviewer: review 1 at 4d9ef9a FAILED (fix brief docs/briefs/2026-10-02-m0-process-verification-fixes.md). Review 2 at d4d3883 PASSED and its skeptic refuted it: the probe suite checked only headings and number formats, the pypi probe depended on bandwidth, browser tools were unrecorded, and no run composed investigation and testing stages. The repair ran as workflow wf_d57d9cab-829 from docs/briefs/2026-10-03-ave-req-094-probe-evidence.md (researcher in parallel with a tester, then an implementer, then a review; handbacks parts 1 to 4 under docs/briefs/handbacks/). Its review at fcd97f0 PASSED and its skeptic refuted AC-1 (handback part 4): scripts/probe-environment.sh took any text nvidia-smi wrote as a GPU with the exit status ignored, so a host with nvidia-smi installed and no device read "accelerator: present (<diagnostic>)", the suite hid nvidia-smi in every scenario, and the cpus, memory, os user and writability lines could be fixed to the host's own values without a failing check; one suite check failed once under concurrent load. The lead's repair commits 1d9fd0d and 1768892 on the task branch claim: nvidia-smi counts only when it exits 0 and prints a GPU row ("<name>, <memory>"); nine checks drive a fake nvidia-smi; fixture inputs that differ from the host (a fake getconf and id on PATH, AVE_PROBE_PROC_DIR, AVE_PROBE_ROOT) prove the CPU count, memory, CPU model, OS user and writability lines; the CPU model follows lscpu where cpuinfo names none and reads unknown for "-"; ten mutations of the probe each fail the suite (115 checks); the requirement's Edge cases, Verification strategy and Implementation evidence state the behavior; the branch holds the working branch merged in (413450f). These are claims.`

const verifyPrompt = `Verify requirement ${REQ} independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${ROOT}). ${setup('verify-ave-req-094')}

Specifics for this run:
- ${HISTORY}
- Run \`./scripts/verify.sh\` (fast tier), \`./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh\`, \`./scripts/dev-container.sh bash scripts/tests/run.sh\`, \`./scripts/dev-container.sh python3 -B scripts/evidence.py show ${REQ} --require-fresh\` (the tooling suites record in the release tier, so the fast manifest reports AC-1 as missing: judge the suite run directly) and the live probe \`./scripts/dev-container.sh ./scripts/probe-environment.sh\` (every Network line reads HTTP <code>).
- AC-1: repeat the skeptic's probes yourself (a fake nvidia-smi first on PATH with AVE_PROBE_DEV_DIR pointing at an empty directory: a driver diagnostic with a failure, "No devices were found" with exit 6, an empty answer with exit 0, a GPU row with exit 0; the four host-value lines fixed in a /tmp copy of scripts/). Then go further: for every line the probe prints, decide whether the suite compares it with a value the suite measures itself or drives through a fixture, whether a mutation of that line fails the suite (run the mutations in a /tmp copy inside the container), and whether the requirement's § Verification strategy names the line as compared or as inspection-only; a compared line whose mutation survives is a finding. Read the accelerator code path for another input that turns the verdict to present without a device (the device-node globs, nvidia-smi rows that are no GPU, environment variables). Run the suite three times in a row and report any check whose result changes. Perform the AC-1 inspections the strategy states (the Claude Code rows of docs/ENVIRONMENT_CAPABILITIES.md against .claude/settings.json, the recorded handbacks and this session's harness; the Browser tools row).
- AC-2: judge whether the repository shows a composition of investigation, implementation, testing and independent review with structured handoffs and dependency-aware parallelism: the probe-evidence brief and its four handbacks with their commits (49ecb21, fcd97f0), the persisted script docs/workflows/ave-req-094-probe-evidence-wf_d57d9cab-829.js and its README row, and the earlier runs in docs/workflows/. Inspect AC-3 and AC-4 as the strategy states.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
Return the report fields as specified by the schema; test_evidence_lines on PASS include one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.`

const challengePrompt = (report) => `A reviewer returned PASS for ${REQ} at commit ${COMMIT}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${setup('challenge-ave-req-094')}

${HISTORY}

Read docs/requirements/${REQ}-*.md in the clone (Acceptance criteria, Edge cases, Verification strategy, Implementation evidence), the probe-evidence brief and its handbacks, and the reviewer's report below; check the strongest claims yourself (run the cited suites, mutate scripts/probe-environment.sh in a /tmp copy to see whether the suite fails, run the live probe, inspect the cited documents). Two earlier skeptics of this requirement each refuted a PASS with one concrete probe the reviewer had missed; look for the next such path with the same rigor: a statement of the requirement's Edge cases or Verification strategy that the probe or the suite does not hold, a capability the probe can report as present without it being present, an AC-1 item (workflow tools, models, subagents, worktree isolation, permissions, hooks, network, browser tools, CPU/RAM, accelerator access) that neither the probe nor a recorded inspection covers. Set refuted=true only with concrete evidence from a run; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const report = await agent(verifyPrompt, { label: `verify:${REQ}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...AGENT })
let challenge = null
if (report && report.verdict === 'PASS') {
  challenge = await agent(challengePrompt(report), { label: `challenge:${REQ}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer', ...AGENT })
}
log(`${REQ} at ${COMMIT}: ${report ? report.verdict : 'missing'}${challenge ? (challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`)
return { commit: COMMIT, report, challenge }
