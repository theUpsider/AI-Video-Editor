"""The fast tier's media tools refuse to run: AVE-REQ-097 AC-3.

scripts/verify.d/20-backend.sh points AVE_FFMPEG and AVE_FFPROBE at scripts/lib/media-tier-only.sh
for the fast pytest step, so a test that renders without the ``media`` marker fails there and the
Stop gate, which runs the fast tier at every stop, never triggers a render.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from ave import proc
from ave.errors import MediaToolError
from ave.proc import ToolName, run_tool, tool_path

pytestmark = pytest.mark.req("AVE-REQ-097 AC-3")

STUB = Path(__file__).resolve().parents[3] / "scripts" / "lib" / "media-tier-only.sh"


@pytest.mark.parametrize("tool", ["ffmpeg", "ffprobe"])
def test_a_media_tool_call_fails_under_the_fast_tier_stub(
    tool: ToolName, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv(f"AVE_{tool.upper()}", str(STUB))
    proc.tool_path.cache_clear()
    try:
        assert tool_path(tool) == str(STUB)
        with pytest.raises(MediaToolError) as caught:
            run_tool(tool, ["-version"], timeout=10.0)
        assert caught.value.details["returncode"] == 1
        assert "media tier only" in caught.value.details["stderr"]
    finally:
        proc.tool_path.cache_clear()
