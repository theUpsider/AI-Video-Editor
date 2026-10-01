# Security and trust boundaries

This is a minimum threat model for implementation and testing, not a legal/security certification.

| Boundary | Risk | Required control/evidence |
| --- | --- | --- |
| Browser import -> storage | Traversal, unsafe names, oversized uploads, duplicate data | Generated storage IDs, allowlisted roots, streaming limits, hash/provenance, independent batch failures. |
| Storage -> media parser | Malformed/hostile media, unsafe protocols, resource exhaustion | Constrained workers, safe argv, patched tools, protocol restrictions, time/memory/disk limits. |
| Text/images -> filter construction | Shell/filter expression injection | Typed operations, validated values, safe text-file/escaping strategy, hostile Unicode/punctuation tests. |
| Metadata/transcripts/keyframes -> AI | Prompt injection, invented facts, excess private data | Treat retrieved media content as data; scoped capabilities, grounding/provenance, reduced payloads and explicit external-analysis policy. |
| AI -> project mutation | Destructive or stale edits, out-of-scope changes | Schema validation, expected revision, locks, atomic transactions, idempotency, inspectable diff and undo. |
| MCP/API -> service | Unauthorized edits or cross-project access | Authenticated remote transport, project/operation scopes, structured errors and audit log. |
| Service -> configured provider | Credential leaks, SSRF, spending, hidden video upload | Server-side secrets, explicit endpoint allowlists including intentionally configured local endpoints, consent/budgets, redacted logs. |
| HF repository -> runtime | Arbitrary executable code or oversized models | Pin revisions, review license, controlled download/cache, no remote code by default, resource checks before loading. |
| Jobs -> output publication | Partial/broken files mistaken for success | Temporary outputs, atomic publish, decoded-output validation, revision-pinned manifests. |
| Cleanup -> filesystem | Original or unrelated file deletion | Strict derived-file registry, application-owned roots, references/retention checks, negative deletion tests. |
| Project bundle -> import | Zip traversal, unknown schemas, secret exfiltration | Path/schema/hash validation, no credentials in bundles, restore into a safe staging area. |
| Agent runtime -> host | General coding tools escape editor scope | Separate constrained runtime/working directory; editor operations only where possible, no blanket shell privileges or secret inheritance. |
| Self-improving workflow -> quality gates | Reward hacking, weakening tests to pass | Immutable baseline/oracles, reviewed changes, held-out scenarios, recorded metrics and rollback. |

## Privacy defaults

Local import/edit/export does not send originals to a provider. Explicitly configured external analysis explains whether it sends transcripts, audio, reduced frames, location tags or original recordings. GPS can remain private even when video is exported. Log identities as opaque IDs where practical and redact secrets and sensitive absolute paths.

## Deployment boundary

A local service binds locally by default. Remote access is not considered safe merely because it runs in a container. Require a documented auth/TLS/reverse-proxy profile, request limits, scoped storage, backup strategy and least-privilege worker permissions. Do not deploy publicly, purchase services or publish media without authorization.

## Residual risks to disclose

Automatic sync/ASR/vision can be wrong; codecs/models have platform-specific resource and licensing constraints; timezones/GPS may be absent or inaccurate; subtitles and social metadata still need user review. The UI should make these uncertainties actionable rather than hide them behind a generic AI confidence score.
