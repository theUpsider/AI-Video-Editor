"""Structured errors shared by the backend modules.

Every error carries a stable machine-readable ``code`` from the editing API vocabulary
(see docs/ARCHITECTURE.md, Error handling), a human-readable message and optional details that
never contain secrets or raw media content.
"""

from __future__ import annotations

from typing import Any

__all__ = [
    "AveError",
    "MediaToolError",
    "ProbeError",
    "RenderPlanningError",
    "RenderValidationError",
    "SourceBoundsError",
]


class AveError(Exception):
    """Base class for structured backend errors."""

    code: str = "INTERNAL_ERROR"

    def __init__(self, message: str, *, code: str | None = None, **details: Any) -> None:
        super().__init__(message)
        if code is not None:
            self.code = code
        self.message = message
        self.details: dict[str, Any] = details

    def to_dict(self) -> dict[str, Any]:
        """JSON-friendly representation for reports and API responses."""
        return {"code": self.code, "message": self.message, "details": self.details}


class MediaToolError(AveError):
    """An FFmpeg/FFprobe invocation failed, timed out or could not be started."""

    code = "MEDIA_TOOL_FAILED"


class ProbeError(AveError):
    """A media file could not be probed or holds no usable stream."""

    code = "PROBE_FAILED"


class RenderPlanningError(AveError):
    """A sequence cannot be compiled into a render plan (missing asset, stream, bounds...)."""

    code = "RENDER_PLANNING_FAILED"


class RenderValidationError(AveError):
    """A rendered output failed decoded-output validation and was not published."""

    code = "RENDER_VALIDATION_FAILED"


class SourceBoundsError(AveError):
    """A clip references source time outside the available media."""

    code = "SOURCE_OUT_OF_BOUNDS"
