---
id: AVE-REQ-094
title: Capability-aware native dynamic workflows
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27]
dependencies: [AVE-REQ-093]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-094.md
---

# AVE-REQ-094 — Capability-aware native dynamic workflows

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.

Imported from the immutable baseline [AVE-REQ-094](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-094.md) (package v1.0); primary gate M0, scope v1.

## Description
Claude Code shall use task-specific native dynamic workflows where actually available, with a documented bounded fallback to subagents or sequential execution.

## Acceptance criteria
- [ ] AC-1 Probe the current environment for workflow tools, available models, subagents, worktree isolation, permissions, hooks, network, browser tools, CPU/RAM, and accelerator access.
- [ ] AC-2 When native workflows are available, compose requirement-specific investigation, implementation, testing, and independent review with structured handoffs and dependency-aware parallelism.
- [ ] AC-3 Validate native workflow syntax against the installed runtime; do not invent APIs or assume a published feature is enabled in this cloud session.
- [ ] AC-4 When unavailable, perform the same lifecycle through bounded subagent/sequential tasks; do not build a custom orchestration platform instead of the editor.

## Edge cases
- Workflow tool, subagents or worktrees unavailable → documented sequential or subagent fallback (AC-4);
  without subagents the independent review runs in a fresh session (or a context holding nothing of the
  implementation work) from the repository alone, the Status log records it as a sequential review, and the
  requirement stays `verification` until that review is recorded (AC-4).
- A capability that changes between sessions (network policy, credentials, tools) → re-probed with
  `scripts/probe-environment.sh` and recorded (AC-1).
- Workflow syntax or a feature not present in the installed runtime → never assumed (AC-3).
- Built-in FFmpeg hardware encoders without a device → reported as no accelerator (AC-1): the probe prints
  `accelerator: none (no device)` whenever no counted device node exists and `nvidia-smi` reports no GPU.
- Entries of `/dev` → an entry counts when it is a character device (directly or through a symbolic link),
  its whole name is `nvidia<N>` or `dri/renderD<N>` with at least one digit, and this user can open it for
  reading and writing (AC-1). No other entry counts: a driver control node (`nvidiactl`, `nvidia-uvm`,
  `nvidia-modeset`), a display-only node (`dri/card<N>`), a directory, a regular file, a FIFO, a dangling link,
  a name with a suffix (`nvidia0.txt`, `renderD128.bak`). The entries named `nvidia*` and the entries of `dri`
  are listed on the two device lines; no other entry of `/dev` is listed.
- A counted node that this user cannot open → `accelerator: none (no access to <node>)`; beside a node that
  opens, the verdict names the open one alone (AC-1).
- `nvidia-smi` installed without a driver or a device (a CI image, a container started without GPU access) →
  no accelerator (AC-1): its answer counts only when it exits 0 within its time limit (10 s, killed 2 s later
  when it ignores the signal) and prints on its standard output a GPU row whose memory field is a figure with
  the unit (`<name>, <n> MiB`; the name may hold a comma). A driver diagnostic, a failure, a query that hangs,
  an empty answer, a diagnostic with exit 0 or a row on the error stream leaves the verdict to the device
  nodes. Without a `timeout` command the query is left out and the line reads
  `no GPU reported (timeout unavailable)`.
- What `present` means → a GPU device node opens, or `nvidia-smi` lists a GPU: the probe opens a node and sends
  it nothing. A render node of a software or virtual DRM driver therefore reads `present`, and whether an
  encoder or a model runs on a device is measured by the requirement that uses it (AVE-REQ-076, AVE-REQ-066);
  `docs/ENVIRONMENT_CAPABILITIES.md` records this limit (AC-1).
- A probe line fixed to the value of the host that runs the suite → fails the suite (AC-1): fixture inputs that
  differ from the host (a fake `getconf` and `id`, `AVE_PROBE_PROC_DIR`, `AVE_PROBE_ROOT`) show that the CPU
  count, memory, CPU model, OS user and writability lines are computed.
- No `claude` command where the probe runs (the development container) → reported as not installed; the
  version row comes from `claude --version` on the host (AC-1).
- A deny rule of the project settings → recorded as enforced only after an attempted denied command was
  refused (AC-1).
- A media tool or toolchain absent from PATH → its line reads `not installed` (AC-1).
- The probe started outside the repository → the disk and Git lines still measure the repository (AC-1).
- A host that answers with any status, a 4xx or 5xx to the HEAD request included → `HTTP <code>`; no response
  within 10 s (refused, unresolved, TLS failure, timeout) → `unreachable`; the request is header-only, so a large
  body such as the pypi simple index never decides the verdict (AC-1). No `curl` → `curl not installed`;
  `--offline` → the probes are skipped and `curl` is never invoked (AC-1).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/tests/test-probe-environment.sh` runs `scripts/probe-environment.sh` from a directory outside the repository and compares these lines with values the suite measures itself in the same run: CPUs equal `getconf _NPROCESSORS_ONLN`; memory equals MemTotal of `/proc/meminfo` in GiB with one decimal; disk equals the Avail and Size fields of `df -h` on the repository, also through a fake `df` that answers differently for every other directory; the ffmpeg, ffprobe, python3, uv and git lines equal the first line of their own version output, read `not installed` when hidden from PATH and follow a fake placed first on PATH; `PLAYWRIGHT_BROWSERS_PATH` reads `unset`, or its directory with the directory's entries listed; a browser binary on PATH (fake `chromium`, `chromium-browser` and `google-chrome`) is reported with the first line of its `--version`; the worktree count and branch equal `git worktree list | wc -l` and `git rev-parse --abbrev-ref HEAD`, for the repository and for a fixture repository with three worktrees; the accelerator verdict, with device nodes built as symbolic links to `/dev/null` (a character device every user can open) in directories given through `AVE_PROBE_DEV_DIR`: `accelerator: none (no device)` for an empty directory, for ordinary entries (`null`, `sda`, a directory), for driver control nodes with and without a `nvidia-smi` that finds no device, for a display-only `dri/card0` with `dri/by-path`, for a device directory whose own name starts with `nvidia`, for character devices named `nvidia-readme.txt`, `nvidia0.txt`, `nvidia0-readme.txt`, `nvidia3d-vision.conf`, `nvidia`, `dri/renderD128.bak`, `dri/renderD1-notes` and `dri/renderD`, and for `nvidia0` as a directory, a regular file, a FIFO, a dangling link and a link to a directory; present naming the node for `nvidia0`, `nvidia1`, `nvidia10`, `dri/renderD128` and `dri/renderD129`, and naming GPU node and render node for both, with the display node left out; a counted node that cannot be opened (a link to `/dev/tty`, run without a controlling terminal through `setsid`) gives `accelerator: none (no access to <node>)`, and beside a node that opens the verdict names the open one; with a fake `nvidia-smi` first on PATH: none for a driver diagnostic with a failure, for `No devices were found` with exit 6, for a GPU row with a failure, for a diagnostic with exit 0, for an empty answer, for three answers with a comma and no memory figure, for `GPU 0 failed, 3 errors`, for a row on the error stream alone and for a query that hangs past its time limit; present with the first GPU row for exit 0 with rows, for a row after a line that is no row and for a GPU name that holds a comma, present with row and node when both exist, and present with the node alone when `nvidia-smi` fails beside a node; a fake `timeout` shows that the query runs as `timeout -k 2 10 nvidia-smi` with the query arguments and that `AVE_PROBE_SMI_TIMEOUT` replaces the 10, and without a `timeout` command the line reads `no GPU reported (timeout unavailable)`; the two device-list lines (`/dev/nvidia* devices`, `/dev/dri devices`) and the `nvidia-smi` line are compared in the same scenarios, and the section headings once; fixture inputs that differ from the host: a fake `getconf` answering 3 gives `cpus 3`, `AVE_PROBE_PROC_DIR` with a `meminfo` of 2883584 kB and a `cpuinfo` model name gives `memory 2.8 GiB` and that CPU model, a fake `id` gives `os user probeuser (uid 4242)`, and `AVE_PROBE_ROOT` gives `repository writable yes` for an existing directory and `no` for a missing one; the Claude Code version (reported when `claude` is on PATH, "not installed" otherwise); the OS user and repository writability; credential variables by name only (the section holds exactly the provider variables of `.env.example`, each reads `set` when it is set, and no value is printed); network: `--offline` skips the probes and never invokes `curl`, a missing `curl` reads `curl not installed`, and in two scenarios a fake `curl` with scripted answers shows that each of the seven hosts reads `HTTP <code>` for any status and `unreachable` without a response, that every request fetches no body (HEAD, a bounded range or `--max-filesize`) and carries a time limit of at most 10 s, that only the seven hosts are requested and that no credential value reaches `curl`. The probe also prints its header with the time of the run, the kernel and OS, FFmpeg's built-in hwaccels, hardware encoders, libx264/aac and filters, and the node, pnpm, docker and docker daemon lines; the suite compares none of them, and they enter `docs/ENVIRONMENT_CAPABILITIES.md` by inspection of the live run. The live run (`./scripts/dev-container.sh ./scripts/probe-environment.sh`) stays outside the suite; its results are the § Network policy rows of `docs/ENVIRONMENT_CAPABILITIES.md`. The Claude Code rows of that document are observations a shell cannot make, inspected against the session: workflow tool, subagents, worktrees, hooks, permissions (permission mode, project allow and deny rules with a denied rule checked by an attempted command, launcher-level settings, OS user and writability, sandbox and network), browser tools (the browser tools the session's tool list exposes; the probe reports only browser binaries and the Playwright directory) and models (how the session's model and the default model of subagent and workflow runs are observed, which overrides the Agent and Workflow tools accept, checked by a run).
- AC-2 — inspection — completed workflow runs with structured handbacks and dependency-aware parallelism: M0 build workflow `wf_5493b930-f7c` (two writers; integrated as `486b3a0`, `24499a6`), review workflow `wf_1a23bf0d-2a0` (three lenses, adversarial refutation; PASS), persisted briefs in `docs/briefs/`; the run `wf_d57d9cab-829` of [the probe-evidence brief](../briefs/2026-10-03-ave-req-094-probe-evidence.md) (script in `docs/workflows/`) composes the investigation (researcher, part 1) in parallel with the testing (tester, part 2), the implementation from both structured handbacks (part 3) and the independent review, with each part's handback in `docs/briefs/handbacks/`; only a run of the real runtime can show this.
- AC-3 — inspection — every workflow script used here ran on the installed runtime (run IDs above); no API outside the runtime's documented hooks. Inspection, because the workflow runtime is reachable only from a session: no repository check can execute a workflow script.
- AC-4 — inspection — CLAUDE.md § Delegation, `.claude/skills/develop/SKILL.md` § 6 step 3 and `.claude/skills/ai-video-editor-delivery/SKILL.md` describe the subagent and sequential fallback, including how independent review happens without subagents (a fresh session working from the repository alone, recorded as a sequential review; the requirement stays `verification` until it is recorded); WF-002 records a real fallback (the lead finished an interrupted task sequentially). Inspection, because the fallback is a documented procedure with recorded occurrences: the repository holds no code path a test could run.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/ENVIRONMENT_CAPABILITIES.md` — measured capabilities and limits of the environment, including the Permissions, Browser tools and Models rows, the § Network policy results of the probe's HEAD requests (2026-10-03) and the external gaps with their unblock actions (AC-1)
- `scripts/probe-environment.sh` — repeatable probe of the shell-observable environment: resources (test inputs `AVE_PROBE_PROC_DIR` and `AVE_PROBE_ROOT`), accelerator verdict from character devices whose whole name is `nvidia<N>` or `dri/renderD<N>` and that open for this user (every other entry is listed at most) and from a GPU row with a memory figure of a `nvidia-smi` that succeeds under `timeout -k 2 10` (test inputs `AVE_PROBE_DEV_DIR`, `AVE_PROBE_SMI_TIMEOUT`), media tools, toolchains, browsers, the repository's disk and Git worktrees and branch from any working directory, Claude Code version, OS user and repository writability, credential variables by name, and network reachability through one HEAD request per host with a 10 s limit (`HTTP <code>` for any status, `unreachable` without a response); never prints credential values (AC-1)
- `.claude/skills/resume-project/SKILL.md` step 6 — re-probes at every resume and updates ENVIRONMENT_CAPABILITIES.md when a value differs (AC-1)
- `docs/WORKFLOW_LOG.md` (operating baseline, WF-001–WF-004), `docs/briefs/` (including `docs/briefs/2026-10-03-ave-req-094-probe-evidence.md` and its part handbacks) — workflow composition, handoffs and measured behavior (AC-2, AC-3)
- `CLAUDE.md` § Delegation, `.claude/skills/develop/SKILL.md` § 6 step 3, `.claude/skills/ai-video-editor-delivery/SKILL.md` step 6 — bounded subagent/sequential fallback, with independent review in a fresh session recorded as sequential (AC-4)
- Tests: `scripts/tests/test-probe-environment.sh` — AVE-REQ-094 AC-1
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md), [ASM-006](../ASSUMPTIONS.md)

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
- 2026-10-02 — in-progress — verification levels recorded per criterion; AT-29/AT-30 run at the final review (lead)
- 2026-10-02 — verification — implementation evidence complete; independent verification requested (lead)
- 2026-10-02 — in-progress — verify-requirement FAIL at `4d9ef9a` (workflow `wf_b0c34bba-a20`); blocking findings and fixes in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) (lead)
- 2026-10-03 — in-progress — verify-requirement PASS at `d4d3883` (workflow `wf_ed1f5104-63a`) refuted by its skeptic: the probe suite checked only headings and a number format for most AC-1 items, the pypi probe depended on bandwidth, browser tools were unrecorded at that commit, and no completed run composed the investigation and testing stages of AC-2; repair through [the probe-evidence brief](../briefs/2026-10-03-ave-req-094-probe-evidence.md), a run that composes those stages (lead)
- 2026-10-06 — in-progress — verify-requirement PASS at `fcd97f0` (Verify stage of run `wf_d57d9cab-829`) refuted by its skeptic ([handback part 4](../briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-4.md)): the accelerator verdict took any text `nvidia-smi` printed as a GPU, exit status ignored, and the suite hid `nvidia-smi` in every scenario; four more lines could be fixed to the host's values unnoticed. Repaired by the lead on the task branch (`1d9fd0d`): `nvidia-smi` counts only with exit 0 and a GPU row, fixture inputs prove the CPU, memory, CPU model, OS user and writability lines, ten probe mutations each fail the suite (lead)
- 2026-10-06 — verification — repair in place on branch `ave-req-094-probe-evidence`, merged with the working branch; independent verification requested again (lead)
- 2026-10-06 — in-progress — verify-requirement FAIL at `eb73896` (workflow `wf_db16f332-fdf`; [handback part 5](../briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-5.md)): the accelerator verdict counted names, so a driver control node, a display-only node or any `nvidia-smi` line with one comma read as a GPU, and three mutations of the verdict survived the suite. Repaired by the lead on the task branch: only per-GPU nodes and render nodes count, a `nvidia-smi` row needs a memory figure and an answer within 10 s; the suite gained the reviewer's device fixtures and row cases, a `chromium-browser` fake and the exact list of provider variables (133 checks), and twenty-six probe mutations each fail it; the strategy lines of AC-3 and AC-4 state why inspection (lead)
- 2026-10-06 — verification — repair in place on branch `ave-req-094-probe-evidence`, merged with the working branch; independent verification requested again (lead)
- 2026-10-06 — in-progress — verify-requirement FAIL at `d4147d8` (workflow `wf_7d9d015c-906`; [handback part 6](../briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-6.md)): AC-1 — the node rule counted every entry that is no directory and whose name starts with `nvidia<digit>` or `renderD<digit>`, so `nvidia0.txt`, a FIFO or a dangling link read as a GPU, and the suite's nodes were regular files, which left eight mutants of the rule alive. Repaired by the lead on the task branch: an entry counts when it is a character device with the whole name `nvidia<N>` or `renderD<N>` that opens for this user; a node without access is reported as such; the `nvidia-smi` query always runs under `timeout -k 2`; the suite builds its nodes as links to `/dev/null` and gained the reviewer's names, kinds, numbers, access and row cases (155 checks), and 38 mutants of the probe each fail it (lead)
- 2026-10-06 — verification — fixes of the final review integrated on branch `m0-final-integration`; independent verification with a skeptic requested from [the review brief](../briefs/2026-10-06-m0-final-review-2.md) (lead)
- 2026-10-07 — in-progress — verify-requirement FAIL at `f996c17` (workflow `wf_b18a5f3e-54e`, briefed in [the review brief](../briefs/2026-10-06-m0-final-review-2b.md); [handback part 2](../briefs/handbacks/2026-10-06-m0-final-review-2b.part-2.md)): AC-1 — the node rule judges names on lines of `find` output and opens with a form that creates a missing path, so a device name that holds a line feed reads as a GPU and the probe writes a file; the network clause of § Verification strategy claims both states for each of the seven hosts while two hosts answer in both scenarios; AC-2 to AC-4 PASS. The fixes go through [the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), track C (lead)
