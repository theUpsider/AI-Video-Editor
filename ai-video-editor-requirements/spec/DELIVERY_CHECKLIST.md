# Release and handover checklist

## Scope and evidence

- Every user clause U01-U27 maps to preserved requirements and current implementation evidence.
- Every claimed complete version-one criterion has a relevant executed test or documented review method, current code/tree fingerprint, artifacts and environment.
- Future AVE-REQ-067 and AVE-REQ-101 remain deferred and are not hidden dependencies.
- No bootstrap-only check, placeholder response, mocked media pipeline or skipped external test is presented as complete feature verification.

## Real user journey

- Import a mixed library; inspect actual dimensions/rates and preserve original checksums.
- Generate a real AI draft with a configured provider; inspect assumptions/exclusions and apply a scoped revision.
- Preview and manually edit split/full/split sections with one reference audio source, correct aspect ratio and aligned perspectives.
- Exercise unequal starts/ends, silent-source/manual alignment and known drift without false confidence.
- Apply and inherit color profiles, timed titles/images and subtitle languages; export sidecars without forced burn-in.
- Generate/edit an 18-second square short and export whole, section and short outputs with consistent metadata.
- Decode outputs and check actual frame content, timing, audio, codecs, subtitles and color tags.

## Operations and security

- Fresh CPU-first setup, persistent storage, migrations, crash recovery, backup/relink and offline edit/export work.
- Jobs have cancellation, bounded concurrency, resource limits and safe cleanup.
- Malicious paths/media/text/prompt injection and wrong-scope tool access are tested.
- API keys never appear in the repository, browser, exports, AI prompts or logs.
- Downloaded models/dependencies/codecs/fonts have a documented inventory and pinned tested configuration.

## External capability report

Use an explicit matrix, not one overall green label:

| Capability | Implemented | Contract tests | Real integration test | Remaining condition |
| --- | --- | --- | --- | --- |
| Direct Anthropic provider | Record actual state | Record actual result | Credentials/model used or not run | Exact prerequisite |
| OpenAI-compatible provider | Record actual state | Record actual result | Endpoint/model used or not run | Exact prerequisite |
| Claude Agent adapter | Record actual state | Record actual result | SDK/auth/tool path used or not run | Exact prerequisite |
| Codex adapter/client | Record actual state | Record actual result | SDK/client/auth used or not run | Exact prerequisite |
| Local ASR | Record actual state | Record actual result | Model revision/device/speech fixture | Exact prerequisite |
| Optional vision | Record actual state | Record actual result | Model revision/device or not run | Exact prerequisite |
| CPU export | Record actual state | Record actual result | Actual codec/output evidence | Must be verified |
| GPU export | Record actual state | Record actual result | Actual device/encode or not run | Device/driver needed |

## Required handover artifacts

Provide setup/run commands, user guide, API/MCP/provider guide, architecture/ADRs, requirement evidence, redacted test reports, real demo media or generation instructions, actual UI screenshots/walkthrough, benchmarks, license notes, known limitations, and exact resume/unblock actions for unfinished work.

Do not claim a production service was deployed when only local/cloud development ran. Do not claim work will continue after the session has ended.
