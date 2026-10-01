# Primary sources and research notes

**Checked:** 2026-10-02. These sources support implementation choices and capability boundaries. The user brief, not a vendor tutorial, defines the requested product. Verify installed versions and current provider policies during implementation. Do not copy stale examples or assume a documented feature is enabled in the current cloud account.

Numeric UI/resource defaults, layout geometry, the task roadmap, requirement decomposition, and test fixtures are design choices or derived calculations, not vendor benchmark claims. No model quality ranking, universal sync guarantee, or production certification is asserted.

## Sources

<a id="src-01"></a>

### SRC-01 - Anthropic - Claude Code best practices

Source: [Anthropic - Claude Code best practices](https://code.claude.com/docs/en/best-practices)

Verification, context management, targeted delegation, and effective repository instructions. Recommendations in this package adapt these principles to media editing; they are not performance guarantees.

<a id="src-02"></a>

### SRC-02 - Anthropic - A harness for every task: dynamic workflows in Claude Code

Source: [Anthropic - A harness for every task: dynamic workflows in Claude Code](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)

Official explanation of task-specific native workflows and agent coordination. Publication: 2026-06-02. Check installed availability before use; avoid unnecessary orchestration overhead.

<a id="src-03"></a>

### SRC-03 - Anthropic - Custom subagents

Source: [Anthropic - Custom subagents](https://code.claude.com/docs/en/sub-agents)

Subagent context, configuration and worktree isolation. Explicitly verify the intended base revision and installed-version behavior.

<a id="src-04"></a>

### SRC-04 - Anthropic - Extend Claude with skills

Source: [Anthropic - Extend Claude with skills](https://code.claude.com/docs/en/skills)

Repository-local skill conventions and progressive procedure loading.

<a id="src-05"></a>

### SRC-05 - Anthropic - Hooks reference

Source: [Anthropic - Hooks reference](https://code.claude.com/docs/en/hooks)

Lifecycle events, blocking feedback, stop-hook reentry and supported configuration. A hook is not an unlimited autonomous-session guarantee.

<a id="src-06"></a>

### SRC-06 - Anthropic - Agent SDK overview

Source: [Anthropic - Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)

Agent runtime versus direct client SDK; supported integrations, authentication and branding guidance. The documentation restricts unapproved third-party use of claude.ai login/rate limits.

<a id="src-07"></a>

### SRC-07 - Anthropic - Claude Code cloud

Source: [Anthropic - Claude Code cloud](https://code.claude.com/docs/en/claude-code-on-the-web)

Cloud environments, isolation, network and session limitations. Published capability does not establish access in a specific session.

<a id="src-08"></a>

### SRC-08 - OpenAI - Codex SDK

Source: [OpenAI - Codex SDK](https://developers.openai.com/codex/sdk/)

Programmatic Codex integrations and current SDK/app-server guidance. At review the page states that legacy codex mcp-server commands have been removed; recheck before implementation.

<a id="src-09"></a>

### SRC-09 - OpenAI - Codex MCP

Source: [OpenAI - Codex MCP](https://developers.openai.com/codex/mcp/)

Connecting Codex clients to external stdio or Streamable HTTP MCP servers and authentication/configuration distinctions.

<a id="src-10"></a>

### SRC-10 - Model Context Protocol - Tools

Source: [Model Context Protocol - Tools](https://modelcontextprotocol.io/specification/latest/server/tools)

Tool discovery, schemas, structured output and error semantics. Negotiate actual supported versions and capabilities.

<a id="src-11"></a>

### SRC-11 - Model Context Protocol - Authorization

Source: [Model Context Protocol - Authorization](https://modelcontextprotocol.io/specification/latest/basic/authorization)

Authorization requirements for supported network transports and client/server boundaries; local stdio has a different trust setup.

<a id="src-12"></a>

### SRC-12 - FFmpeg - Filters documentation

Source: [FFmpeg - Filters documentation](https://ffmpeg.org/ffmpeg-filters.html)

Building blocks for scaling/cropping/composition, overlays, timed filters, transitions, audio processing and subtitles. Availability depends on the actual build.

<a id="src-13"></a>

### SRC-13 - FFmpeg - ffprobe documentation

Source: [FFmpeg - ffprobe documentation](https://ffmpeg.org/ffprobe.html)

Machine-readable stream/container probing, metadata and timecode inspection.

<a id="src-14"></a>

### SRC-14 - FFmpeg - Command-line documentation

Source: [FFmpeg - Command-line documentation](https://ffmpeg.org/ffmpeg.html)

Input/output streams, mapping, transcoding, timing and hardware-related options. Probe actual host support rather than infer it from an option name.

<a id="src-15"></a>

### SRC-15 - SYSTRAN - faster-whisper repository

Source: [SYSTRAN - faster-whisper repository](https://github.com/SYSTRAN/faster-whisper)

Primary project documentation for Whisper inference with CTranslate2, CPU/GPU profiles, int8 execution and timestamps. This package does not adopt repository benchmark claims as guaranteed performance.

<a id="src-16"></a>

### SRC-16 - SYSTRAN - faster-whisper-small model card

Source: [SYSTRAN - faster-whisper-small model card](https://huggingface.co/Systran/faster-whisper-small)

Multilingual converted small-model candidate and its license/configuration. Pin a tested revision and check real language/accuracy behavior.

<a id="src-17"></a>

### SRC-17 - Qwen - Qwen3-VL-4B-Instruct model card

Source: [Qwen - Qwen3-VL-4B-Instruct model card](https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct)

Primary candidate model card documenting image/video input support and license. No claim that it is the latest, universally best, or feasible on every CPU/GPU.

<a id="src-18"></a>

### SRC-18 - YouTube Help - Supported subtitle and closed-caption files

Source: [YouTube Help - Supported subtitle and closed-caption files](https://support.google.com/youtube/answer/2734698?hl=en)

Supported caption-file types and limitations. Separate sidecar captions from burned text and container streams; verify current upload behavior when documenting platform instructions.

<a id="src-19"></a>

### SRC-19 - SciPy - scipy.signal.correlate

Source: [SciPy - scipy.signal.correlate](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.correlate.html)

Cross-correlation and lag estimation primitives. Camera sync accuracy still requires evidence, ambiguity handling and real output tests.

<a id="src-20"></a>

### SRC-20 - DJI - DJI GO

Source: [DJI - DJI GO](https://www.dji.com/jp/goapp)

Official DJI GO application description; does not identify the user's camera or prove its recording metadata/features.

<a id="src-21"></a>

### SRC-21 - Vite - Getting started

Source: [Vite - Getting started](https://vite.dev/guide/)

Current frontend starter/build documentation, including React/TypeScript templates. Pin compatible versions after environment inspection.

<a id="src-22"></a>

### SRC-22 - FastAPI - Background tasks

Source: [FastAPI - Background tasks](https://fastapi.tiangolo.com/tutorial/background-tasks/)

Distinction between lightweight response-associated work and heavier processing. A separate durable worker is this package's chosen architecture.

<a id="src-23"></a>

### SRC-23 - SQLite - Write-ahead logging

Source: [SQLite - Write-ahead logging](https://sqlite.org/wal.html)

WAL concurrency/operational behavior and local-host/network-filesystem constraints relevant to the default persistence choice.

## Citation usage

Other package documents use these stable SRC IDs. Research references should not be treated as permission to fetch arbitrary user media, install unreviewed code, or reveal secrets. When implementation changes a cited technical assumption, add a dated ADR and updated source reference while preserving the original input baseline.
