# Original product brief - structured source record

This is a meaning-preserving decomposition of the user's supplied brief, not a transcript of verified hardware specifications. No demo media was attached to this requirements request.

## User requirements

### U01

Import the user's clips into a collection rather than requiring a hand-built timeline.

### U02

Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.

### U03

Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.

### U04

Both the user and AI can place images or text over the video for explicit start/end intervals.

### U05

Place contextual titles such as locations near the start and optional credits/references near the end, not continuously.

### U06

Object tracking and motion tracking are future features, explicitly excluded from the first version.

### U07

Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.

### U08

Expose editing capabilities through a standardized AI interface, preferably MCP or equivalent integration.

### U09

Extract speech and generate automatic transcript/subtitle information.

### U10

Allow selectable subtitle languages and an optional second simultaneously displayed language.

### U11

Provide separately usable caption/metadata outputs for external platforms such as YouTube, rather than forcing permanent captions into every export.

### U12

Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.

### U13

Generate copyable keywords and related SEO/publication text.

### U14

Identify accidental or content-poor recordings so they can be omitted from a draft.

### U15

Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.

### U16

Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.

### U17

Extract recording date, time, and location when available in metadata.

### U18

Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.

### U19

Mix two-perspective split-screen footage with full-width 16:9 footage of both people and then return to split-screen.

### U20

Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

### U21

Offer color grading, shadows/highlights/contrast and related controls, with reusable looks applied across a trip/project.

### U22

Support CPU-only rendering and GPU acceleration when available.

### U23

Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

### U24

End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

### U25

Ideally integrate Claude Code and Codex as selectable AI/agent backends.

### U26

Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.

### U27

Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.

## Derived implementation and safety clauses

These clauses make the requested product implementable and safe; they are not statements that the user explicitly specified these technical mechanisms.

### D01

Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

### D02

Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

### D03

Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

### D04

Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.

### D05

Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

## Terminology normalization

Interpret "Cloud Code" as **Claude Code** in this context. Treat the camera phrase "DJI Go" as unconfirmed user terminology, not proof of a camera model, log profile, GPS support, shared timecode, or synchronization capability. Read real files and identify capabilities before implementing device-specific assumptions.
