#!/bin/sh
# scripts/lib/media-tier-only.sh — stands in for ffmpeg and ffprobe in the fast tier's test step
# (scripts/verify.d/20-backend.sh; AVE-REQ-097 AC-3): AVE_FFMPEG and AVE_FFPROBE name this file, and
# copies of it named `ffmpeg` and `ffprobe` come first on PATH. The fast tier runs at every stop and
# renders nothing: a test that calls a media tool carries the `media` marker and runs in the media
# tier.
echo "media tools run in the media tier only: mark the test with @pytest.mark.media (AVE-REQ-097 AC-3)" >&2
exit 1
