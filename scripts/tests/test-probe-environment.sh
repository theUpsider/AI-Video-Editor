#!/usr/bin/env bash
# scripts/tests/test-probe-environment.sh — tests of scripts/probe-environment.sh. Every AC-1 line is
# compared with a value this suite measures itself in the same run: CPUs, memory (MemTotal of
# /proc/meminfo in GiB) and disk (`df -h .`); the accelerator verdict from device nodes alone; the
# ffmpeg, ffprobe, python3, uv and git versions (`not installed` when hidden from PATH, a fake's
# version when a fake comes first); Playwright's browser directory and the browser binaries; the
# Git worktree count and branch (of the repository and of a fixture repository with three
# worktrees); the Claude Code version, OS user and repository writability; credential variables by
# name only; and the Network section, driven by a fake curl that answers from a script, records
# every request and flags a request that downloads a body without a bound. Device nodes come from
# a temp directory (AVE_PROBE_DEV_DIR) and every other external command is hidden or faked through
# PATH, so the results hold on any host and no host is contacted. Exit 0 when every check passes.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$W/../.." && pwd)"
PROBE="$W/../probe-environment.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/probe-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
has() { printf '%s\n' "$OUT" | grep -Eq -- "$1"; }
# line <label> <value> — one report line laid out as the probe prints it (`%-28s %s`).
line() { printf '%-28s %s' "$1" "$2"; }
# has_line <label> <value> — $OUT holds exactly that line.
has_line() { printf '%s\n' "$OUT" | grep -qxF -- "$(line "$1" "$2")"; }
# lines_of <label> — how many lines of $OUT start with the label and a space.
lines_of() { printf '%s\n' "$OUT" | awk -v p="$1 " 'index($0, p) == 1 { n++ } END { print n + 0 }'; }
# pw_entries — the entries of the `playwright browsers` lines of $OUT, sorted, space-separated.
pw_entries() {
  printf '%s\n' "$OUT" | awk 'index($0, "playwright browsers ") == 1 { sub(/^playwright browsers +/, ""); print }' |
    tr -s ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' '
}

# path_without <command>... — prints PATH with the named commands hidden: a directory that holds
# one of them is replaced by a fresh mirror of its other entries.
path_without() {
  local dir cmd hide mirror out=""
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    hide=0
    for cmd in "$@"; do [ -e "$dir/$cmd" ] && hide=1; done
    if [ "$hide" -eq 1 ]; then
      mirror="$(mktemp -d "$T/path-mirror.XXXXXX")" || return 1
      ln -s "$dir"/* "$mirror/" 2>/dev/null
      for cmd in "$@"; do rm -f "${mirror:?}/${cmd:?}"; done
      dir="$mirror"
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}
# first_line <path> <command>... — the first output line of the command found through <path>, or
# "not installed" when <path> holds no such command.
first_line() {
  local p="$1"; shift
  (PATH="$p"; if command -v "$1" >/dev/null 2>&1; then "$@" 2>/dev/null | head -n 1; else printf 'not installed'; fi)
}
# second_line <path> <command>... — the second output line of the command found through <path>.
second_line() { local p="$1"; shift; (PATH="$p"; "$@" 2>/dev/null | sed -n 2p); }
# no_line <text> — $OUT holds no line equal to <text> (always true for an empty text).
no_line() { [ -z "$1" ] || ! printf '%s\n' "$OUT" | grep -qxF -- "$1"; }
# disk_free — "<Avail> free of <Size>" from the second line of `df -h .`, read by this suite.
disk_free() { df -h . 2>/dev/null | { read -r _ && read -r _ size _ avail _ && printf '%s free of %s' "$avail" "$size"; }; }

# make_fake_curl <dir> <script line>... — writes <dir>/bin/curl, a fake curl that answers each URL
# from the script lines ("<URL without scheme> <HTTP code> [<body bytes>]" or "<URL without scheme>
# fail:<curl exit code>"), records every invocation in <dir>/calls (raw arguments, then one CALL line
# per URL with the request form and time limit) and, in <dir>/violations, every request that would
# download a body without a bound (a GET without -I/--head, a bounded -r/--range or --max-filesize).
make_fake_curl() {
  local dir="$1"; shift
  mkdir -p "$dir/bin" || return 1
  : > "$dir/calls"; : > "$dir/violations"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; fi > "$dir/script"
  { printf '#!/usr/bin/env bash\nNET=%q\n' "$dir"; cat <<'FAKE'
# Fake curl of scripts/tests/test-probe-environment.sh. Emulates -I/--head, -r/--range,
# --max-filesize (exit 63 before a larger body, the response code known), -f/--fail (exit 22 on a
# code >= 400), -i, -o, -D and -w (%{http_code}, %{response_code}, %{exitcode}, %{url_effective});
# a scripted failure exits with its code and writes http_code 000, as curl does.
set -u
ALL=("$@")
{ printf 'ARGS'; printf ' %q' "$@"; printf '\n'; } >> "$NET/calls"
head=0 fail=0 include=0 range="" maxfs="" maxtime="" out="" wout="" dump="" method=""
urls=()
while [ "$#" -gt 0 ]; do
  arg="$1"; shift
  case "$arg" in
    --head) head=1 ;;
    --fail | --fail-with-body) fail=1 ;;
    --include) include=1 ;;
    --range) range="${1-}"; shift ;;
    --max-filesize) maxfs="${1-}"; shift ;;
    --max-time) maxtime="${1-}"; shift ;;
    --output) out="${1-}"; shift ;;
    --write-out) wout="${1-}"; shift ;;
    --dump-header) dump="${1-}"; shift ;;
    --request) method="${1-}"; shift ;;
    --url) urls+=("${1-}"); shift ;;
    --connect-timeout | --header | --user-agent | --user | --referer | --retry | --retry-delay) shift ;;
    --retry-max-time | --proxy | --noproxy | --resolve | --connect-to | --cacert | --capath) shift ;;
    --interface | --max-redirs | --limit-rate | --speed-limit | --speed-time | --proto) shift ;;
    --proto-redir | --oauth2-bearer | --data | --data-raw | --data-binary | --data-urlencode) shift ;;
    --form | --cookie | --cookie-jar | --config | --stderr | --trace | --trace-ascii) shift ;;
    --keepalive-time | --expect100-timeout | --output-dir) shift ;;
    --*) ;;
    -?*)
      opts="${arg#-}"
      while [ -n "$opts" ]; do
        c="${opts:0:1}"; opts="${opts:1}"
        case "$c" in
          [owmrXDHAeuxdFTKCEbcUYyztQ])
            if [ -n "$opts" ]; then val="$opts"; opts=""; else val="${1-}"; shift; fi
            case "$c" in
              o) out="$val" ;; w) wout="$val" ;; m) maxtime="$val" ;; r) range="$val" ;;
              X) method="$val" ;; D) dump="$val" ;;
            esac ;;
          I) head=1 ;;
          f) fail=1 ;;
          i) include=1 ;;
        esac
      done ;;
    *) urls+=("$arg") ;;
  esac
done
bounded_range() {
  local part
  [ -n "$1" ] || return 1
  local IFS=,
  for part in $1; do [[ "$part" =~ ^[0-9]*-[0-9]+$ ]] || return 1; done
}
to_bytes() {
  local n="${1%[kKmMgG]}"
  [[ "$n" =~ ^[0-9]+$ ]] || { echo 0; return; }
  case "$1" in
    *[kK]) echo $((n * 1024)) ;; *[mM]) echo $((n * 1048576)) ;; *[gG]) echo $((n * 1073741824)) ;;
    *) echo "$n" ;;
  esac
}
emit() {
  case "$1" in
    "" | -) printf '%s' "$2" ;;
    /dev/null) ;;
    *) printf '%s' "$2" > "$1" ;;
  esac
}
render() {
  local w="$wout" p
  p='%{http_code}'; w="${w//"$p"/$1}"
  p='%{response_code}'; w="${w//"$p"/$1}"
  p='%{exitcode}'; w="${w//"$p"/$2}"
  p='%{url_effective}'; w="${w//"$p"/$3}"
  printf '%b' "$w"
}
# -X HEAD sends HEAD but leaves curl waiting for a body: only -I/--head is header-only.
form=unbounded
if [ "$head" = 1 ]; then form=head
elif bounded_range "$range"; then form=range
elif [ -n "$maxfs" ]; then form=max-filesize
fi
[ "${#urls[@]}" -gt 0 ] || { printf 'curl: no URL specified\n' >&2; exit 2; }
rc=0
for url in "${urls[@]}"; do
  key="${url#http://}"; key="${key#https://}"
  printf 'CALL url=%s form=%s maxtime=%s method=%s\n' "$key" "$form" "${maxtime:-none}" "${method:-default}" >> "$NET/calls"
  if [ "$form" = unbounded ]; then
    { printf 'VIOLATION %s: the request downloads the body without a bound:' "$key"; printf ' %q' "${ALL[@]}"; printf '\n'; } >> "$NET/violations"
  fi
  rec="$(awk -v k="$key" '$1 == k { print $2, ($3 == "" ? 512 : $3); exit }' "$NET/script")"
  code=000 err=0 size=512
  if [ -z "$rec" ]; then
    printf 'UNEXPECTED %s\n' "$key" >> "$NET/calls"; err=6
  else
    result="${rec%% *}"; size="${rec#* }"
    case "$result" in fail:*) err="${result#fail:}" ;; *) code="$result" ;; esac
  fi
  if [ "$err" = 0 ] && [ "$head" = 0 ] && [ -n "$maxfs" ] && [ "$size" -gt "$(to_bytes "$maxfs")" ]; then
    err=63
  elif [ "$err" = 0 ] && [ "$fail" = 1 ] && [ "$code" -ge 400 ]; then
    err=22
  fi
  if [ "$err" = 0 ]; then
    printf -v headers 'HTTP/2 %s \r\ncontent-length: %s\r\n\r\n' "$code" "$size"
    body="fake body of $key"
    [ "$head" = 1 ] && body=""
    [ "$head" = 0 ] && [ "$form" = range ] && body="f"
    [ -n "$dump" ] && emit "$dump" "$headers"
    if [ "$head" = 1 ] || [ "$include" = 1 ]; then emit "$out" "$headers$body"; else emit "$out" "$body"; fi
  else
    case "$err" in
      22) printf 'curl: (22) The requested URL returned error: %s\n' "$code" >&2 ;;
      63) printf 'curl: (63) Exceeded the maximum allowed file size (%s) with %s bytes\n' "$maxfs" "$size" >&2 ;;
      *) code=000; printf 'curl: (%s) no response from %s (fake)\n' "$err" "$url" >&2 ;;
    esac
  fi
  [ -n "$wout" ] && render "$code" "$err" "$url"
  [ "$err" = 0 ] || rc="$err"
done
exit "$rc"
FAKE
  } > "$dir/bin/curl"
  chmod +x "$dir/bin/curl"
}
# time_limits_ok <calls file> — every request carries -m/--max-time with 0 < seconds <= 10.
time_limits_ok() {
  awk '/^CALL / { n++; t = ""
         for (i = 2; i <= NF; i++) if (index($i, "maxtime=") == 1) t = substr($i, 9)
         if (t !~ /^[0-9]+([.][0-9]+)?$/ || t + 0 <= 0 || t + 0 > 10) bad++ }
       END { exit !(n > 0 && bad == 0) }' "$1"
}

# Every probe run starts in the repository: `df -h .` and the Git lines then measure the repository
# whichever directory the probe resolves them in.
cd "$REPO" || exit 2
unset PLAYWRIGHT_BROWSERS_PATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
BARE_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome)"
mkdir -p "$T/dev-none" "$T/dev-gpu" "$T/bin"
: > "$T/dev-gpu/nvidia0"
printf '#!/bin/sh\nprintf "9.9.9 (Claude Code)\\n"\n' > "$T/bin/claude"; chmod +x "$T/bin/claude"

# Memory oracle: MemTotal (kB) to GiB with one decimal by integer arithmetic, half up; an exact tie
# also accepts the value below (printf rounds a tie to even).
MEM_KB="$(sed -n 's/^MemTotal:[[:space:]]*\([0-9][0-9]*\) kB$/\1/p' /proc/meminfo 2>/dev/null)"
MEM_T=$(( (${MEM_KB:-0} * 10 + 524288) / 1048576 ))
MEM_GIB="$((MEM_T / 10)).$((MEM_T % 10)) GiB"; MEM_TIE="$MEM_GIB"
if [ $(( ${MEM_KB:-0} * 10 % 1048576 )) -eq 524288 ]; then
  MEM_TIE="$(((MEM_T - 1) / 10)).$(((MEM_T - 1) % 10)) GiB"
fi

SECRET="probe-test-secret-$$-value"
# Disk space and worktrees can change while the probe runs: both are measured before and after.
DISK_BEFORE="$(disk_free)"; WT_BEFORE="$(git worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" HF_TOKEN="$SECRET" ANTHROPIC_API_KEY="" "$PROBE" --offline 2>&1)"; CODE=$?
DISK_AFTER="$(disk_free)"; WT_AFTER="$(git worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
# AVE-REQ-094 AC-1
check "offline probe exits 0" '[ "$CODE" = 0 ]'
for heading in "Platform and resources" "Accelerators" "Media tools" "Toolchains" "Browsers" "Git" \
  "Claude Code and session" "Product credential variables" "Network"; do
  check "reports section: $heading" 'printf "%s\n" "$OUT" | grep -q "^## $heading"'
done
# AVE-REQ-094 AC-1: resources equal this suite's own measurement.
check "cpus equals getconf _NPROCESSORS_ONLN ($(getconf _NPROCESSORS_ONLN))" 'has "^cpus +$(getconf _NPROCESSORS_ONLN)\$"'
check "memory equals MemTotal of /proc/meminfo in GiB ($MEM_GIB)" '[ -n "$MEM_KB" ] && { has_line memory "$MEM_GIB" || has_line memory "$MEM_TIE"; }'
check "disk equals the Avail and Size fields of df -h . ($DISK_BEFORE)" '[ -n "$DISK_BEFORE" ] && { has_line "disk (repository)" "$DISK_BEFORE" || has_line "disk (repository)" "$DISK_AFTER"; }'
# AVE-REQ-094 AC-1: media tools and toolchains equal the first line of their own version output,
# without the lines that follow it.
for SPEC in "ffmpeg -hide_banner -version" "ffprobe -hide_banner -version" "python3 --version" "uv --version" "git --version"; do
  TOOL="${SPEC%% *}"
  # shellcheck disable=SC2086
  EXPECTED="$(first_line "$BARE_PATH" $SPEC)"; NEXT="$(second_line "$BARE_PATH" $SPEC)"
  check "$TOOL equals the first line of '$SPEC' ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
# AVE-REQ-094 AC-1: browsers and Git equal this suite's own measurement.
check "PLAYWRIGHT_BROWSERS_PATH unset: reported as unset" 'has_line PLAYWRIGHT_BROWSERS_PATH unset'
check "worktrees equals git worktree list | wc -l ($WT_BEFORE)" 'has_line worktrees "$WT_BEFORE" || has_line worktrees "$WT_AFTER"'
check "branch equals git rev-parse --abbrev-ref HEAD ($BRANCH)" 'has_line branch "$BRANCH"'
# AVE-REQ-094 AC-1: no device and no nvidia-smi means no accelerator, whatever FFmpeg lists.
check "no device, no nvidia-smi: nvidia-smi not installed" 'has "^nvidia-smi +not installed$"'
check "no device, no nvidia-smi: accelerator: none (no device)" 'has "^accelerator: none \(no device\)$"'
check "exactly one accelerator verdict" '[ "$(printf "%s\n" "$OUT" | grep -c "^accelerator:")" = 1 ]'
check "no line claims a GPU" '! printf "%s\n" "$OUT" | grep -Eqi "gpu (available|present|found)"'
# AVE-REQ-094 AC-1: the shell-observable part of the Claude Code and permission rows.
check "claude absent from PATH: not installed" 'has "^claude +not installed$"'
check "os user is the user running the probe" 'has "^os user +$(id -un) \(uid $(id -u)\)$"'
WRITABLE=no; [ -w "$REPO" ] && WRITABLE=yes
check "repository writability matches the file system ($WRITABLE)" 'printf "%s\n" "$OUT" | grep -qxF "$(printf "%-28s %s" "repository writable" "$WRITABLE ($REPO)")"'
check "network probes skipped offline" 'has "skipped \(--offline\)"'
check "a set credential is reported as set" 'has "^HF_TOKEN +set$"'
check "an empty credential is reported as unset" 'has "^ANTHROPIC_API_KEY +unset$"'
check "no credential value is printed" '! printf "%s\n" "$OUT" | grep -qF "$SECRET"'
# AVE-REQ-098 AC-3: every credential the probe reports is documented in .env.example.
NAMES="$(printf '%s\n' "$OUT" | awk '/^## Product credential variables/ { on = 1; next } /^## / { on = 0 } on && NF { print $1 }')"
UNLISTED=""; for name in $NAMES; do grep -q "^$name=" "$REPO/.env.example" 2>/dev/null || UNLISTED="$UNLISTED $name"; done
check "every reported credential variable is listed in .env.example (missing:${UNLISTED:- none})" '[ -n "$NAMES" ] && [ -z "$UNLISTED" ]'

OUT="$(PATH="$T/bin:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-gpu" "$PROBE" --offline 2>&1)"; CODE=$?
# AVE-REQ-094 AC-1
check "device node present: accelerator verdict names it" '[ "$CODE" = 0 ] && has "^accelerator: present \($T/dev-gpu/nvidia0\)$"'
check "claude on PATH: its version is reported" 'has "^claude +9\.9\.9 \(Claude Code\)$"'

# AVE-REQ-094 AC-1: a tool hidden from PATH is reported as not installed.
HIDDEN_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome ffmpeg ffprobe python3 uv git)"
OUT="$(PATH="$HIDDEN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "tools hidden from PATH: probe exits 0" '[ "$CODE" = 0 ]'
for TOOL in ffmpeg ffprobe python3 uv git; do
  check "$TOOL hidden from PATH: not installed" '! (PATH="$HIDDEN_PATH"; command -v "$TOOL" >/dev/null 2>&1) && has_line "$TOOL" "not installed"'
done

# AVE-REQ-094 AC-1: fakes first on PATH: each line follows the command the probe finds, so a value
# fixed in the probe fails here or in the run above; Playwright's directory lists its entries.
FAKE="$T/fake-bin"; mkdir -p "$FAKE" "$T/pw/chromium-1187" "$T/pw/ffmpeg-1011" "$T/pw/firefox-1490"
REAL_GIT="$(PATH="$BARE_PATH"; command -v git)"
cat > "$FAKE/ffmpeg" <<'EOF'
#!/bin/sh
case "$*" in *-version*) printf '%s\n' 'ffmpeg version 99.1-probe-fake Copyright (c) the probe tests' 'ffmpeg built with probe-fake' ;; esac
EOF
cat > "$FAKE/ffprobe" <<'EOF'
#!/bin/sh
case "$*" in *-version*) printf '%s\n' 'ffprobe version 99.2-probe-fake Copyright (c) the probe tests' 'ffprobe built with probe-fake' ;; esac
EOF
cat > "$FAKE/python3" <<'EOF'
#!/bin/sh
printf '%s\n' 'Python 3.99.3-probe-fake' 'python3 second line'
EOF
cat > "$FAKE/uv" <<'EOF'
#!/bin/sh
printf '%s\n' 'uv 0.99.4-probe-fake (0000000 2026-10-03)' 'uv second line'
EOF
cat > "$FAKE/git" <<EOF
#!/bin/sh
case "\$1" in
  --version) printf '%s\n' 'git version 2.99.5.probe-fake' 'git second line' ;;
  *) exec "$REAL_GIT" "\$@" ;;
esac
EOF
cat > "$FAKE/df" <<'EOF'
#!/bin/sh
printf '%s\n' 'Filesystem      Size  Used Avail Use% Mounted on' 'probe-fake-fs   977G  512G  465G  53% /probe'
EOF
cat > "$FAKE/chromium" <<'EOF'
#!/bin/sh
printf '%s\n' 'Chromium 140.0.7339.185 probe-fake' 'chromium second line'
EOF
cat > "$FAKE/google-chrome" <<'EOF'
#!/bin/sh
printf '%s\n' 'Google Chrome 139.0.7258.66 probe-fake' 'google-chrome second line'
EOF
chmod +x "$FAKE"/*
make_fake_curl "$T/net-offline"
FAKE_PATH="$FAKE:$T/net-offline/bin:$BARE_PATH"
DISK_FAKE="$(PATH="$FAKE_PATH"; disk_free)"
OUT="$(PATH="$FAKE_PATH" PLAYWRIGHT_BROWSERS_PATH="$T/pw" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "fakes first on PATH: probe exits 0" '[ "$CODE" = 0 ]'
for SPEC in "ffmpeg -hide_banner -version" "ffprobe -hide_banner -version" "python3 --version" "uv --version" "git --version"; do
  TOOL="${SPEC%% *}"
  # shellcheck disable=SC2086
  EXPECTED="$(first_line "$FAKE_PATH" $SPEC)"; NEXT="$(second_line "$FAKE_PATH" $SPEC)"
  check "fake $TOOL first on PATH: equals the first line of '$SPEC' ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
check "fake df first on PATH: disk equals its Avail and Size fields ($DISK_FAKE)" 'has_line "disk (repository)" "$DISK_FAKE"'
for TOOL in chromium google-chrome; do
  EXPECTED="$(first_line "$FAKE_PATH" "$TOOL" --version)"; NEXT="$(second_line "$FAKE_PATH" "$TOOL" --version)"
  check "fake $TOOL on PATH: reported with the first line of its --version ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
check "PLAYWRIGHT_BROWSERS_PATH set: reported with its directory" 'has_line PLAYWRIGHT_BROWSERS_PATH "$T/pw"'
PW_EXPECTED="$(ls -1 "$T/pw" | sort | tr '\n' ' ')"
check "playwright browsers lists the entries of PLAYWRIGHT_BROWSERS_PATH ($PW_EXPECTED)" '[ "$(pw_entries)" = "$PW_EXPECTED" ]'
check "offline: curl is never invoked" '[ ! -s "$T/net-offline/calls" ]'

# AVE-REQ-094 AC-1: Git lines of a fixture repository with three worktrees on a known branch; the
# probe runs from its copy in the fixture, so the repository and the working directory coincide.
GITFIX="$T/gitfix"
git_fixture() {
  git -c init.defaultBranch=probe-main init -q "$GITFIX/main" &&
    git -C "$GITFIX/main" -c user.name=probe-test -c user.email=probe-test@example.invalid \
      -c commit.gpgsign=false commit -q --allow-empty -m fixture &&
    git -C "$GITFIX/main" checkout -q -b probe-fixture-branch &&
    git -C "$GITFIX/main" worktree add -q -b probe-wt-a "$GITFIX/wt-a" &&
    git -C "$GITFIX/main" worktree add -q -b probe-wt-b "$GITFIX/wt-b" &&
    mkdir -p "$GITFIX/main/scripts" && cp "$PROBE" "$GITFIX/main/scripts/probe-environment.sh"
}
git_fixture >/dev/null 2>&1; FIX_CODE=$?
FIX_WT="$(cd "$GITFIX/main" 2>/dev/null && git worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
FIX_BRANCH="$(cd "$GITFIX/main" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
OUT="$(cd "$GITFIX/main" 2>/dev/null && PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" ./scripts/probe-environment.sh --offline 2>&1)"; CODE=$?
check "git fixture: three worktrees on branch probe-fixture-branch" '[ "$FIX_CODE" = 0 ] && [ "$FIX_WT" = "3 listed" ] && [ "$FIX_BRANCH" = probe-fixture-branch ]'
check "git fixture: worktrees equals git worktree list | wc -l ($FIX_WT)" '[ "$CODE" = 0 ] && has_line worktrees "$FIX_WT"'
check "git fixture: branch equals git rev-parse --abbrev-ref HEAD ($FIX_BRANCH)" 'has_line branch "$FIX_BRANCH"'

# AVE-REQ-094 AC-1: network. Without curl the probe says so.
NOCURL_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome curl)"
OUT="$(PATH="$NOCURL_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" 2>&1)"; CODE=$?
check "curl absent: network probes report curl not installed" '[ "$CODE" = 0 ] && has_line probes "curl not installed"'

# net_run <name> <script line>... — runs the probe online with a fake curl that answers from the
# script lines and the product credential variables set, then checks each host line against the
# script (`HTTP <code>` for a code, `unreachable` for a failure) and every recorded request.
net_run() {
  local name="$1" rec result
  shift
  NET="$T/net-$name"
  make_fake_curl "$NET" "$@"
  OUT="$(PATH="$NET/bin:$NOCURL_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" ANTHROPIC_API_KEY="$SECRET" \
    OPENAI_API_KEY="$SECRET" HF_TOKEN="$SECRET" "$PROBE" 2>&1)"; CODE=$?
  check "$name: probe exits 0" '[ "$CODE" = 0 ]'
  for rec in "$@"; do
    KEY="${rec%% *}"; result="${rec#* }"; result="${result%% *}"
    case "$result" in fail:*) WANT="unreachable" ;; *) WANT="HTTP $result" ;; esac
    check "$name: $KEY reads '$WANT' on one line (fake curl: $result)" 'has_line "$KEY" "$WANT" && [ "$(lines_of "$KEY")" = 1 ]'
    check "$name: $KEY is requested" 'grep -qF "CALL url=$KEY " "$NET/calls"'
  done
  check "$name: every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)" '[ -s "$NET/calls" ] && [ ! -s "$NET/violations" ]'
  [ -s "$NET/violations" ] && sed 's/^/         /' "$NET/violations"
  check "$name: every request has a time limit of at most 10 s (-m/--max-time)" 'time_limits_ok "$NET/calls"'
  check "$name: only the seven hosts are requested" '[ -s "$NET/calls" ] && ! grep -q "^UNEXPECTED " "$NET/calls"'
  check "$name: no credential value reaches curl" '! grep -qF "$SECRET" "$NET/calls" && ! printf "%s\n" "$OUT" | grep -qF "$SECRET"'
}
# AVE-REQ-094 AC-1: each host answers in one scenario and gets no response in the other; a 4xx
# still proves that the host answers; pypi.org/simple/ and github.com/ answer with a large body.
net_run network-1 "pypi.org/simple/ 200 48000000" "files.pythonhosted.org/ fail:28" "registry.npmjs.org/ 301" \
  "github.com/ 405" "huggingface.co/api/models?limit=1 429" "api.anthropic.com/ 404" "api.openai.com/ fail:6"
net_run network-2 "pypi.org/simple/ fail:7" "files.pythonhosted.org/ 503" "registry.npmjs.org/ fail:28" \
  "github.com/ 200 600000" "huggingface.co/api/models?limit=1 401" "api.anthropic.com/ fail:35" "api.openai.com/ 421"

"$PROBE" --bogus >/dev/null 2>&1; CODE=$?
check "unknown option exits 2" '[ "$CODE" = 2 ]'

echo "PROBE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
