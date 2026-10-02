# Brief — Execute the media-core follow-ups and fix the background color matrix

## Requirements
AVE-REQ-012 AC-4, AVE-REQ-024 AC-3: items 1–12 of
[the follow-up brief](2026-10-02-m0-media-core-round-3-follow-ups.md), unchanged. One more finding, measured by
the lead on 2026-10-02 while moving to an arm64 host:

13. AVE-REQ-020 AC-3 (background), AVE-REQ-019 AC-1 — `backend/src/ave/render/ffmpeg.py:177`
    (`build_segment_command`): the background `color=c=…,format=yuv420p` source stores BT.601 values while the
    output is tagged BT.709. Probe: `#204060` (32, 64, 96) is stored as Y 66, U 147, V 112, which is its BT.601
    encoding; decoded with the tagged BT.709 matrix by the exact scaler path and by `zscale` it reads
    (30, 63, 98), and decoded as BT.601 it reads (33, 64, 97). `test_gaps_and_bars_show_the_configured_background`
    tolerates 4 levels, so the 2-level error passes. Required: the renderer converts the background color with
    the BT.709 limited-range matrix it tags (an explicit conversion in the filter graph, or Y, U and V computed
    in Python and passed to the source); a media test that renders a pure-background segment and contain bars
    for at least three colors, computes the expected BT.709 limited-range round trip by spec math in the test,
    and asserts every decoded channel mean within 1 level; mutation: restoring the old source fails it. Check
    whether the fixture generator (`backend/src/ave/fixtures/generate.py`, `color=…,format=rgb24`) encodes its
    fixtures with the matrix their streams declare, and report the finding (no change required there).

The frame oracle (`backend/src/ave/render/validate.py`, `_scale_filter`) now decodes with
`accurate_rnd+full_chroma_int+bitexact`, so its values agree on arm64 and x86_64; keep it.

## Input revision
`ccr-af7078da-q8r8mf` at the commit that adds this brief
(`git log -1 --format=%h -- docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md`); isolated worktree
`.claude/worktrees/m0-media-follow-ups` on branch `m0-media-follow-ups`, created by the lead from that commit.
Add commits; never amend.

## Allowed paths
The allowed paths of the follow-up brief, plus `docs/briefs/handbacks/**` (new, the handback file only).

## Forbidden paths
The forbidden paths of the follow-up brief (with the handback file as the single exception under `docs/`), and
every file outside the worktree.

## Dependencies and constraints
- ADR-004, ADR-005, ASM-007, ASM-008; independent oracles; no loosened tolerance or skipped test.
- [ADR-009](../decisions/ADR-009-linux-development-container-for-other-hosts.md): the host is Windows; edit
  files with the file tools, and run every check through the development container. `./scripts/verify.sh`
  enters it by itself; other commands take the prefix `./scripts/dev-container.sh`, for example
  `./scripts/dev-container.sh uv run --frozen --directory backend pytest -q tests/unit/test_compiler.py`.
- One heavy media job at a time across every agent: a media-tier run is
  `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media`, and a targeted
  media test run is `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock uv run --frozen --directory backend pytest …`.
  The lock waits while another agent renders; run long commands in the background.
- Each change gets a test confirmed to fail without it (mutation; delete `__pycache__` first, WF-004). Revert a
  mutation with the inverse edit or `git checkout -- <file>` inside the worktree.
- Files keep LF line endings. Commit message: `AVE-REQ-012, AVE-REQ-024: <imperative summary>` (item 13 in its
  own commit `AVE-REQ-019, AVE-REQ-020: …`) with the session trailers the launch prompt names. Never push,
  merge or switch branches; never run `git worktree prune`.

## Test commands
`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media` must pass.

## Handback schema
Per item 1–13: change (file), test, mutation result; commands with results; the commit hashes; proposed
requirement text for item 11; the fixture-matrix finding of item 13. Written to
`docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md` and returned as the final report.
