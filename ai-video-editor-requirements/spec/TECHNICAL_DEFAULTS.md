# Technical starting point

## Status

This is a recommended starting architecture, not a claim that one stack is universally best. Preserve an established compatible repository stack. Otherwise use these defaults, pin versions that work together, and record significant deviations as ADRs. User behavior and acceptance criteria outrank a preferred library.

Current documentation was checked on 2026-10-02. Recheck installed versions and provider policies during implementation. Source IDs refer to [SOURCES.md](SOURCES.md).

## Suggested application structure

| Responsibility | Default | Boundary |
| --- | --- | --- |
| Browser UI | React + TypeScript + Vite | Collection, timeline, preview, inspector, AI panel, jobs/exports. Vite has a React/TypeScript starting template [SRC-21]. |
| UI state | Small explicit state store; Zustand is acceptable | Selection and optimistic interaction only; authoritative edits go through the domain service. |
| Backend | Python + FastAPI + typed schemas | Project/domain commands, media requests, provider adapters, auth and resource routing. |
| Persistence | SQLite on local disk with WAL, schema migrations, short transactions | Metadata, revisions and job state. Do not put WAL databases on NAS/network filesystems; use server DB if distribution becomes necessary [SRC-23]. |
| Media storage | Managed filesystem roots and manifests | Originals immutable; separate proxies, analysis, model cache, temporary files, exports. A media NAS mount is not the database. |
| Worker | Separate durable worker process with bounded subprocess/model concurrency | Real heavy work outside request handlers; do not rely on lightweight in-process response background tasks for durable rendering [SRC-22]. |
| Probe/render | FFprobe/FFmpeg with a typed composition compiler | Multiple inputs, filters, stream mapping and output validation [SRC-12, SRC-13, SRC-14]. |
| Sync | Extracted analysis audio + NumPy/SciPy correlation and multiple anchors | Start with an interpretable signal method; SciPy supplies cross-correlation primitives, not a turnkey perfect video-sync service [SRC-19]. |
| ASR | `faster-whisper`, multilingual `small`, CPU `int8` starting profile | Explicit cached download; optional higher-quality GPU profile. Repository and model card document CPU/int8 and the converted model [SRC-15, SRC-16]. |
| Vision | Optional bounded-frame adapter; candidate `Qwen/Qwen3-VL-4B-Instruct` | Its model card documents image/video inputs. This is a candidate, not a RAM/latency guarantee; pin a tested revision, check memory, and keep it opt-in [SRC-17]. |
| Translation/planning | User-configured capable text provider | Reuse direct Anthropic/OpenAI-compatible adapters; no unapproved credentials or provider spending. |
| Agent runtimes | Optional Claude Agent SDK and Codex supported SDK/app-server adapters | Distinct from raw LLM providers. Support external MCP clients too [SRC-06, SRC-08, SRC-09]. |
| MCP | Current official SDK compatible with backend language | Shared operation schemas; local stdio and secured remote Streamable HTTP [SRC-10, SRC-11]. |
| Tests | Python unit/integration + TypeScript UI tests + browser end-to-end | Add real FFmpeg fixtures, decoded-output oracles, and separately gated live-provider/device checks. |
| Packaging | CPU-first local development plus optional container deployment | The coding cloud is a build environment, not production hosting [SRC-07]. |

Do not introduce Kubernetes, a vector database, Redis, a distributed renderer, or a large multi-service fleet before a measured requirement demands them. A job queue can begin as durable database records consumed by a separate worker with atomic claims and recovery. Avoid holding database transactions open during rendering.

## Reference renderer and browser preview

Compile the typed edit graph into bounded media operations. Share project timing, layout, crop, text, grade and subtitle semantics across all consumers. Prefer one authoritative render path for export and backend reference previews.

A responsive browser can use proxies and lightweight composition, but approximate playback must not become the specification. Verify it against backend reference frames, especially for font layout, transition boundaries, color, and subtitles. Do not promise that GPU encoding also accelerates every filter; report actual stages [SRC-14].

Avoid an unbounded single giant command/graph for a long trip. Render reusable segments where justified, with cache keys covering input revision and output parameters, then assemble without violating timing or audio boundaries. Do not use stream-copy at arbitrary cuts when correctness requires decoded re-encoding.

## Synchronization progression

1. Probe capture information and stream timestamps; propose likely pairs.
2. Extract a bounded analysis representation from both source audio tracks, including ones muted in export.
3. Use nonperiodic correlation evidence, plausible overlap bounds and ambiguity checks to estimate offset.
4. Verify additional anchors; estimate affine clock scale when justified.
5. When sound is unavailable, use reliable timestamps, explicit visual events or manual anchors.
6. Preserve uncertainty and test actual exported events. Signal-processing success on a fixture is not a guarantee for every real scene.

Maintain independent source-to-reference maps and explicit coverage/fallback policies. Do not assume coarse camera timestamps can provide frame-accurate synchronization.

## Analysis defaults

Use metadata, corrected transcripts, scene boundaries and sampled frames as the base evidence. ASR runs locally with a CPU-capable profile; large models must not load alongside a render in a small worker by accident. A vision model is an opt-in capability rather than a startup dependency.

For multilingual subtitles, keep transcription and translation separate. Apply translation through the configured provider, retain the original, and allow corrections. Export SRT/VTT sidecars per language; external platforms have their own supported-file behavior [SRC-18].

Before a Hugging Face download, display repository, task, pinned revision, license and expected resource/storage use. Do not enable arbitrary remote code by default or install unreproducible main-branch dependencies because an old model-card example does so.

## Output defaults

Default to MP4 with H.264 video and AAC audio, SDR Rec.709, square pixels, project dimensions, exact project rate, and a tested pixel format. A software CRF around 20 with a medium speed preset is an initial product choice, not an externally guaranteed optimal value. Give the user control and document encoder-specific behavior. Use 48 kHz output audio; source rates are resampled correctly.

For a 2K/60 source, support native-resolution/rate choices, but do not equate input resolution to the default 1080p delivery canvas. Preserve 60 fps where the resolved Auto choice indicates it. Do not auto-upscale merely to satisfy a misleading preset label.

Implement the required software output matrix first, then capability-probe hardware. Read back actual output properties and content. A listed encoder without a successful device encode does not establish usability.

## Rejected shortcuts

Do not put all project truth in React state, mutate the timeline directly from LLM prose, shell out with interpolated untrusted text, call a generated edit JSON a rendered video, treat a CPU mock as GPU verification, or stop after building an API without the requested manual editor.

Do not use the developer's Claude Code login as an embedded application credential. Anthropic documents restrictions on third-party use of claude.ai login/rate limits; use supported authentication [SRC-06]. Codex integration must follow current SDK/app-server documentation rather than assume legacy command availability [SRC-08].
