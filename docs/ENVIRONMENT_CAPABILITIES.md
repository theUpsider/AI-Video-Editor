# Environment capabilities

Observed on 2026-10-02 in the Claude Code desktop session on a Windows 11 ARM64 laptop (AVE-REQ-094 AC-1).
Verification and tests run inside the Linux development container of
[ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md) (`scripts/dev-container.sh`);
every entry below is a measured observation or an executed test on this host or in that container. The
container is a build and test environment; it is no production host. Re-check after a session restart: tools,
network policy and credentials can change. `./scripts/dev-container.sh ./scripts/probe-environment.sh`
re-measures the shell-observable part (resources, accelerators with a device verdict, media tools, toolchains,
browsers, the Claude Code version, OS user and repository writability, credential variables by name, network);
its runs on 2026-10-02 produced the container observations below. The Claude Code rows record what a session
observed (the lead's session, or a workflow agent where the row says so); the container has no `claude` command,
so the version comes from `claude --version` on the host. The work before `bd12fe8` ran in a Linux x86_64 cloud
container (4 vCPU, 15 GiB, egress proxy); Git history holds its record.

## Platform and resources

| Item | Observation | How observed |
|---|---|---|
| Host OS | Windows 11 Home 10.0.26200, ARM64; shell Git Bash (MSYS, x86_64 emulation) | `uname -a`, system information |
| Host CPU / memory / disk | Snapdragon X Plus, 8 cores; 15.6 GiB; 19 GiB free on `C:` (93 % used) | `Get-CimInstance`, `df -h` |
| Host toolchain | Git 2.55.0, uv 0.11.29, Python 3.14 only, no `python3` command, no FFmpeg; Docker Desktop with the WSL 2 backend | command checks |
| Native verification on the host | Unsupported: the fast tier failed 5 of 9 steps (no `python3`; backend unit tests reject Windows paths) | `./scripts/verify.sh` before ADR-009 |
| Container OS / kernel | Ubuntu 24.04.5 LTS, Linux 6.18 (WSL 2) aarch64 | probe |
| Container CPU / memory | 8 CPUs, 7.5 GiB plus 2 GiB swap | probe, `free -h` |
| Container limits | 1 048 576 open files; runs as root (uid 0); the checkout is a writable bind mount at `/workspace` | `ulimit -n`; probe § Claude Code and session |
| GPU | Host: integrated Qualcomm Adreno X1-45. Container: none (no `/dev/nvidia*`, no `/dev/dri`, no `nvidia-smi`; probe verdict `accelerator: none (no device)`), so no GPU path is verifiable | probe § Accelerators |
| CI | GitHub Actions `ubuntu-24.04` x86_64 runner, release tier on every push | `.github/workflows/verify.yml` |

## Tooling

Versions inside the development container (the image mirrors the CI package list).

| Tool | Version | Notes |
|---|---|---|
| Python | 3.12.3 system `python3` (tooling scripts); 3.11 managed by `uv` 0.8.17 for the backend | one backend environment per worktree on the state volume |
| Node.js / pnpm / jq | Node.js 18.19.1 and jq 1.7 from the Ubuntu archive (tooling suites); pnpm absent | Node.js 22 and pnpm join the image when the frontend milestone starts |
| FFmpeg / FFprobe | 6.1.1-3ubuntu5 (arm64) | GPL build; details below |
| Git | 2.55.0 (Git maintainers' PPA) | resolves the relative worktree links the host creates |
| Docker | Docker Desktop on the host; no client inside the container | the container is the only Linux environment here |
| Playwright | absent | added with the frontend milestone |
| Fonts | 8 faces (DejaVu) | more font packages are needed before title and caption rendering work (M3) |
| SQLite | Python `sqlite3` module (library 3.45.1); no `sqlite3` CLI | |

### FFmpeg capabilities

- Software encoders: libx264, libx264rgb, libx265, libvpx (VP8), libvpx-vp9, libaom-av1, libsvtav1,
  ProRes (prores, prores_ks), AAC, libopus, libmp3lame, FLAC, PCM; subtitle encoders mov_text, srt/subrip,
  webvtt, ass.
- Hardware encoders compiled in: h264/hevc/av1 NVENC and VAAPI. They are listed only: no device
  exists, so no hardware encode can succeed here (AVE-REQ-076 hardware paths stay externally unverified).
- Filters used by the editor: scale, crop, pad, overlay, hstack, xfade, fade, fps, setpts, trim, concat,
  drawtext (FreeType, HarfBuzz, FriBiDi, Fontconfig), subtitles/ass (libass), eq, curves, colorbalance,
  colorlevels, colortemperature, vibrance, lut3d, zscale, colorspace, scdet, select, amix, atrim, aresample
  (SoXR), atempo, rubberband, volume, afade, acrossfade, loudnorm, ebur128, showwavespic.
- Sources for synthetic fixtures: testsrc2, smptebars, sine, aevalsrc, anoisesrc and `flite` speech
  synthesis.

## Network policy

The laptop reaches the internet directly (no egress proxy). Observed from the container on 2026-10-02:

| Host | Result | Consequence |
|---|---|---|
| pypi.org, files.pythonhosted.org | reachable (`uv sync` installed the locked environment) | Python dependencies install with `uv` |
| registry.npmjs.org | reachable (HTTP 200) | frontend dependencies install with `pnpm` |
| ports.ubuntu.com, ppa.launchpadcontent.net | reachable | apt packages installable in the image |
| github.com | reachable (HTTP 200) | release assets and `gh` work |
| huggingface.co | reachable (HTTP 200, anonymous) | public model downloads are possible on this host; CI and `verify.sh` stay offline for models |
| api.anthropic.com, api.openai.com | reachable (HTTP 404 / 421 without a request) | no application credential exists (below) |

## Credentials

Environment variable names were listed without values. No application credential exists for the
product: no `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `HF_TOKEN` or Codex credential. The session has
its own coding-agent credentials (the desktop app's account and the host's GitHub login); the product
never uses them (ASM-015 of the baseline: a developer subscription is no product API secret).

## Local AI capability actually available

| Capability | Status | Evidence |
|---|---|---|
| Local speech recognition | Available: the PyPI `pocketsphinx` wheel bundles a US-English acoustic model and runs offline on CPU | Executed: transcribed a `flite` utterance in 0.7 s ("hello well this is a test of this paycheck ignition system" for "hello world this is a test of the speech recognition system") |
| faster-whisper / Whisper models | Code path possible; no model is cached; Hugging Face is reachable anonymously from this host | network probe; nothing downloaded yet |
| Multilingual ASR | Not set up: needs a downloaded multilingual model | |
| Translation | Requires a configured provider; none configured | |
| Vision captioning (Qwen3-VL candidate) | Unavailable here (no GPU device in the container) | |
| Text-to-speech for fixtures | `flite` (English) inside FFmpeg; `espeak-ng` installable from apt (multilingual) | |

## Claude Code capabilities

| Capability | Status | Evidence |
|---|---|---|
| Claude Code version | 2.1.282 (desktop app session on the host); the development container has no `claude` command | `claude --version` on the host, 2026-10-02; the probe reports it wherever `claude` is on PATH |
| Native dynamic workflows (Workflow tool) | Available; completed runs: `wf_5493b930-f7c` (2 writers; integrated as `486b3a0` and `24499a6`), `wf_1a23bf0d-2a0` (3 review lenses; PASS, 0 blocking findings), `wf_b0c34bba-a20` (5 reviewers; all five FAIL with findings) | [docs/workflows/](workflows/README.md) |
| Observed workflow concurrency | 2 to 4 agents ran at once on the earlier 4-vCPU host; this host has 8 cores | workflow transcripts |
| Subagents (Agent tool) and custom agents | Available: architect, implementer, reviewer, tester, researcher load from `.claude/agents/` | session agent list |
| Worktree isolation | Works: a smoke-test agent ran in `.claude/worktrees/agent-…` on its own branch, created from local HEAD `6160278` (confirms `worktree.baseRef: "head"`), separate git-dir | smoke test 2026-10-01 |
| Skills | Project skills load, including forked skills bound to custom agents | session skill list |
| Project hooks | SessionStart hook active: the "Project state" block was injected at every resume and compaction (ASM-001 confirmed); the Stop gate runs the fast tier only; `scripts/check-project-control.sh` check 12 keeps the SessionStart hook on startup, resume and compact | session start output; `scripts/tests/test-stop-hook.sh`, `scripts/tests/test-checker.sh` |
| Permissions | Mode: an automatic mode in which a classifier reviews tool calls; a classifier refusal states its reason and the session continues. Project rules: the allow and deny lists of `.claude/settings.json`; the deny rule `Bash(git push --force *)` is enforced: `git push --force --dry-run origin HEAD:refs/heads/permission-probe` was refused before it ran. Launcher-level settings: none visible to the session beyond `.claude/settings.json`; the gitignored `.claude/settings.local.json` is absent. No bypass: check 12 of `scripts/check-project-control.sh` fails on a `bypassPermissions` or `dontAsk` default mode, a skipped permission prompt, and a hook command with a loop, sleep, background job or bypass flag. OS user and writability: the host session runs as the desktop user without elevation (`id -G` holds no Administrators group); the container runs as root with the checkout writable. Sandbox and network: `.claude/settings.json` configures no sandbox; network reach as in § Network policy | Lead session (mode, one classifier refusal); workflow agent of the M0 process fixes, 2026-10-02 (the attempted denied command, a classifier refusal of a later call, `id -G` on the host); probe § Claude Code and session in the container |
| Models | The session's model is named only in the session's system context; repository files never name one. Subagents and workflow agents inherit the session's model by default. The Agent tool accepts a `model` override from a fixed list of tier aliases; the Workflow tool's `agent()` call accepts `opts.model`. Checked by a run on 2026-10-02: in the workflow run of the M0 process fixes ([execution brief](briefs/2026-10-02-m0-process-fixes-execution.md)), an agent launched with an explicit override from the tier-alias list completed and returned its structured result. The product never uses coding-session models as product models | Session system context; Agent and Workflow tool definitions; workflow run of 2026-10-02 |
| Background agents | `run_in_background` agents sometimes return only on completion; start them alongside independent work ([WF-003](WORKFLOW_LOG.md)) | session observation 2026-10-02 |
| Account usage limits | A weekly account limit (HTTP 429) stopped a delegated agent on 2026-10-02; its worktree kept the partial work ([WF-002](WORKFLOW_LOG.md)) | agent error |

## Limits that shape the plan

1. CPU-only rendering and analysis: render jobs run one heavy FFmpeg job at a time (8 cores, 7.5 GiB in the
   container).
2. At most two concurrent writing agents plus one heavy media job, per the baseline workflow rule and the
   observed concurrency.
3. Account usage limits can stop agents mid-task: every delegated task has a persisted brief in
   [docs/briefs/](briefs/README.md) and runs in a worktree, so the work resumes from the repository.
4. Live provider, agent-runtime, vision and GPU tests cannot run here (no credentials, no GPU device); their
   adapters get contract tests, and the release report lists each as externally unverified with the exact
   prerequisite (§ External gaps).
5. Disk: 19 GiB free on the host; the development image takes 1.3 GiB, and render outputs stay in gitignored
   or container-local paths.

## External gaps

Each gap with the one action that unblocks it. Variable names and purposes: [.env.example](../.env.example);
`.env` is gitignored and Claude Code is denied reading it.

| Gap | Blocks | Unblock action |
|---|---|---|
| No Anthropic API key | Live tests of the Anthropic Messages adapter (AVE-REQ-050) and the Claude Agent runtime adapter (AVE-REQ-051), M5 | The human sets `ANTHROPIC_API_KEY=<key>` in `.env` at the repository root |
| No OpenAI-compatible endpoint | Live tests of the OpenAI-compatible adapter (AVE-REQ-050), M5; translation through the text provider (AVE-REQ-060), M4 | The human sets `OPENAI_API_KEY=<key>` in `.env`, plus `OPENAI_BASE_URL=<url>` for an endpoint other than the OpenAI API |
| No Codex credential | Live tests of the Codex runtime adapter (AVE-REQ-052), M5 | The human signs the test machine in with the authentication the Codex SDK documents; the adapter's brief (M5) names the exact command |
| No GPU device in the container | Hardware encode paths (AVE-REQ-076), M6; local vision captioning (AVE-REQ-066), M4 | Run those tests on an x86_64 Linux host with an NVIDIA GPU, its driver and the NVIDIA Container Toolkit, where `./scripts/probe-environment.sh` prints `accelerator: present (…)` |
| No cached faster-whisper or multilingual speech model | faster-whisper transcription (AVE-REQ-057) and language detection (AVE-REQ-059), M4; the multilingual criteria of AT-13 | The human approves the download of the pinned model through the model registry (AVE-REQ-053, M4); huggingface.co is reachable from this host |
| No vision captioning model | Local visual captions (AVE-REQ-066), M4 | A GPU host (row above) plus the approved download of the pinned vision model, or a configured remote provider (first two rows) |
