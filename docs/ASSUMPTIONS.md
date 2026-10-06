# Assumptions

Missing information that does not justify interrupting the human becomes a recorded
assumption here. Escalation criteria: [CLAUDE.md](../CLAUDE.md) § Autonomy and escalation.

## Rules

1. Make a reasonable, industry-standard assumption; record it here; continue.
2. Record it before, or in the same commit as, the work that relies on it, and cite its
   `ASM-NNN` in that requirement or ADR.
3. Allocate the next free `ASM-NNN` and append the entry at the end. Never reuse, renumber or
   delete entries.
4. Change **Status** in place and append ` — YYYY-MM-DD — <evidence or link>`.
5. When an assumption becomes a requirement or ADR, set `superseded` and add the REQ/ADR to
   **Links**.
6. When an assumption proves false, set `invalidated`, add the follow-up (new requirement, ADR
   change or re-plan) to **Links**, and repair the affected work.
7. `milestone-review` revisits every `open` assumption: confirm, invalidate, supersede, or keep
   it open with a reason.
8. An assumption that would materially change the intended product is a question for the
   human: escalate it and track it in [PRODUCT.md](PRODUCT.md) § Open product questions.

## Entry format

```
### ASM-NNN — Short title
- **Date:** YYYY-MM-DD
- **Assumption:** what is taken as true
- **Reason:** why it is reasonable and why the human was not asked
- **Impact:** what changes if it proves false
- **Status:** open | confirmed | invalidated | superseded
- **Links:** ADR-NNN, AVE-REQ-NNN
```

## Status meanings

- `open` — in effect, unverified.
- `confirmed` — validated by evidence or by the human.
- `invalidated` — proven false; follow-up recorded.
- `superseded` — became a requirement or ADR; linked.

## Entries

### ASM-001 — Project hooks activate after workspace trust
- **Date:** 2026-10-01
- **Assumption:** Future sessions load the SessionStart and Stop hooks from
  [.claude/settings.json](../.claude/settings.json) once the workspace is trusted.
- **Reason:** The bootstrap session created the hooks mid-session and could not exercise them.
- **Impact:** If false, the verification gate and recovery context fall back to
  [CLAUDE.md](../CLAUDE.md) instructions and CI.
- **Status:** confirmed — 2026-10-01 — the resumed session showed the "Project state" block injected by
  [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh) (source: resume). Stop hook: confirmed —
  2026-10-06 — `.git/claude-verify/last-result`, a record only
  [.claude/hooks/stop-verify.sh](../.claude/hooks/stop-verify.sh) writes, read
  `PASS 2026-10-06T03:23:21Z cfaf58aff77b…` after a turn of the working session ended.
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-002 — Baseline tooling
- **Date:** 2026-10-01
- **Assumption:** `bash` (3.2+), `git`, and POSIX `awk`, `grep` and `sed` exist wherever
  verify.sh and the hooks run (Linux, macOS, WSL/Git Bash).
- **Reason:** These tools ship with mainstream development environments and CI runners, so
  the scripts need no further dependencies.
- **Impact:** If false, verification needs a POSIX shell environment on that machine.
- **Status:** open
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-003 — GitHub hosts the repository and runs CI
- **Date:** 2026-10-01
- **Assumption:** GitHub hosts the canonical repository (`github.com/theUpsider/AI-Video-Editor`)
  and GitHub Actions runs CI.
- **Reason:** The configured Git remote points to that GitHub repository.
- **Impact:** If false, port [.github/workflows/verify.yml](../.github/workflows/verify.yml) to
  the actual CI system; it only runs `./scripts/verify.sh`.
- **Status:** confirmed — 2026-10-01 — first CI run green on commit f605c6c
  (https://github.com/theUpsider/AI-Video-Editor/actions/runs/36851238702).
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-004 — Baseline interpretation register adopted
- **Date:** 2026-10-01
- **Assumption:** The baseline's interpretation register (ASM-01 to ASM-20 in
  [SCOPE_AND_ASSUMPTIONS.md](../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)) holds for this
  implementation: self-hosted single-owner browser editor with a media worker; probed (never assumed)
  dimensions/rates; unconfirmed "DJI Go" device terminology; contain/padding as the default square layout; Auto
  output rate from the reference source with a 1080p 16:9 canvas; final audio separate from sync evidence; common
  coverage for split segments; evidence-dependent sync; ASR scope without dubbing/diarization; bounded indexing as
  the version-one foundation; distinct caption/metadata products; 1:1 15–20 s shorts; agent runtimes distinct from
  models; no inherited credentials; CPU mandatory and GPU conditional; no social publishing; consented, budgeted
  external compute; environment-discovered versions; defaults changeable only by ADR.
- **Reason:** The human supplied the register with the requirements; it resolves every ambiguity the brief leaves.
- **Impact:** If the human revises any entry, apply it through `product-definition` amendment mode.
- **Status:** open
- **Links:** [ADR-002](decisions/ADR-002-technology-stack.md), [ADR-003](decisions/ADR-003-requirements-baseline-import.md)

### ASM-005 — Synthetic fixtures stand in for real camera footage
- **Date:** 2026-10-01
- **Assumption:** Deterministic, clearly labeled synthetic media (markers, flashes, impulses, pilot tones,
  synthesized speech) is sufficient evidence for timing, geometry, routing and caption criteria; it never
  represents the user's real footage.
- **Reason:** No user footage, camera model or color profile was supplied; the baseline requires generated
  fixtures with independent ground truth.
- **Impact:** Real-footage behavior (camera color profiles, real-world sync evidence quality) stays a reported gap
  until footage is supplied.
- **Status:** open
- **Links:** [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md)

### ASM-006 — The development container is no deployment target
- **Date:** 2026-10-01
- **Assumption:** The measured Claude Code container ([ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md))
  is a build/test environment with no GPU, no Docker daemon, no product credentials and no Hugging Face access.
  Live provider, agent-runtime, vision, translation, multilingual ASR, container and GPU criteria are implemented
  and contract-tested here and reported as externally unverified with exact prerequisites.
- **Reason:** Measured network policy and device checks.
- **Impact:** If the environment gains access, rerun the corresponding live tests and update the matrix.
- **Status:** confirmed — 2026-10-01 — measured — 2026-10-06 — the development container on the laptop host
  reaches huggingface.co anonymously (HTTP 200, [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md)
  § Network policy); model downloads stay behind the model registry with consent, and `verify.sh` and CI use
  no model download
- **Links:** [ADR-007](decisions/ADR-007-ai-integration-boundaries.md), [ADR-008](decisions/ADR-008-local-speech-recognition.md)

### ASM-007 — Audio sync accepts an offset only when chance and rival alignments are ruled out
- **Date:** 2026-10-02
- **Assumption:** The audio offset estimator (`ave.sync.audio`) reports OK only when the coinciding onsets at the
  chosen lag are unlikely by chance (binomial bound times the number of searched lags at most 1e-3) and no other
  alignment that chance does not explain has at least half as many coincidences; otherwise it reports
  insufficient evidence or ambiguity with alternatives. Thresholds are validated on seeded synthetic populations
  only.
- **Reason:** A confident wrong offset is the one unacceptable outcome (CLAUDE.md product invariants,
  AVE-REQ-024); independent reviews found wrong offsets on unrelated, lattice-noise and same-tempo populations
  before these gates.
- **Impact:** Sensitivity cost, measured by the independent review: music-like scenes with a strong shared
  rhythm become ambiguous (9 of 100 music-like positives right with the gate, 100 without), so such footage needs
  visual or manual anchors (AVE-REQ-025, AVE-REQ-030) until the M2 synchronization work adds a waveform-level
  discriminator. Known open weakness, measured by the round-3 review of `dc89da2`: unrelated recordings whose
  notes sit on a shared rhythmic grid still return a confident wrong offset in 0.3 to 0.9 % of synthetic pairs
  (22 of 6,720 over grid steps 1/8 to 1/2 s, densities 0.05 to 0.4 and four transient families; none at
  densities 0.3 and above; the worst family is step 1/2 s at densities 0.1 to 0.2; the population test's own
  family, step 1/4 s at density 0.15, gives 5 of 1,000 outside its seed slice). The wrong results match 3 to 6
  onsets with chance probabilities from 8e-4 down to 1e-9, and the rival gate never fires on them. The M2
  synchronization task owns the fix (a lattice-aware null model or the waveform-level discriminator).
- **Status:** open
- **Links:** [AVE-REQ-024](requirements/AVE-REQ-024-audio-based-offset-estimation.md), [WORKFLOW_LOG WF-001](WORKFLOW_LOG.md)

### ASM-008 — Audio timestamp deviations below 10 ms are jitter
- **Date:** 2026-10-02 (revised 2026-10-03 after the follow-up review measured the boundary)
- **Assumption:** Decoded audio is placed by its timestamps; deviations from a contiguous stream below 10 ms are
  treated as container rounding or muxer jitter (samples stay contiguous), deviations of 10 ms or more as real
  gaps or overlaps (filled with silence or dropped in full; FFmpeg's threshold is a float option, so exactly
  10 ms is corrected). A deviation is measured from the contiguous continuation of the first decoded packet:
  the stream's first packet in the analysis extraction, the first decoded packet that ends after the seek
  point in a render, and the corrected packet after a correction. Jitter therefore stays uncorrected while
  its peak-to-peak spread is below 10 ms (an amplitude below 5 ms), and a rendered clip then sits its
  anchor's deviation from the stream's first packet (at most the spread) from the analysis placement of the
  same source. Measured: gaps of 5 ms stay (chirps 240 samples early, no zero run), gaps of 12, 21 and 50 ms
  are corrected exactly, in Matroska/PCM and MPEG-TS/AAC; the ±2 ms jitter fixture renders 112 and 192
  samples from its analysis placement, within the file's largest deviation of 208 samples.
- **Reason:** A 1 ms threshold inserted hundreds of dropouts into a stream with 2 ms jitter; one lost AAC frame is
  21.3 ms at 48 kHz, so real gaps stay above the threshold.
- **Impact:** A genuine gap shorter than 10 ms stays uncorrected (an error below one frame at 60 fps). A source
  whose timestamp jitter reaches 5 ms each way gets dropouts: silence inserted and samples dropped wherever a
  packet lies 10 ms or more from the current anchor, at different packets in the analysis extraction and in
  each render (AAC in MPEG-TS alternating ±5 ms: 701 silence runs of 10 ms in the 30 s analysis extraction,
  141 in every 6 s render); AVE-REQ-104 proposes a fitted reference for such sources. A stream without its
  own duration can lose up to its end-packet jitter (below 10 ms) at the end of the analysis extraction.
- **Status:** open
- **Links:** [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md), `backend/src/ave/media/audio_timing.py`,
  `backend/tests/media/test_source_timing.py`, [AVE-REQ-104](requirements/AVE-REQ-104-robust-audio-placement-for-timestamp-jitter.md)

### ASM-009 — Output before a source's first video frame shows that first frame
- **Date:** 2026-10-02
- **Assumption:** When a clip's source time precedes the stream's first video frame (a video stream that starts
  after the container start), the output shows the first frame instead of the background.
- **Reason:** The frame rule (latest frame with PTS <= t) has no frame there; a background flash at a clip's start
  would be a visible artifact, while the first frame is what players show.
- **Impact:** Up to the stream's start offset (typically a few milliseconds) shows a held first frame.
- **Status:** open
- **Links:** [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md), `backend/src/ave/render/compiler.py`

### ASM-010 — Background colors are coded with the BT.709 limited-range matrix in Python
- **Date:** 2026-10-03
- **Assumption:** The renderer computes the 8-bit Y'CbCr values of a sequence background from its RGB value with the
  BT.709 limited-range matrix in exact rationals (half up) and draws them directly, so the stored values match the
  BT.709 tag of the output. FFmpeg's `color` source converts with BT.601 when the link colorspace is unset.
- **Reason:** Measured on FFmpeg 6.1: `#204060` through the `color` source stores Y 66, U 147, V 112 (its BT.601
  encoding) and decodes as (30, 63, 98) under the BT.709 tag; the Python coding decodes within one level.
- **Impact:** A later change of the output matrix (BT.2020 outputs) changes the coding function as well.
- **Status:** confirmed — 2026-10-03 — `test_background_decodes_to_its_color_under_the_tagged_bt709_matrix` and the
  round-2 real-media review (ten colors, two decoders, spec math)
- **Links:** [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md), `backend/src/ave/render/ffmpeg.py`,
  [AVE-REQ-019](requirements/AVE-REQ-019-aspect-preserving-composition-and-transforms.md), [AVE-REQ-020](requirements/AVE-REQ-020-two-perspective-split-screen-layout.md)

### ASM-011 — The baseline is anchored by the pinned SHA-256 of its manifest
- **Date:** 2026-10-03
- **Assumption:** `scripts/check_baseline.py` pins `BASELINE_MANIFEST_SHA256`, the SHA-256 of
  `ai-video-editor-requirements/MANIFEST.json`, and verifies the manifest's inventory and every listed file's
  size and SHA-256 itself before it runs the package's own validator; no package file takes part in proving the
  package unchanged.
- **Reason:** Of the two anchors the fix brief offered (manifest hash, Git tree), the hash works in every checkout
  and in the test suite's fixture copies outside Git, with the standard library alone. The re-verification of
  2026-10-03 (`wf_ed1f5104-63a`) showed that a hash check delegated to a package file is disabled by editing that
  file, so the checker verifies the hashes itself.
- **Impact:** Adopting a new baseline version from the human needs a commit that updates the pin and cites the
  human's input.
- **Status:** open
- **Links:** [ADR-003](decisions/ADR-003-requirements-baseline-import.md), [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

### ASM-012 — A requirement's Description is compared with the baseline as a whole section
- **Date:** 2026-10-03
- **Assumption:** The baseline check compares the whole `## Description` section of an imported requirement with the
  baseline statement, fenced blocks included, exactly, apart from blank lines around the section; a difference
  needs a Status-log line that opens with `Description changed [<mark>]: <reason>` (the mark is a digest of the
  new text; revised 2026-10-06).
- **Reason:** Text added in a fenced block changes the statement as much as plain text does.
- **Impact:** Every visible edit of an imported Description needs its logged reason.
- **Status:** open
- **Links:** [ADR-003](decisions/ADR-003-requirements-baseline-import.md), [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

### ASM-013 — Tooling evidence is credited per suite file that ran
- **Date:** 2026-10-03
- **Assumption:** A tooling test file's `# AVE-REQ-NNN AC-n` tags count only through a suite result of the run
  (`scripts/tests/run.sh` for the shell suites it lists, `scripts/evidence.py unittest` for `test_*.py`), each tag
  with the file's exit status and check count (`run.sh` fails a listed suite that exited 0 without a
  `TOTAL: pass=N fail=M` line with N ≥ 1, and `collect` counts such a result against its tags); `evidence.py
  unittest` fails a file in which no test ran; tooling tags are validated
  by scanning every tooling test file at `record` and `check-done`; `show --require-complete` exits 1 for a failed
  run while `--require-fresh` alone checks freshness. A comment tag in any other file of `scripts/tests/` stops
  `record` and `check-done`; `scripts/evidence.py` reads the list of shell suites from the `run_suite` lines at
  the start of a line of `scripts/tests/run.sh`. A unit-test tag binds to the test below it by class and name;
  an inherited test counts for the class that defines it.
- **Reason:** The shell suites have no per-case runner; a never-collected test gives no evidence; a bad tag must
  stop every tier although the fast tier runs no shell suite; certifying completeness needs a passing run.
- **Impact:** One failing case fails every criterion its file tags; a shell-suite tag counts only in the release
  tier; an empty `test_*.py` in `scripts/tests/` fails the fast tier; a reviewer certifies with both flags. A tagged
  suite is listed in `run.sh` in the commit that adds it; a suite called from an indented or commented
  `run_suite` line counts as unlisted.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), `scripts/evidence.py`, `scripts/tests/run.sh`

### ASM-014 — Hook matchers are checked with Python's regex engine
- **Date:** 2026-10-03
- **Assumption:** Check 12 of `scripts/check-project-control.sh` evaluates hook matchers by Claude Code's documented
  rules with Python's `re.search` standing in for JavaScript's unanchored `RegExp.test`; the SessionStart hook must
  match `startup`, `resume` and `compact`, while `clear` and `fork` stay optional.
- **Reason:** The checker runs without Claude Code; AVE-REQ-098 AC-2 names compaction and a new session.
- **Impact:** An exotic regex construct can differ between the two engines; a matcher without `clear` passes.
  Only `|`-separated names form a list; a comma-separated list is a regular expression that matches no source,
  and check 12 rejects it (found by the AVE-REQ-098 skeptic, 2026-10-03).
- **Status:** open
- **Links:** [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

### ASM-015 — The probe counts accelerators by device nodes and nvidia-smi
- **Date:** 2026-10-03
- **Assumption:** `scripts/probe-environment.sh` reports an accelerator as present from a character device
  under `/dev` whose whole name is `nvidia<N>` or `dri/renderD<N>` and that this user can open, and from a GPU
  row with a memory figure that `nvidia-smi` prints; FFmpeg's built-in hardware encoders and every other entry
  of `/dev` never count.
- **Reason:** AVE-REQ-094 edge case: a compiled-in encoder says nothing about a device.
- **Impact:** A host with a render node, a software or virtual DRM driver included, reports `present` before any
  hardware encode is tested; AVE-REQ-076 still needs a test encode.
- **Status:** open — 2026-10-06 — narrowed to GPU nodes and rows with a memory figure after the review of
  AVE-REQ-094 at `eb73896` (handback part 5), and to character devices with the whole name that open after the
  review at `d4147d8` (handback part 6)
- **Links:** [AVE-REQ-094](requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

### ASM-016 — .env.example lists the product's variables only
- **Date:** 2026-10-03
- **Assumption:** `.env.example` documents the product's runtime and credential variables; development-tool
  variables (`VERIFY_TIER`, `CLAUDE_VERIFY_*`, `AVE_EVIDENCE_DIR`, `AVE_HEAVY_LOCK`, `AVE_PROBE_DEV_DIR`) stay
  documented in their scripts.
- **Reason:** The fix brief asks for the product variables with their purposes.
- **Impact:** None on the product.
- **Status:** open
- **Links:** [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

### ASM-017 — The heavy-media lock serializes jobs that share one lock file
- **Date:** 2026-10-03
- **Assumption:** `flock` works per file: agents serialize their media and release tiers only when they share the
  lock file. In the development container `scripts/dev-container.sh` sets `AVE_HEAVY_LOCK` to
  `/state/ave-heavy-media.lock` on the state volume every container of the host mounts; CI runs one job per runner.
- **Reason:** A reviewer's private clone runs in its own container, and the lock must still cover it.
- **Impact:** A host with another isolation scheme needs the same shared path.
- **Status:** open
- **Links:** [ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md), [AVE-REQ-096](requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md), `scripts/verify.sh`

### ASM-018 — Check 11 reads a commit as lowercase hex
- **Date:** 2026-10-03
- **Assumption:** A brief's Input revision names a commit as a delimited token of 7 to 40 lowercase hex digits (Git's
  own output) or as the self-reference `git log -1 --format=%h -- <this brief>`. The rule is syntactic and
  checks no object of the repository: a hex token delimited by `/`, `.`, `:` or other punctuation inside a
  longer name (`feature/abcdef1`, `fix.1234567`), a branch named in hex (`deadbeef`), a word of seven or more
  hex letters (`effaced`), a compact date (`20261006`), any number of 7 to 40 digits and `0000000` count as a
  commit; under Requirements an ID without a file (`AVE-REQ-999`) counts. HTML comments are removed first, and
  `docs/briefs/` holds briefs, `README.md`, `drafts/` and `handbacks/` only (the folder files `.DS_Store` and
  `Thumbs.db` are passed over).
- **Reason:** The rule stays mechanical and awk-portable.
- **Impact:** The reader of the brief and the task's base check (`git rev-parse HEAD` equals the base commit)
  judge whether the token is the intended commit.
- **Status:** open — 2026-10-06 — forms named after the review of AVE-REQ-096 at `2df637f`
- **Links:** [AVE-REQ-096](requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)

### ASM-019 — PROGRESS.md claims no ongoing execution
- **Date:** 2026-10-03
- **Assumption:** Check 7 rejects the wordings "running", "underway", "under way", "in flight", "ongoing", "still
  executing" and "runs now" in PROGRESS.md outside comments, fences and code spans, in any letter case and with
  spaces or hyphens between the words, and allows the negations ("nothing is running", "not running", "no longer
  running"). The rule knows this list; the commit review judges any other wording.
- **Reason:** AVE-REQ-098 AC-3 forbids claiming that unfinished work keeps executing after the session stops.
- **Impact:** Other uses of the words in PROGRESS.md need rephrasing.
- **Status:** open
- **Links:** [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

### ASM-020 — Workflow resume caches depend on call order
- **Date:** 2026-10-03
- **Assumption:** A resumed Workflow run replays a cached agent result only while the sequence of `agent()` calls
  before it is unchanged; parallel tracks interleave differently per run, so a resume after a session restart can
  rerun completed stages. A restart therefore continues through a hand-written continuation script that embeds
  the completed stages' results as facts (`docs/workflows/`).
- **Reason:** Observed on 2026-10-03: the resume of `wf_164de68e-23b` restarted the completed review stages.
- **Impact:** A lead that resumes a parallel workflow plans for the rerun or writes the continuation.
- **Status:** confirmed — 2026-10-03 — `wf_df2de811-039` completed the run from the embedded facts
- **Links:** [AVE-REQ-094](requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md), [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

### ASM-021 — Provider fakes carry the contract marker by hand until the adapters land
- **Date:** 2026-10-03
- **Assumption:** A test that runs a provider fake carries `pytest.mark.contract` by hand; the first
  provider-adapter requirement makes its fake fixtures apply the marker automatically, as a Definition-of-Ready
  item of that requirement.
- **Reason:** No provider adapter exists in M0; the marker rule (AVE-REQ-097 AC-4) is enforced by review until a
  fixture can carry it. Noted by the AVE-REQ-097 re-review of 2026-10-03.
- **Impact:** A fake-based test without the marker could credit a criterion; reviewers check every provider test
  for it until the fixtures apply it.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)

### ASM-022 — Evidence written to the bind mount persists after the run
- **Date:** 2026-10-03
- **Assumption:** A run's directory under `var/verify/runs/` and `latest-<tier>.json` persist once
  `scripts/evidence.py record` wrote them; `record` validates nothing after writing.
- **Reason:** One reviewer clone observed a release run's directory absent about 40 s after the run on the Docker
  Desktop bind mount, while its harness had run the launch twice; the lead has not reproduced it
  ([ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Limits item 6).
- **Impact:** A manifest absent after a PASS means the tier is rerun before any transition cites it. The follow-up
  (`record` re-reads the manifest it wrote and names it in the summary line) joins the next change of the evidence
  tooling.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

### ASM-023 — The verification toolchain and local state are trusted; CI decides for `main`
- **Date:** 2026-10-06
- **Assumption:** The mechanical gates trust the interpreter, the shell and the tools on `PATH` of the development
  container and of CI, and they treat `var/verify/` and `.git/claude-verify/` as local, unauthenticated state.
  `verify.sh` starts its steps from a named set of variables and reads no cache from the tree; a replaced
  tool, a hand-written manifest or a hand-written Stop-gate record lies outside every diff and outside the gates,
  and so do the files under `HOME`, the personal and user-level Claude Code settings, the shell options that act
  before the first line of a script (`SHELLOPTS`, `BASHOPTS`) and the files of a backend environment beyond the
  names and versions of its packages. On the container host that environment is kept per clone path.
- **Reason:** A gate cannot prove the machine it runs on. The red-team pass of 2026-10-06 closed every path through
  repository files and environment variables that it found; what remains needs write access to the toolchain or
  to ignored state.
- **Impact:** The run that certifies a requirement is the one an independent reviewer starts in a private clone
  (`verify-requirement`), and the run that admits a commit to `main` is CI's on a fresh checkout. A local PASS
  alone moves nothing to `main`.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

### ASM-024 — A fingerprint entry holds the index mode, the executable bit and the raw bytes
- **Date:** 2026-10-06
- **Assumption:** The tree fingerprint lists every index entry and every untracked file that no `.gitignore` file
  ignores, each with the mode of its index entry (or `untracked`), the executable bit of the working file and the
  hash of its raw bytes. A Windows host counts every regular file as executable, which is what the development
  container reads through its mount of the same checkout. Staging a new file changes its entry from `untracked`
  to its index mode.
- **Reason:** The index mode alone leaves `chmod -x` of a script outside the fingerprint on Linux; bytes read from
  the working tree keep every index flag, attribute and fsmonitor state out of the result.
- **Impact:** Host and container print one value for one checkout. A run that should stay fresh after its commit
  starts with its new files staged (`git add -A`); otherwise the next run renews the evidence.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), `scripts/lib/verify-state.sh`

### ASM-025 — The steps of verify.sh start from a named set of variables
- **Date:** 2026-10-06
- **Assumption:** `PATH`, `HOME`, `USER`, `LOGNAME`, `TMPDIR`, `LANG`, `LC_ALL`, `TZ`, `UV_PROJECT_ENVIRONMENT`,
  `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR`, `AVE_HEAVY_LOCK` and `AVE_HEAVY_LOCK_HELD` are the variables of the
  caller a step may see; `AVE_VAR_DIR`, proxy variables, `XDG_*`, `CI` and `GITHUB_*` reach no step.
- **Reason:** A list of variables to clear is never complete; the set derives from `scripts/dev-container.sh`,
  `.devcontainer/Dockerfile` and `.github/workflows/verify.yml`.
- **Impact:** The locked backend environment exists before `verify.sh` runs wherever the network needs a proxy; a
  host that needs another variable adds it to the set in `scripts/verify.sh` and to the tiers suite in one
  reviewed change.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), `scripts/verify.sh`

### ASM-026 — Requirement files hold the characters of an allow-list
- **Date:** 2026-10-06
- **Assumption:** U+0020 to U+007E, the line feed and the seven signs the working files held on 2026-10-06
  (U+00A7, U+00B1, U+2013, U+2014, U+2192, U+2265, U+2282; `EXTRA_CHARACTERS` in `scripts/reqfile.py`) suffice
  for EPIC, FEAT and REQ files.
- **Reason:** An allow-list closes every class of invisible character at once.
- **Impact:** Any other character (an accented letter, a typographic quote, an ellipsis, sample text in another
  script) fails "Requirements baseline integrity" until the list grows in a reviewed change.
- **Status:** open
- **Links:** [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md), `scripts/reqfile.py`

### ASM-027 — A deferred or superseded child never blocks its parent from done
- **Date:** 2026-10-06
- **Assumption:** A feature or epic is `done`, and its acceptance boxes ticked, when every child that is neither
  superseded nor deferred is `done` (requirements README § Status lifecycle rule 6).
- **Reason:** AVE-FEAT-014 holds the deferred AVE-REQ-067; counting it would bar the feature from `done` for good.
- **Impact:** A deferred child stays visible in its parent's list and takes no part in the parent's status.
- **Status:** open
- **Links:** [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md), `scripts/check_baseline.py`

### ASM-028 — Change marks hold sixteen hex digits and a marker reason holds a letter or digit
- **Date:** 2026-10-06
- **Assumption:** The mark of a change marker is the first sixteen hex digits of the SHA-256 of the marked text,
  and the reason of a marker line holds a letter or a digit of U+0020 to U+007E.
- **Reason:** A deliberate search for a second text with one mark costs about 2^64 hash evaluations; a reason of
  punctuation or of a blank glyph explains nothing.
- **Impact:** None for the files of today: no working file holds a mark yet.
- **Status:** open
- **Links:** [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md), `scripts/reqfile.py`

### ASM-029 — A milestone entry of the roadmap holds its lists once, under the template labels
- **Date:** 2026-10-06
- **Assumption:** A `### M<n>` entry holds one Status line, one requirement list and at most one
  `Proposed during ...` line; the Deferred group holds its own label and no Proposed line; fence lines follow
  the rules of the requirement files.
- **Reason:** A list under another label, or a second list, would hide requirements from the roadmap rules.
- **Impact:** A later round of proposals under one milestone extends the existing line.
- **Status:** open
- **Links:** [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md), `scripts/check_baseline.py`

### ASM-030 — Check 12 fails every loop word in a hook command
- **Date:** 2026-10-06
- **Assumption:** A hook command in `.claude/settings.json` with the shell word `while` or `until` or with a
  `for ((` loop fails check 12, whatever its condition; so does `--permission-mode` with any value. The folder
  files `.DS_Store` and `Thumbs.db` pass in `docs/briefs/`, as in the ignored-file step.
- **Reason:** An always-true condition has unbounded spellings; a hook command of this project is a script path.
- **Impact:** A hook that needs a loop keeps it inside its script, where the inspection of `.claude/hooks/*.sh`
  reads it.
- **Status:** open
- **Links:** [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md), [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), [AVE-REQ-096](requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)

### ASM-031 — The evidence plugin takes a .git entry as the mark of a repository
- **Date:** 2026-10-06
- **Assumption:** `backend/tests/evidence_plugin.py` treats a tree as inside a repository when its directory or
  one above it holds a `.git` entry; there a Git that fails stops the session.
- **Reason:** Git's own answer is the thing that fails, so the test for a repository uses no Git command.
- **Impact:** With `GIT_CEILING_DIRECTORIES` between the tree and that entry the session fails; a source archive
  placed inside another checkout is judged by that checkout's ignore rules.
- **Status:** open
- **Links:** [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)
