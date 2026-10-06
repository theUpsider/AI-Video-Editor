// Fix round of the final M0 review, from docs/briefs/2026-10-06-m0-final-review-fixes.md: three writers, each in
// a worktree the lead created from the brief's commit, two at a time (track A, then track B2; beside them
// track B1). Launch arguments: {base: '<full hash of the brief commit>', model: '<tier alias>',
// effort: '<effort level>', trailers: '<the two commit trailer lines of the session>'}. The model alias and the
// trailer lines arrive as arguments, so this file names no model.
export const meta = {
  name: 'm0-final-review-fixes',
  description: 'Fix round of the final M0 review: three writers in worktrees of the brief commit, two at a time',
  phases: [
    { title: 'Fix', detail: 'one implementer per track of the brief; each confirms its base commit, verifies the release tier and commits on its branch' },
  ],
}

const ROOT = 'C:/dev/AI-Video-Editor'
const BRIEF = 'docs/briefs/2026-10-06-m0-final-review-fixes.md'
const BASE = args.base
const AGENT = { model: args.model, effort: args.effort }
const TRAILERS = args.trailers

const TRACKS = {
  A: { dir: 'm0-final-fixes-a', message: 'AVE-REQ-093: close the findings of the final review on the baseline gate' },
  B1: { dir: 'm0-final-fixes-b1', message: 'AVE-REQ-097, AVE-REQ-096, AVE-REQ-098: start the steps from a named environment, fingerprint by content, close the hook findings' },
  B2: { dir: 'm0-final-fixes-b2', message: 'AVE-REQ-097, AVE-REQ-096, AVE-REQ-098: close the findings of the final review on the evidence tool and the checker' },
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
Begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${t.dir} && \` (the shell's directory can reset between commands) and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${t.dir}\\ with Read, Write, Edit, Grep and Glob. Never write into the main checkout ${ROOT} or into another worktree; mutation copies live in the container's /tmp.
Host facts: Windows 11 with Git Bash; the repository's checks run inside a Linux development container (ADR-009). \`./scripts/verify.sh\` enters it by itself; every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, bash scripts/tests/<suite>.sh, bash -c '...'). Your worktree has its own container and backend environment. The media and release tiers wait for the heavy-media lock that another writer may hold: run them in the background or with a 10-minute timeout and read the log. One other writer works on this host: keep CPU stress below four parallel busy processes.
Editing notes for this host: every file keeps LF line ends (a Python helper that writes text passes newline=""); a Bash heredoc collapses backslash escapes, so write a helper script with the Write tool and run it; \`sleep\` chains are refused, use a command with its own timeout.
Commit: yes, on branch ${t.dir}, after \`./scripts/verify.sh --tier release\` passes on your final tree and you inspected \`git status\` and \`git diff\`; message "${t.message}", ending with these trailer lines:
${TRAILERS}
Never push, merge, rebase or switch branches.
Return the handback report as the brief's § Handback schema states.`
}

const run = (key) => agent(prompt(key), { label: `fix:${key}`, phase: 'Fix', schema: REPORT, agentType: 'implementer', ...AGENT })

// Two writers at a time: track A and track B2 one after the other, track B1 beside them.
const laneOne = async () => {
  const a = await run('A')
  const b2 = await run('B2')
  return [{ track: 'A', ...a }, { track: 'B2', ...b2 }]
}
const laneTwo = async () => [{ track: 'B1', ...(await run('B1')) }]
const results = (await parallel([laneOne, laneTwo])).flat().filter(Boolean)
log(results.map((r) => `${r.track}: ${r.result} ${String(r.commit || '').slice(0, 7)}`).join('; '))
return { base: BASE, tracks: results }
