"""Output (delivery) profiles for the CPU reference renderer (AVE-REQ-072).

The default profile is MP4 with H.264 (libx264, CRF 20, preset ``medium``, 4:2:0, SDR Rec.709 TV
range) and 48 kHz stereo AAC at 192 kbit/s. CRF 20 / ``medium`` is a documented software starting
point, not a claim of universal optimality. Canvas size and frame rate always come from the
sequence; the profile controls encoding only. Quality-based (``crf``) and target-bitrate
(``bitrate``) rate control are both available.
"""

from __future__ import annotations

from fractions import Fraction
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from ave.domain.model import Canvas
from ave.errors import RenderPlanningError
from ave.timebase import PositiveRational

__all__ = ["DEFAULT_PROFILE", "OutputProfile", "X264Preset"]

X264Preset = Literal[
    "ultrafast",
    "superfast",
    "veryfast",
    "faster",
    "fast",
    "medium",
    "slow",
    "slower",
    "veryslow",
]


class OutputProfile(BaseModel):
    """Encoder settings applied identically to every segment of one export."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    name: str = "mp4-h264-aac-sdr"
    container: Literal["mp4"] = "mp4"
    video_encoder: Literal["libx264"] = "libx264"
    rate_control: Literal["crf", "bitrate"] = "crf"
    crf: int = Field(default=20, ge=0, le=51)
    video_bitrate_kbps: int | None = Field(default=None, ge=100, le=400_000)
    preset: X264Preset = "medium"
    h264_profile: Literal["high"] = "high"
    pix_fmt: Literal["yuv420p"] = "yuv420p"
    gop_seconds: PositiveRational = Fraction(2)
    """Maximum keyframe interval; every segment additionally starts with a keyframe."""
    audio_encoder: Literal["aac"] = "aac"
    audio_bitrate_kbps: int = Field(default=192, ge=32, le=512)
    sample_rate: Literal[48000] = 48000
    channels: Literal[2] = 2
    color: Literal["bt709-tv"] = "bt709-tv"

    @model_validator(mode="after")
    def _bitrate_needs_target(self) -> OutputProfile:
        if self.rate_control == "bitrate" and self.video_bitrate_kbps is None:
            raise ValueError("bitrate rate control requires video_bitrate_kbps")
        return self

    def check_canvas(self, canvas: Canvas) -> None:
        """Rejects canvas sizes the encoder cannot represent, explaining the nearest valid sizes.

        4:2:0 chroma subsampling needs even dimensions. The editor never stretches media to fix an
        invalid canvas silently (AVE-REQ-018 AC-4).
        """
        problems = []
        for label, value in (("width", canvas.width), ("height", canvas.height)):
            if value % 2:
                problems.append(f"{label} {value} is odd (use {value - 1} or {value + 1})")
        if problems:
            raise RenderPlanningError(
                f"{self.pix_fmt} H.264 output requires even canvas dimensions: "
                + "; ".join(problems)
                + ". Change the canvas explicitly; media is never stretched to fit.",
                code="UNSUPPORTED_CAPABILITY",
                canvas=f"{canvas.width}x{canvas.height}",
            )

    def describe(self) -> dict[str, object]:
        """Human-readable summary of the encoder settings (for render reports)."""
        video = (
            f"{self.video_encoder} crf={self.crf}"
            if self.rate_control == "crf"
            else f"{self.video_encoder} {self.video_bitrate_kbps} kbit/s"
        )
        return {
            "video": f"{video} preset={self.preset} {self.h264_profile} {self.pix_fmt}",
            "audio": f"{self.audio_encoder} {self.audio_bitrate_kbps} kbit/s "
            f"{self.sample_rate} Hz {self.channels} ch",
            "container": self.container,
            "color": self.color,
            "gop_seconds": str(self.gop_seconds),
        }


DEFAULT_PROFILE = OutputProfile()
"""MP4 / H.264 CRF 20 medium / AAC 192k 48 kHz stereo / SDR Rec.709."""
