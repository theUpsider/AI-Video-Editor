// Workflow run wf_7d9d015c-906, launched 2026-10-06 with {commit: '2df637f', commit094: 'd4147d8'}: final review round of the M0 process requirements (AVE-REQ-093, AVE-REQ-097, AVE-REQ-096, AVE-REQ-098 on the working branch, AVE-REQ-094 on its task branch), each PASS challenged by a skeptic; two lanes at a time.
// Model tier aliases are redacted in this copy (repository files name no model).
export const meta = {
  name: 'verify-m0-final',
  description: 'Independent verify-requirement reviews of the M0 process requirements at their final commits, each PASS challenged by a skeptic; two lanes at a time',
  phases: [
    { title: 'Verify', detail: 'one reviewer per requirement, following verify-requirement in a private clone' },
    { title: 'Challenge', detail: 'a skeptic tries to refute each PASS' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const COMMIT = args.commit
const COMMIT_094 = args.commit094 || ''
const ONLY = args.only || null
const AGENT = { model: '<tier alias>', effort: 'xhigh' }

const setup = (name, commit) => `Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009): \`./scripts/verify.sh\` enters it by itself, and every other check, test or probe command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, bash scripts/tests/<suite>.sh, bash -c '...'). A private clone gets its own container; the heavy-media lock is shared through the state volume, so a media or release tier can wait for another agent's run (use the background or a 10-minute timeout and read the log). One other reviewer works on this host at the same time: keep CPU stress below four parallel busy processes.
Work in a private clone, never in the main checkout ${ROOT}: run \`cd /c/dev/AI-Video-Editor && git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/${name} && git -C .claude/worktrees/${name} checkout -q ${commit}\` (a commit of a task branch arrives in the clone as a remote branch); the clone must live under .claude/worktrees/ (the only path the container mounts). Then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Grep and Glob. Mutations and scratch runs happen only in that clone or in the container's /tmp; restore every file you changed before a run you report as evidence (\`git status --porcelain\` empty). At the end run \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && ./scripts/dev-container.sh --stop\` and then \`cd /c/dev/AI-Video-Editor && rm -rf .claude/worktrees/${name}\`. Never run \`git worktree prune\`, never commit, never push. Delete __pycache__ directories before rerunning mutated Python (WF-004).`

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

const RED_TEAM = `Since the last review a red-team pass (brief docs/briefs/2026-10-03-m0-gates-red-team.md, runs wf_98f469f7-ec5 and wf_44376763-43f at 35f99c5) attacked the gates of AVE-REQ-093 and AVE-REQ-097 from six lenses and one completeness critic per requirement. Its handbacks hold every finding with reproduction, expected behavior and the lead's disposition: docs/briefs/handbacks/2026-10-03-m0-gates-red-team.part-1.md (lenses 093-A/B/C, 20 findings), part-2.md (lenses 097-D/E/F, 35 findings), part-3.md (critic of AVE-REQ-093, 4 findings), part-4.md (critic of AVE-REQ-097, 10 findings). The lead states that every finding is fixed (commits 4413e4a, f894bbf, 13c1b7a, 863c7c2) and that 160 mutants of the new rules each fail a named case. These are claims.`

const REQS = [
  {
    id: 'AVE-REQ-093',
    commit: COMMIT,
    history: `History of AVE-REQ-093: reviews 1 and 2 FAILED (4d9ef9a, d4d3883); reviews 3 and 4 PASSED and were refuted by their skeptics for AC-3 (text inside § Acceptance criteria that qualified a criterion; a version-one human requirement superseded by a weaker derived one); review 5 at 442f68c was cut off without a verdict. ${RED_TEAM} For this requirement the fixes are: one reader of working requirement files (scripts/reqfile.py) with a canonical form that scripts/check_baseline.py and scripts/evidence.py share (docs/requirements/README.md § Canonical form); change markers in the Status log bound to the changed text by a digest; supersession rules checked along the whole chain; one file per derived ID; roadmap membership rules; the checker restarts itself isolated and loads the importer from source.`,
    runs: `Run \`./scripts/verify.sh --tier release\` once (Definition of Done item 4), then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 --require-fresh --tier release\`, \`./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh\` and \`./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py\`. Repeat at least two findings of each of the lenses 093-A, 093-B and 093-C and two of the critic's (parts 1 and 3) by their written reproduction and confirm each is rejected now; then attack the same rules from a direction no handback names (another spelling, another file kind, a rule pair that interacts, the importer, the roadmap rules). Mutate scripts/reqfile.py and scripts/check_baseline.py in the clone for at least six rules of your choice and confirm the baseline suite fails each time. Perform the inspections § Verification strategy states.`,
  },
  {
    id: 'AVE-REQ-097',
    commit: COMMIT,
    history: `History of AVE-REQ-097: review 1 FAILED (4d9ef9a); review 2 at d4d3883 PASSED and its skeptic refuted AC-4 with a listed suite reduced to \`exit 0\` that still credited its tags; review 3 at 442f68c was cut off without a verdict. ${RED_TEAM} For this requirement the fixes are listed in the requirement's § Implementation evidence and § Edge cases: the tree fingerprint and the trees it cannot see, the environment a run clears, a run directory and a record per run, registered step files only, suite results validated against tooling files, the done gate in every tier, not-run evidence, the pytest plugin's rules (ignored files, never-ran tests, marker-only selection), the ignored-file step, the safe module path, the fast tier's media stand-in, the fixture cache key, the Stop hook's limits and cache rule, check 12 of the project-control checker.`,
    runs: `Run \`./scripts/verify.sh\` (fast tier) and \`./scripts/verify.sh --tier release\` once, then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --tier release\`, \`./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests\` and the suites test-verify-tiers.sh, test-stop-hook.sh and test-checker.sh through \`./scripts/dev-container.sh bash scripts/tests/<suite>\`. Repeat at least two findings of each of the lenses 097-D, 097-E and 097-F and three of the critic's (parts 2 and 4) by their written reproduction and confirm each is rejected now; then look for the next path with which a run passes, or evidence reads fresh and complete, while a criterion's behavior is absent (a placeholder suite, a test that does not run, a file outside the fingerprint, a variable or file that changes what a step loads, a state record written by hand that a certifying path trusts). Mutate scripts/evidence.py, scripts/verify.sh, backend/tests/evidence_plugin.py and .claude/hooks/stop-verify.sh in the clone for at least eight rules of your choice and confirm a named case fails each time. Judge the Edge cases that declare limits of the mechanical gate (local state, the trusted toolchain, vacuous tests): each must be honest about what is unguarded and name the inspection that covers it. Perform the inspections § Verification strategy states (AC-3: the hooks and the smoke-test record in docs/ASSUMPTIONS.md ASM-001; AC-4: the three inspection items).`,
  },
  {
    id: 'AVE-REQ-096',
    commit: COMMIT,
    history: `History of AVE-REQ-096: review 1 FAILED (4d9ef9a); review 2 at d4d3883 PASSED and its skeptic upheld the PASS. ${RED_TEAM} Those fixes changed files this requirement relies on (scripts/verify.sh with the heavy-media lock and its confirmation of an inherited AVE_HEAVY_LOCK_HELD, scripts/check-project-control.sh, the brief and handback rules, scripts/tests/test-verify-tiers.sh), so the requirement is verified again at this commit; the earlier PASS decides nothing here.`,
    runs: `Run \`./scripts/verify.sh --tier release\` once, then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-096 --require-fresh --tier release\` and the suites that carry its tags (\`grep -rl "AVE-REQ-096" scripts/tests backend/tests\`). For the heavy-media lock probe the cases yourself: two media-tier runs started together (the second waits and prints one waiting line), AVE_HEAVY_LOCK_HELD=1 exported while nobody holds the lock (refused before any step), a fast run while the lock is held (runs). Perform every inspection § Verification strategy states (briefs and handbacks under docs/briefs/ against the rules of docs/briefs/README.md and CLAUDE.md § Delegation; independent review records in the Status logs; the concurrency limit) and judge whether each inspection shows the criterion.`,
  },
  {
    id: 'AVE-REQ-098',
    commit: COMMIT,
    history: `History of AVE-REQ-098: review 1 FAILED (4d9ef9a); review 2 at d4d3883 PASSED and its skeptic upheld the PASS. ${RED_TEAM} Those fixes changed files this requirement relies on (.claude/hooks/stop-verify.sh: the parser of stop_hook_active, the attempt limit between 1 and 10, no cached pass over a recorded failure; .claude/hooks/session-start.sh; scripts/lib/verify-state.sh; check 12 of scripts/check-project-control.sh; docs/PROGRESS.md rules), so the requirement is verified again at this commit; the earlier PASS decides nothing here.`,
    runs: `Run \`./scripts/verify.sh --tier release\` once, then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-098 --require-fresh --tier release\` and the suites that carry its tags (\`grep -rl "AVE-REQ-098" scripts/tests backend/tests\`; test-stop-hook.sh and test-session-start.sh among them). Probe the bounded continuation yourself in a fixture built by scripts/tests/make-fixture.sh (a failing tree: block, block, release at the limit; a limit of 0, 11 and a word; stop_hook_active inside a nested object; the gate switched off by variable and what check 12 says about a settings file that does it). Compare docs/PROGRESS.md at this commit with the repository (branch, commits it names, statuses of the requirements it names, the stop-safe form of delegated work) and report every disagreement. Perform every inspection § Verification strategy states.`,
  },
  {
    id: 'AVE-REQ-094',
    commit: COMMIT_094,
    history: `History of AVE-REQ-094 (task branch ave-req-094-probe-evidence): review 1 FAILED (4d9ef9a); review 2 at d4d3883 PASSED and its skeptic refuted it (probe suite checked headings only, pypi probe depended on bandwidth, browser tools unrecorded, no run composed investigation and testing); the repair ran as workflow wf_d57d9cab-829 (brief docs/briefs/2026-10-03-ave-req-094-probe-evidence.md, handbacks parts 1 to 4); its review at fcd97f0 PASSED and its skeptic refuted AC-1 (any text of nvidia-smi read as a GPU; four lines could be fixed to the host's values); the review at eb73896 (wf_db16f332-fdf, handback part 5) FAILED AC-1: the accelerator verdict counted names in /dev and any nvidia-smi line with one comma, and three mutations of the verdict survived the suite. The lead's repair on the task branch claims: only per-GPU nodes /dev/nvidia<N> and render nodes /dev/dri/renderD<N> count (control nodes, display-only nodes, directories and other entries are listed only); a nvidia-smi answer counts with exit 0 within 10 s and a row whose memory field is a figure; the suite gained the reviewer's device fixtures and row cases, a chromium-browser fake, the exact list of provider variables and a hanging nvidia-smi (133 checks); twenty-six mutations of the probe each fail the suite; § Edge cases names which nodes count and the limit that a render node of a software or virtual DRM driver reads present; the AC-3 and AC-4 strategy lines state why inspection. These are claims.`,
    runs: `Run \`./scripts/verify.sh --tier release\` once, then \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-094 --require-fresh --tier release\`, \`./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh\` three times in a row (report any check whose result changes) and the live probe \`./scripts/dev-container.sh ./scripts/probe-environment.sh\`. AC-1: repeat the two blocking findings of handback part 5 by their written reproduction; for every line the probe prints decide whether the suite compares it with a value it measures itself or drives through a fixture, whether a mutation of that line fails the suite (run mutations in a /tmp copy of scripts/ plus .env.example inside the container, and check first that the suite passes there unmutated), and whether § Verification strategy names the line as compared or as inspection-only; a compared line whose mutation survives is a finding. Read the accelerator code path for another input that turns the verdict to present without a GPU device, and judge the stated limit (render node of a software driver) against the criterion's words "accelerator access". Perform the AC-1 inspections the strategy states (the Claude Code rows of docs/ENVIRONMENT_CAPABILITIES.md against .claude/settings.json, the recorded handbacks and this session's harness). AC-2: judge whether the repository shows a composition of investigation, implementation, testing and independent review with structured handoffs and dependency-aware parallelism (the probe-evidence brief with its handbacks and commits, the persisted scripts in docs/workflows/ with their README rows). Inspect AC-3 and AC-4 as the strategy states. The dependency AVE-REQ-093 is still in-progress on this branch: the lead moves AVE-REQ-093 to done first; report it as non-blocking.`,
  },
].filter((r) => r.commit && (!ONLY || ONLY.includes(r.id)))

const verifyPrompt = (r) => `Verify requirement ${r.id} at commit ${r.commit} independently by following .claude/skills/verify-requirement/SKILL.md step by step (read it in the clone; you are the reviewer it describes; modify no files in ${ROOT}). ${setup(`verify-${r.id.toLowerCase()}`, r.commit)}

Specifics for this run:
- ${r.history}
- ${r.runs}
- The requirement's § Verification strategy states, per AC, whether evidence is a test or an inspection; perform every stated inspection yourself and judge whether it really shows the AC. An AC whose only evidence is an inspection that does not show the behavior is FAIL.
- The acceptance scenarios AT-29/AT-30 are whole-product scenarios scheduled for the final review; do not fail the requirement for them, but report whether anything already contradicts them.
- Hunt false positives per section 8 of the skill (mutate in your clone to confirm a critical test fails without its behavior; delete __pycache__ before each run of mutated Python).
- Blocking means: an acceptance criterion is unmet, unevidenced, or a statement of the requirement file (Edge cases, Verification strategy, Implementation evidence) is false at this commit. Report everything else as non-blocking with its fix.
Return the report fields as specified by the schema; test_evidence_lines on PASS hold, per criterion, the tests or suites with their outcome in your release run and one \`- AC-n → inspection: <what was checked and how> — pass\` line for every inspected criterion.`

const challengePrompt = (r, report) => `A reviewer returned PASS for ${r.id} at commit ${r.commit}. Your job is to REFUTE that verdict: find at least one acceptance criterion judged PASS that is in fact unmet, unevidenced, evidenced only by a false-positive test or by an inspection that does not show the behavior. ${setup(`challenge-${r.id.toLowerCase()}`, r.commit)}

${r.history}

Read docs/requirements/${r.id}-*.md in the clone (Acceptance criteria, Edge cases, Verification strategy, Implementation evidence) and the reviewer's report below; check the strongest claims yourself (run the cited tests, mutate the behavior to see whether they fail, inspect the cited documents). Earlier skeptics of the M0 requirements refuted PASS verdicts with one concrete probe the reviewer had missed; look for the next such path with the same rigor: a statement of the requirement file that the code or a suite does not hold, a criterion evidenced only by a check that cannot fail, an inspection that shows something else than the criterion. A limit that § Edge cases states openly, with the inspection that covers it, is no refutation by itself; an unstated one is. Set refuted=true only with concrete evidence from a run or a file at this commit; list each disputed AC with your evidence.

Reviewer report:
${JSON.stringify(report, null, 2)}`

const one = async (r) => {
  const report = await agent(verifyPrompt(r), { label: `verify:${r.id}`, phase: 'Verify', schema: REPORT, agentType: 'reviewer', ...AGENT })
  let challenge = null
  if (report && report.verdict === 'PASS') {
    challenge = await agent(challengePrompt(r, report), { label: `challenge:${r.id}`, phase: 'Challenge', schema: CHALLENGE, agentType: 'reviewer', ...AGENT })
  }
  log(`${r.id} at ${r.commit}: ${report ? report.verdict : 'missing'}${challenge ? (challenge.refuted ? ' (challenge: REFUTED)' : ' (challenge: upheld)') : ''}`)
  return { id: r.id, commit: r.commit, report, challenge }
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
return { requirements: results }
