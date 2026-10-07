// Fix round after the third round of the final M0 review, from docs/briefs/2026-10-07-m0-review-3-fixes.md:
// four writers, each in a worktree the lead created from the brief's commit, two at a time (track A, then
// track C; beside them track B2a, then track B2b). Launch arguments: {base: '<full hash of the brief commit>',
// model: '<tier alias>', effort: '<effort level>', trailers: '<the two commit trailer lines of the session>',
// only: ['A', ...] (optional)}. The model alias and the trailer lines arrive as arguments, so this file names
// no model.
export const meta = {
  name: 'm0-review-3-fixes',
  description: 'Fix round after the third M0 review round: four writers in worktrees of the brief commit, two at a time',
  phases: [
    { title: 'Fix', detail: 'one implementer per track of the brief; each confirms its base commit, closes its items, audits its statements, verifies the release tier and commits on its branch' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const BRIEF = 'docs/briefs/2026-10-07-m0-review-3-fixes.md'
const BASE = args.base
const ONLY = args.only || null
const AGENT = { model: args.model, effort: args.effort }
const TRAILERS = args.trailers

const TRACKS = {
  A: { dir: 'm0-r3-fixes-a', message: 'AVE-REQ-093: read acceptance boxes and roadmap entries by grammar, refuse character references' },
  C: { dir: 'm0-r3-fixes-c', message: 'AVE-REQ-094: test credential variables without expanding them, resolve the probe root' },
  B2a: { dir: 'm0-r3-fixes-b2a', message: 'AVE-REQ-097, AVE-REQ-098: count failed runs of this tree from the kept runs, compare the injected progress file' },
  B2b: { dir: 'm0-r3-fixes-b2b', message: 'AVE-REQ-098, AVE-REQ-096, AVE-REQ-097: join list items in check 7, hold every hook handler to listed keys' },
}

const REPORT = {
  type: 'object',
  properties: {
    result: { type: 'string', enum: ['COMPLETE', 'PARTIAL', 'BLOCKED'] },
    branch: { type: 'string' },
    commit: { type: 'string', description: 'full hash of the commit on the worktree branch, or an empty string' },
    report: { type: 'string', description: 'the complete handback report in Markdown, as the brief § Handback schema states; the lead files it unchanged' },
  },
  required: ['result', 'branch', 'commit', 'report'],
}

const prompt = (key) => {
  const t = TRACKS[key]
  const tree = `${ROOT}/.claude/worktrees/${t.dir}`
  return `You are the writer of track ${key} of the brief ${BRIEF}; read the brief first, then every finding of your track in the handback parts it links, in full.
Worktree: yes — ${tree} on branch ${t.dir}, created by the lead; base commit ${BASE}; before changing anything confirm that \`git rev-parse HEAD\` in that worktree prints exactly that hash, else return BLOCKED with both hashes.
Begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${t.dir} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${t.dir}\\ with Read, Write, Edit, Grep and Glob. Never write into the main checkout ${ROOT} or into another worktree; mutation copies and probe fixtures live in the container's /tmp.
Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009). \`./scripts/verify.sh\` enters it by itself; every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, bash scripts/tests/<suite>.sh, bash -c '...'). Your worktree has its own backend environment and shares the container with the other writer: stop a process only by its process ID or by a working directory of your own. When the worktree already holds edits (the run started the task again), read \`git status\` and \`git diff\` before changing anything. The media and release tiers wait for the heavy-media lock that another writer may hold: run them in the background or with a 10-minute timeout and read the log. One other writer works on this host: keep CPU stress below four parallel busy processes.
Editing notes for this host: every file keeps LF line ends (a Python helper that writes text passes newline=""); a Bash heredoc collapses backslash escapes, so write a helper script with the Write tool and run it; \`sleep\` chains are refused, use a command with its own timeout. A merge or a new file on this host can lose the executable bit in the Git index: \`git ls-files -s\` shows mode 100755 for every script a command starts by path, else \`git update-index --chmod=+x <file>\`.
Commit: yes, on branch ${t.dir}, after \`git add -A\`, a passing \`./scripts/verify.sh --tier release\` on that tree and your inspection of \`git status\` and \`git diff --cached\`; message "${t.message}", ending with these trailer lines:
${TRAILERS}
Never push, merge, rebase or switch branches.
Return the handback report as the brief's § Handback schema states.`
}

const run = async (key) => {
  if (ONLY && !ONLY.includes(key)) return null
  const result = await agent(prompt(key), { label: `fix:${key}`, phase: 'Fix', schema: REPORT, agentType: 'implementer', ...AGENT })
  return result ? { track: key, ...result } : null
}

// Two writers at a time: tracks A and C one after the other, tracks B2a and B2b beside them.
const lane = async (keys) => {
  const done = []
  for (const key of keys) done.push(await run(key))
  return done
}
const results = (await parallel([() => lane(['A', 'C']), () => lane(['B2a', 'B2b'])])).flat().filter(Boolean)
log(results.map((r) => `${r.track}: ${r.result} ${String(r.commit || '').slice(0, 7)}`).join('; '))
return { base: BASE, tracks: results }
