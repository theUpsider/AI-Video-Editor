# Baseline capabilities checklist

Step 5 of [product-definition](SKILL.md) walks this list. It names capabilities a production-quality product commonly needs although the human left them unstated. Decide each category against the actual product.

Inclusion rule:

> «Include what is required to make the requested product coherent, reliable, usable, and production-quality. Avoid speculative features that do not support an identified user need.»

**Anti-inflation warning.** Never inflate a small product into an enterprise platform. Every included capability names the need it serves: a journey step (`UJ-NNN`), a goal (`GOAL-NNN`) or a human must-have. A capability that serves none stays out. Size each one to the product's real users, data and deployment, and choose the smallest version that meets the need.

## How to apply

1. Profile the product from PRODUCT.md § Target users, § Product boundaries and § Deployment assumptions: who uses it and how many, data sensitivity, input types and sizes, operation durations, paid external services, delivery form.
2. Decide each category: **include** (now), **defer** (a later milestone needs it; note which) or **skip**.
3. Included: write `source: derived` requirements whose Intent names the need. User-visible behavior is `functional`; quality thresholds are `non-functional` with measurable ACs.
4. Skipped where a reader would expect it: add it to PRODUCT.md § Explicit non-goals with the reason. Uncertain: record an `ASM-NNN`.
5. Stay technology-neutral: state behavior and thresholds; `technical-foundation` picks the means.

Red flags, included only with a named need: multi-tenancy, roles beyond the stated user types, admin consoles, plugin systems, real-time collaboration, offline sync, billing, analytics dashboards, localization beyond the stated audience, scaling or availability targets without a stated load.

## 1. Data and persistence

- **Include when:** users create, import or configure anything they expect to find again, or work spans sessions.
- **Usually skip when:** the product is a stateless transformation whose result the user keeps.
- **Typical requirements to consider:**
  - What is stored, who owns it, and for how long.
  - Saved work survives restart and crash; writes are atomic, so no half-saved items exist.
  - Existing data stays readable after an upgrade (migration path).
  - Export or backup when losing the data would hurt the user.
  - Defined behavior when two actors modify the same item.

## 2. Input validation and error states

- **Include when:** always; scale it to the inputs that exist (user input, files, external responses).
- **Usually skip when:** never; every trust boundary validates.
- **Typical requirements to consider:**
  - Every input validated at the boundary, with a message naming the problem and the fix.
  - An error state per journey step: what the user sees, what is preserved, how to retry.
  - A defined user-visible outcome for each external dependency failure.
  - Internal details (stack traces, identifiers) go to logs and stay out of user messages.
  - Invalid input never corrupts stored data.

## 3. Loading, progress and empty states

- **Include when:** the product has an interactive interface, or any operation takes noticeable time.
- **Usually skip when:** there is no interactive user (library, batch job); exit codes and logs cover it.
- **Typical requirements to consider:**
  - An empty state for each list or workspace that shows the next action.
  - A busy indicator above about 1 s; determinate progress (percent, step, remaining time) above about 10 s when measurable.
  - Actions disabled or idempotent while running, so double submission has no effect.
  - Confirmation for actions with no visible result.

## 4. Uploaded content and file handling

- **Include when:** users provide files or media.
- **Usually skip when:** the product accepts no user files.
- **Typical requirements to consider:**
  - Storage: where originals and derived files live, who owns them; originals are never modified in place.
  - Formats: accepted formats detected from content as well as extension; others rejected with the supported list.
  - Size limits: maximum size, duration and count, enforced before expensive work, with the limit in the message.
  - Transfer: progress, cancellation, and defined handling of interrupted uploads or imports.
  - Management: list, inspect metadata, rename and delete items; deleting an item deletes its derived files.
  - Cleanup and lifecycle: temporary and intermediate files removed after success, failure and cancellation; orphans cleaned up; a disk-space or quota check with a clear error.
  - Untrusted content: corrupt, truncated or crafted files are rejected without crashing or exhausting resources; filenames cannot escape their storage location.

## 5. Long-running and asynchronous jobs

- **Include when:** an operation can outlast an interactive wait (roughly 10 s or more): processing, rendering, analysis, bulk import, slow external services.
- **Usually skip when:** every operation completes within interactive latency.
- **Typical requirements to consider:**
  - Visible job states: queued, running with progress, succeeded, failed with reason, cancelled.
  - Cancellation that stops the work and removes partial output.
  - Retries with backoff for transient failures, a bounded attempt count, and permanent failures reported.
  - Idempotency: retries and resubmissions never duplicate results or charges.
  - Restart behavior: interrupted jobs resume, restart or fail visibly; none vanish.
  - Concurrency limits that protect CPU, memory, disk and paid quotas.
  - Completion visible to a user who navigated away.

## 6. Authentication and access control

- **Include when:** several people use the same instance, the data is sensitive, or others can reach the product over a network.
- **Usually skip when:** a single user runs it locally and the operating system or device controls access.
- **Typical requirements to consider:**
  - An established authentication mechanism suited to the audience; never custom cryptography.
  - Users see and change only their own data unless sharing is a stated need.
  - Session expiry and sign-out.
  - Authorization enforced at the trust boundary for every operation.
  - Only as many roles as the stated user types require.

## 7. Security

- **Include when:** always, scaled to exposure (local tool, private network, public service).
- **Usually skip when:** never; scale it down for local single-user tools.
- **Typical requirements to consider:**
  - Untrusted input handled safely: injection, path traversal, unsafe deserialization, resource exhaustion through large or crafted input.
  - Secrets kept out of code, logs and anything shipped to clients.
  - Dependency vulnerability scanning as a `./scripts/verify.sh` step.
  - Encrypted transport for any network traffic carrying user data.
  - Least-privilege credentials for external services.
  - The standard protections of the delivery form (for web interfaces: cross-site request forgery, cross-origin and content-security policies) and rate limits on publicly reachable endpoints.

## 8. Privacy and data retention

- **Include when:** the product handles personal data or user content, or sends either to third parties (AI services included).
- **Usually skip when:** no personal data exists and no user content leaves the device.
- **Typical requirements to consider:**
  - An inventory of personal data and where it flows, including third-party processors.
  - Disclosure to the user before content is sent to an external service.
  - A retention period per kind of data; deletion removes derived copies and caches.
  - Minimal collection; logs exclude content and personal data beyond operational needs.
  - Applicable regulations recorded as constraints. Legal requirements that are unknowable from the repository are escalated.

## 9. Reliability and recovery

- **Include when:** users invest effort in work the product holds, or the product runs unattended.
- **Usually skip when:** rerunning a stateless operation is cheap for the user.
- **Typical requirements to consider:**
  - No loss of saved work on crash, restart or failed operation; save semantics stated (explicit save or autosave).
  - Timeouts on every external call; dependency outages yield a clear error or a degraded mode, and recovery needs no manual cleanup.
  - Interrupted operations detected and recovered at startup.
  - Confirmation or undo for destructive actions.

## 10. Performance budgets

- **Include when:** users wait on a journey step, inputs can be large, or the human stated speed expectations.
- **Usually skip when:** no step is time-sensitive and inputs are small and bounded.
- **Typical requirements to consider:**
  - A measurable budget per key interaction (for example 95th-percentile latency) under stated conditions (input size, hardware class).
  - Maximum supported input sizes, with defined behavior beyond them.
  - Memory and disk bounds when processing large inputs.
  - Throughput or concurrency targets only where the usage profile requires them.
  - A repeatable measurement (benchmark or smoke test) per budget.

## 11. Accessibility

- **Include when:** the product has a human-facing interface.
- **Usually skip when:** there is no interface beyond an API or library; clear messages and documentation cover command-line tools.
- **Typical requirements to consider:**
  - A target conformance level; WCAG 2.2 AA is the common default for graphical interfaces.
  - Full keyboard operation with visible focus.
  - Text alternatives for non-text content; captions or transcripts where media is a core output.
  - Sufficient contrast, no meaning carried by color alone, respect for reduced-motion preferences.
  - Automated accessibility checks in `./scripts/verify.sh` and a manual pass over core journeys at milestone review.

## 12. Observability

- **Include when:** the product runs as a service, runs unattended, or runs long jobs whose failures need diagnosis.
- **Usually skip when:** a small local tool; clear error messages and an optional debug log suffice.
- **Typical requirements to consider:**
  - Structured logs with levels and a correlation identifier per request or job.
  - Logs free of secrets and personal content.
  - A health check for services.
  - Metrics limited to the budgets and failure modes that matter (job duration, error rate, queue length).
  - Diagnostics a user can attach to a bug report (version, log excerpt) for installed software.

## 13. Configuration and secrets

- **Include when:** behavior depends on environment-specific values or credentials (API keys, endpoints, storage locations).
- **Usually skip when:** defaults cover every environment.
- **Typical requirements to consider:**
  - Configuration with documented defaults, validated at startup with an error naming the missing or invalid value.
  - Secrets supplied only through the environment or a secret store; every variable listed by name in `.env.example`.
  - The product starts locally without paid services configured where practical: fakes, or the dependent feature disabled with a clear message.

## 14. Deployment and operability

- **Include when:** always for the build-and-run path of the product's delivery form, scoped by § Deployment assumptions.
- **Usually skip when:** release automation, staging environments and rollout strategies have no deployment target that needs them yet.
- **Typical requirements to consider:**
  - A reproducible build of the deliverable (package, installer, image, bundle).
  - One documented command to run locally; documented installation for users.
  - Versioning, with release notes for each release.
  - Upgrades preserve data and configuration.
  - Rollback or reinstall procedure for hosted services; documented resource needs (disk, memory, external tools).

## 15. Cost controls for paid external services

- **Include when:** the product calls metered services (AI models, transcoding, storage, messaging).
- **Usually skip when:** no metered dependency exists.
- **Typical requirements to consider:**
  - Hard caps on input size, request count or spend per job, user or period.
  - Cost estimate or confirmation before expensive user-triggered actions.
  - Reuse of results for identical requests where results are reusable.
  - Usage recorded per job so cost can be audited.
  - Defined behavior when a quota or budget is exhausted: a clear message and no unbounded retries.
  - Tests and `./scripts/verify.sh` use fakes behind the integration interface and never call paid services.

## 16. User documentation

- **Include when:** users install, configure or learn the product.
- **Usually skip when:** the interface explains itself to its audience; in-product hints suffice.
- **Typical requirements to consider:**
  - A README with installation, configuration and a quick start for the core journey.
  - In-product help for non-obvious steps; error messages that state the next action.
  - Documented limits (formats, sizes, quotas) matching the enforced values.
  - A changelog for released versions.
