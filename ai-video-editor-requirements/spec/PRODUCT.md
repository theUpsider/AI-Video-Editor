# Product definition

## Contents

- Vision and primary user
- End-to-end experience
- Editing behavior
- AI behavior
- Outputs and defaults
- Completion boundary

## Vision and primary user

Build an AI-assisted, non-destructive video editor for travel and conversational recordings captured by two people from different perspectives. A user imports a collection, describes the intended edit, receives an actual playable draft, and refines it through a usable timeline or additional prompts.

The defining use case alternates between synchronized left/right camera views and one full-width shot of both people. One selected source may provide all audible sound during a split-screen segment. The recordings can start or stop independently, mix aspect ratios and frame rates, span several days and cities, and use a common creative look.

This is an editing product, not a video-generation service, a command-line FFmpeg wrapper without a usable interface, or an attempt to replicate all of DaVinci Resolve.

## End-to-end experience

### 1. Create a project and import a collection

The user creates a project, selects the output ratio, and imports videos, audio, and images. The collection displays thumbnails, duration, exact dimensions/rates, camera labels, capture dates/locations where known, and analysis progress. Originals remain unchanged. Proxies support efficient preview.

### 2. Analyze and propose a first draft

The user gives an instruction such as: "Make a chronological travel video. Use left/right split-screen when we recorded together, use camera A audio, use the full-width joint shots between those segments, introduce each city briefly, keep scenic clips, and avoid accidental recordings."

The application probes metadata, proposes pairings, estimates synchronization, builds source transcripts and bounded keyframe indexes, and asks the configured AI for validated editorial decisions. It forms sections, assembles a timeline, chooses layouts and audio routing, applies a selected look, and adds timed text and requested captions. The outcome is an editable project revision and a playable preview, with uncertainty and exclusions exposed.

### 3. Review and refine

The user changes cuts, transition durations, overlays, crop, final audio, section boundaries, and color controls in a conventional timeline. They can alternatively ask "Keep this section five seconds longer," "Swap the two views here," or "Use this clip's audio only." AI changes use the same editing service and are inspectable, scoped, reversible transactions.

### 4. Add captions and publication material

The user corrects transcripts, chooses original and translated subtitle languages, optionally displays two languages, and selects whether final captions are separate, embedded where supported, or deliberately burned in. The AI suggests copyable titles, descriptions, keywords, and hashtags grounded in content.

### 5. Create shorts and deliver

The user requests 15-20-second highlights, reviews the proposed moments, selects square/portrait/landscape composition, and adjusts each derived short independently. Export the whole project, a section, or selected shorts using CPU or verified available hardware acceleration. Deliver video files plus selected caption, chapter, and metadata artifacts.

## Editing behavior

The canonical timeline supports multiple simultaneous video and audio tracks, overlay tracks, source handles, linked synchronization groups, static transforms, basic transitions, and reusable profiles. The output canvas is independent of source shape. A square source is never silently stretched into a rectangular region.

Synchronization and final audio selection are separate concepts. Muted camera audio can remain useful evidence for alignment. Automatic synchronization must express confidence and refuse to invent an exact solution when the required shared evidence is absent. Manual anchors and precise nudges are mandatory.

A complete version one supports mixed-rate and variable-rate material, exact rational frame rates, unequal camera coverage, detectable clock drift, scene transitions between split and full-width, and subtitle retiming through edits and exports.

## AI behavior

Default AI authority covers ordinary reversible editing decisions, not credential acquisition, external uploads, unlimited spending, permanent media deletion, or publishing. Initial drafts may apply directly to an empty timeline; subsequent changes respect revisions, locks, and user edit scope. The user may explicitly authorize a scoped autonomous edit.

AI descriptions reference available evidence. Silence does not mean worthless footage; a place name is not inferred as certain from an uncertain caption; captions do not supply unspoken dialogue. Analysis adapters communicate capability limits rather than return synthetic success.

## Outputs and defaults

| Decision | Starting default | User control |
| --- | --- | --- |
| Deployment | Single-user local/self-hosted browser editor with media worker | Compatible alternative by ADR; remote use requires authentication |
| Main canvas | 16:9, 1920x1080, square pixels | 1:1, 9:16, exact custom dimensions |
| Frame rate | Auto from selected reference/dominant source, frozen after resolution | Exact rational override; provisional 30 fps before import |
| Split layout | Equal left/right regions, contain, explicit background | Cover/crop, divider, gap, swap, static focal position |
| Default split coverage | Common source overlap | Explicit union/fallback/gap policy |
| Split audio | One user-selected/reference source | Separate tracks and mixing |
| Creative look | Neutral unless a saved profile is selected | Project, camera, and clip overrides |
| Color output | Documented SDR Rec.709 workflow | Other paths only when implemented and validated |
| Intro/end text | About 3 seconds / 4 seconds, bounded to actual duration | Per project/section, wording, timing, or off |
| Captions | Stored independently; no forced burn-in | None, one or two preview languages; sidecars/embed/burn-in |
| Shorts | Target 18 seconds, allowed 15-20 seconds, 1:1 | Range, length, ratio, layout, language, bitrate |
| Delivery | MP4/H.264/AAC, project dimensions/rate | Supported WebM/MKV and capability-dependent alternatives |
| Compute | CPU works; acceleration auto-tested | Force CPU or select a verified device profile |
| External analysis | Off until configured and consented | Text, reduced frames, audio, or larger payload policy |

These are chosen design defaults, not assertions of universal optimality or platform mandates.

## Completion boundary

A working release requires the entire version-one requirement set and applicable acceptance evidence, not only a first milestone. It includes a usable UI, real rendered media, configured AI paths, source-based synchronization, subtitles, sections, shorts, profiles, safe integration, and recovery documentation.

Hardware- or credential-dependent paths may remain explicitly externally unverified when the development environment cannot execute them; the release report must enumerate these gaps. That is not permission to replace integrations with stubs or claim the full requested product is verified.

Exclude motion/object tracking and advanced continuous video understanding from version one. Also exclude social-platform publishing, real-time multiplayer editing, full professional color/HDR mastering, voice cloning/dubbing, and speaker-source separation unless the user later requests them. Basic audio extraction and transcription are included.
