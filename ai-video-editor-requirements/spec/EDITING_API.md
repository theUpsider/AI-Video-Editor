# Shared editing API and MCP contract

## Purpose

UI, internal planning models, embedded agent runtimes, and external MCP clients all operate on the same domain command service. Avoid separate AI-only editing logic or direct mutation of database rows by a language model.

The names below define semantic capabilities, not a mandatory HTTP routing style. The implementer must publish and test actual versioned schemas. JSON examples are normative examples of intended behavior, not a complete generated API schema.

## Reads and analysis

| Operation | Essential inputs | Essential result |
| --- | --- | --- |
| `capabilities.get` | Optional project ID | API version, operations, codecs, actual device checks, providers/models, limits. |
| `projects.get` | Project ID, optional revision | Immutable project summary and revision. |
| `assets.search` | Project ID, filters, cursor, limit | Paginated IDs, metadata, uncertainty and analysis status. |
| `assets.inspect` | Asset ID | Streams, capture metadata/provenance, proxy/transcript references. |
| `analysis.request` | Asset IDs, tasks, allowed provider/data policy | Job ID and planned budget. |
| `analysis.get` | Asset IDs, bounded source intervals, desired fields | Relevant transcript, keyframes, shot summaries, confidence and provenance. |
| `timeline.get` | Project/sequence/revision, optional time/track range | Typed timeline subset. |
| `sync.propose` | Candidate assets, evidence policy | Mappings, coverage, anchors, confidence or insufficient-evidence result. |
| `preview.frame` | Project revision, output time, bounded resolution | Reference frame artifact/job reference. |
| `jobs.get` | Job ID | State, stage, progress, errors and output references. |

## Editing operations

Use validated batched transactions for:

- Creating/updating output profiles and sequences.
- Inserting, moving, trimming, splitting, replacing, linking/unlinking, and removing clip instances.
- Setting layout regions, source fit/crop, track order/visibility/locks, and transitions.
- Applying or manually adjusting synchronization transforms and selecting reference audio.
- Setting audio gain/fades/routing and adding independent audio clips.
- Adding/updating/removing timed text, images, or manual overlay keyframes.
- Applying named color profiles and per-camera/clip overrides.
- Creating/updating sections, transcript corrections, subtitle tracks, and translations.
- Creating a derived short sequence without modifying its parent.

No raw arbitrary code, shell string, unrestricted filesystem path, or unvalidated renderer filtergraph belongs in this interface. The AI can select constrained operations and parameters, not invent privileged tools.

## Transaction lifecycle

```text
inspect revision
 -> propose operations
 -> validate/dry-run
 -> inspect diff and warnings
 -> apply with expected revision and idempotency key
 -> retrieve resulting revision
 -> preview/reference render
 -> optional undo
```

For an initial empty timeline, application policy may allow an automatically accepted safe draft. Subsequent replacements, cross-scope changes, protected objects, external uploads, and irreversible actions need the configured explicit authority. A normal user edit can be committed directly but still uses shared validation and history.

### Example: atomic request

```json
{
  "api_version": "1",
  "project_id": "project-trip",
  "sequence_id": "sequence-main",
  "expected_revision": 12,
  "idempotency_key": "user-request-018",
  "scope": {"section_ids": ["section-city-02"]},
  "operations": [
    {
      "op": "clip.trim",
      "clip_id": "clip-a-12",
      "source_in": {"num": 5, "den": 1},
      "source_out": {"num": 22, "den": 1},
      "linked_policy": "preserve_sync"
    },
    {
      "op": "overlay.update",
      "overlay_id": "title-city-02",
      "start": {"num": 30, "den": 1},
      "end": {"num": 33, "den": 1},
      "time_domain": "project"
    }
  ]
}
```

The validator must reject this request if the selected objects are outside `section-city-02`, source handles are invalid, linked members are locked, or revision 12 is stale. The example is not authorization to assume its referenced objects exist.

### Structured errors

At minimum distinguish `REVISION_CONFLICT`, `LOCKED_OBJECT`, `INVALID_TIME_RANGE`, `MISSING_ASSET`, `SOURCE_OUT_OF_BOUNDS`, `UNSUPPORTED_CAPABILITY`, `INSUFFICIENT_SYNC_EVIDENCE`, `PROVIDER_UNAVAILABLE`, `BUDGET_EXCEEDED`, `UNAUTHORIZED`, `CANCELLED`, and `RENDER_VALIDATION_FAILED`.

An error includes operation index, affected object IDs, safe diagnostic text, retryability, and any required corrective action. Never silently coerce a wrong asset ID into the first available asset.

## Export and asynchronous work

`exports.plan` validates a selected revision/range/profile and returns warnings and estimates. `exports.start` returns a durable job ID; `jobs.get` and `jobs.cancel` control its lifecycle. Exports are idempotent and tied to immutable inputs. Similar semantics apply to model downloads, transcription, visual analysis, and AI drafts.

Do not assume clients support an optional MCP long-running-task extension. Job IDs plus bounded polling are the compatibility baseline; add negotiated extensions only when actually supported.

## MCP transport and resources

Use a current official SDK and negotiate supported protocol capabilities. Provide local stdio for a user-controlled desktop/local agent. For remote use, provide authenticated Streamable HTTP with scope enforcement and deployment guidance. Do not expose an unauthenticated public mutation endpoint.

Offer bounded resources for project summaries, requirement-like editing constraints, selected transcript spans, and keyframe artifacts. Tools return structured results and concise summaries rather than entire media payloads or thousands of timeline objects by default. Connect both externally configured Claude Code and Codex clients to the editor's MCP server; do not confuse that server with a coding agent's own removed or unsupported server mode.

## AI provider separation

1. **Direct LLM adapter:** messages, capabilities, structured planning/tool calls, usage and streaming. Anthropic and OpenAI-compatible implementations.
2. **Agent runtime adapter:** supported Claude Agent SDK or Codex SDK/app-server, isolated from unrelated files and constrained to editor operations.
3. **Analysis adapter:** ASR, optional translation, bounded vision, and HF model management. A speech model is not an editing planner.
4. **External MCP client:** the user's agent connects to an already-running editor; the editor does not acquire that client's credentials.

Probe and document actual availability. Contract mocks test failure handling and schemas; credentialed/device-backed tests establish live interoperability. No adapter may return placeholder success when its dependency is absent.
