"""Safe execution of external media tools.

Rules enforced here (THREAT_MODEL, docs/ARCHITECTURE.md Security):

* commands are argv lists, never shell strings (``shell=False``);
* the executable is resolved to an absolute path once (``$AVE_FFMPEG`` / ``$AVE_FFPROBE`` or
  ``PATH``);
* every run has a timeout and the child is killed when it expires;
* file arguments are passed through :func:`media_url`, which forces FFmpeg's ``file:`` protocol so
  a crafted name can neither select another protocol nor be read as an option.
"""

from __future__ import annotations

import functools
import os
import shutil
import subprocess
import threading
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from pathlib import Path
from typing import IO, Literal

from ave.errors import MediaToolError

__all__ = ["ToolName", "ffmpeg_version", "media_url", "run_tool", "stream_tool", "tool_path"]

ToolName = Literal["ffmpeg", "ffprobe"]

_STDERR_TAIL = 4000


@functools.cache
def tool_path(name: ToolName) -> str:
    """Absolute path of ``ffmpeg`` or ``ffprobe``; raises ``MediaToolError`` when unavailable."""
    override = os.environ.get(f"AVE_{name.upper()}")
    candidate = override or shutil.which(name)
    if not candidate:
        raise MediaToolError(f"{name} is not installed or not on PATH", tool=name)
    resolved = Path(candidate).resolve()
    if not resolved.is_file() or not os.access(resolved, os.X_OK):
        raise MediaToolError(f"{name} at {resolved} is not an executable file", tool=name)
    return str(resolved)


def media_url(path: Path | str) -> str:
    """FFmpeg input/output argument for a local file: ``file:`` plus the absolute path."""
    return "file:" + str(Path(path).resolve())


def _check_argv(argv: Sequence[str]) -> list[str]:
    items = list(argv)
    if not items or not all(isinstance(item, str) for item in items):
        raise MediaToolError("tool arguments must be a non-empty list of strings")
    if any("\x00" in item for item in items):
        raise MediaToolError("tool arguments must not contain NUL characters")
    return items


def _tail(data: bytes | None) -> str:
    if not data:
        return ""
    return data[-_STDERR_TAIL:].decode("utf-8", errors="replace")


def run_tool(
    tool: ToolName,
    args: Sequence[str],
    *,
    timeout: float,
    stdin_data: bytes | None = None,
) -> subprocess.CompletedProcess[bytes]:
    """Runs ``tool`` with ``args`` and returns the completed process (stdout/stderr as bytes).

    Raises :class:`MediaToolError` on a non-zero exit status or when ``timeout`` seconds elapse.
    """
    argv = [tool_path(tool), *_check_argv(args)]
    try:
        completed = subprocess.run(
            argv,
            input=stdin_data,
            stdin=None if stdin_data is not None else subprocess.DEVNULL,
            capture_output=True,
            timeout=timeout,
            check=False,
            shell=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise MediaToolError(
            f"{tool} timed out after {timeout:.0f} s",
            tool=tool,
            timeout_s=timeout,
            stderr=_tail(exc.stderr),
        ) from exc
    except OSError as exc:
        raise MediaToolError(f"{tool} could not be started: {exc}", tool=tool) from exc
    if completed.returncode != 0:
        raise MediaToolError(
            f"{tool} exited with status {completed.returncode}",
            tool=tool,
            returncode=completed.returncode,
            stderr=_tail(completed.stderr),
        )
    return completed


@contextmanager
def stream_tool(tool: ToolName, args: Sequence[str], *, timeout: float) -> Iterator[IO[bytes]]:
    """Runs ``tool`` and yields its stdout pipe for incremental reading.

    A watchdog kills the process after ``timeout`` seconds. When the ``with`` body raises, the
    process is killed and the exception propagates; otherwise the process is awaited and a non-zero
    exit status (or a watchdog kill) raises :class:`MediaToolError`.
    """
    argv = [tool_path(tool), *_check_argv(args)]
    process = subprocess.Popen(
        argv,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False,
    )
    timed_out = threading.Event()

    def _expire() -> None:
        timed_out.set()
        process.kill()

    watchdog = threading.Timer(timeout, _expire)
    watchdog.daemon = True
    watchdog.start()
    try:
        if process.stdout is None:  # pragma: no cover - guaranteed by stdout=PIPE
            raise MediaToolError(f"{tool} stdout pipe is unavailable", tool=tool)
        try:
            yield process.stdout
        except BaseException:
            process.kill()
            process.communicate()
            raise
        _, stderr = process.communicate()
    finally:
        watchdog.cancel()
    if timed_out.is_set():
        raise MediaToolError(f"{tool} timed out after {timeout:.0f} s", tool=tool)
    if process.returncode != 0:
        raise MediaToolError(
            f"{tool} exited with status {process.returncode}",
            tool=tool,
            returncode=process.returncode,
            stderr=_tail(stderr),
        )


@functools.cache
def ffmpeg_version() -> str:
    """First line of ``ffmpeg -version`` (recorded in reports and fixture cache keys)."""
    completed = run_tool("ffmpeg", ["-hide_banner", "-version"], timeout=30)
    return completed.stdout.decode("utf-8", errors="replace").splitlines()[0].strip()
