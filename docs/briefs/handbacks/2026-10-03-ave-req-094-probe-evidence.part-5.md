# Handback — AVE-REQ-094 probe evidence, part 5: review of the repaired branch at eb73896

Brief: [2026-10-03-ave-req-094-probe-evidence.md](../2026-10-03-ave-req-094-probe-evidence.md). Run `wf_db16f332-fdf` ([script](../../workflows/verify-094-repaired-wf_7d239bd1-b31.js), `{commit: 'eb73896'}`): one verify-requirement review in a private clone of the task branch `ave-req-094-probe-evidence`. The verdict is FAIL, so no challenge ran. The report follows unedited apart from local paths; the fixes land on the task branch.

## Review

Verdict: **FAIL** — AVE-REQ-094 — Capability-aware native dynamic workflows (reviewed at eb73896, branch ave-req-094-probe-evidence; private clone, removed after the review)

### AC-1 — FAIL

```text
What holds: scripts/tests/test-probe-environment.sh ran 3 times in a row in the container (PROBE TOTAL: pass=115 fail=0 each, check lists identical after normalising the temp path) and once more inside scripts/tests/run.sh under concurrent load (115/115). The skeptic's four probes now read correctly (fake nvidia-smi first on PATH, AVE_PROBE_DEV_DIR empty): driver diagnostic exit 9 -> none; 'No devices were found' exit 6 -> none; empty answer exit 0 -> none; 'Tesla T4, 15360 MiB' exit 0 -> present. The four host-value lines are now proven by fixtures: cpus, memory, os user and writability fixed to the host's values each fail the suite. 67 mutations of the probe in a /tmp clone inside the container: 58 killed, 9 survived (4 are lines the strategy names inspection-only). Live probe: all seven Network lines read HTTP <code> (200, 404, 200, 200, 200, 404, 421), equal to the § Network policy rows. Inspections of the Claude Code rows passed (see Test quality). What fails: (1) the accelerator verdict reads 'present' without any GPU for inputs the requirement's own Edge cases map to 'no accelerator' (blocking finding 1); (2) three mutations of the compared accelerator verdict line survive 115/115, one of which makes the verdict 'present' on every real host (blocking finding 2).
```

### AC-2 — PASS

```text
Inspection. docs/workflows/ave-req-094-probe-evidence-wf_d57d9cab-829.js composes parallel([researcher, tester]) -> implementer(research, tests) -> reviewer -> skeptic on PASS, each agent() call with a JSON schema (RESEARCH, HANDBACK, REPORT, CHALLENGE) as the structured handoff; the implementer prompt embeds both results. Brief docs/briefs/2026-10-03-ave-req-094-probe-evidence.md (parts, allowed and forbidden paths, handback schema) and handbacks part 1 to 4 exist. Commit times (UTC) match the declared dependency order and the overlap: brief 4e607de 04:47:57, script 0bd46d9 04:48:47, research measurements until 04:53 and its handback 08237ac 05:14:06 (persisted while the tester still worked), tester 49ecb21 05:23:23 (suite and handback only), implementer fcd97f0 06:11:08 (allowed paths only: probe, suite, ENVIRONMENT_CAPABILITIES.md, requirement sections, handback), review and challenge bb94bf7 07:16:19. The probe's request form equals part 1's recommendation; part 3 records part 2's 7 failing checks as its input. README row for wf_d57d9cab-829 exists. Earlier runs in docs/workflows/ (wf_5493b930-f7c two parallel writers, wf_1a23bf0d-2a0 three review lenses) have scripts and cited commits 486b3a0, 24499a6 that exist. This review itself runs as a workflow agent with the REPORT schema of the persisted verify scripts.
```

### AC-3 — PASS

```text
Inspection. The 14 scripts in docs/workflows/ call only agent(), parallel(), pipeline(), phase(), log() and read args and meta; no file-system, process or network API. Each README row names a run with a recorded outcome, and the cited commits exist (49ecb21, fcd97f0, 486b3a0, 24499a6, 97a8d20, 08237ac checked). First-hand: this session is launched by such a script (the harness states it runs inside a workflow script; the StructuredOutput schema equals the REPORT schema in verify-094-repaired-wf_7d239bd1-b31.js including the description text of test_evidence_lines; the system prompt equals .claude/agents/reviewer.md, so agent(prompt, {schema, agentType}) exists in the installed runtime). Feature claims in docs/ENVIRONMENT_CAPABILITIES.md are tied to runs or session observations; rows that could not be verified say so (README rows 'verdict not recorded').
```

### AC-4 — PASS

```text
Inspection. CLAUDE.md § Delegation (fallback paragraph: sequential lifecycle, review in a fresh session recorded as sequential, requirement stays verification), .claude/skills/develop/SKILL.md § 6 step 3 (same rule with the Status-log note), .claude/skills/ai-video-editor-delivery/SKILL.md steps 3 and 6 ('Never invent workflow APIs', fallback review). docs/WORKFLOW_LOG.md WF-002 records a real fallback: the lead finished an interrupted delegated task sequentially (commit 90a1f2e exists). No orchestration platform exists: git ls-files holds verification tooling only under scripts/ (verify, evidence, probe, dev-container, tests) and no scheduler, queue or agent runner.
```

### Verification runs

```text
- git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/verify-ave-req-094 && git checkout -q eb73896 — clone at eb738964b6f8, clean tree
- ./scripts/verify.sh (fast tier), first run — FAIL 1 of 9 steps: 'Working tree unchanged by verification' listed '?? .verify-fast.log'. Cause: my own log redirect inside the clone, no defect of the work. Log moved out, run repeated.
- ./scripts/verify.sh (fast tier), second run with the log outside the tree — PASS, 9 of 9 steps; manifest var/verify/runs/20261006T041628Z-302/manifest.json (tier fast, commit eb738964b6f8)
- ./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh, three runs in a row — exit 0 each, PROBE TOTAL: pass=115 fail=0, 22 to 23 s; the three check lists are identical (diff after replacing the temp directory name): no check changed its result
- ./scripts/dev-container.sh bash scripts/tests/run.sh — PASS (6 suites): checker 201, check-baseline 205, stop-hook 72, session-start 31, verify-tiers 23, probe 115 checks; it ran while the mutation job loaded the container
- ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-094 --require-fresh — exit 0; 'tier fast, PASS, commit eb738964b6f8, FRESH'; AC-1 to AC-4 'missing' (expected: the tooling suites record in the release tier; AC-2 to AC-4 are inspection criteria). AC-1 judged from the suite runs above.
- ./scripts/dev-container.sh ./scripts/probe-environment.sh (live, 7 s) — exit 0; cpus 8, cpu model unknown, memory 7.5 GiB, disk 5.1G free of 237G, nvidia-smi not installed, both device lists none, accelerator: none (no device); Network: pypi.org/simple/ HTTP 200, files.pythonhosted.org/ HTTP 404, registry.npmjs.org/ HTTP 200, github.com/ HTTP 200, huggingface.co/api/models?limit=1 HTTP 200, api.anthropic.com/ HTTP 404, api.openai.com/ HTTP 421
- Tag mapping: git grep -w 'AVE-REQ-094 AC-1' -- ':!*.md' — 16 tag lines in scripts/tests/test-probe-environment.sh; AC-2, AC-3, AC-4 have no tagged test (inspection criteria per § Verification strategy)
- Mutation matrix in the container (git clone /workspace /tmp/m; baseline there 115/115; each mutant written over /tmp/m/scripts/probe-environment.sh with an exact single-match replacement, suite rerun, pristine restored and re-run 115/115) — 67 mutations, 58 killed, 9 survived, 0 not applied. Survivors: acc_drop_dri_nodes, acc_dri_dir_misnamed, acc_any_dev_entry_counts (compared verdict line: findings); nvidia list line, dri list line, node, kernel (named inspection-only in the strategy); browsers_drop_chromium_browser; cred_drop_OPENAI_BASE_URL. Killed among others: cpus fixed to 8 and cpus from nproc ('fake getconf answers 3'); memory fixed to 7.5 GiB, read from /proc, GB for GiB, %.0f; cpu model fixed, /proc/cpuinfo, lscpu fallback removed, '-' rule removed; disk from cwd, fields swapped, Used for Avail; nvidia-smi exit status ignored, any text on exit 0, never counted, last row, item fixed; nvidia nodes dropped, GPU row dropped, always none, present whenever nvidia-smi is installed; ffmpeg, ffprobe, python3, uv, git fixed to host values; whole version output; PLAYWRIGHT_BROWSERS_PATH fixed; chromium or google-chrome dropped; browser version fixed; playwright list removed; worktrees and branch fixed or taken from cwd; claude fixed; os user fixed, whoami, $UID; writable always yes, real root tested, AVE_PROBE_ROOT ignored; credential value printed, inverted, always unset; plain GET, -X HEAD, -m 30, no -m, only 2xx as HTTP, failure as HTTP, host dropped, host added, --offline ignored, no-curl branch removed; unknown option exit 0.
- Surviving mutant shown concretely (container): with find "$DEV_DIR" -mindepth 1 -maxdepth 1 in place of -name 'nvidia*' the suite prints PROBE TOTAL: pass=115 fail=0 and the mutant prints on the container's real /dev 'accelerator: present (/dev/core /dev/fd /dev/full /dev/mqueue /dev/null /dev/ptmx ...)'. With $dri_nodes removed from the evidence the suite prints 115/115 and a dev dir holding dri/renderD128 reads 'accelerator: none (no device)' (pristine probe: present).
- Accelerator probes of my own (container; fake nvidia-smi first on PATH printing given lines with a given exit status; AVE_PROBE_DEV_DIR on fixture directories; pristine probe --offline) — results in blocking finding 1; controls: unrelated entries (null, sda, shm) -> none; missing dev dir -> none; real /dev -> none; NVIDIA_VISIBLE_DEVICES=all CUDA_VISIBLE_DEVICES=0 without a device -> none; AVE_PROBE_DEV_DIR empty string -> /dev.
- node --check on each persisted script of docs/workflows/ wrapped in an async function (container, Node 18) — 12 parse; 2 fail with 'SyntaxError: Unexpected identifier': ave-req-094-probe-evidence-wf_d57d9cab-829.js line 19 and m0-fix-tracks-wf_164de68e-23b.js line 25
- claude --version on the host — '2.1.282 (Claude Code)', equal to the Claude Code version row; git worktree list in the main checkout — the worktree .claude/worktrees/ave-req-094-probe-evidence on its own branch at eb73896; .claude/settings.local.json absent
- ./scripts/dev-container.sh --stop (state absent) and rm -rf .claude/worktrees/verify-ave-req-094 — done; the main checkout was never written. Logs of every run: <session scratchpad>\verify-094-reviewer\ (mutations.log, acc.log, probe-suite-1..3.log, tooling-run.log, verify-fast-run2.log, live-probe.log)
```

### Blocking findings (2)

1.

```text
location: scripts\probe-environment.sh:62-63, :68-73 and :56 (requirement § Edge cases, docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:42-47)
defect: AC-1, accelerator access: the verdict still reads 'accelerator: present (...)' without any GPU. The probe counts names, never GPU devices: every entry of /dev whose name starts with 'nvidia' and every entry of /dev/dri is evidence, and any exit-0 nvidia-smi line holding exactly one comma is a GPU row. This contradicts the requirement's own Edge cases: 'nvidia-smi installed without a driver or a device (a CI image, a container started without GPU access) -> no accelerator', 'prints accelerator: none (no device) whenever no device node exists and nvidia-smi reports no GPU', and 'a diagnostic with exit 0 leaves the verdict to the device nodes'.
evidence: Reproduced in the container with the pristine probe (--offline), fake nvidia-smi first on PATH, AVE_PROBE_DEV_DIR on a fixture directory. (a) Driver control nodes only (nvidiactl, nvidia-uvm, nvidia-uvm-tools) while nvidia-smi answers 'No devices were found' with exit 6: 'nvidia-smi no GPU reported' and 'accelerator: present (/tmp/acc/ctl/nvidia-uvm /tmp/acc/ctl/nvidia-uvm-tools /tmp/acc/ctl/nvidiactl)'; the same without nvidia-smi. This is the realistic form of the edge case the requirement names: nvidia-smi prints 'No devices were found' only after it reached the kernel driver through /dev/nvidiactl, so a real host that gives this answer carries the control node (a container under the NVIDIA runtime with driver capabilities and no GPU exposed); the suite's scenario pairs that answer with an empty directory, a combination real hosts do not produce. Real-driver behaviour is my domain knowledge, not measured here (no NVIDIA hardware); the fixture run is measured. (b) Entries that are no device node: directory nvidia-caps alone -> present; regular file nvidia-readme.txt -> present; directory dri/by-path alone -> 'accelerator: present (/tmp/acc/dribypath/dri/by-path)'; an empty AVE_PROBE_DEV_DIR whose own name starts with nvidia -> present (find lacks -mindepth 1). (c) dri/card0 alone, the display node every virtual display adapter creates (no render node) -> 'accelerator: present (/tmp/acc/dricard/dri/card0)'; beyond the Edge-case text, same cause. (d) nvidia-smi exit 0 with a one-comma line that is no GPU: 'Sorry, no GPU is attached to this machine' -> 'accelerator: present (Sorry, no GPU is attached to this machine)'; the csv header 'name, memory.total [MiB]' -> present; '[N/A], [N/A]' -> present. I know no stock nvidia-smi diagnostic with exactly one comma and exit 0, so (d) weighs less than (a); the Edge-case sentence is general and the suite's only exit-0 diagnostic ('No devices were found') holds no comma. Inverse error: 'Acme GPU, Model X, 8192 MiB' with exit 0 -> 'no GPU reported', none. Consumer: docs/ENVIRONMENT_CAPABILITIES.md:151 tells the human that a host is ready for the hardware tests 'where ./scripts/probe-environment.sh prints accelerator: present (...)' and names the NVIDIA Container Toolkit, the setting of case (a); resume-project step 6 copies the verdict into the GPU row. A false 'present' is a fake platform capability (AT-30).
fix: Count GPU devices only. In scripts/probe-environment.sh: nvidia nodes from find "$DEV_DIR" -mindepth 1 -maxdepth 1 -name 'nvidia[0-9]*' (per-GPU nodes; nvidiactl, nvidia-uvm*, nvidia-modeset and nvidia-caps stay listed on the '/dev/nvidia* devices' line and never enter the verdict); DRI evidence from render nodes only (find "$DEV_DIR/dri" -mindepth 1 -maxdepth 1 -name 'renderD*'), with card* and by-path listed and uncounted; accept an nvidia-smi row only when its memory field is a figure, for example grep -m1 -E '^.*[^,[:space:]].*,[[:space:]]*[0-9]+ MiB$' (this also admits a GPU name that holds a comma). State in the requirement's § Edge cases and § Verification strategy which nodes count and that control nodes, display-only nodes and directories do not; record in docs/ENVIRONMENT_CAPABILITIES.md that a render node of a software or virtual DRM driver can still read present, if the lead keeps that limit. Then add the checks of blocking finding 2.
```

2.

```text
location: scripts\tests\test-probe-environment.sh:227-228, :289, :304-322
defect: AC-1, test quality: three mutations of the accelerator verdict, a line § Verification strategy names as compared, survive the suite. The device fixtures are an empty directory (dev-none) and a directory holding only nvidia0 (dev-gpu): 'none' is proven only for an empty /dev, 'present by a node' only for nvidia0, and the /dev/dri input has no check at all.
evidence: In a /tmp clone inside the container, each mutant with PROBE TOTAL: pass=115 fail=0: (1) acc_any_dev_entry_counts: line 62 as find "$DEV_DIR" -mindepth 1 -maxdepth 1 (every entry of /dev counts); this mutant prints on the container's real /dev 'accelerator: present (/dev/core /dev/fd /dev/full /dev/mqueue /dev/null ...)', so a probe that claims an accelerator on every real host passes every check; (2) acc_drop_dri_nodes: line 68 without $dri_nodes; a dev dir with dri/renderD128 then reads 'accelerator: none (no device)'; (3) acc_dri_dir_misnamed: line 63 reading "$DEV_DIR/drm". The suite's six matches of 'dri' are the words 'driven' and 'driver'. The pristine probe was restored and re-run 115/115 after the matrix.
fix: Add fixtures and checks, each tagged AVE-REQ-094 AC-1: a dev dir with ordinary entries (null, sda, a directory shm) and no nvidia-smi -> exactly 'accelerator: none (no device)'; a dev dir with nvidiactl, nvidia-uvm and a directory nvidia-caps plus a fake nvidia-smi answering 'No devices were found' with exit 6 -> none; a dev dir with dri/renderD128 -> present naming that node; nvidia0 plus dri/renderD128 -> present naming both; dri/card0 with dri/by-path only -> the verdict the requirement states; an exit-0 nvidia-smi answer with one comma and no memory figure -> none; a GPU name holding a comma -> that row. Rerun the three mutants above and a mutant that drops the memory test of the row: each must fail the suite. Name the new scenarios in § Verification strategy.
```

### Non-blocking findings (9)

1.

```text
location: docs/workflows/ave-req-094-probe-evidence-wf_d57d9cab-829.js:19 and docs/workflows/m0-fix-tracks-wf_164de68e-23b.js:25
defect: The redaction placeholder '<the session's Co-Authored-By and Claude-Session trailer lines>' holds an apostrophe inside a single-quoted string, so the persisted copy of the run AC-2 cites is no valid script as stored.
evidence: node --check on the copy wrapped in an async function: 'SyntaxError: Unexpected identifier' at line 19 (and line 25 of the other file); the other 12 copies parse. The run itself completed (commits 49ecb21, fcd97f0, handbacks), so AC-3 stands.
fix: Write the placeholder without an apostrophe or in a template literal (const TRAILERS = `<session trailer lines, redacted>`) in both copies.
```

2.

```text
location: docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:12 and :63
defect: The dependency AVE-REQ-093 has status in-progress; verify-requirement § 9 expects every dependency done before this requirement moves to done.
evidence: grep '^status:' docs/requirements/AVE-REQ-093-*.md -> 'status: in-progress' at eb73896.
fix: Move AVE-REQ-094 to done only after AVE-REQ-093 is done, or log the reason for another order in the Status log.
```

3.

```text
location: docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:68-69
defect: The AC-3 and AC-4 strategy lines state what is inspected and omit the reason automation is impractical, which docs/requirements/README.md asks of every inspection level.
evidence: AC-1 ('observations a shell cannot make') and AC-2 ('only a run of the real runtime can show this') carry a reason; AC-3 and AC-4 carry none.
fix: Add one clause each, for example AC-3: the workflow runtime is reachable only from a session, so no repository check can execute a script; AC-4: the fallback is a documented procedure with one recorded occurrence, no code path.
```

4.

```text
location: scripts/probe-environment.sh:103 and scripts/tests/test-probe-environment.sh:411-418
defect: The chromium-browser binary has no check; the strategy names only the fake chromium and google-chrome.
evidence: Mutation 'for browser in chromium google-chrome' survived 115/115.
fix: Add a fake chromium-browser to the fakes scenario, or name the line as uncompared in § Verification strategy.
```

5.

```text
location: scripts/probe-environment.sh:123 and scripts/tests/test-probe-environment.sh:279-285
defect: The suite does not pin the four credential variable names; only HF_TOKEN (set) and ANTHROPIC_API_KEY (unset) are checked by name.
evidence: Mutation dropping OPENAI_BASE_URL from the list survived 115/115.
fix: Check that the section holds exactly the four names of .env.example, and that OPENAI_API_KEY and OPENAI_BASE_URL read set in the network scenarios where they are set.
```

6.

```text
location: scripts/probe-environment.sh:55
defect: nvidia-smi runs without a time limit; a driver query that hangs blocks the probe and the resume step that runs it.
evidence: Code reading: every curl call carries -m 10, the nvidia-smi call carries none.
fix: Run it as timeout 10 nvidia-smi ... where timeout exists; a timeout is a failure and leaves the verdict to the device nodes. Add a check with a fake that sleeps.
```

7.

```text
location: docs/ENVIRONMENT_CAPABILITIES.md:24 and :130
defect: The disk rows say 16 GiB free on 2026-10-06; the live probe and df on the host read 5.1G free of 237G (98 % used) during this review.
evidence: Live probe at 2026-10-06T04:20Z: 'disk (repository) 5.1G free of 237G'; df -h /c after the clone was removed: 5.1G available.
fix: Re-measure and update both rows; free space before further reviewer clones and release-tier runs start (each clone gets a backend environment on the state volume).
```

8.

```text
location: docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:66
defect: The list of uncompared lines in § Verification strategy omits the report's timestamp header and the docker daemon line.
evidence: Probe lines 35 and 98 against the sentence 'The probe also prints ... the suite compares none of them'.
fix: Add both to that sentence.
```

9.

```text
location: docs/ENVIRONMENT_CAPABILITIES.md:109
defect: The Browser tools row is only partly observable from a workflow agent: the reviewer harness shows the computer-use connector and the Chrome-extension connector as deferred tools needing the user's grants, which agrees with the row; the built-in browser pane is outside a reviewer's tool list (Read, Grep, Glob, Bash) and stays the lead's observation of 97a8d20.
evidence: This session's tool list and server instructions.
fix: None needed; keep 'session tool list 2026-10-03' as the lead-session source in the row, as it stands.
```

### Test quality

```text
AC-1, line by line (compared = the suite checks it against its own measurement or a fixture; mutation result from my 67-mutant matrix; strategy = what § Verification strategy says):
- cpus: compared (host getconf and fake getconf=3); fixed-to-host and nproc mutants killed; strategy: compared.
- cpu model: compared (cpuinfo fixture, lscpu fixture, '-' -> unknown); 4 mutants killed; strategy: compared.
- memory: compared (own integer oracle and meminfo fixture 2883584 kB -> 2.8 GiB); 4 mutants killed; strategy: compared.
- disk (repository): compared (own df read before and after, fake df that answers per directory); 3 mutants killed; strategy: compared.
- nvidia-smi line: compared (not installed, no GPU reported, first GPU row); 5 mutants killed; strategy: compared.
- accelerator verdict: compared; 7 mutants killed, 3 survive (dri nodes dropped, dri directory misnamed, every /dev entry counted) -> blocking finding 2; strategy: compared.
- /dev/nvidia* and /dev/dri lists, kernel, os, hwaccels, hw encoders, libx264/aac, filters, node, pnpm, docker: uncompared; mutants of four of them survive as the strategy states (inspection of the live run); the live values agree with docs/ENVIRONMENT_CAPABILITIES.md (Ubuntu 24.04.5, kernel 6.18 WSL 2 aarch64, NVENC and VAAPI encoders listed only, rubberband and soxr, Node 18.19.1, pnpm and docker absent).
- ffmpeg, ffprobe, python3, uv, git: compared (real tool, hidden from PATH, fake first on PATH); all mutants killed.
- PLAYWRIGHT_BROWSERS_PATH, playwright browsers, chromium, google-chrome: compared, mutants killed; chromium-browser unchecked (non-blocking).
- worktrees, branch: compared (repository and a three-worktree fixture); fixed and cwd mutants killed.
- claude, os user, repository writable: compared (fake claude, fake id, AVE_PROBE_ROOT existing and missing); all mutants killed.
- credential variables: set, unset and no value printed are checked; the list of names is unpinned (non-blocking).
- Network (skipped offline, curl not installed, seven host lines): compared through the fake curl; all 10 mutants killed.
Checklist: assertion strength, independent oracles (no value read from the probe's output), real unit under test (only external commands faked through PATH), execution (115 checks listed, none skipped), tags (16 'AVE-REQ-094 AC-1' lines), determinism (four pristine runs on the repository and two in the /tmp clone, all 115/115; the earlier load-sensitive check did not recur) hold. 'Fails without the behavior' fails for the accelerator verdict's device-node inputs, and 'own constructions' exposed the false 'present' cases of blocking finding 1.
AC-1 inspections performed: .claude/settings.json holds the SessionStart and Stop hooks, the allow and deny lists as the Permissions row says (deny rule Bash(git push --force *) present), no sandbox key, worktree.baseRef head; .claude/settings.local.json is absent; the refused attempt 'git push --force --dry-run origin HEAD:refs/heads/permission-probe' is recorded in docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-3.md (lines 21-23, 40, 159); check 12 of scripts/check-project-control.sh rejects bypassPermissions, dontAsk and async hooks; the stop-hook (72) and session-start (31) suites pass; this session is a workflow agent whose system prompt equals .claude/agents/reviewer.md (workflow tool, subagents, custom agents); the main checkout lists the worktree ave-req-094-probe-evidence on its own branch; claude --version on the host prints 2.1.282; the Models row is backed by the probe stage in docs/workflows/m0-fix-tracks-wf_164de68e-23b.js, the model is named only in the session's system context, and git grep finds no model identifier in repository files; Browser tools row: the two connectors agree with this harness, the browser pane is the lead's observation.
AC-2, AC-3, AC-4: inspection only, as § Verification strategy states; no tagged test is expected. The inspected artifacts exist and agree with the claims (rows above). Gap: run IDs are session data a reviewer cannot query; the commits, handbacks and this run corroborate them.
AT-29 and AT-30 (final review): nothing contradicts AT-29. For AT-30 ('no fake platform capability') the false 'present' paths of blocking finding 1 would contradict the scenario on a host with driver control nodes or a display-only DRI node; the capability report of the current environment is correct (accelerator: none).
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
