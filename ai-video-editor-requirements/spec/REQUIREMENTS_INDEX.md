# Requirements index

101 requirements; 99 version-one commitments; 2 future exclusions; 404 acceptance criteria. Status here is the original specification status, not application delivery progress.

Read [PRODUCT.md](PRODUCT.md), [SCOPE_AND_ASSUMPTIONS.md](SCOPE_AND_ASSUMPTIONS.md), and [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) before selecting implementation tasks. Read individual requirement files only as needed.

## AVE-FEAT-001 - Projects and media collection

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-001 - Persistent projects and project settings](requirements/AVE-REQ-001.md) | v1 | M1 |
| [AVE-REQ-002 - Collection-based batch ingestion](requirements/AVE-REQ-002.md) | v1 | M1 |
| [AVE-REQ-003 - Immutable originals and stable asset identities](requirements/AVE-REQ-003.md) | v1 | M1 |
| [AVE-REQ-004 - Media probing, exact dimensions, and source timing](requirements/AVE-REQ-004.md) | v1 | M1 |
| [AVE-REQ-005 - Capture date, timezone, and location metadata](requirements/AVE-REQ-005.md) | v1 | M3 |
| [AVE-REQ-006 - Library organization and filtering](requirements/AVE-REQ-006.md) | v1 | M3 |
| [AVE-REQ-007 - Proxies, thumbnails, and waveforms](requirements/AVE-REQ-007.md) | v1 | M1 |
| [AVE-REQ-008 - Reviewable accidental-recording detection](requirements/AVE-REQ-008.md) | v1 | M4 |
| [AVE-REQ-009 - Broken media and relinking](requirements/AVE-REQ-009.md) | v1 | M1 |
| [AVE-REQ-010 - Portable project backups](requirements/AVE-REQ-010.md) | v1 | M7 |

## AVE-FEAT-002 - Manual timeline and history

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-011 - Non-destructive multitrack timeline](requirements/AVE-REQ-011.md) | v1 | M2 |
| [AVE-REQ-012 - Canonical rational timing and temporal invariants](requirements/AVE-REQ-012.md) | v1 | M1 |
| [AVE-REQ-013 - Manual editing and precision controls](requirements/AVE-REQ-013.md) | v1 | M2 |
| [AVE-REQ-014 - Basic transitions and handles](requirements/AVE-REQ-014.md) | v1 | M2 |
| [AVE-REQ-015 - Undo, redo, autosave, and revisions](requirements/AVE-REQ-015.md) | v1 | M2 |
| [AVE-REQ-016 - Concurrent user and AI edit safety](requirements/AVE-REQ-016.md) | v1 | M5 |
| [AVE-REQ-017 - Usable synchronized preview](requirements/AVE-REQ-017.md) | v1 | M2 |

## AVE-FEAT-003 - Canvas and mixed layouts

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-018 - Configurable canvas, dimensions, and output rate](requirements/AVE-REQ-018.md) | v1 | M1 |
| [AVE-REQ-019 - Aspect-preserving composition and transforms](requirements/AVE-REQ-019.md) | v1 | M2 |
| [AVE-REQ-020 - Two-perspective split-screen layout](requirements/AVE-REQ-020.md) | v1 | M1 |
| [AVE-REQ-021 - Mixed split-screen and full-width segments](requirements/AVE-REQ-021.md) | v1 | M2 |
| [AVE-REQ-022 - Preview and export composition parity](requirements/AVE-REQ-022.md) | v1 | M7 |

## AVE-FEAT-004 - Multicamera synchronization

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-023 - Synchronization candidate matching](requirements/AVE-REQ-023.md) | v1 | M2 |
| [AVE-REQ-024 - Audio-based offset estimation](requirements/AVE-REQ-024.md) | v1 | M2 |
| [AVE-REQ-025 - Silent or weak-evidence synchronization](requirements/AVE-REQ-025.md) | v1 | M2 |
| [AVE-REQ-026 - Persistent synchronization transforms](requirements/AVE-REQ-026.md) | v1 | M2 |
| [AVE-REQ-027 - Unequal coverage and missing-perspective policy](requirements/AVE-REQ-027.md) | v1 | M2 |
| [AVE-REQ-028 - Clock-drift detection and correction](requirements/AVE-REQ-028.md) | v1 | M2 |
| [AVE-REQ-029 - Linked edits preserve synchronization](requirements/AVE-REQ-029.md) | v1 | M2 |
| [AVE-REQ-030 - Manual synchronization tools](requirements/AVE-REQ-030.md) | v1 | M2 |

## AVE-FEAT-005 - Audio routing and mixing

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-031 - Explicit master audio and routing](requirements/AVE-REQ-031.md) | v1 | M1 |
| [AVE-REQ-032 - Independent audio tracks and basic mixing](requirements/AVE-REQ-032.md) | v1 | M2 |
| [AVE-REQ-033 - Rendered audiovisual synchronization verification](requirements/AVE-REQ-033.md) | v1 | M7 |

## AVE-FEAT-006 - Overlays and titles

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-034 - Timed text and image overlays](requirements/AVE-REQ-034.md) | v1 | M3 |
| [AVE-REQ-035 - Contextual opening titles and end references](requirements/AVE-REQ-035.md) | v1 | M3 |
| [AVE-REQ-036 - Readable international text and safe areas](requirements/AVE-REQ-036.md) | v1 | M3 |
| [AVE-REQ-037 - Basic overlay animation without tracking](requirements/AVE-REQ-037.md) | v1 | M3 |

## AVE-FEAT-007 - Sections and chapters

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-038 - Editable date and location sections](requirements/AVE-REQ-038.md) | v1 | M3 |
| [AVE-REQ-039 - Section and whole-project export](requirements/AVE-REQ-039.md) | v1 | M6 |

## AVE-FEAT-008 - Color and reusable looks

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-040 - Non-destructive color and tonal controls](requirements/AVE-REQ-040.md) | v1 | M3 |
| [AVE-REQ-041 - Reusable project, camera, and clip color profiles](requirements/AVE-REQ-041.md) | v1 | M3 |
| [AVE-REQ-042 - Input color interpretation and SDR normalization](requirements/AVE-REQ-042.md) | v1 | M3 |
| [AVE-REQ-043 - Color consistency across outputs](requirements/AVE-REQ-043.md) | v1 | M7 |

## AVE-FEAT-009 - AI draft and conversational editing

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-044 - Natural-language editing interface](requirements/AVE-REQ-044.md) | v1 | M5 |
| [AVE-REQ-045 - End-to-end AI first draft](requirements/AVE-REQ-045.md) | v1 | M5 |
| [AVE-REQ-046 - Reviewable and atomic AI edit proposals](requirements/AVE-REQ-046.md) | v1 | M5 |
| [AVE-REQ-047 - Grounded editorial reasoning](requirements/AVE-REQ-047.md) | v1 | M5 |

## AVE-FEAT-010 - Typed editing API and MCP

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-048 - One typed editing command service](requirements/AVE-REQ-048.md) | v1 | M1 |
| [AVE-REQ-049 - MCP editing interface and external agent clients](requirements/AVE-REQ-049.md) | v1 | M5 |

## AVE-FEAT-011 - Providers and downloadable models

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-050 - Provider-neutral language-model adapters](requirements/AVE-REQ-050.md) | v1 | M5 |
| [AVE-REQ-051 - Claude Agent runtime adapter](requirements/AVE-REQ-051.md) | v1 | M5 |
| [AVE-REQ-052 - Codex runtime adapter](requirements/AVE-REQ-052.md) | v1 | M5 |
| [AVE-REQ-053 - Hugging Face model registry and downloads](requirements/AVE-REQ-053.md) | v1 | M4 |
| [AVE-REQ-054 - AI budgets, retries, caching, and cancellation](requirements/AVE-REQ-054.md) | v1 | M5 |

## AVE-FEAT-012 - AI trust and tool authorization

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-055 - Untrusted media and prompt-injection boundary](requirements/AVE-REQ-055.md) | v1 | M5 |
| [AVE-REQ-056 - Tool authorization and credential boundaries](requirements/AVE-REQ-056.md) | v1 | M5 |

## AVE-FEAT-013 - Speech, translation, and captions

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-057 - Speech extraction and local transcription](requirements/AVE-REQ-057.md) | v1 | M4 |
| [AVE-REQ-058 - Editable searchable source transcripts](requirements/AVE-REQ-058.md) | v1 | M4 |
| [AVE-REQ-059 - Language detection and source-language control](requirements/AVE-REQ-059.md) | v1 | M4 |
| [AVE-REQ-060 - Translated subtitle language tracks](requirements/AVE-REQ-060.md) | v1 | M4 |
| [AVE-REQ-061 - Toggleable single- and dual-language captions](requirements/AVE-REQ-061.md) | v1 | M4 |
| [AVE-REQ-062 - Subtitle retiming through edits and synchronization](requirements/AVE-REQ-062.md) | v1 | M4 |
| [AVE-REQ-063 - Subtitle sidecars and supported embedded tracks](requirements/AVE-REQ-063.md) | v1 | M6 |
| [AVE-REQ-064 - Caption formatting and manual cue editor](requirements/AVE-REQ-064.md) | v1 | M4 |

## AVE-FEAT-014 - Visual indexing and understanding

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-065 - Timestamped keyframes and shot summaries](requirements/AVE-REQ-065.md) | v1 | M4 |
| [AVE-REQ-066 - Optional local or remote visual-caption adapter](requirements/AVE-REQ-066.md) | v1 | M4 |
| [AVE-REQ-067 - Advanced continuous video understanding](requirements/AVE-REQ-067.md) | future | FUTURE |

## AVE-FEAT-015 - Shorts

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-068 - Grounded short-form highlight suggestions](requirements/AVE-REQ-068.md) | v1 | M6 |
| [AVE-REQ-069 - Independent short sequences and reframing](requirements/AVE-REQ-069.md) | v1 | M6 |
| [AVE-REQ-070 - Short preview and batch delivery](requirements/AVE-REQ-070.md) | v1 | M6 |

## AVE-FEAT-016 - Publication metadata

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-071 - Copyable SEO and publication suggestions](requirements/AVE-REQ-071.md) | v1 | M6 |

## AVE-FEAT-017 - Rendering and output delivery

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-072 - Real export pipeline and default delivery profile](requirements/AVE-REQ-072.md) | v1 | M1 |
| [AVE-REQ-073 - Multiple containers and codec choices](requirements/AVE-REQ-073.md) | v1 | M6 |
| [AVE-REQ-074 - Mixed-rate input and controlled output timing](requirements/AVE-REQ-074.md) | v1 | M6 |
| [AVE-REQ-075 - CPU-only reference rendering](requirements/AVE-REQ-075.md) | v1 | M1 |
| [AVE-REQ-076 - Capability-tested hardware acceleration](requirements/AVE-REQ-076.md) | v1 | M6 |
| [AVE-REQ-077 - Durable asynchronous jobs](requirements/AVE-REQ-077.md) | v1 | M1 |
| [AVE-REQ-078 - Export preflight and decoded-output validation](requirements/AVE-REQ-078.md) | v1 | M7 |
| [AVE-REQ-079 - Editable output presets and quality guidance](requirements/AVE-REQ-079.md) | v1 | M6 |
| [AVE-REQ-080 - Storage quotas and safe derived-file cleanup](requirements/AVE-REQ-080.md) | v1 | M7 |
| [AVE-REQ-081 - Complete output delivery bundle](requirements/AVE-REQ-081.md) | v1 | M6 |

## AVE-FEAT-018 - Runtime quality and handover

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-082 - Self-hostable browser application and CPU reference setup](requirements/AVE-REQ-082.md) | v1 | M1 |
| [AVE-REQ-083 - Real-media automated verification suite](requirements/AVE-REQ-083.md) | v1 | M7 |
| [AVE-REQ-084 - Measured responsiveness and bounded memory](requirements/AVE-REQ-084.md) | v1 | M7 |
| [AVE-REQ-085 - Observable jobs and reproducible diagnostics](requirements/AVE-REQ-085.md) | v1 | M7 |
| [AVE-REQ-086 - Safe media processing boundary](requirements/AVE-REQ-086.md) | v1 | M7 |
| [AVE-REQ-087 - Private-by-default media and secrets handling](requirements/AVE-REQ-087.md) | v1 | M5 |
| [AVE-REQ-088 - Pinned dependencies and license inventory](requirements/AVE-REQ-088.md) | v1 | M7 |
| [AVE-REQ-089 - Accessible, discoverable editing interface](requirements/AVE-REQ-089.md) | v1 | M7 |
| [AVE-REQ-090 - Crash recovery and safe migrations](requirements/AVE-REQ-090.md) | v1 | M7 |
| [AVE-REQ-091 - Offline editing and graceful AI degradation](requirements/AVE-REQ-091.md) | v1 | M7 |
| [AVE-REQ-092 - User and developer handover](requirements/AVE-REQ-092.md) | v1 | M7 |

## AVE-FEAT-019 - Autonomous implementation workflow

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-093 - Adopt and preserve the supplied requirements baseline](requirements/AVE-REQ-093.md) | v1 | M0 |
| [AVE-REQ-094 - Capability-aware native dynamic workflows](requirements/AVE-REQ-094.md) | v1 | M0 |
| [AVE-REQ-095 - Evidence-driven workflow self-improvement](requirements/AVE-REQ-095.md) | v1 | M7 |
| [AVE-REQ-096 - Isolated bounded tasks and independent review](requirements/AVE-REQ-096.md) | v1 | M0 |
| [AVE-REQ-097 - Verification gates that cannot pass as placeholders](requirements/AVE-REQ-097.md) | v1 | M0 |
| [AVE-REQ-098 - Persistent progress and bounded autonomous continuation](requirements/AVE-REQ-098.md) | v1 | M0 |
| [AVE-REQ-099 - Honest completion and conditional verification](requirements/AVE-REQ-099.md) | v1 | M7 |
| [AVE-REQ-100 - Milestone-level product validation](requirements/AVE-REQ-100.md) | v1 | M7 |

## AVE-FEAT-020 - Future tracking

| Requirement | Scope | Primary gate |
| --- | --- | --- |
| [AVE-REQ-101 - Object and motion tracking](requirements/AVE-REQ-101.md) | future | FUTURE |
