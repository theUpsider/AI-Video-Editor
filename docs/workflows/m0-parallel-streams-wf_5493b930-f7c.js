export const meta = {
  name: 'm0-parallel-streams',
  description: 'M0: requirements baseline import tooling and first real CPU render/sync media core, in parallel',
  phases: [{ title: 'Build', detail: 'docs-import and media-core writers on disjoint paths' }],
}
const SP = '/tmp/claude-0/-home-user-AI-Video-Editor/65c52291-f6ac-506f-a9b7-7ad960580698/scratchpad'
phase('Build')
const [docs, media] = await parallel([
  () => agent(`You are an implementer for the AI Video Editor repository. Read and follow the contract at ${SP}/contract-docs-import.md exactly. Work in /home/user/AI-Video-Editor on the paths the contract assigns to you only. Another agent is concurrently building backend/ and the lead is editing other docs; never touch their paths.`, { label: 'docs-import', phase: 'Build' }),
  () => agent(`You are an implementer for the AI Video Editor repository. Read and follow the contract at ${SP}/contract-media-core.md exactly. Work in /home/user/AI-Video-Editor on backend/ and var/ only. Another agent is concurrently editing docs/requirements and scripts; never touch their paths. This is product infrastructure: write clean, typed, well-structured code with small modules and clear docstrings. Validate actual decoded media; do not claim results you did not run.`, { label: 'media-core', phase: 'Build' }),
])
return { docs, media }
