# Environment capabilities

Observed in the Claude Code cloud development session on 2026-10-01 (AVE-REQ-094 AC-1). Every entry
below is a measured observation or an executed test in this container. The container is a build and
test environment; it is no production host. Re-check after a session restart: tools, network policy
and credentials can change. `./scripts/probe-environment.sh` re-measures the shell-observable part
(resources, accelerators, media tools, toolchains, browsers, credential variables by name, network);
its run on 2026-10-02 matched every observation below. The Claude Code rows are observed by the lead.

## Platform and resources

| Item | Observation | How observed |
|---|---|---|
| OS / kernel | Ubuntu 24.04.4 LTS, Linux 6.18 x86_64 | `uname -a`, `/etc/os-release` |
| CPU | 4 vCPU, Intel Xeon @ 2.80 GHz, AVX2 present | `nproc`, `/proc/cpuinfo` |
| Memory | 15 GiB, no swap | `free -h` |
| Disk | 29 GiB free on `/` | `df -h` |
| Process limits | 20 000 open files, 64 303 processes, no cgroup CPU/memory cap exposed | `ulimit -a`, `/sys/fs/cgroup` |
| GPU | None: no `/dev/nvidia*`, no `/dev/dri`, no `nvidia-smi` | device and command checks |

## Tooling

| Tool | Version | Notes |
|---|---|---|
| Python | 3.11.15 | system interpreter; `uv` 0.8.17 manages project environments |
| Node.js / npm / pnpm | 22.22.0 / 10.9.4 / 10.28.0 | yarn 1.22.22 also present |
| FFmpeg / FFprobe | 6.1.1-3ubuntu5 | GPL build; details below |
| Git | 2.43.0 | commit signing configured by the environment |
| Docker | client 29.6.2 only | no daemon socket: containers cannot run here |
| Playwright | CLI 1.56.1 with Chromium 1194 under `/opt/pw-browsers` | browser automation available headless |
| Fonts | 59 faces: DejaVu, Liberation, Free, IPAGothic (CJK), Noto Color Emoji | `fc-list` |
| SQLite | Python `sqlite3` module; no `sqlite3` CLI | |

### FFmpeg capabilities

- Software encoders: libx264, libx264rgb, libx265, libvpx (VP8), libvpx-vp9, libaom-av1, libsvtav1,
  ProRes (prores, prores_ks), AAC, libopus, libmp3lame, FLAC, PCM; subtitle encoders mov_text, srt/subrip,
  webvtt, ass.
- Hardware encoders compiled in: h264/hevc/av1 NVENC, QSV and VAAPI. They are listed only: no device
  exists, so no hardware encode can succeed here (AVE-REQ-076 hardware paths stay externally unverified).
- Filters used by the editor: scale, crop, pad, overlay, hstack, xfade, fade, fps, setpts, trim, concat,
  drawtext (FreeType, HarfBuzz, FriBiDi, Fontconfig), subtitles/ass (libass), eq, curves, colorbalance,
  colorlevels, colortemperature, vibrance, lut3d, zscale, colorspace, scdet, select, amix, atrim, aresample
  (SoXR), atempo, rubberband, volume, afade, acrossfade, loudnorm, ebur128, showwavespic.
- Sources for synthetic fixtures: testsrc2, smptebars, sine, aevalsrc, anoisesrc and `flite` speech
  synthesis (executed: a 2.6 s English utterance rendered to WAV).

## Network policy

All traffic goes through the session's egress proxy. Observed responses:

| Host | Result | Consequence |
|---|---|---|
| pypi.org, files.pythonhosted.org | reachable | Python dependencies install with `uv` |
| registry.npmjs.org | reachable | frontend dependencies install with `pnpm` |
| archive.ubuntu.com, security.ubuntu.com | reachable | apt packages installable |
| registry-1.docker.io | reachable (401 auth challenge) | irrelevant while no daemon runs |
| api.anthropic.com | reachable | no application credential exists (below) |
| huggingface.co, cdn-lfs.huggingface.co, hf-mirror.com | blocked (403 from proxy) | no Hugging Face model download here |
| api.openai.com | blocked | no live OpenAI-compatible test here |
| openaipublic.azureedge.net (Whisper weights), alphacephei.com (Vosk) | blocked | no downloadable Whisper/Vosk models |
| github.com releases | blocked (403); raw.githubusercontent.com reachable | release assets unavailable |

## Credentials

Environment variable names were listed without values. No application credential exists for the
product: no `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `HF_TOKEN` or Codex credential. The session has
its own coding-agent credentials (an `ANTHROPIC_BASE_URL` proxy, cloud and GitHub tokens); the product
never uses them (ASM-015 of the baseline: a developer subscription is no product API secret).

## Local AI capability actually available

| Capability | Status | Evidence |
|---|---|---|
| Local speech recognition | Available: the PyPI `pocketsphinx` wheel bundles a US-English acoustic model and runs offline on CPU | Executed: transcribed a `flite` utterance in 0.7 s ("hello well this is a test of this paycheck ignition system" for "hello world this is a test of the speech recognition system") |
| faster-whisper / Whisper models | Code path possible; model weights cannot be downloaded here | Hugging Face and Whisper hosts blocked |
| Multilingual ASR | Unavailable here (no non-English model reachable) | |
| Translation | Requires a configured provider; none configured | |
| Vision captioning (Qwen3-VL candidate) | Unavailable here (Hugging Face blocked, no GPU) | |
| Text-to-speech for fixtures | `flite` (English) inside FFmpeg; `espeak-ng` installable from apt (multilingual) | |

## Claude Code capabilities

| Capability | Status | Evidence |
|---|---|---|
| Claude Code version | 2.1.286 | `claude --version` |
| Native dynamic workflows (Workflow tool) | Available and exercised | Bootstrap ran five workflows (up to 69 agents); M0 runs a two-writer workflow |
| Observed workflow concurrency | 2 to 4 agents run at once on this 4-vCPU host; further agents queue | workflow transcripts |
| Subagents (Agent tool) and custom agents | Available: architect, implementer, reviewer, tester, researcher load from `.claude/agents/` | session agent list |
| Worktree isolation | Works: a smoke-test agent ran in `.claude/worktrees/agent-…` on its own branch, created from local HEAD `6160278` (confirms `worktree.baseRef: "head"`), separate git-dir | smoke test 2026-10-01 |
| Skills | Project skills load, including forked skills bound to custom agents | session skill list |
| Project hooks | SessionStart hook active: the "Project state" block was injected at every resume and compaction (ASM-001 confirmed); the Stop gate runs the fast tier only | session start output; `scripts/tests/test-stop-hook.sh` |
| Background agents | `run_in_background` agents sometimes return only on completion; start them alongside independent work ([WF-003](WORKFLOW_LOG.md)) | session observation 2026-10-02 |
| Account usage limits | A weekly account limit (HTTP 429) stopped a delegated agent on 2026-10-02; its worktree kept the partial work ([WF-002](WORKFLOW_LOG.md)) | agent error |
| Model | The session runs on the model configured for this account; the product never names coding-session models as product models | system configuration |

## Limits that shape the plan

1. CPU-only rendering and analysis: render jobs run one heavy FFmpeg job at a time (4 vCPU).
2. At most two concurrent writing agents plus one heavy media job, per the baseline workflow rule and the
   observed concurrency.
3. Account usage limits can stop agents mid-task: every delegated task has a persisted brief in
   [docs/briefs/](briefs/README.md) and runs in a worktree, so the work resumes from the repository.
4. Live provider, agent-runtime, Hugging Face, vision and GPU tests cannot run here; their adapters get
   contract tests, and the release report lists each as externally unverified with the exact prerequisite.
