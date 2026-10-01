# Acceptance scenarios and fixture contract

## How to use this document

These are **test specifications**, not reports of executed product tests. Generate fixtures and implement the tests in the working repository. Link each relevant requirement's individual acceptance criteria to test evidence. A single scenario can exercise several requirements, but a scenario link alone does not prove all of their criteria.

Use independent ground truth. The renderer must not generate its own expected answer from the same buggy transform it is being tested against. Retain fixture-generation parameters/hashes and expected markers separately from production algorithms.

The development cloud may lack cameras, GPU devices, or provider credentials. Generate clearly labeled synthetic media for deterministic tests. Use consented/licensed speech fixtures or generated test speech with a known transcript for ASR. Distinguish these from the user's actual footage, which was not supplied here. Do not use a fabricated transcript as evidence that transcription ran.

## Tolerances and truthfulness

- Time-critical qualified tests allow at most one output frame error unless a criterion explicitly requires a tighter value. At 60/1 this is about 16.67 ms; fractional rates use their exact frame period.
- Check decoded exports, not only internal plans. Account for actual container time bases and audio encoder delay; do not blindly treat metadata start time as audible onset.
- Compare geometry, events, color patches and text masks with declared tolerances suitable for compression. GPU and CPU outputs need not be byte-identical.
- Longer/synthetic tests must cover drift. One successful short clip is not proof that a long recording stays synchronized.
- Provider mocks verify contracts. Real model/credential tests verify live integrations. No GPU means GPU tests are not run, not passed.
- Subjective editorial quality uses a small explicit rubric and sample human review, alongside automatic factual/timing invariants. Never let an LLM grade itself as the sole acceptance evidence.

## Standard synthetic travel composition

Use source A (square, source [0,30)) as reference. Source B (square, source [0,25)) corresponds to reference [2,27), so `a_B=2` and `b_B=1`. Source C is a six-second full-width 16:9 clip.

| Project interval | Source interval | Layout | Final audio |
| --- | --- | --- | --- |
| [0,8) | A [2,10), B [0,8) | Split, equal regions | A |
| [8,14) | C [0,6) | Full width | C |
| [14,22) | A [12,20), B [10,18) | Split, equal regions | A |

Place distinct visible event markers and nonperiodic audible impulses at known source/reference times. Set a text overlay to project [3,6), include a brief section title, and add a separate image overlay. Define two manual sections and a derived 18-second short. Use source labels and artificial locations such as City A/City B; do not pretend this fixture represents the user's actual trip.

## Scenario index

- [AT-01 - Import, inspect, duplicate, and reopen](#at-01)
- [AT-02 - Square split-screen, full-width, then split-screen](#at-02)
- [AT-03 - Mixed rates, VFR, and exact 2K/60 input](#at-03)
- [AT-04 - Audio-based synchronization with known offset](#at-04)
- [AT-05 - Unequal coverage and linked trimming](#at-05)
- [AT-06 - Silent source with visual and manual anchors](#at-06)
- [AT-07 - Unobservable or ambiguous synchronization](#at-07)
- [AT-08 - Clock drift at beginning, middle, and end](#at-08)
- [AT-09 - Dates, locations, and section exports](#at-09)
- [AT-10 - Overlays, international text, and creative profiles](#at-10)
- [AT-11 - Manual nonlinear editing journey](#at-11)
- [AT-12 - User/AI conflicts and atomic proposals](#at-12)
- [AT-13 - ASR, translations, and subtitle time mapping](#at-13)
- [AT-14 - Real AI draft and natural-language revisions](#at-14)
- [AT-15 - Accidental-recording classification without data loss](#at-15)
- [AT-16 - Editing API and MCP interoperability](#at-16)
- [AT-17 - Durable job cancellation, crash, and retry](#at-17)
- [AT-18 - Format, quality, and hardware export matrix](#at-18)
- [AT-19 - Visual indexing and editable shorts](#at-19)
- [AT-20 - Media, model, credential, and prompt security](#at-20)
- [AT-21 - Fresh installation and disconnected operation](#at-21)
- [AT-22 - Backup, relink, cache cleanup, and recovery](#at-22)
- [AT-23 - Resource limits and large-media behavior](#at-23)
- [AT-24 - Provider and model capability matrix](#at-24)
- [AT-25 - Grounded publication metadata](#at-25)
- [AT-26 - Color tags, HDR/log uncertainty, and range correctness](#at-26)
- [AT-27 - UI responsiveness and preview behavior](#at-27)
- [AT-28 - Audio routing, mixing, resampling, and clipping](#at-28)
- [AT-29 - Verification integrity and requirement coverage](#at-29)
- [AT-30 - Cloud capability audit, continuation, and whole-product handover](#at-30)
- [AT-31 - Future-scope exclusion and no dependency creep](#at-31)

<a id="at-01"></a>

## AT-01 - Import, inspect, duplicate, and reopen

**Fixtures:** Landscape, square, rotated portrait, audio-only, image, duplicate-bytes, no-audio, and corrupt fixtures; include an exact 2560x1440 60/1 source.

**Actions:** Create a project, import the batch, inspect properties, retry the failed item, re-import a duplicate, save, and restart.

**Expected result:** Valid assets survive restart with stable IDs, exact probe properties and immutable checksums. The corrupt item fails independently. Duplicates and missing audio are visible, not silently remapped.

**Required evidence:** Import API/browser assertions, probe JSON, before/after checksums, persistence snapshot, redacted failure record.

**Requirement coverage:** [AVE-REQ-001](requirements/AVE-REQ-001.md), [AVE-REQ-002](requirements/AVE-REQ-002.md), [AVE-REQ-003](requirements/AVE-REQ-003.md), [AVE-REQ-004](requirements/AVE-REQ-004.md), [AVE-REQ-009](requirements/AVE-REQ-009.md).

<a id="at-02"></a>

## AT-02 - Square split-screen, full-width, then split-screen

**Fixtures:** Two square sources A/B with event/time markers and one 16:9 joint shot C. Use the standard 22-second composition below.

**Actions:** Compose split [0,8), full-width [8,14), split [14,22). Use A audio for split segments and C audio for full width. Render 1920x1080.

**Expected result:** Contain mode produces two 960x960 images at y=60 in equal halves; no stretching. Cover changes crop, not aspect. Full-width C fills its intended segment. All source references, cuts and selected audio match the timeline.

**Required evidence:** Decoded frames at boundaries and interiors, geometric image masks/markers, audio source checks, 22-second duration tolerance of one output frame.

**Requirement coverage:** [AVE-REQ-011](requirements/AVE-REQ-011.md), [AVE-REQ-014](requirements/AVE-REQ-014.md), [AVE-REQ-017](requirements/AVE-REQ-017.md), [AVE-REQ-018](requirements/AVE-REQ-018.md), [AVE-REQ-019](requirements/AVE-REQ-019.md), [AVE-REQ-020](requirements/AVE-REQ-020.md), [AVE-REQ-021](requirements/AVE-REQ-021.md), [AVE-REQ-027](requirements/AVE-REQ-027.md), [AVE-REQ-031](requirements/AVE-REQ-031.md), [AVE-REQ-045](requirements/AVE-REQ-045.md), [AVE-REQ-069](requirements/AVE-REQ-069.md), [AVE-REQ-072](requirements/AVE-REQ-072.md), [AVE-REQ-075](requirements/AVE-REQ-075.md).

<a id="at-03"></a>

## AT-03 - Mixed rates, VFR, and exact 2K/60 input

**Fixtures:** Inputs at 24, 25, 30, 60, 30000/1001, 60000/1001 and deliberately variable PTS; include 2560x1440 at 60/1.

**Actions:** Probe, proxy, trim, preview and export selected sequences at 60/1 and 60000/1001. Exercise repeated edits on a long synthetic time model.

**Expected result:** Exact rates remain distinct, intended source speed/duration is preserved, VFR access uses PTS mapping, and output timestamps remain monotonic. No hidden downsampling is used to pass the 2K/60 support test.

**Required evidence:** Probe/packet timestamp output, selected decoded event frames, rational-time unit/property tests, measured duration and A/V offsets.

**Requirement coverage:** [AVE-REQ-004](requirements/AVE-REQ-004.md), [AVE-REQ-007](requirements/AVE-REQ-007.md), [AVE-REQ-012](requirements/AVE-REQ-012.md), [AVE-REQ-018](requirements/AVE-REQ-018.md), [AVE-REQ-074](requirements/AVE-REQ-074.md), [AVE-REQ-083](requirements/AVE-REQ-083.md).

<a id="at-04"></a>

## AT-04 - Audio-based synchronization with known offset

**Fixtures:** A has source/master [0,30). B has source [0,25) corresponding to master [2,27). Both have correlated chirps/impulses at distinct nonperiodic reference times; B has noise and different gain.

**Actions:** Estimate alignment, choose A as final audio, build split-screen and render. Repeat with a negative offset and sample-rate mismatch.

**Expected result:** Recovered mapping uses a_B=2 under the stated convention. Qualified exported event alignment is within one output frame. Only A is audible in the final mix; B audio still contributed to sync analysis.

**Required evidence:** Estimated transforms/confidence, independently calculated oracle, decoded flash/impulse positions, sample-level source-selection checks.

**Requirement coverage:** [AVE-REQ-012](requirements/AVE-REQ-012.md), [AVE-REQ-020](requirements/AVE-REQ-020.md), [AVE-REQ-023](requirements/AVE-REQ-023.md), [AVE-REQ-024](requirements/AVE-REQ-024.md), [AVE-REQ-026](requirements/AVE-REQ-026.md), [AVE-REQ-031](requirements/AVE-REQ-031.md), [AVE-REQ-032](requirements/AVE-REQ-032.md), [AVE-REQ-033](requirements/AVE-REQ-033.md), [AVE-REQ-074](requirements/AVE-REQ-074.md), [AVE-REQ-078](requirements/AVE-REQ-078.md), [AVE-REQ-083](requirements/AVE-REQ-083.md).

<a id="at-05"></a>

## AT-05 - Unequal coverage and linked trimming

**Fixtures:** The same offset pair, including leading/trailing source handles.

**Actions:** Build default overlap; choose union with full-width fallback; trim and split a linked group; attempt an edit with one member locked; undo.

**Expected result:** Default common coverage is master [2,27), 25 seconds. Union behavior is explicit and no stale B frame repeats by accident. Linked edits preserve relative timing or fail atomically when locked.

**Required evidence:** Timeline state diffs, decoded frames around coverage boundaries, event alignment and history roundtrip.

**Requirement coverage:** [AVE-REQ-013](requirements/AVE-REQ-013.md), [AVE-REQ-024](requirements/AVE-REQ-024.md), [AVE-REQ-026](requirements/AVE-REQ-026.md), [AVE-REQ-027](requirements/AVE-REQ-027.md), [AVE-REQ-029](requirements/AVE-REQ-029.md).

<a id="at-06"></a>

## AT-06 - Silent source with visual and manual anchors

**Fixtures:** B has no audio. A and B share a visible flash in one case; another case requires two user-supplied anchors.

**Actions:** Run permitted visual-event matching, inspect confidence, set manual anchors and nudge timing through the UI.

**Expected result:** Visual/manual evidence produces an explicit map without requiring tracking. Controls can align the qualified fixture. Manual corrections persist through reanalysis and restart.

**Required evidence:** Anchor coordinates/source times, mapping evidence, preview/export event checks, UI interaction assertions.

**Requirement coverage:** [AVE-REQ-025](requirements/AVE-REQ-025.md), [AVE-REQ-030](requirements/AVE-REQ-030.md).

<a id="at-07"></a>

## AT-07 - Unobservable or ambiguous synchronization

**Fixtures:** Unrelated videos with missing audio, absent/coarse metadata, and no shared visual event; another pair has repetitive audio with ambiguous peaks.

**Actions:** Request automatic pairing and exact synchronization.

**Expected result:** Return insufficient evidence or low-confidence alternatives; do not assert a precise alignment or auto-pair solely from filenames. Manual sync remains usable.

**Required evidence:** Structured uncertainty/error result, no unauthorized timeline mutation, visible manual fallback.

**Requirement coverage:** [AVE-REQ-023](requirements/AVE-REQ-023.md), [AVE-REQ-025](requirements/AVE-REQ-025.md).

<a id="at-08"></a>

## AT-08 - Clock drift at beginning, middle, and end

**Fixtures:** 180-second synthetic source pair with independently generated anchors under T_reference=2+1.001*t_B; include a non-linear or inconsistent-anchor negative case.

**Actions:** Estimate offset and drift, render a low-resolution but time-correct verification output, then inspect early/middle/late events.

**Expected result:** Qualified affine fixture has residual at most one output frame at all inspected events. Negative fixture is flagged instead of forced into a false correction. Audio/transcript mappings follow the same transform.

**Required evidence:** Independent ground-truth anchors, estimated scale, decoded event timing, pitch/voice continuity check where audio was stretched.

**Requirement coverage:** [AVE-REQ-026](requirements/AVE-REQ-026.md), [AVE-REQ-028](requirements/AVE-REQ-028.md), [AVE-REQ-030](requirements/AVE-REQ-030.md), [AVE-REQ-033](requirements/AVE-REQ-033.md), [AVE-REQ-062](requirements/AVE-REQ-062.md).

<a id="at-09"></a>

## AT-09 - Dates, locations, and section exports

**Fixtures:** Assets with known timezones, timezone-free values, contradictory file modification dates, missing GPS, user city labels, and two recording days.

**Actions:** Group into sections, correct labels, add opening location titles, export each section and the whole sequence.

**Expected result:** No invented capture timezone/location; corrections persist. Individual sections start at zero with correctly clipped/rebased audio, overlays, captions, and selected chapter/metadata artifacts.

**Required evidence:** Raw/normalized metadata and provenance, section manifests, decoded export boundaries, caption timestamps.

**Requirement coverage:** [AVE-REQ-005](requirements/AVE-REQ-005.md), [AVE-REQ-006](requirements/AVE-REQ-006.md), [AVE-REQ-023](requirements/AVE-REQ-023.md), [AVE-REQ-035](requirements/AVE-REQ-035.md), [AVE-REQ-038](requirements/AVE-REQ-038.md), [AVE-REQ-039](requirements/AVE-REQ-039.md), [AVE-REQ-045](requirements/AVE-REQ-045.md), [AVE-REQ-062](requirements/AVE-REQ-062.md).

<a id="at-10"></a>

## AT-10 - Overlays, international text, and creative profiles

**Fixtures:** Color ramps, a transparent PNG, timed overlay [3,6), opening/ending text, and Latin/CJK strings; multiple camera sources.

**Actions:** Edit overlay timing/position via UI and API, add fades/manual keyframes, save a project look, add camera and clip overrides, export full/section/short.

**Expected result:** Text appears only in its interval, glyphs render, aspect changes expose overflow, and previews/reference frames show the selected styles. Profiles apply once with documented precedence; no original is modified.

**Required evidence:** Pixel masks around t=3 and t=6, glyph bounding checks, color-patch metrics, profile inheritance assertions, original hashes.

**Requirement coverage:** [AVE-REQ-019](requirements/AVE-REQ-019.md), [AVE-REQ-022](requirements/AVE-REQ-022.md), [AVE-REQ-034](requirements/AVE-REQ-034.md), [AVE-REQ-035](requirements/AVE-REQ-035.md), [AVE-REQ-036](requirements/AVE-REQ-036.md), [AVE-REQ-037](requirements/AVE-REQ-037.md), [AVE-REQ-040](requirements/AVE-REQ-040.md), [AVE-REQ-041](requirements/AVE-REQ-041.md), [AVE-REQ-042](requirements/AVE-REQ-042.md), [AVE-REQ-043](requirements/AVE-REQ-043.md), [AVE-REQ-061](requirements/AVE-REQ-061.md), [AVE-REQ-064](requirements/AVE-REQ-064.md), [AVE-REQ-078](requirements/AVE-REQ-078.md).

<a id="at-11"></a>

## AT-11 - Manual nonlinear editing journey

**Fixtures:** A multitrack timeline with four video and four audio tracks, mixed layouts, transitions, sections, subtitles, and source handles.

**Actions:** Drag/reorder/trim, split at playhead, ripple-delete, edit transition handles, select/lock tracks, change audio and numeric controls, then undo/redo.

**Expected result:** Each action is real, bounded, and reflected in preview/export. Invalid handles are rejected, linked sync remains valid, keyboard/numeric alternatives work, and no primary timeline control is decorative.

**Required evidence:** Browser end-to-end recording/screenshots, command history, domain-state assertions, post-edit reference frames.

**Requirement coverage:** [AVE-REQ-011](requirements/AVE-REQ-011.md), [AVE-REQ-013](requirements/AVE-REQ-013.md), [AVE-REQ-014](requirements/AVE-REQ-014.md), [AVE-REQ-017](requirements/AVE-REQ-017.md), [AVE-REQ-021](requirements/AVE-REQ-021.md), [AVE-REQ-029](requirements/AVE-REQ-029.md), [AVE-REQ-030](requirements/AVE-REQ-030.md), [AVE-REQ-038](requirements/AVE-REQ-038.md), [AVE-REQ-089](requirements/AVE-REQ-089.md).

<a id="at-12"></a>

## AT-12 - User/AI conflicts and atomic proposals

**Fixtures:** Project revision 12; an AI proposal targets it while the user commits revision 13; locked and out-of-scope objects also exist.

**Actions:** Apply the stale proposal, retry an idempotent operation, submit a batch with one invalid operation, perform a valid scoped edit and undo it.

**Expected result:** Stale or invalid changes fail atomically with structured reasons, idempotent replay creates no duplicates, locks/scope are enforced server-side, and one undo reverses the entire AI edit.

**Required evidence:** Before/after project snapshots, revision and request IDs, conflict responses, database transaction checks.

**Requirement coverage:** [AVE-REQ-015](requirements/AVE-REQ-015.md), [AVE-REQ-016](requirements/AVE-REQ-016.md), [AVE-REQ-029](requirements/AVE-REQ-029.md), [AVE-REQ-044](requirements/AVE-REQ-044.md), [AVE-REQ-046](requirements/AVE-REQ-046.md), [AVE-REQ-048](requirements/AVE-REQ-048.md).

<a id="at-13"></a>

## AT-13 - ASR, translations, and subtitle time mapping

**Fixtures:** Clearly labeled test speech with known content in at least two supported languages, silence, editable source cue ranges, and a repeated/trimmed source. Include non-ASCII text.

**Actions:** Transcribe with a real supported local model, correct text, translate with a real configured provider, select primary/secondary display, trim/sync and export section/short/full outputs with SRT/VTT.

**Expected result:** Speech text and timing meet the recorded test rubric; silence yields no accepted invented transcript. Original/translation state is distinct; cues clip/split/rebase correctly. Sidecars are valid UTF-8 and toggles are separate from burn-in.

**Required evidence:** Model/revision/device log, reviewed fixture transcript, cue mapping oracle, parsed SRT/VTT, decoded burn-in samples; mark unavailable live translation as unverified, not passed.

**Requirement coverage:** [AVE-REQ-012](requirements/AVE-REQ-012.md), [AVE-REQ-022](requirements/AVE-REQ-022.md), [AVE-REQ-028](requirements/AVE-REQ-028.md), [AVE-REQ-036](requirements/AVE-REQ-036.md), [AVE-REQ-039](requirements/AVE-REQ-039.md), [AVE-REQ-057](requirements/AVE-REQ-057.md), [AVE-REQ-058](requirements/AVE-REQ-058.md), [AVE-REQ-059](requirements/AVE-REQ-059.md), [AVE-REQ-060](requirements/AVE-REQ-060.md), [AVE-REQ-061](requirements/AVE-REQ-061.md), [AVE-REQ-062](requirements/AVE-REQ-062.md), [AVE-REQ-063](requirements/AVE-REQ-063.md), [AVE-REQ-064](requirements/AVE-REQ-064.md), [AVE-REQ-069](requirements/AVE-REQ-069.md).

<a id="at-14"></a>

## AT-14 - Real AI draft and natural-language revisions

**Fixtures:** The labeled travel fixture library with two perspectives, joint shots, day/city metadata, usable scenic footage, and a flagged accidental clip; a real configured planning provider.

**Actions:** Ask for the described chronological trip edit, then shorten a section, swap views, and move its title using scoped prompts.

**Expected result:** The provider produces valid grounded proposals and an actual playable timeline with mixed layouts and reference audio. Exclusions/uncertainties are reported. Revisions are reversible and do not bypass manual locks.

**Required evidence:** Redacted live-provider request metadata, structured proposals, independent invariant checks, actual preview/export, acceptance rubric; provider mocks cannot certify live AI behavior.

**Requirement coverage:** [AVE-REQ-006](requirements/AVE-REQ-006.md), [AVE-REQ-008](requirements/AVE-REQ-008.md), [AVE-REQ-035](requirements/AVE-REQ-035.md), [AVE-REQ-044](requirements/AVE-REQ-044.md), [AVE-REQ-045](requirements/AVE-REQ-045.md), [AVE-REQ-047](requirements/AVE-REQ-047.md), [AVE-REQ-050](requirements/AVE-REQ-050.md), [AVE-REQ-068](requirements/AVE-REQ-068.md).

<a id="at-15"></a>

## AT-15 - Accidental-recording classification without data loss

**Fixtures:** Corrupt, tiny, black, frozen, silent-scenic, dark-night, and speech-free action fixtures with explicit intended labels.

**Actions:** Analyze, inspect reasons, override classifications, draft with selected exclusions, then reanalyze.

**Expected result:** Flags are reviewable; silence/night alone are not mandatory exclusion. User overrides survive, excluded clips can be restored, and originals remain present.

**Required evidence:** Feature measurements, reason/confidence output, override persistence, source hashes and draft exclusion manifest.

**Requirement coverage:** [AVE-REQ-008](requirements/AVE-REQ-008.md), [AVE-REQ-057](requirements/AVE-REQ-057.md).

<a id="at-16"></a>

## AT-16 - Editing API and MCP interoperability

**Fixtures:** Known project, restricted credentials, malformed operation payloads, and a standards-compliant MCP test client.

**Actions:** Discover tools; read assets/timeline; submit/dry-run/apply a bounded edit; request export; poll/cancel jobs. Test both local and configured remote transports.

**Expected result:** Actual typed operations work, structured errors propagate, no arbitrary shell/file-write tool is exposed, and UI-equivalent operations produce equivalent state. Scope/auth rules survive MCP wrapping.

**Required evidence:** Contract tests, protocol transcripts with secrets removed, capability negotiation and output references. Live Claude/Codex client checks remain separately recorded.

**Requirement coverage:** [AVE-REQ-016](requirements/AVE-REQ-016.md), [AVE-REQ-034](requirements/AVE-REQ-034.md), [AVE-REQ-046](requirements/AVE-REQ-046.md), [AVE-REQ-048](requirements/AVE-REQ-048.md), [AVE-REQ-049](requirements/AVE-REQ-049.md), [AVE-REQ-055](requirements/AVE-REQ-055.md).

<a id="at-17"></a>

## AT-17 - Durable job cancellation, crash, and retry

**Fixtures:** Queued/running proxy, transcription, and render jobs with controlled slow processing and injected failures.

**Actions:** Cancel, kill a worker, restart the service, retry with the same request ID, and edit the project while an export runs.

**Expected result:** No duplicate committed edit or published partial file; work recovers or fails clearly. Export stays pinned to its original revision and one failed batch item does not invalidate other outputs.

**Required evidence:** Job-state transition log, persistence checks, temporary-file audit, output manifests.

**Requirement coverage:** [AVE-REQ-015](requirements/AVE-REQ-015.md), [AVE-REQ-039](requirements/AVE-REQ-039.md), [AVE-REQ-054](requirements/AVE-REQ-054.md), [AVE-REQ-070](requirements/AVE-REQ-070.md), [AVE-REQ-077](requirements/AVE-REQ-077.md), [AVE-REQ-078](requirements/AVE-REQ-078.md), [AVE-REQ-085](requirements/AVE-REQ-085.md), [AVE-REQ-090](requirements/AVE-REQ-090.md).

<a id="at-18"></a>

## AT-18 - Format, quality, and hardware export matrix

**Fixtures:** A small composition with overlays, audio, and captions; reference software codecs; a real accelerator only when accessible.

**Actions:** Export MP4/H.264/AAC, WebM/VP9/Opus and declared MKV profile. Exercise quality/bitrate, ratios, rates, embedded-caption compatibility, forced CPU and detected GPU paths.

**Expected result:** Actual container/codec/streams/dimensions/rate/duration match settings and decode correctly. Unsupported combinations fail preflight. Hardware detection requires a real encode; absent hardware is not a passing GPU test.

**Required evidence:** ffprobe output, decode checks, reference frame/audio metrics, actual selected device, explicit pass/fail/not-run matrix.

**Requirement coverage:** [AVE-REQ-018](requirements/AVE-REQ-018.md), [AVE-REQ-022](requirements/AVE-REQ-022.md), [AVE-REQ-043](requirements/AVE-REQ-043.md), [AVE-REQ-063](requirements/AVE-REQ-063.md), [AVE-REQ-070](requirements/AVE-REQ-070.md), [AVE-REQ-072](requirements/AVE-REQ-072.md), [AVE-REQ-073](requirements/AVE-REQ-073.md), [AVE-REQ-074](requirements/AVE-REQ-074.md), [AVE-REQ-075](requirements/AVE-REQ-075.md), [AVE-REQ-076](requirements/AVE-REQ-076.md), [AVE-REQ-078](requirements/AVE-REQ-078.md), [AVE-REQ-079](requirements/AVE-REQ-079.md), [AVE-REQ-081](requirements/AVE-REQ-081.md), [AVE-REQ-085](requirements/AVE-REQ-085.md).

<a id="at-19"></a>

## AT-19 - Visual indexing and editable shorts

**Fixtures:** Longer source clips with distinct labeled moments, scene changes, transcript hooks, and optional real frame-caption model output.

**Actions:** Build bounded frame/shot index; retrieve relevant evidence; propose 15-20-second highlights; create an 18-second square short; manually reframe and export.

**Expected result:** Every index item and proposal retains source time/provenance. Derived shorts leave the parent unchanged, preserve sound/sync/look/captions, and satisfy actual duration/canvas constraints.

**Required evidence:** Extraction sample budget, optional live-model log, highlight evidence links, parent/child diffs, decoded short probe and cue mapping.

**Requirement coverage:** [AVE-REQ-047](requirements/AVE-REQ-047.md), [AVE-REQ-058](requirements/AVE-REQ-058.md), [AVE-REQ-065](requirements/AVE-REQ-065.md), [AVE-REQ-066](requirements/AVE-REQ-066.md), [AVE-REQ-068](requirements/AVE-REQ-068.md), [AVE-REQ-069](requirements/AVE-REQ-069.md), [AVE-REQ-070](requirements/AVE-REQ-070.md), [AVE-REQ-071](requirements/AVE-REQ-071.md), [AVE-REQ-079](requirements/AVE-REQ-079.md).

<a id="at-20"></a>

## AT-20 - Media, model, credential, and prompt security

**Fixtures:** Malicious filenames/paths, symlinks, subtitle text, overlay expressions, archive traversal, transcript prompt injection, wrong-project tokens, SSRF URLs, and a fake secret canary.

**Actions:** Exercise all ingestion, provider, export and tool routes in a constrained test environment.

**Expected result:** No arbitrary code execution, path escape, unauthorized egress, cross-project mutation, original deletion, or secret leak. External media analysis requires the selected data policy.

**Required evidence:** Negative security tests, sandbox/path checks, logs and bundle canary scans, operation authorization assertions.

**Requirement coverage:** [AVE-REQ-005](requirements/AVE-REQ-005.md), [AVE-REQ-010](requirements/AVE-REQ-010.md), [AVE-REQ-036](requirements/AVE-REQ-036.md), [AVE-REQ-046](requirements/AVE-REQ-046.md), [AVE-REQ-049](requirements/AVE-REQ-049.md), [AVE-REQ-051](requirements/AVE-REQ-051.md), [AVE-REQ-052](requirements/AVE-REQ-052.md), [AVE-REQ-055](requirements/AVE-REQ-055.md), [AVE-REQ-056](requirements/AVE-REQ-056.md), [AVE-REQ-080](requirements/AVE-REQ-080.md), [AVE-REQ-081](requirements/AVE-REQ-081.md), [AVE-REQ-082](requirements/AVE-REQ-082.md), [AVE-REQ-085](requirements/AVE-REQ-085.md), [AVE-REQ-086](requirements/AVE-REQ-086.md), [AVE-REQ-087](requirements/AVE-REQ-087.md).

<a id="at-21"></a>

## AT-21 - Fresh installation and disconnected operation

**Fixtures:** Clean documented Linux CPU reference setup and supported desktop browsers; cached model assets for offline tests.

**Actions:** Install, migrate, start, run the quick-start journey, restart, disconnect external network, edit and export again.

**Expected result:** Instructions work with pinned dependencies, persistent storage and health checks. Core manual editing and CPU export work offline. Missing credentials/models show actionable status without breaking the editor.

**Required evidence:** Exact commands, dependency inventory, health probes, browser screenshots and offline export artifacts.

**Requirement coverage:** [AVE-REQ-082](requirements/AVE-REQ-082.md), [AVE-REQ-088](requirements/AVE-REQ-088.md), [AVE-REQ-089](requirements/AVE-REQ-089.md), [AVE-REQ-091](requirements/AVE-REQ-091.md), [AVE-REQ-092](requirements/AVE-REQ-092.md).

<a id="at-22"></a>

## AT-22 - Backup, relink, cache cleanup, and recovery

**Fixtures:** Projects with edits, profiles, translations, missing assets, derived caches, and API credentials held outside project data.

**Actions:** Export metadata-only and self-contained bundles, restore, relink media, clean caches, simulate crashes during autosave and migration.

**Expected result:** Accepted edits and original checksums survive. Bundles omit secrets, paths are safe, caches regenerate, and unsupported versions or mismatched media do not corrupt projects.

**Required evidence:** Roundtrip schema/state comparison, hashes, bundle inventory, migration/recovery logs.

**Requirement coverage:** [AVE-REQ-001](requirements/AVE-REQ-001.md), [AVE-REQ-003](requirements/AVE-REQ-003.md), [AVE-REQ-007](requirements/AVE-REQ-007.md), [AVE-REQ-009](requirements/AVE-REQ-009.md), [AVE-REQ-010](requirements/AVE-REQ-010.md), [AVE-REQ-015](requirements/AVE-REQ-015.md), [AVE-REQ-041](requirements/AVE-REQ-041.md), [AVE-REQ-080](requirements/AVE-REQ-080.md), [AVE-REQ-090](requirements/AVE-REQ-090.md).

<a id="at-23"></a>

## AT-23 - Resource limits and large-media behavior

**Fixtures:** Reference 4-vCPU/8-GiB worker, a genuine large media/import stream, long recording, 2K/60 pair, low-disk condition, and insufficient-model-memory condition.

**Actions:** Import/process with instrumentation; launch competing jobs; fill a controlled temporary quota; request an infeasible model profile.

**Expected result:** Work is streaming/chunked, concurrency bounded, baseline render worker respects the configured 6-GiB budget excluding optional LLM/VLM inference, and failures preserve originals/edits.

**Required evidence:** Peak RSS/cgroup metrics, job admission log, disk behavior, elapsed time and cleanup audit. Do not claim real-time rendering.

**Requirement coverage:** [AVE-REQ-002](requirements/AVE-REQ-002.md), [AVE-REQ-053](requirements/AVE-REQ-053.md), [AVE-REQ-065](requirements/AVE-REQ-065.md), [AVE-REQ-075](requirements/AVE-REQ-075.md), [AVE-REQ-076](requirements/AVE-REQ-076.md), [AVE-REQ-077](requirements/AVE-REQ-077.md), [AVE-REQ-080](requirements/AVE-REQ-080.md), [AVE-REQ-082](requirements/AVE-REQ-082.md), [AVE-REQ-084](requirements/AVE-REQ-084.md), [AVE-REQ-086](requirements/AVE-REQ-086.md).

<a id="at-24"></a>

## AT-24 - Provider and model capability matrix

**Fixtures:** Controlled mock endpoints for negative contract cases plus real configured Anthropic/OpenAI-compatible, Claude Agent, Codex, ASR and optional vision paths where available.

**Actions:** Test connection, capability fallback, malformed output, rate limit, timeout, cancellation, cache invalidation, download/pinning and missing credentials.

**Expected result:** Capabilities and billing/auth boundaries are respected. Unsupported paths remain visibly unavailable. Mocks certify contracts only; actual credentialed/model/device tests establish live support.

**Required evidence:** Per-adapter implemented/contract-tested/live-tested/unavailable matrix with exact SDK/model revisions and redacted commands.

**Requirement coverage:** [AVE-REQ-044](requirements/AVE-REQ-044.md), [AVE-REQ-049](requirements/AVE-REQ-049.md), [AVE-REQ-050](requirements/AVE-REQ-050.md), [AVE-REQ-051](requirements/AVE-REQ-051.md), [AVE-REQ-052](requirements/AVE-REQ-052.md), [AVE-REQ-053](requirements/AVE-REQ-053.md), [AVE-REQ-054](requirements/AVE-REQ-054.md), [AVE-REQ-056](requirements/AVE-REQ-056.md), [AVE-REQ-057](requirements/AVE-REQ-057.md), [AVE-REQ-059](requirements/AVE-REQ-059.md), [AVE-REQ-060](requirements/AVE-REQ-060.md), [AVE-REQ-066](requirements/AVE-REQ-066.md), [AVE-REQ-073](requirements/AVE-REQ-073.md), [AVE-REQ-076](requirements/AVE-REQ-076.md), [AVE-REQ-087](requirements/AVE-REQ-087.md), [AVE-REQ-091](requirements/AVE-REQ-091.md).

<a id="at-25"></a>

## AT-25 - Grounded publication metadata

**Fixtures:** Known transcript, city labels and selected whole/section/short output with no claim of attendance, identities or locations beyond supplied evidence.

**Actions:** Generate keywords, title/description and hashtags; change target language; copy fields and export the bundle.

**Expected result:** Text relates to actual content, is editable, and remains distinct from subtitle/container data. No fabricated credits or guaranteed SEO claims; artifacts match selected output range.

**Required evidence:** Redacted model provenance, content-grounding checklist, copied/exported text/JSON and output manifest.

**Requirement coverage:** [AVE-REQ-047](requirements/AVE-REQ-047.md), [AVE-REQ-071](requirements/AVE-REQ-071.md), [AVE-REQ-081](requirements/AVE-REQ-081.md).

<a id="at-26"></a>

## AT-26 - Color tags, HDR/log uncertainty, and range correctness

**Fixtures:** SDR ramps with known range/primaries; recognized HDR test media; unknown/unlabeled camera-log fixture; two cameras with different input interpretations.

**Actions:** Probe, select technical input transform, apply project/camera/clip looks, inspect reference frames, and render SDR output.

**Expected result:** Known transforms apply once, tags match output, full/limited-range behavior is correct, and unknown log/HDR is flagged rather than silently certified accurate.

**Required evidence:** Probe metadata, documented transform decisions, decoded patch measurements and grade inheritance tests.

**Requirement coverage:** [AVE-REQ-004](requirements/AVE-REQ-004.md), [AVE-REQ-040](requirements/AVE-REQ-040.md), [AVE-REQ-042](requirements/AVE-REQ-042.md), [AVE-REQ-043](requirements/AVE-REQ-043.md).

<a id="at-27"></a>

## AT-27 - UI responsiveness and preview behavior

**Fixtures:** 300-item indexed timeline, proxies, representative overlays/audio, and declared browser/CPU/RAM/display settings.

**Actions:** Instrument repeated selection, trim feedback, zoom, scroll, scrubbing, and quality changes while a render is active.

**Expected result:** Local feedback targets p95 under 150 ms as specified; reference-frame generation shows pending state; export rate/resolution do not change with preview quality.

**Required evidence:** Timestamped benchmark results, browser trace, UI/worker isolation metrics, exact configuration and any unmet target.

**Requirement coverage:** [AVE-REQ-007](requirements/AVE-REQ-007.md), [AVE-REQ-017](requirements/AVE-REQ-017.md), [AVE-REQ-084](requirements/AVE-REQ-084.md), [AVE-REQ-089](requirements/AVE-REQ-089.md).

<a id="at-28"></a>

## AT-28 - Audio routing, mixing, resampling, and clipping

**Fixtures:** Distinct signals in A/B plus independent music/voice tracks, 44.1/48 kHz sources, one silent video and a full-width joint shot.

**Actions:** Select one master, mix intentional extra audio, trim/fade/normalize optionally, switch layouts and export.

**Expected result:** Only intended tracks are audible; camera audio is not doubled, clipping is detected, resampling/encoder delay are handled, and switches/fades preserve sync.

**Required evidence:** Decoded audio, spectral/event/source markers, gain/peak measurements, A/V timestamp comparisons.

**Requirement coverage:** [AVE-REQ-031](requirements/AVE-REQ-031.md), [AVE-REQ-032](requirements/AVE-REQ-032.md), [AVE-REQ-033](requirements/AVE-REQ-033.md), [AVE-REQ-072](requirements/AVE-REQ-072.md).

<a id="at-29"></a>

## AT-29 - Verification integrity and requirement coverage

**Fixtures:** Working repository with the imported baseline, one intentionally failing test, stale verification evidence, and proposed workflow changes.

**Actions:** Run package checks and actual product tiers; modify source after a pass; inspect traceability; propose weakening a tolerance or dropping a test.

**Expected result:** Package checks cannot certify product completion. Current-tree evidence is required. Failures remain failures; forbidden gate weakening is rejected; each applicable criterion has evidence or an explicit gap.

**Required evidence:** CI/local reports, baseline hashes, criterion-level coverage matrix, stale-evidence detection and reviewed workflow-change log.

**Requirement coverage:** [AVE-REQ-083](requirements/AVE-REQ-083.md), [AVE-REQ-088](requirements/AVE-REQ-088.md), [AVE-REQ-093](requirements/AVE-REQ-093.md), [AVE-REQ-094](requirements/AVE-REQ-094.md), [AVE-REQ-095](requirements/AVE-REQ-095.md), [AVE-REQ-096](requirements/AVE-REQ-096.md), [AVE-REQ-097](requirements/AVE-REQ-097.md), [AVE-REQ-098](requirements/AVE-REQ-098.md), [AVE-REQ-099](requirements/AVE-REQ-099.md).

<a id="at-30"></a>

## AT-30 - Cloud capability audit, continuation, and whole-product handover

**Fixtures:** Actual Claude Code cloud environment; existing bootstrap; simulated lack of native workflows, GPU or provider credentials; interrupted progress state.

**Actions:** Adopt specification, select a capability-aware workflow, implement a vertical slice, checkpoint/resume, review the complete product scope and deliver evidence.

**Expected result:** No bootstrap overwrite or fake platform capability. Native dynamic workflows are used when available; bounded subagent/sequential fallback works. The agent does not call a partial milestone the complete product.

**Required evidence:** Environment capability report, task handoffs, exact resume action, actual application walkthrough and explicit unverified integration list.

**Requirement coverage:** [AVE-REQ-092](requirements/AVE-REQ-092.md), [AVE-REQ-093](requirements/AVE-REQ-093.md), [AVE-REQ-094](requirements/AVE-REQ-094.md), [AVE-REQ-095](requirements/AVE-REQ-095.md), [AVE-REQ-096](requirements/AVE-REQ-096.md), [AVE-REQ-097](requirements/AVE-REQ-097.md), [AVE-REQ-098](requirements/AVE-REQ-098.md), [AVE-REQ-099](requirements/AVE-REQ-099.md), [AVE-REQ-100](requirements/AVE-REQ-100.md).

<a id="at-31"></a>

## AT-31 - Future-scope exclusion and no dependency creep

**Fixtures:** Version-one dependency graph, UI feature flags, product README, analysis schemas and roadmap.

**Actions:** Review required feature paths and released claims for hidden tracking or advanced temporal-understanding dependencies.

**Expected result:** Version one works without object/motion tracking or full continuous video understanding. Static crops/manual keyframes/basic sampled-frame descriptions are not misadvertised as those future features.

**Required evidence:** Dependency/feature audit, explicit deferred requirements, tested version-one journey with future features absent.

**Requirement coverage:** [AVE-REQ-037](requirements/AVE-REQ-037.md), [AVE-REQ-067](requirements/AVE-REQ-067.md), [AVE-REQ-100](requirements/AVE-REQ-100.md), [AVE-REQ-101](requirements/AVE-REQ-101.md).
