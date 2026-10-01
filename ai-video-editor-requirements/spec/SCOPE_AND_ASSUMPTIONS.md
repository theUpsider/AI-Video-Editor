# Scope, assumptions, and resolved ambiguities

## Interpretation register

| ID | Interpretation/default | Rationale and effect |
| --- | --- | --- |
| ASM-01 | Build a local/self-hosted desktop-browser application with a backend media worker. | The user did not specify an OS or desktop packaging. This avoids requiring GPU/media processing inside a development-cloud browser. Preserve portability; change only by justified ADR. |
| ASM-02 | Begin with one owner per deployment, not enterprise multi-tenancy or live collaborative editing. | Multiple camera operators do not imply multiplayer software requirements. User/AI edits still require revision-safe coordination. |
| ASM-03 | A 2K label is not an exact dimension. | Probe actual dimensions, display orientation, and rational rate. No real demo file was provided with this request. |
| ASM-04 | DJI Go is unconfirmed device terminology. | Do not hard-code camera model, log transfer curve, GPS, timecode, sample rate, or sensor dimensions. The official DJI GO page describes an application, not proof of the user's exact camera hardware. See SRC-20. |
| ASM-05 | Preserve both square frames by default with contain/padding. | Two full square images side-by-side have ratio 2:1, not 16:9. Filling 16:9 without padding requires cropping or distortion; distortion is not the default. |
| ASM-06 | First selected/reference source drives the Auto output rate; initial canvas is 1080p 16:9. | Source resolution and delivery resolution are separate. Preserve 60 vs 60000/1001; no unannounced rate change after import. |
| ASM-07 | Final audio and synchronization evidence are separate. | Camera B may be muted in export but still provide waveform evidence. A truly silent recording may need shared visual events or manual anchors. |
| ASM-08 | Default split segments use common coverage. | Automatically retaining a missing second perspective would require an explicit fallback; unselected source intervals remain recoverable. |
| ASM-09 | Automatic sync is evidence-dependent, not a guarantee for all footage. | Without common signals or trustworthy time references, exact alignment is underdetermined. Display insufficient evidence and provide manual controls. |
| ASM-10 | "Extract voices" means extract audio for speech recognition and editable transcripts. | Voice isolation, diarization, cloning, and dubbing were not unambiguously requested. They are not prerequisites for version one. |
| ASM-11 | Basic source indexing and optional frame captioning are version-one foundations; full temporal video understanding is future. | This preserves the user's future-facing wording while making present AI cuts and highlights possible from metadata, transcripts, and bounded frames. |
| ASM-12 | Caption files, embedded streams, burned pixels, and SEO metadata are distinct products. | Platform language toggles cannot be guaranteed merely by embedding tracks in a video. Sidecar language files and explicit instructions are required. See SRC-18. |
| ASM-13 | Shorts default to 1:1 and 15-20 seconds because the user requested them. | Offer 9:16 and other shapes without overriding the requested square workflow. No claim that every platform prefers or accepts identical settings. |
| ASM-14 | Claude Code/Codex are agent runtimes or external tool clients, not model identifiers. | Support raw provider adapters, optional embedded agent SDK adapters, and external MCP clients as separate integrations. See SRC-06 through SRC-09. |
| ASM-15 | Runtime credentials are not inherited from the coding session. | The developer's subscription/login is not a product API secret. Use only documented provider authentication and explicit configuration. |
| ASM-16 | CPU-only rendering is mandatory; GPU execution is conditional on actual host capabilities. | A cloud coding session may not provide a GPU. Implement detection and CPU fallback; require real-device evidence before claiming GPU validation. |
| ASM-17 | No automatic upload/publishing to social platforms. | The user asked for compatible exports and copyable metadata, not account access or publication. |
| ASM-18 | API/model downloads and external compute have explicit consent/budgets. | Autonomous implementation does not authorize arbitrary costs or transmission of private trip media. |
| ASM-19 | Technology versions and native Claude workflow syntax are discovered in the actual environment. | Published documentation does not establish feature availability, permissions, or model entitlements in this session. |
| ASM-20 | Defaults may be changed through ADRs, but requested capabilities cannot be silently cut. | Record rationale, impacts, and equivalent test coverage. A smaller milestone is not a smaller final scope. |

## Square layout example

For a 1920x1080 output, equal halves are 960x1080. Containing a square source in each half yields a 960x960 image, at y=60. The left image begins at x=0 and the right at x=960. Covering each region instead scales to 1080x1080 and crops 120 horizontal pixels total in each region, with crop position configurable.

The same normalized-region policy applies at other resolutions. Background strips, padding, and cropping must be visible decisions in the UI and the AI proposal.

## Explicitly deferred

- **AVE-REQ-067:** richer continuous temporal video understanding, beyond bounded frame/shot/transcript indexing.
- **AVE-REQ-101:** object or motion tracking, subject-following crops, and tracked overlays.

Static crop, manual keyframes, a common flash/event for alignment, and frame extraction do not count as object tracking. Do not use the exclusion as an excuse to omit synchronization, manual composition, or grounded AI drafts.

## Not part of the requested first product

No automatic social posting, paid media library, collaboration/billing platform, generative video footage, voice cloning/dubbing, automatic speaker separation, deep face/person identification, dedicated camera-control integration, or attempt to match every professional NLE tool.

## Missing inputs that must not be invented

The actual source files, camera model, recording color profile, typical clip duration/library size, target deployment hardware, installed accelerator drivers, user model credentials, approved paid budget, and production domain are not provided. Use the declared defaults and synthetic fixtures, report exact gaps, and continue independent work without repeatedly asking ordinary implementation questions.
