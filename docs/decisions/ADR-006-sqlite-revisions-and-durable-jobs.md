# ADR-006 — SQLite revisions and a durable job table consumed by a separate worker

## Status
Accepted — 2026-10-01

## Context
Projects need atomic, revision-checked, idempotent transactions (AVE-REQ-015/016), restart persistence
(AVE-REQ-001) and durable asynchronous jobs that survive crashes, support cancellation and never publish partial
output (AVE-REQ-077, AVE-REQ-090).

## Decision
1. One SQLite database (WAL, foreign keys on, `busy_timeout`) under the data root with numbered SQL migrations
   applied at startup inside a transaction, with a backup before each migration.
2. Tables for projects, revisions (immutable snapshots), transactions (idempotency key, request hash, base and
   result revision, actor, scope, operations, undone flag), assets, project-asset links, derived assets, jobs,
   analysis results, provider profiles (credential references only) and an audit log.
3. A transaction validates `expected_revision`, locks and scope, applies all operations to a copy, and inserts
   the new revision and transaction row in one SQLite transaction. An equivalent retry with the same idempotency
   key returns the original result; a different payload with the same key fails.
4. Jobs are rows with state `queued | running | succeeded | failed | cancelled`, a lease and heartbeat. The
   worker claims with one atomic `UPDATE … WHERE state='queued'`, renews the lease while running, and requeues or
   fails expired leases on start. Cancellation is a flag the worker observes; it terminates subprocesses and
   deletes temporary output. No transaction stays open during media work.

## Alternatives considered
- PostgreSQL — rejected for the single-owner local default; revisit for multi-host deployment.
- In-process FastAPI background tasks — rejected: not durable across restarts (baseline SRC-22).

## Consequences
- The database must live on local disk (no network filesystem).
- The API process and the worker process share the database; the worker never mutates revisions directly except
  through the command service.

## Related requirements
- [AVE-REQ-001 — Persistent projects and project settings](../requirements/AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-016 — Concurrent user and AI edit safety](../requirements/AVE-REQ-016-concurrent-user-and-ai-edit-safety.md)
- [AVE-REQ-077 — Durable asynchronous jobs](../requirements/AVE-REQ-077-durable-asynchronous-jobs.md)
- [AVE-REQ-090 — Crash recovery and safe migrations](../requirements/AVE-REQ-090-crash-recovery-and-safe-migrations.md)
