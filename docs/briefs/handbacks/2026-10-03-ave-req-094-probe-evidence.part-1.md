# Handback — AVE-REQ-094 probe evidence — part 1 (research)

Brief: [2026-10-03-ave-req-094-probe-evidence.md](../2026-10-03-ave-req-094-probe-evidence.md), part 1. Run `wf_d57d9cab-829`, researcher stage, 2026-10-03; the lead persisted this structured result unchanged in content.

## Result
COMPLETE; commits: none (read-only).

## Items

- **Request form per host (HEAD, byte range, bounded GET), measured twice from the container** — done: HEAD answers on all seven hosts with a status code (200, 404, 200, 200, 200, 404, 421) in 0.836 to 1.454 s and fetches 0 body bytes. Byte range: honored by pypi.org/simple/ and github.com/ (206, 1 byte); ignored by the other five (full body, 2 to 542 B), so it bounds nothing. Bounded GET with --max-filesize 1: status code arrives, curl exits 63 on all seven, 0 or 1 body bytes. The current unbounded GET downloads 15 to 17 MB of the 46713682-byte pypi index and times out at 8 s with exit 28 after receiving status 200. Test: none (research). Mutation: none (research).
- **Recommended curl invocation and timeout** — done: `curl -sS -o /dev/null -I -m 10 -w '%{http_code}' "$url"`, verdict `HTTP <code>` when curl exits 0 and the code is not 000, `unreachable` otherwise. Unreachable paths checked without contacting other hosts: --resolve pypi.org:443:127.0.0.1 gives exit 7 and code 000; -m 0.001 gives exit 28 and code 000; both read unreachable. A full run over the seven hosts prints HTTP 200, 404, 200, 200, 200, 404, 421 in 8 s, twice. For part 2's fake curl: the probe passes -I as its own word; the fake accepts -I or --head and fails on a call that has neither (a plain GET), and it may also assert that -m/--max-time is present and at most 10.
- **Memory oracle** — done: Integer half-up computation from /proc/meminfo MemTotal (command in oracles); 7.5 GiB measured, equal to the probe's awk value. The only divergence is at exact x.25 GiB values (documented, with checked examples). A hard-coded `1.0 GiB` mutation fails against it on this host.
- **Disk oracle** — done: `df -h --output=avail,size "$REPO" | tail -n 1` read into AVAIL and SIZE, expected `$AVAIL free of $SIZE`; measured 21G free of 237G on /workspace, equal to the probe's line from /workspace. The probe measures cwd: from /tmp the same line reads 943G free of 1007G. Bracket the oracle around the probe run to tolerate concurrent writers. A hard-coded `1G free of 2G` mutation fails against it.
- **Host memory or cgroup limit** — done: The container has no cgroup memory or CPU limit (memory.max max, docker HostConfig Memory 0); /proc/meminfo reports the Docker Desktop WSL 2 VM total (7909796 kB, equal to docker info MemTotal), which is the effective limit here. The Windows host's 15.6 GiB is not visible in the container.

## Hosts

| Host | Request form | Status code | Response time | Body bytes fetched |
|---|---|---|---|---|
| pypi.org/simple/ | HEAD (-I) | 200 (both runs) | 0.848 s / 0.836 s | 0 (headers 1666 B; Content-Length announces 46713682) |
| files.pythonhosted.org/ | HEAD (-I) | 404 (both runs) | 1.431 s / 0.861 s | 0 (headers 499 B) |
| registry.npmjs.org/ | HEAD (-I) | 200 (both runs) | 1.432 s / 1.149 s | 0 (headers 505 B) |
| github.com/ | HEAD (-I) | 200 (both runs) | 1.454 s / 0.877 s | 0 (headers 5315 B) |
| huggingface.co/api/models?limit=1 | HEAD (-I) | 200 (both runs) | 1.214 s / 0.954 s | 0 (headers 1267 B) |
| api.anthropic.com/ | HEAD (-I) | 404 (both runs) | 1.239 s / 0.971 s | 0 (headers 240 B) |
| api.openai.com/ | HEAD (-I) | 421 (both runs) | 1.150 s / 0.865 s | 0 (headers 852 B) |
| pypi.org/simple/ | byte range GET (-r 0-0) | 206 (range honored) | 0.838 s / 0.836 s | 1 |
| files.pythonhosted.org/ | byte range GET (-r 0-0) | 404 (range ignored, full error body) | 1.112 s / 1.114 s | 10 |
| registry.npmjs.org/ | byte range GET (-r 0-0) | 200 (range ignored, full body) | 1.165 s / 1.164 s | 2 |
| github.com/ | byte range GET (-r 0-0) | 206 (range honored) | 1.397 s / 0.870 s | 1 |
| huggingface.co/api/models?limit=1 | byte range GET (-r 0-0) | 200 (range ignored, full body) | 1.223 s / 0.944 s | 542 |
| api.anthropic.com/ | byte range GET (-r 0-0) | 404 (range ignored, full error body) | 0.876 s / 0.869 s | 132 |
| api.openai.com/ | byte range GET (-r 0-0) | 421 (range ignored, full error body) | 0.875 s / 0.881 s | 124 |
| pypi.org/simple/ | bounded GET (--max-filesize 1) | 200, curl exit 63 | 0.833 s / 0.835 s | 0 (size known from Content-Length, transfer never starts) |
| files.pythonhosted.org/ | bounded GET (--max-filesize 1) | 404, curl exit 63 | 1.401 s / 1.118 s | 0 |
| registry.npmjs.org/ | bounded GET (--max-filesize 1) | 200, curl exit 63 | 1.151 s / 1.151 s | 0 |
| github.com/ | bounded GET (--max-filesize 1) | 200, curl exit 63 | 1.678 s / 1.145 s | 1 (no Content-Length; curl 8.5.0 aborts mid-transfer) |
| huggingface.co/api/models?limit=1 | bounded GET (--max-filesize 1) | 200, curl exit 63 | 0.958 s / 0.943 s | 0 |
| api.anthropic.com/ | bounded GET (--max-filesize 1) | 404, curl exit 63 | 1.143 s / 0.864 s | 0 |
| api.openai.com/ | bounded GET (--max-filesize 1) | 421, curl exit 63 | 1.140 s / 0.878 s | 0 |
| pypi.org/simple/ | current probe form: unbounded GET (-m 8), for reference | 200 received, then curl exit 28 (timeout), so the probe prints unreachable | 8.001 s / 8.000 s (timeout) | 17216657 / 15135916 of 46713682 |

## Recommended curl invocation

```sh
if code="$(curl -sS -o /dev/null -I -m 10 -w '%{http_code}' "$url" 2>/dev/null)" && [ "$code" != 000 ]; then item "${url#https://}" "HTTP $code"; else item "${url#https://}" "unreachable"; fi
```

HEAD request (-I as its own word, so a fake curl can match it), 10 s total timeout, write-out of the status code. curl exits 0 for every HTTP status without --fail, so 2xx, 4xx and 421 all read `HTTP <code>`; a refused connection (exit 7, code 000) or a timeout (exit 28, code 000) reads `unreachable`. The `!= 000` guard also covers a fake or a curl that exits 0 without a response. Measured: all seven hosts answer in 0.84 to 1.45 s; the whole Network section took 8 s per run (two runs, 04:53:35 to 04:53:51 UTC). The 10 s timeout is the brief's ceiling and leaves about 7x headroom over the slowest response; with every host blackholed the section takes at most 70 s. The bounded GET ends with exit 63 on every host that sends a body, so exit status no longer separates a response from a failure. Byte ranges are honored by only 2 of the 7 hosts (pypi, github), so they do not bound the body. HEAD fetches 0 body bytes everywhere and needs no curl version feature.

## Oracles

```text
Measured in the container (cwd /workspace, curl 8.5.0, GNU coreutils df 9.4, LANG=C.UTF-8) on 2026-10-03.

Memory, a computation of the test's own (integer half-up rounding on tenths of a GiB):
  kb="$(sed -n 's/^MemTotal: *\([0-9]*\) kB$/\1/p' /proc/meminfo)"; t=$(( (kb * 10 + 524288) / 1048576 )); MEM="$(printf '%d.%d GiB' $((t / 10)) $((t % 10)))"
  expected line: printf '%-28s %s' memory "$MEM"
  Measured: MemTotal 7909796 kB = 7.54337 GiB exactly (python Decimal); the integer oracle, the probe's awk and free -h all give 7.5 GiB. Rounding note: the probe's awk "%.1f" rounds the exact binary value half to even; the integer oracle rounds half up. They differ only when MemTotal is exactly an x.25 GiB value (an odd multiple of 262144 kB whose tenths floor is even). Checked: 2359296 kB gives awk 2.2 and integer 2.3; 1310720 kB gives 1.2 and 1.3; 2883584 kB gives 2.8 for both. Kernels report MemTotal below installed RAM, so real hosts do not hit these values; a test that wants to be exact at the boundary accepts either value when kb*10 % 1048576 == 524288.

Disk, the test's own df command (df -h rounding is df's own: powers of 1024, rounded up, one decimal below 10, so the test reads df -h and does not compute from blocks):
  read -r AVAIL SIZE <<EOF
  $(df -h --output=avail,size "$REPO" | tail -n 1)
  EOF
  expected line: printf '%-28s %s' "disk (repository)" "$AVAIL free of $SIZE"
  Measured: "21G free of 237G" for /workspace (a 9p drvfs bind mount of C:\, 92 % used); --output=avail,size and the probe's `df -h . | awk 'NR == 2 { print $4 " free of " $2 }'` agree. Free space can move between the probe run and the oracle when another agent writes: measure the oracle before and after the probe run and accept either value.
  The probe's `df -h .` measures the caller's cwd: from /tmp in the container it prints "943G free of 1007G" (overlay root), from /workspace "21G free of 237G". The label says repository, so `df -h "$ROOT"` in the probe and `df -h "$REPO"` in the oracle, with the probe started from "$T", make the line and its check independent of cwd (see openQuestions).

Host memory or cgroup limit: the container reports the Docker Desktop WSL 2 VM's memory and has no cgroup limit. Evidence: /proc/self/cgroup "0::/" on cgroup2fs; /sys/fs/cgroup/memory.max "max", memory.swap.max "max", memory.high "max", cpu.max "max 100000"; docker inspect HostConfig Memory=0 MemorySwap=0 NanoCpus=0; MemTotal 7909796 kB x 1024 = 8099631104 B equals `docker info` MemTotal (Docker Desktop 29.8.0, kernel 6.18.33.2-microsoft-standard-WSL2). The Windows host has 15.6 GiB; WSL 2 assigns 50 % of Windows memory by default, matching 7.5 GiB. SwapTotal 2097152 kB (2.0 GiB). /proc/meminfo follows the kernel and ignores cgroup limits, so under a `docker run --memory` limit it would still show the VM total while memory.max holds the limit. CPUs: nproc and getconf _NPROCESSORS_ONLN both 8, no CPU quota.
```

## Verification

All commands run from C:/dev/AI-Video-Editor at 4e607de through ./scripts/dev-container.sh (container ave-dev-3084842326-4183265287), anonymous, -m 10 or less, against the seven briefed hosts only; no repository file modified.
1. `curl --version`: curl 8.5.0 (aarch64-unknown-linux-gnu), OpenSSL/3.0.13, nghttp2/1.59.0, Ubuntu 8.5.0-2ubuntu10.15.
2. HEAD loop (`curl -sS -o /dev/null -m 10 -I -w ...`), 7 hosts x 2 runs: all exit 0, codes 200/404/200/200/200/404/421, size_download 0, 0.836 to 1.454 s.
3. Range loop (`-r 0-0`), 7 x 2: 206 on pypi and github (1 byte); 404/200/200/404/421 with full bodies (10/2/542/132/124 B) on the others; all exit 0.
4. Bounded GET loop (`--max-filesize 1`), 7 x 2: codes as for HEAD, every run exit 63; github aborted after 1 byte (`Exceeded the maximum allowed file size (1) with 1 bytes`).
5. `curl -sS -I -m 10` headers: pypi.org/simple/ Content-Length 46713682, Accept-Ranges bytes; huggingface 542; openai 124; files.pythonhosted 10; npm, github, anthropic send no Content-Length.
6. Current probe form `curl -sS -o /dev/null -m 8 -w '%{http_code}' https://pypi.org/simple/` x 2: code 200, exit 28 at 8.001 s and 8.000 s, 17216657 and 15135916 of 46713682 bytes.
7. Unreachable simulation: `--resolve pypi.org:443:127.0.0.1` gives 000 exit 7; `-m 0.001` gives 000 exit 28; verdict snippet prints unreachable; `api.openai.com/` prints HTTP 421.
8. Recommended loop x 2: all seven lines `HTTP <code>`, 8 s per run.
9. Oracles: grep /proc/meminfo (MemTotal 7909796 kB, SwapTotal 2097152 kB), probe awk 7.5 GiB, integer oracle 7.5 GiB, python Decimal 7.543369293212890625; boundary checks via awk vs integer; free -h 7.5Gi/2.0Gi; df -h . / -P / -Pk / --output=avail,size on /workspace (21G of 237G) and /tmp (943G of 1007G); /proc/mounts shows /workspace as 9p drvfs C:\; cgroup files as listed; nproc 8.
10. Host side (read-only): `./scripts/dev-container.sh --status`; `docker inspect` HostConfig Memory=0 MemorySwap=0 NanoCpus=0; `docker info` MemTotal=8099631104 NCPU=8 Kernel=6.18.33.2-microsoft-standard-WSL2 Server=29.8.0.

## Sources

- https://curl.se/docs/manpage.html (curl 8.23.0 man page: -I/--head 'Fetch the headers only'; -r/--range 'HTTP servers are not required to honor range requests'; exit codes 7, 28, 63; write-out http_code, exitcode; checked 2026-10-03)
- https://raw.githubusercontent.com/curl/curl/master/docs/cmdline-opts/max-filesize.md (before 8.4.0 no effect when size unknown; since 8.4.0 aborts the transfer at the threshold; checked 2026-10-03)
- https://www.rfc-editor.org/rfc/rfc9110.html (RFC 9110 9.3.2: 'A server MUST NOT send a message body in the response to a HEAD request'; 14.2: 'A server MAY ignore a Range header field'; checked 2026-10-03)
- https://docs.docker.com/engine/containers/resource_constraints/ ('By default, a container has no resource constraints'; checked 2026-10-03)
- https://docs.kernel.org/admin-guide/cgroup-v2.html (memory.max and memory.swap.max default 'max'; checked 2026-10-03)
- https://learn.microsoft.com/en-us/windows/wsl/wsl-config (.wslconfig memory default '50% of total memory on Windows'; page updated 2026-09-16; checked 2026-10-03)
- Live measurements from the development container, 2026-10-03 (commands in verification)

## Confidence
High: every host was measured twice in each of three request forms, the recommended form was run end to end twice, the unreachable outcomes were reproduced locally, and the oracles were cross-checked against the probe, free -h, python and docker info. HEAD semantics come from RFC 9110 and the curl man page.

## Unknowns
1. A server that rejects HEAD would answer 405 or 501; the verdict rule still reads `HTTP 405`. None of the seven does this today; a future change by a host would show up only as a different code.
2. Behavior behind an HTTPS egress proxy is unmeasured (this host has none). Expected: a proxy that refuses CONNECT yields http_code 000 with a non-zero exit, so the line reads unreachable; not verified.
3. Network from the GitHub Actions runner is unmeasured; the live probe stays outside verify.sh, so CI does not depend on it.
4. The swap total (2.0 GiB) does not match the .wslconfig documented default (25 % of Windows memory); Docker Desktop's own WSL settings presumably set it; not investigated, and the probe reports no swap line.
5. Response times are single-link, single-day figures (2026-10-03, 04:4x to 04:53 UTC).

## Lead updates
Proposed ENVIRONMENT_CAPABILITIES.md § Network policy rows for part 3 (observed from the container on 2026-10-03 with a HEAD request, `curl -sS -o /dev/null -I -m 10 -w '%{http_code}'`, two runs, 0 body bytes): pypi.org/simple/ HTTP 200 (0.84 s); files.pythonhosted.org/ HTTP 404 (0.86 to 1.43 s); registry.npmjs.org/ HTTP 200 (1.15 to 1.43 s); github.com/ HTTP 200 (0.88 to 1.45 s); huggingface.co/api/models?limit=1 HTTP 200 (0.95 to 1.21 s); api.anthropic.com/ HTTP 404 (0.97 to 1.24 s); api.openai.com/ HTTP 421 (0.87 to 1.15 s). Probe sentence: the Network section sends one HEAD request per host with a 10 s timeout and reports `HTTP <code>` for any status and `unreachable` when no response arrives.
Platform rows: Container CPU / memory unchanged (8 CPUs, 7.5 GiB plus 2 GiB swap); add that the container has no cgroup limit (memory.max max) and /proc/meminfo shows the Docker Desktop WSL 2 VM total. Disk: from the container the bind-mounted C: reads 21G free of 237G (92 % used) on 2026-10-03; the host row says 19 GiB free (93 % used) from 2026-10-02.
Status line (lead's choice): AVE-REQ-094 part 1 research done on 2026-10-03 in the main checkout at 4e607de; handback docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-1.md. TRACEABILITY.md and PROGRESS.md: no change from part 1. No ADR is needed: the request form is an implementation detail of the probe, recorded in the probe sentence.

## Open questions
1. Disk line scope: the brief names `df -h .`, and the probe measures the caller's cwd (from /tmp the container prints 943G free of 1007G; from /workspace, 21G free of 237G). Recommended default: part 3 changes the probe to `df -h "$ROOT"` so the `disk (repository)` label holds from any cwd, and part 2's oracle uses `df -h "$REPO"` with the probe started from "$T"; that check fails on the current probe and passes after part 3. If the lead keeps `.`, the test must run the probe and its oracle from the same cwd.
2. Memory limit visibility: /proc/meminfo ignores cgroup limits. A probe line for /sys/fs/cgroup/memory.max would make a future `--memory` limit visible. This is discovered work outside AC-1 as briefed; recommended default: no change now, and the capabilities document records that the container has no cgroup limit.
3. Fake curl contract for part 2: recommended default is that the probe passes `-I` as a separate argument and `-m 10`. The fake records its argv, prints the scripted code for the URL (last argument) and exits 0, or exits non-zero for a scripted failure, and fails the check when neither `-I` nor `--head` is present.
