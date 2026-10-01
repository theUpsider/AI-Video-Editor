# ADR-008 — Pluggable local ASR: faster-whisper when cached, bundled PocketSphinx as the offline floor

## Status
Accepted — 2026-10-01

## Context
Speech must be transcribed by a real local model (AVE-REQ-057, AT-13); the baseline suggests `faster-whisper`
multilingual `small` on CPU int8. This environment blocks Hugging Face and Whisper weight downloads, while the
PyPI `pocketsphinx` wheel bundles a US-English model that transcribed synthetic speech offline in measurement
([ENVIRONMENT_CAPABILITIES.md](../ENVIRONMENT_CAPABILITIES.md)).

## Decision
1. An `AsrEngine` adapter interface returns source-time words/cues with confidence, language, engine name and
   model revision.
2. `faster-whisper` is the preferred engine when its pinned model is present in the model cache (downloaded
   through the model registry with consent, or installed offline).
3. `pocketsphinx` (pinned wheel, bundled en-US model) is the always-available offline engine; it reports English
   only and lower accuracy honestly in capabilities.
4. Engines never invent text for silence; language support is reported per engine.

## Alternatives considered
- Whisper via `openai-whisper` — same download restriction and a heavier PyTorch dependency.
- Vosk — models need a separate download (blocked here).
- Cloud ASR only — violates local-first privacy and offline operation.

## Consequences
- AT-13's multilingual live criteria remain externally unverified until a multilingual model is installed.
- The model registry (AVE-REQ-053) manages faster-whisper and vision models; PocketSphinx needs no download.

## Related requirements
- [AVE-REQ-053 — Hugging Face model registry and downloads](../requirements/AVE-REQ-053-hugging-face-model-registry-and-downloads.md)
- [AVE-REQ-057 — Speech extraction and local transcription](../requirements/AVE-REQ-057-speech-extraction-and-local-transcription.md)
