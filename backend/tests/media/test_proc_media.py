"""Robustness of the FFmpeg process boundary on real child processes (ave.proc, ave.sync.audio).

A streamed tool must never stall on its own diagnostics, must report a bounded tail of them when
it fails, and the analysis extraction must keep one float32 buffer when the stream length is
unknown. The children are real FFmpeg runs on generated input; the expected values follow from the
generator's parameters.
"""

from __future__ import annotations

import time
import tracemalloc
from pathlib import Path

import numpy as np
import pytest

from ave.errors import MediaToolError
from ave.proc import media_url, run_tool, stream_tool
from ave.sync.audio import _read_float32

pytestmark = pytest.mark.media

FLOOD_SECONDS = 600
"""Generated audio whose per-frame log lines (ashowinfo) exceed the 64 KiB stderr pipe buffer
many times over."""


def _drain(pipe_args: list[str], timeout: float) -> int:
    """Runs FFmpeg through :func:`stream_tool` and returns the stdout byte count."""
    received = 0
    with stream_tool("ffmpeg", pipe_args, timeout=timeout) as pipe:
        while chunk := pipe.read(1 << 16):
            received += len(chunk)
    return received


def test_streamed_tool_never_stalls_on_a_flood_of_diagnostics() -> None:
    """AVE-REQ-086 AC-3: a child that writes megabytes of diagnostics to stderr while its stdout
    is read runs to completion well inside its timeout (stderr is drained concurrently); a full
    stderr pipe would block it until the watchdog kills it."""
    args = [
        "-hide_banner", "-nostdin", "-v", "info", "-f", "lavfi",
        "-i", f"sine=frequency=440:sample_rate=8000:duration={FLOOD_SECONDS}",
        "-af", "ashowinfo", "-f", "s16le", "-",
    ]  # fmt: skip
    started = time.monotonic()
    received = _drain(args, timeout=120)
    assert received == FLOOD_SECONDS * 8000 * 2
    assert time.monotonic() - started < 60


def test_failing_streamed_tool_reports_a_bounded_diagnostic_tail(tmp_path: Path) -> None:
    """AVE-REQ-009 AC-4, AVE-REQ-086 AC-4: decoding an MP4 whose media data is cut off at 90 %
    (with ``-xerror``, after megabytes of per-frame diagnostics) raises MediaToolError with the
    non-zero exit status and a bounded tail of the diagnostics that names the read error: the
    demuxer's "corrupt input packet" line and FFmpeg's closing "Conversion failed!" (both printed
    by FFmpeg 4.2, 6.1 and 7.0)."""
    complete = tmp_path / "complete.mp4"
    run_tool(
        "ffmpeg",
        [
            "-hide_banner", "-nostdin", "-v", "error", "-f", "lavfi",
            "-i", "sine=frequency=440:sample_rate=48000:duration=120",
            "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart", "-f", "mp4",
            media_url(complete),
        ],
        timeout=300,
    )  # fmt: skip
    data = complete.read_bytes()
    truncated = tmp_path / "truncated.mp4"
    truncated.write_bytes(data[: len(data) * 9 // 10])
    args = [
        "-hide_banner", "-nostdin", "-v", "info", "-xerror", "-i", media_url(truncated),
        "-af", "ashowinfo", "-f", "s16le", "-",
    ]  # fmt: skip
    with pytest.raises(MediaToolError) as caught:
        _drain(args, timeout=120)
    details = caught.value.details
    assert details["returncode"] != 0
    tail = details["stderr"]
    assert 0 < len(tail) <= 4000
    assert "corrupt input packet" in tail  # the failure itself, after megabytes of frame lines
    assert tail.rstrip().endswith("Conversion failed!")  # the end of the diagnostics is kept


def test_extraction_of_unknown_length_grows_one_float32_buffer() -> None:
    """AVE-REQ-024 AC-1: when the stream length is unknown the analysis reader grows a single
    float32 array in place: every delivered sample is kept exactly, and the peak memory stays
    below 5 bytes per sample plus a fixed overhead (no second full-length copy)."""
    seconds, rate = 40, 48000
    args = [
        "-hide_banner", "-nostdin", "-v", "error", "-f", "lavfi",
        "-i", f"sine=frequency=1000:sample_rate={rate}:duration={seconds}",
        "-ac", "1", "-f", "f32le", "-",
    ]  # fmt: skip
    tracemalloc.start()
    try:
        samples = _read_float32(args, None)
        _, peak = tracemalloc.get_traced_memory()
    finally:
        tracemalloc.stop()
    count = seconds * rate
    assert samples.dtype == np.float32
    assert len(samples) == count  # more than the initial buffer: it grew
    reference = _read_float32(args, count)
    assert np.array_equal(samples, reference)
    assert peak <= 5 * count + 2 * 2**20
