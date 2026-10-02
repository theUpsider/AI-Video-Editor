export const meta = {
  name: 'review-media-core-round3',
  description: 'Independent multi-lens review of media-core round-3 fixes (dc89da2) with adversarial verification of blocking findings',
  phases: [
    { title: 'Review', detail: 'three independent lenses on the round-3 diff, each in its own scratch copy' },
    { title: 'Verify', detail: 'two skeptics try to refute each blocking finding' },
  ],
}

const REPO = '/home/user/AI-Video-Editor'
const BRIEF = REPO + '/docs/briefs/2026-10-02-m0-media-core-review-fixes-round-3.md'

const COMMON = `You are an independent reviewer of commit dc89da2 (branch worktree-agent-ace5eb07e8aecbfbf, parent 90a1f2e) in the repository ${REPO}. Read the task brief ${BRIEF} first: it lists one blocking finding and five non-blocking findings from the previous review that this commit claims to fix. Earlier rounds were verified already; review only \`git -C ${REPO} diff 90a1f2e dc89da2\` and the code it touches. Treat every claim in the commit, its tests and its docstrings as unverified.

Rules:
- Work only in your own scratch copy: \`tmp=$(mktemp -d); git -C ${REPO} archive dc89da2 | tar -x -C "$tmp"\`; in "$tmp/backend" run \`uv sync --frozen\` and set AVE_VAR_DIR to a directory inside $tmp for every test run. Delete $tmp at the end (only what you created). Never write into ${REPO} or its worktrees.
- When you mutate code to check that a test fails without the behavior, delete every __pycache__ directory under src and tests before rerunning (a same-size edit within one second keeps a stale .pyc valid), and restore the file afterwards.
- Another reviewer works concurrently on another lens; keep heavy FFmpeg work to one process at a time.
- Report only what you verified yourself with commands or code reading; give exact evidence.`

const LENSES = [
  {
    key: 'oracles',
    prompt: `${COMMON}

Your lens: oracle independence and the exact container start (brief items 1, 2 and 5).
1. backend/tests/unit/test_compiler.py "origin" case and backend/tests/assets.py: is the oracle now independent of the code under test (no value read back from the probe result)? Is the fake stream consistent with what FFprobe would print?
2. The new parse tests in backend/tests/unit/test_probe_parse.py: confirm by mutation that each fails when _exact_container_start (backend/src/ave/media/probe.py) (a) returns the printed value, (b) picks the latest instead of the earliest matching stream, (c) drops the warning. Look for any input where _exact_container_start picks a wrong stream or silently falls back.
3. backend/tests/media/test_proc_media.py: is the failure-tail assertion version-independent yet still meaningful (would it pass if the tail were unrelated text)?
Run: \`uv run --frozen pytest -q -p no:cacheprovider tests/unit tests/media/test_proc_media.py\`.`,
  },
  {
    key: 'audio-timing',
    prompt: `${COMMON}

Your lens: the 10 ms audio timestamp tolerance (brief item 3; backend/src/ave/media/audio_timing.py, its use in backend/src/ave/render/ffmpeg.py and backend/src/ave/sync/audio.py, and the tests in backend/tests/media/test_source_timing.py).
Build your own real-media files from the standard fixture A (generate it by running \`uv run --frozen pytest -q -p no:cacheprovider tests/media/test_fixtures_media.py\` once; the file lands under $AVE_VAR_DIR/fixtures/std-a-*/std-a.mp4):
- Matroska PCM and MPEG-TS AAC with ±2 ms and ±4 ms per-frame timestamp jitter: no inserted silence (count zero runs in the analysis extraction), chirps at their original positions, in analysis extraction (ave.sync.audio.extract_analysis_audio) and in a render (ave.render.compiler.compile_render_plan + ave.render.ffmpeg.render of a single audio clip).
- Gaps of 5, 12, 21 and 50 ms at a known time: gaps above 10 ms fully compensated, 5 ms left uncompensated with an error of at most 5 ms; check the docstrings and docs/ASSUMPTIONS.md ASM-008 in the repository match the measured behavior.
- Re-run \`uv run --frozen pytest -q -p no:cacheprovider tests/media/test_source_timing.py -k "jitter or gap"\` and mutation-check both tests (1 ms and 100 ms thresholds).`,
  },
  {
    key: 'sync-and-seek',
    prompt: `${COMMON}

Your lens: the synchronization population tests and the intra-only keyframe index (brief items 4 and 6).
1. backend/tests/unit/test_sync_populations.py::test_unrelated_music_on_a_shared_grid_never_yields_an_offset: confirm it fails with the rival gate disabled (backend/src/ave/sync/audio.py, the AMBIGUOUS branch that tests coarse.rival_chance) and passes with it. Then try neighbouring grid families of your own (steps 0.125–0.5 s, densities 0.05–0.4, different seeds, different transient shapes per note) with the gate on and report every confident wrong offset you find, with its parameters. A known open weakness exists for sparse 16th-note grids with identical transients (docs/ASSUMPTIONS.md ASM-007); quantify it and say whether anything worse exists.
2. backend/src/ave/media/probe.py keyframe index: an intra-only MPEG-TS (x264 -g 1) stores no index; check frame exactness at several cuts of such a file and confirm a long-GOP TS still records its index and stays frame-exact (tests in backend/tests/media/test_source_timing.py: intra and long_gop).
Run: \`uv run --frozen pytest -q -p no:cacheprovider -m slow\` and \`uv run --frozen pytest -q -p no:cacheprovider tests/media/test_source_timing.py -k "intra or long_gop"\`.`,
  },
]

const FINDING = {
  type: 'object',
  properties: {
    location: { type: 'string', description: 'path:line' },
    defect: { type: 'string' },
    evidence: { type: 'string', description: 'commands and outputs, inputs, or reasoning' },
    fix: { type: 'string' },
  },
  required: ['location', 'defect', 'evidence', 'fix'],
}

const REVIEW = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    blocking: { type: 'array', items: FINDING },
    non_blocking: { type: 'array', items: FINDING },
    measurements: { type: 'string', description: 'numbers measured on your own constructions' },
    commands: { type: 'array', items: { type: 'string' }, description: 'command — result' },
  },
  required: ['verdict', 'blocking', 'non_blocking', 'measurements', 'commands'],
}

const REFUTE = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reasoning: { type: 'string' },
    evidence: { type: 'string' },
  },
  required: ['refuted', 'reasoning', 'evidence'],
}

const results = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: `review:${lens.key}`, phase: 'Review', schema: REVIEW, agentType: 'reviewer' }),
  async (review, lens) => {
    if (!review) return { lens: lens.key, review: null, verified: [] }
    const verified = await parallel((review.blocking || []).map((finding, i) => () =>
      parallel([0, 1].map((k) => () => agent(
        `${COMMON}\n\nAnother reviewer reports this BLOCKING finding about dc89da2. Try to REFUTE it: reproduce it yourself in your own scratch copy, check whether it is real, in scope of the brief, and blocking (a criterion or the brief's required fix not met, a false-positive test, or a correctness defect). Default to refuted=false only when you reproduced it.\n\nFinding:\n${JSON.stringify(finding, null, 2)}`,
        { label: `refute:${lens.key}:${i}:${k}`, phase: 'Verify', schema: REFUTE, agentType: 'reviewer' },
      ))).then((votes) => {
        const valid = votes.filter(Boolean)
        const upheld = valid.filter((v) => !v.refuted).length
        return { finding, upheld, votes: valid }
      })
    ))
    return { lens: lens.key, review, verified: verified.filter(Boolean) }
  },
)

const out = results.filter(Boolean)
const confirmedBlocking = out.flatMap((r) => r.verified.filter((v) => v.upheld >= 1).map((v) => ({ lens: r.lens, ...v.finding, upheld: v.upheld })))
const refutedBlocking = out.flatMap((r) => r.verified.filter((v) => v.upheld === 0).map((v) => ({ lens: r.lens, ...v.finding })))
log(`lenses: ${out.map((r) => `${r.lens}=${r.review ? r.review.verdict : 'missing'}`).join(', ')}; confirmed blocking: ${confirmedBlocking.length}; refuted: ${refutedBlocking.length}`)
return {
  lenses: out.map((r) => ({ lens: r.lens, verdict: r.review ? r.review.verdict : 'missing', non_blocking: r.review ? r.review.non_blocking : [], measurements: r.review ? r.review.measurements : '', commands: r.review ? r.review.commands : [] })),
  confirmedBlocking,
  refutedBlocking,
}
