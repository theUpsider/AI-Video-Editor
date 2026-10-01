"""Immutable media asset descriptions used by the composition and the renderer.

An asset couples a stable ID, the file location, the SHA-256 checksum of the original bytes and the
probe result. Import, content-addressed storage and persistence are built on top of this (later
requirements); the renderer only needs this read-only description.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

from pydantic import BaseModel, ConfigDict, field_validator

from ave.media.probe import AudioStreamInfo, ProbeInfo, VideoStreamInfo, probe

__all__ = ["MediaAsset", "describe_asset", "sha256_file"]

_CHUNK = 1 << 20


def sha256_file(path: Path | str) -> str:
    """Hex SHA-256 of a file's bytes, read in 1 MiB chunks."""
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        while chunk := handle.read(_CHUNK):
            digest.update(chunk)
    return digest.hexdigest()


class MediaAsset(BaseModel):
    """A read-only original media file with its checksum and probed streams."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    id: str
    path: str
    """Absolute path of the original (never modified by the editor)."""
    sha256: str
    probe: ProbeInfo

    @field_validator("path")
    @classmethod
    def _absolute(cls, value: str) -> str:
        if not Path(value).is_absolute():
            raise ValueError("asset path must be absolute")
        return value

    @property
    def file(self) -> Path:
        """The original file location."""
        return Path(self.path)

    def video_stream(self, index: int | None = None) -> VideoStreamInfo | None:
        """The video stream with container index ``index``, or the first one when ``None``."""
        streams = self.probe.video_streams
        if index is None:
            return streams[0] if streams else None
        return next((s for s in streams if s.index == index), None)

    def audio_stream(self, index: int | None = None) -> AudioStreamInfo | None:
        """The audio stream with container index ``index``, or the first one when ``None``."""
        streams = self.probe.audio_streams
        if index is None:
            return streams[0] if streams else None
        return next((s for s in streams if s.index == index), None)


def describe_asset(path: Path | str, asset_id: str | None = None) -> MediaAsset:
    """Probes and checksums ``path``; the default ID derives from the checksum."""
    file_path = Path(path).resolve()
    checksum = sha256_file(file_path)
    return MediaAsset(
        id=asset_id or f"asset_{checksum[:16]}",
        path=str(file_path),
        sha256=checksum,
        probe=probe(file_path),
    )
