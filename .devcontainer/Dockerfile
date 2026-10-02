# Development and verification container for hosts without the Linux toolchain (Windows, macOS).
# It installs what CI installs (.github/workflows/verify.yml): Ubuntu 24.04 with FFmpeg 6.1 and the
# awk implementations of the checker suite from the Ubuntu archive, uv pinned to the version in
# docs/ENVIRONMENT_CAPABILITIES.md, and Python 3.11 for the backend; jq and Node.js, which the CI
# runner image provides and the tooling suites use. Git comes from the Git maintainers' PPA:
# worktrees created on the host with relative links (worktree.useRelativePaths) need Git 2.48 or
# newer inside the container. scripts/dev-container.sh builds and runs it.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    UV_CACHE_DIR=/state/uv-cache

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        git ffmpeg mawk gawk original-awk busybox pipx python3 curl file jq nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN pipx install uv==0.8.17 \
    && uv python install 3.11 \
    && rm -rf /state \
    && git config --system --add safe.directory '*'

WORKDIR /workspace
