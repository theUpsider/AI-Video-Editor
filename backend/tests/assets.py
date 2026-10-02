"""Synthetic :class:`MediaAsset` descriptions for planning tests (no media files needed)."""

from __future__ import annotations

from fractions import Fraction
from typing import Any

from ave.media.asset import MediaAsset
from ave.media.probe import parse_probe_json


def fake_asset(
    asset_id: str,
    *,
    width: int = 1080,
    height: int = 1080,
    fps: Fraction = Fraction(60),
    duration: Fraction = Fraction(30),
    time_base: Fraction = Fraction(1, 15360),
    audio: tuple[int, int] | None = (48000, 1),
    start_time: str = "0.000000",
    video_start_pts: int = 0,
    rotation: int | None = None,
) -> MediaAsset:
    """An asset whose probe data looks like an FFmpeg-written MP4.

    ``start_time`` is the format start time as FFprobe prints it; ``video_start_pts`` is the video
    stream's first timestamp in ``time_base`` ticks. Keep them consistent the way FFmpeg does: the
    printed value is the earliest stream start rounded to microseconds.
    """
    streams: list[dict[str, Any]] = [
        {
            "index": 0,
            "codec_type": "video",
            "codec_name": "h264",
            "width": width,
            "height": height,
            "sample_aspect_ratio": "1:1",
            "r_frame_rate": f"{fps.numerator}/{fps.denominator}",
            "avg_frame_rate": f"{fps.numerator}/{fps.denominator}",
            "time_base": f"{time_base.numerator}/{time_base.denominator}",
            "start_pts": video_start_pts,
            "duration_ts": int(duration / time_base),
            "pix_fmt": "yuv420p",
            "color_space": "bt709",
            "side_data_list": [{"rotation": rotation}] if rotation is not None else [],
        }
    ]
    if audio is not None:
        rate, channels = audio
        streams.append(
            {
                "index": 1,
                "codec_type": "audio",
                "codec_name": "aac",
                "sample_rate": str(rate),
                "channels": channels,
                "time_base": f"1/{rate}",
                "start_pts": 0,
                "duration_ts": int(duration * rate),
            }
        )
    probe = parse_probe_json(
        {
            "format": {
                "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
                "duration": str(float(duration)),
                "start_time": start_time,
            },
            "streams": streams,
        }
    )
    return MediaAsset(id=asset_id, path=f"/media/{asset_id}.mp4", sha256="0" * 64, probe=probe)
