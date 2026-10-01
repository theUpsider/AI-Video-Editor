# ave — AI Video Editor backend

Python package for the AI Video Editor backend: exact rational timing (`ave.timebase`), media probing
(`ave.media`), the typed composition model and layout geometry (`ave.domain`), audio-based synchronization
(`ave.sync`), the segmented CPU reference renderer with decoded-output validation (`ave.render`) and
deterministic synthetic test fixtures (`ave.fixtures`).

```sh
uv sync                      # install the locked environment
uv run pytest                # all tests, including real-FFmpeg media tests (marker `media`)
uv run pytest -m "not media" # fast unit tests only
uv run ruff check && uv run ruff format --check && uv run mypy src
```

Runtime files (generated fixtures, render work directories, test artifacts) live under the repository's
gitignored `var/` directory, or under `$AVE_VAR_DIR` when set. FFmpeg/FFprobe are resolved from `PATH`
or from `$AVE_FFMPEG` / `$AVE_FFPROBE`.
