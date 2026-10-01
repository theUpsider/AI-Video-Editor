# Product definition

**Status:** defined — 2026-10-01
**Name:** AI Video Editor
**Inputs:** [2026-10-01 AI Video Editor version one](product-inputs/2026-10-01-ai-video-editor-v1.md); immutable
baseline [ai-video-editor-requirements/](../ai-video-editor-requirements/README.md) (package v1.0).

This file is the canonical product definition. It condenses the baseline's
[spec/PRODUCT.md](../ai-video-editor-requirements/spec/PRODUCT.md),
[scope and assumptions](../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md) and
[user brief](../ai-video-editor-requirements/intake/USER_BRIEF.md). Epics, features and requirements in
`docs/requirements/` ([format](requirements/README.md), [import mapping](requirements/IMPORT_MAPPING.md)) carry
the baseline's stable AVE IDs; [ROADMAP.md](ROADMAP.md) orders them.

## Maintenance rules

1. Replace each `_TBD:` line with content. A populated file has no line starting with `_TBD`
   (`grep -n '^_TBD' docs/PRODUCT.md` prints nothing); a section with nothing to state says
   `None.` with the reason.
2. Stay at product level. Behavior details and acceptance criteria live in requirement files.
3. Infer baseline capabilities with
   [baseline-capabilities.md](../.claude/skills/product-definition/baseline-capabilities.md)
   and this rule: «Include what is required to make the requested product coherent,
   reliable, usable, and production-quality. Avoid speculative features that do not support
   an identified user need.»
4. Never silently change human-stated content. A change that alters product intent goes to
   the human ([CLAUDE.md](../CLAUDE.md) § Autonomy and escalation). Apply new human input
   through the amendment mode of `product-definition`. The baseline package stays unchanged.
5. Allocate `GOAL-NNN` and `UJ-NNN` sequentially (three digits, zero-padded); never reuse or
   renumber them.

## Product vision

An AI-assisted, non-destructive video editor for travel and conversational recordings captured by two
people from different perspectives. The user imports a collection, describes the intended edit, receives
an actual playable draft, and refines it through a conventional timeline or further prompts. The defining
case alternates synchronized left/right camera views with full-width shots of both people, one selected
source supplying the sound, across several days and cities with a common look.

## Problem statement

Two manually started cameras produce overlapping, differently framed recordings with independent clocks,
mixed rates and aspect ratios. Assembling a synchronized split-screen/full-width travel edit with titles,
captions, sections, shorts and publication text takes hours of manual multicamera work in conventional
editors, and generic AI video tools either generate footage or hide their edits in unreviewable output.

## Target users

- **Primary:** a creator who records trips and conversations with a second person and two cameras, edits
  on a self-hosted machine, and wants a fast AI-assisted first draft that remains fully editable.
- **Secondary:** an external AI agent (Claude Code, Codex or another MCP client) acting for that creator
  through the editor's typed editing interface, with the creator's authority and limits.

## Product goals

| ID | Goal | Success signal |
|---|---|---|
| GOAL-001 | Import and organize a mixed travel collection without touching originals | A mixed batch imports with exact probed dimensions/rates and capture metadata; original SHA-256 values are unchanged after every operation (AT-01, AT-22) |
| GOAL-002 | Edit a multitrack timeline with mixed split-screen and full-width layouts manually | Every primary timeline control changes the rendered output; contain/cover geometry is exact (AT-02, AT-11) |
| GOAL-003 | Keep two perspectives synchronized while one selected source supplies the sound | Known-offset and drift fixtures render with event alignment within one output frame and only the selected source audible; weak evidence yields an explicit uncertainty result (AT-04–AT-08, AT-28) |
| GOAL-004 | Present the trip with timed titles, sections and consistent looks | Overlays appear only in their half-open intervals; sections export independently; profiles apply once with documented precedence (AT-09, AT-10, AT-26) |
| GOAL-005 | Draft and revise edits through safe, scoped AI and standard integrations | A configured provider produces a valid playable draft and a scoped reversible revision; stale, locked or out-of-scope edits fail atomically; MCP clients use the same operations (AT-12, AT-14, AT-16, AT-24) |
| GOAL-006 | Transcribe, caption and index source media honestly | Test speech is transcribed by a real local model; original and translated cue tracks stay distinct and retime through edits; missing capabilities are reported (AT-13, AT-15, AT-19) |
| GOAL-007 | Deliver real full, section and short exports with publication text | Decoded outputs match profile, timing, audio, captions and looks; an 18-second square short exports; copyable metadata stays separate from captions (AT-18, AT-19, AT-25) |
| GOAL-008 | Operate reliably, securely and offline as a self-hosted application | Fresh CPU install, crash recovery, backup/relink, security negatives and offline edit/export pass (AT-17, AT-20–AT-23, AT-27) |
| GOAL-009 | Deliver through a verified, resumable autonomous workflow | Every claimed criterion has current-tree evidence; gates fail on injected faults; progress resumes from the repository (AT-29, AT-30) |
| GOAL-010 | Keep deferred future capabilities out of version one | Version one works with object/motion tracking and continuous video understanding absent and unadvertised (AT-31) |

## Core user journeys

### UJ-001 — Import and inspect a collection
- **Actor and trigger:** the creator starts a new trip project.
- **Steps:** 1. create a project and choose the output ratio; 2. import videos, audio and images as a batch;
  3. inspect thumbnails, exact dimensions/rates, camera labels, capture dates/locations and analysis progress;
  4. retry or relink failed items.
- **Outcome:** stable assets with unchanged originals and proxies for preview.
- **Failure paths:** corrupt or unsupported file fails alone with a reason; duplicates are reported; missing
  metadata stays unknown.
- **Goals:** GOAL-001, GOAL-008.

### UJ-002 — Generate an AI first draft
- **Actor and trigger:** the creator describes the intended edit in natural language.
- **Steps:** 1. the editor proposes camera pairs and estimates synchronization with confidence; 2. builds source
  transcripts and bounded keyframe indexes; 3. the configured AI returns validated editorial operations; 4. the
  editor assembles sections, split/full layouts, audio routing, a look, timed titles and captions as one
  revision; 5. the creator plays the draft and reviews reported exclusions and uncertainties.
- **Outcome:** an editable project revision and a playable preview.
- **Failure paths:** no provider configured → the manual editor and rule-based assembly stay usable with an
  actionable status; insufficient sync evidence → manual anchors requested.
- **Goals:** GOAL-003, GOAL-005, GOAL-006.

### UJ-003 — Refine manually and conversationally
- **Actor and trigger:** the creator reviews the draft.
- **Steps:** 1. drag cuts, trim, split, change transitions, overlays, crop, final audio, section boundaries and
  color controls; 2. ask for scoped changes ("keep this section five seconds longer", "swap the two views
  here", "use this clip's audio only"); 3. inspect the proposed diff, apply, preview, and undo when needed.
- **Outcome:** every change is a validated, atomic, undoable transaction on the same composition.
- **Failure paths:** stale proposals, locked objects and out-of-scope operations are rejected with reasons.
- **Goals:** GOAL-002, GOAL-005.

### UJ-004 — Add captions and publication material
- **Steps:** 1. correct transcripts; 2. choose original and translated subtitle languages and an optional second
  displayed language; 3. choose sidecar, embedded or deliberate burn-in delivery; 4. review AI-suggested titles,
  descriptions, keywords and hashtags grounded in the content and copy them.
- **Failure paths:** no translation provider → translation reported unavailable; silence never yields invented
  dialogue.
- **Goals:** GOAL-006, GOAL-007.

### UJ-005 — Create shorts and deliver
- **Steps:** 1. request 15–20-second highlights; 2. review proposed moments with evidence; 3. choose square,
  portrait or landscape composition and adjust each short independently; 4. export the whole project, a section
  or selected shorts on CPU or a verified accelerator, with caption, chapter and metadata artifacts.
- **Failure paths:** unsupported format combinations fail preflight; a failed batch item does not invalidate the
  others; cancellation never publishes partial files.
- **Goals:** GOAL-004, GOAL-007, GOAL-008.

### UJ-006 — Edit through an external agent
- **Actor and trigger:** the creator's MCP client (Claude Code, Codex or another) connects to the running editor.
- **Steps:** 1. discover tools and capabilities; 2. read assets and the timeline; 3. dry-run and apply a bounded
  edit with the expected revision; 4. request an export and poll its job.
- **Failure paths:** unauthenticated remote access, wrong-project scope and arbitrary shell/file tools are refused.
- **Goals:** GOAL-005, GOAL-008.

## Must-have features

Each line quotes the user brief clause ([USER_BRIEF.md](../ai-video-editor-requirements/intake/USER_BRIEF.md))
and names the feature that covers it; the full clause-to-requirement matrix is the baseline's
[TRACEABILITY.md](../ai-video-editor-requirements/spec/TRACEABILITY.md).

- U01 "Import the user's clips into a collection" → AVE-FEAT-001
- U02 "simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output" → AVE-FEAT-002, AVE-FEAT-003, AVE-FEAT-005
- U03 "Detect actual input frame rates and resolutions … approximately 2K/60 fps … mixed inputs" → AVE-FEAT-001, AVE-FEAT-017
- U04 "place images or text over the video for explicit start/end intervals" → AVE-FEAT-006
- U05 "contextual titles … near the start and optional credits/references near the end" → AVE-FEAT-006
- U07 "identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models" → AVE-FEAT-014
- U08 "standardized AI interface, preferably MCP" → AVE-FEAT-010
- U09 "Extract speech and generate automatic transcript/subtitle information" → AVE-FEAT-013
- U10 "selectable subtitle languages and an optional second simultaneously displayed language" → AVE-FEAT-013
- U11 "separately usable caption/metadata outputs for external platforms" → AVE-FEAT-013, AVE-FEAT-016
- U12 "approximately 15-20-second highlights … editable shorts, including square 1:1 outputs" → AVE-FEAT-015
- U13 "copyable keywords and related SEO/publication text" → AVE-FEAT-016
- U14 "Identify accidental or content-poor recordings" → AVE-FEAT-001
- U15 "Synchronize simultaneous perspectives … while one source supplies the final audio" → AVE-FEAT-004, AVE-FEAT-005
- U16 "cameras can begin and end at different times; automatically estimate their overlap and timing" → AVE-FEAT-004
- U17 "Extract recording date, time, and location when available" → AVE-FEAT-001
- U18 "Organize a multi-day, multi-city trip into editable sections and export any section or the full edit" → AVE-FEAT-007
- U19 "Mix two-perspective split-screen footage with full-width 16:9 footage … and then return to split-screen" → AVE-FEAT-003
- U20 "ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings" → AVE-FEAT-002
- U21 "color grading … reusable looks applied across a trip/project" → AVE-FEAT-008
- U22 "CPU-only rendering and GPU acceleration when available" → AVE-FEAT-017
- U23 "different video/container formats, frame rates, bitrates, and quality settings" → AVE-FEAT-017
- U24 "collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export" → AVE-FEAT-009
- U25 "integrate Claude Code and Codex as selectable AI/agent backends" → AVE-FEAT-011
- U26 "OpenAI-compatible endpoints and downloadable Hugging Face analysis models" → AVE-FEAT-011
- U27 "Use the already-created Claude Code project bootstrap … dynamic, self-improving, optimally adapted workflows" → AVE-FEAT-019
- U06 "Object tracking and motion tracking are future features" → AVE-FEAT-020 (deferred; excluded from version one)

## Product boundaries

- Single-owner, self-hosted browser application with a backend domain service and a separate media worker;
  binds locally by default, remote use requires authentication (baseline ASM-01, ASM-02).
- Inputs: common video, audio and image files with mixed dimensions, orientations, exact rational and variable
  frame rates; actual dimensions are probed, never assumed from labels such as "2K" (ASM-03, ASM-04).
- Outputs: MP4/H.264/AAC by default plus WebM/VP9/Opus and a declared MKV profile; SRT/VTT sidecars, embedded
  captions where the container supports them, chapters and metadata files.
- External AI: Anthropic and OpenAI-compatible providers, optional Claude Agent and Codex runtimes, external MCP
  clients and pinned Hugging Face analysis models, all off until configured and consented.
- CPU rendering always works; GPU acceleration only on a capability-tested device.

## Explicit non-goals

- Object/motion tracking and subject-following crops (AVE-REQ-101) — deferred by the user.
- Advanced continuous temporal video understanding (AVE-REQ-067) — deferred by the user; bounded keyframes,
  transcripts and optional frame captions are the version-one foundation.
- Social-platform publishing or account access — the user asked for compatible exports and copyable text.
- Real-time multiplayer editing, billing or collaboration platforms — one owner per deployment.
- Generative video footage, voice cloning/dubbing and automatic speaker separation — not requested.
- Full professional color/HDR mastering — version one guarantees a documented SDR Rec.709 workflow.
- Deep face/person identification and dedicated camera-control integration — not requested.

## Functional areas

- Project and asset management → AVE-EPIC-01
- Editing and composition → AVE-EPIC-02
- Synchronized perspectives and sound → AVE-EPIC-03
- Presentation, chapters and looks → AVE-EPIC-04
- AI orchestration and integration → AVE-EPIC-05
- Media intelligence and captions → AVE-EPIC-06
- Short-form content and delivery → AVE-EPIC-07
- Reliability, security and operations → AVE-EPIC-08
- Claude Code delivery process → AVE-EPIC-09
- Explicit future scope (deferred) → AVE-EPIC-10

## UX principles

1. Every timeline control is real: it changes the composition the renderer uses; nothing is decorative.
2. Show decisions and uncertainty: padding versus cropping, sync confidence, accidental-recording flags and
   unavailable capabilities are visible and actionable.
3. AI proposals are inspectable diffs with scope; one undo reverses one AI edit.
4. Long work runs as visible jobs with progress, cancellation and honest failure states.
5. Keyboard and numeric alternatives exist for drag interactions; the interface meets basic accessibility
   (focus, labels, contrast).
6. Originals are never at risk: deleting project data and deleting media are distinct, explicit actions.

## Security and privacy expectations

- Originals are immutable and content-addressed; cleanup deletes only registered derived files.
- Media, filenames, transcripts, subtitles and model outputs are untrusted data: typed operations, argv-only
  subprocesses, escaped text files for rendering, prompt-injection boundaries.
- Local import/edit/export sends nothing to a provider; external analysis requires an explicit data policy and
  consent, with budgets.
- Secrets stay server-side: never in the repository, browser, exports, prompts or logs.
- Remote API/MCP access requires authentication and project/operation scopes.
- Details: baseline [THREAT_MODEL.md](../ai-video-editor-requirements/spec/THREAT_MODEL.md).

## Performance expectations

- Local UI feedback (selection, trim, zoom, scroll) p95 under 150 ms on the declared reference setup with a
  300-item timeline (AVE-REQ-084).
- The baseline render worker respects a configured 6 GiB memory budget on a 4-vCPU/8-GiB reference machine,
  excluding optional LLM/VLM inference; work is streamed/chunked and concurrency bounded (AT-23).
- Rendering is not promised in real time; measured throughput is reported.
- Synchronization of qualified synthetic fixtures is accurate within one output frame (AT-04, AT-08).

## Deployment assumptions

- Local/self-hosted installation on Linux with Python, Node.js and FFmpeg (CPU reference setup); an optional
  container profile is documented. The development cloud is a build environment, never a production host.
- No GPU, provider credential, model entitlement or camera footage is assumed; each is detected or configured.
- Details and the measured development environment: [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md).

## Open product questions

- Actual camera model, color profile, clip durations and library size are unknown → baseline ASM-03, ASM-04
  (probe real files; no device assumptions) → ASM-004.
- Target deployment hardware and accelerator drivers are unknown → CPU reference, capability-tested GPU → ASM-004.
- Provider credentials, model entitlements and paid budgets are not supplied → features ship off-by-default with
  explicit configuration and budgets → ASM-004.

## Definition of product completion

The product is complete when all of the following hold; the final `milestone-review` checks them.

1. Every product milestone in [ROADMAP.md](ROADMAP.md) is `done` with a recorded review verdict of PASS.
2. Every version-one requirement (99) is `done`; none is `in-progress`, `verification` or `blocked`; the two
   deferred requirements stay `deferred`.
3. Every success signal in § Product goals holds, and every core user journey passes end to end.
4. `./scripts/verify.sh` passes locally and in CI, including its media and release tiers.
5. [TRACEABILITY.md](TRACEABILITY.md) holds a complete row for every `done` requirement, and every applicable
   acceptance criterion has current-tree evidence.
6. No `open` assumption in [ASSUMPTIONS.md](ASSUMPTIONS.md) affects a must-have feature.
7. This file, [ARCHITECTURE.md](ARCHITECTURE.md) and [PROGRESS.md](PROGRESS.md) describe the delivered product.
8. The handover follows the baseline [DELIVERY_CHECKLIST.md](../ai-video-editor-requirements/spec/DELIVERY_CHECKLIST.md):
   run/install path, walkthrough, render/test artifacts, requirement coverage, output/provider/device matrix and
   an explicit list of externally unverified integrations (credential-, model- and GPU-dependent paths), each
   with its exact prerequisite.
