# Handback — AVE-REQ-094 probe evidence, part 6: review at d4147d8

Run `wf_7d9d015c-906` ([script](../../workflows/verify-m0-final-wf_7d9d015c-906.js)), the final review round of M0 launched 2026-10-06: `verify-requirement` for AVE-REQ-094 at `d4147d8` by an independent reviewer in a private clone. The report is the reviewer's, unedited apart from local paths. The run had no brief of its own ([WF-008](../../WORKFLOW_LOG.md)); the report is filed with the brief whose work it reviews. The fixes follow in [the fix brief](../2026-10-06-m0-final-review-fixes.md).

## Review

Verdict: **FAIL** — AVE-REQ-094 — Capability-aware native dynamic workflows (reviewed at d4147d8, task branch ave-req-094-probe-evidence; private clone, removed after the review)

### AC-1 — FAIL

```text
What holds: release tier PASS 13 of 13 steps at d4147d8 (manifest var/verify/runs/20261006T073658Z-9, FRESH; evidence.py credits AC-1 through scripts/tests/test-probe-environment.sh, 133 checks). The suite ran three more times in a row, 133/133 each with identical check lists. Live probe: accelerator: none (no device); the seven Network lines read HTTP 200, 404, 200, 200, 200, 404, 421, equal to the § Network policy rows. Both blocking findings of handback part 5 are closed by their written reproductions: control nodes with and without a nvidia-smi answering 'No devices were found' (exit 6), directory nvidia-caps, file nvidia-readme.txt, dri/by-path, dri/card0, a device directory named nvidia-empty and the three one-comma answers all read none, 'Acme GPU, Model X, 8192 MiB' reads present; the three surviving mutants of part 5 (every /dev entry counts, render nodes dropped, dri misnamed) and the dropped memory test each fail the suite now. The four host-value lines stay proven by fixtures. The inspections of the Claude Code rows pass (Test quality). What fails: the node rule of the accelerator verdict is not the rule the requirement states. scripts/probe-environment.sh:79-80 counts every entry that is no directory and whose name starts with nvidia<digit> or renderD<digit>. Measured with the pristine probe: files nvidia0.txt, nvidia0-readme.txt, nvidia3d-vision.conf, dri/renderD128.bak and dri/renderD1-notes, and a FIFO, a dangling symbolic link and a block device named nvidia0 each print 'accelerator: present (...)' with no nvidia-smi and no GPU device. § Edge cases (lines 42-47) states that every entry other than a per-GPU node /dev/nvidia<N> and a render node /dev/dri/renderD<N> never enters the verdict and that the probe prints none whenever no GPU device node exists; § Implementation evidence (line 82) repeats it. The suite cannot tell the stated rule from the implemented one: eight mutants of the node rule pass 133/133, and the mutant that counts character devices only fails it (blocking finding 1).
```

### AC-2 — PASS

```text
Inspection. docs/workflows/ave-req-094-probe-evidence-wf_d57d9cab-829.js composes parallel([researcher, tester]) → implementer(research, tests) → reviewer → skeptic on PASS. Every agent() call carries a JSON schema (RESEARCH, HANDBACK, REPORT, CHALLENGE) as the structured handoff, the implementer prompt embeds both results, and the script stops before implementation when the tester is blocked and before review when no commit exists. The brief docs/briefs/2026-10-03-ave-req-094-probe-evidence.md names the parts, allowed and forbidden paths and the handback schema; handbacks parts 1 to 5 exist under docs/briefs/handbacks/. Commit times (UTC, 2026-10-03) match the declared dependency order: brief 4e607de 04:47:57, script 0bd46d9 04:48:47, research handback 08237ac 05:14:06, tester 49ecb21 05:23:23 (suite and handback only), implementer fcd97f0 06:11:08, review and challenge bb94bf7 07:16:19. Part 3's 'Inputs checked' records the reproduction of part 1's request form and part 2's 7 failing checks. The earlier runs the strategy cites have scripts and existing commits (wf_5493b930-f7c with two parallel writers, 486b3a0 and 24499a6; wf_1a23bf0d-2a0 with three lenses). docs/workflows/README.md holds a row per run. First-hand: this review is an agent of a workflow run whose output schema equals the REPORT schema of the persisted verify scripts.
```

### AC-3 — PASS

```text
Inspection. The 14 scripts in docs/workflows/ call only agent(), parallel(), pipeline(), phase() and log() and read args and meta (grep over every call: no import, require, file, process or network API). Each copy parses as stored: node --check on each copy wrapped in an async function, Node 18.19.1 in the container, 14 of 14 (the two copies that failed to parse at eb73896 parse now). Each README row names a run with its recorded outcome, interrupted runs included, and the cited commits exist. First-hand: the harness states that this session runs inside a workflow script; its StructuredOutput schema equals REPORT in docs/workflows/verify-094-repaired-wf_7d239bd1-b31.js down to the description text of test_evidence_lines, and its system prompt and tool list equal .claude/agents/reviewer.md, so agent(prompt, {schema, agentType}) exists in the installed runtime. Feature claims in docs/ENVIRONMENT_CAPABILITIES.md are tied to runs or session observations. The strategy line states why inspection (the runtime is reachable only from a session).
```

### AC-4 — PASS

```text
Inspection. CLAUDE.md § Delegation line 119 (sequential lifecycle; review in a fresh session recorded as a sequential review; the requirement stays verification until it is recorded), .claude/skills/develop/SKILL.md § 6 step 3 (line 146, the same rule with the Status-log note) and .claude/skills/ai-video-editor-delivery/SKILL.md steps 3 and 6 (lines 16 and 19: 'Never invent workflow APIs', the fallback review). docs/WORKFLOW_LOG.md WF-002 records a real fallback: a delegated agent stopped at the account limit, the lead completed items 1 to 9 sequentially (commit 90a1f2e exists) and the result went through independent review again. No orchestration platform exists: git ls-files holds verification tooling under scripts/ (verify, evidence, probe, checkers, dev-container, suites) and the editor's backend (domain, media, render, sync); no scheduler, queue or agent runner. The strategy line states why inspection (a documented procedure with recorded occurrences, no code path).
```

### Verification runs

```text
- git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/verify-ave-req-094 && git checkout -q d4147d8 — clone at d4147d8, clean tree; git status --porcelain was empty before every run reported here and at the end.
- ./scripts/verify.sh --tier release (once; development container, arm64) — PASS, 13 of 13 steps: project control files, baseline integrity, evidence tooling unit tests, backend format, lint, type check, unit tests (124 passed), media and population tests (84 passed, 328 s), tooling suites (checker 822, check-baseline 213, stop-hook 98, session-start 31, verify-tiers 48, probe 133 checks; 'scripts/tests/run.sh: PASS (6 suites)'), done requirements evidenced, working tree unchanged, evidence manifest /workspace/var/verify/runs/20261006T073658Z-9/manifest.json (58 criteria tagged). Log: <session scratchpad>\release-094.log
- ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-094 --require-fresh --tier release — exit 0: 'tier release, PASS, commit d4147d88319e, recorded 2026-10-06T07:49:48Z', 'FRESH — the tree and the toolchain are unchanged since this run'; AC-1 passed (1 result: scripts/tests/test-probe-environment.sh); AC-2, AC-3, AC-4 missing (inspection criteria, as § Verification strategy states).
- ./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh, three runs in a row — exit 0 each, 'PROBE TOTAL: pass=133 fail=0', 133 ok lines and 0 FAIL lines, 17 s each; the three check lists are identical after replacing the temp directory name: no check changed its result. Logs: ...\scratchpad\r094\suite-1.log to suite-3.log
- ./scripts/dev-container.sh ./scripts/probe-environment.sh (live, 4 s, 2026-10-06T07:51:31Z) — exit 0: kernel Linux 6.18.33.2-microsoft-standard-WSL2 aarch64, Ubuntu 24.04.5 LTS, cpus 8, cpu model unknown, memory 7.5 GiB, disk 5.3G free of 237G, nvidia-smi not installed, both device lists none, accelerator: none (no device); ffmpeg and ffprobe 6.1.1-3ubuntu5, Python 3.12.3, uv 0.8.17, node v18.19.1, pnpm and docker not installed, git 2.55.0; claude not installed, os user root (uid 0), repository writable yes (/workspace); four credential variables unset; Network: pypi.org/simple/ HTTP 200, files.pythonhosted.org/ HTTP 404, registry.npmjs.org/ HTTP 200, github.com/ HTTP 200, huggingface.co/api/models?limit=1 HTTP 200, api.anthropic.com/ HTTP 404, api.openai.com/ HTTP 421. Every value agrees with docs/ENVIRONMENT_CAPABILITIES.md.
- Reproduction of handback part 5, blocking finding 1 (pristine probe --offline in the container, fake nvidia-smi first on PATH, AVE_PROBE_DEV_DIR on fixture directories) — (a) nvidiactl, nvidia-uvm, nvidia-uvm-tools with nvidia-smi 'No devices were found' exit 6: 'nvidia-smi no GPU reported', 'accelerator: none (no device)'; the same without nvidia-smi: none. (b) directory nvidia-caps, file nvidia-readme.txt, directory dri/by-path, empty device directories named nvidia-empty and nvidia0: none. (c) dri/card0 alone: none. (d) exit 0 with 'Sorry, no GPU is attached to this machine', 'name, memory.total [MiB]', '[N/A], [N/A]': none; 'Acme GPU, Model X, 8192 MiB': present with that row. The skeptic's probes of part 4 (driver diagnostic exit 9, empty answer exit 0, GPU row with exit 1: none; 'Tesla T4, 15360 MiB' exit 0: present) and the controls (real /dev, missing device directory, null/sda/shm, NVIDIA_VISIBLE_DEVICES=all CUDA_VISIBLE_DEVICES=0, empty AVE_PROBE_DEV_DIR) read correctly. All closed.
- Mutation matrix in the container (git clone /workspace /tmp/m at d4147d8, which holds scripts/ and .env.example; unmutated suite there 133/133 before each batch; each mutant an exact single-match replacement in /tmp/m/scripts/probe-environment.sh; pristine restored, compared byte for byte with the tree and rerun 133/133 after each batch) — 125 mutants, 103 killed, 22 survived, 0 not applied. Handback part 5, blocking finding 2, by its reproduction: every /dev entry counts (with and without directories), render nodes dropped from the evidence, dri read as drm, and the dropped memory test of the row (two forms): each killed. Survivors: 7 on lines the strategy names uncompared (kernel, os, node, pnpm, docker, hwaccels, header time); 3 equivalent or allowed by the strategy (AVE_PROBE_SMI_TIMEOUT ignored with the default 10 s kept, a timed-out query treated as an empty success, a ranged GET -r 0-0); 8 on the node rule of the verdict (names filtered to exactly nvidia<digits>, names filtered to exactly renderD<digits>, -name 'nvidia[0-9]', -name 'nvidia0', -name 'renderD128', -name 'r*' in dri, -type f for the nvidia find, -type f for the dri find); 4 on the nvidia-smi row (any text after the digits of the memory field, stderr merged into the answer, only the first answer line examined, default limit 600 s). The mutant -type c for the nvidia find (character devices only) is killed with 4 failed checks, first 'device node present: accelerator verdict names it'.
- Accelerator constructions of my own (pristine probe --offline, container) — entries that are no GPU node and read 'accelerator: present (<path>)': files nvidia0.txt, nvidia0-readme.txt, nvidia3d-vision.conf, dri/renderD128.bak, dri/renderD1-notes; under the name nvidia0 a FIFO, a dangling symbolic link, a symbolic link to a directory, a block device (mknod b 7 0) and a regular file; a dangling link dri/renderD128. Reading correctly: character devices nvidia0 (195,0), nvidia1, nvidia12, dri/renderD129 → present; character devices nvidiactl and nvidia-uvm alone, dri/card1, dri/controlD64, a directory dri/renderD128, a file dri/renderD, dri as a regular file → none. nvidia-smi answers with exit 0: 'Unable to use 0 GPUs, need 16 MiB', ', 16 MiB', 'Tesla T4, 15360MiB', a trailing space, a CRLF row, 'NVIDIA Jetson, [N/A]', a row on stderr only → none; 'Tesla T4, 0 MiB', a header line then a row, a warning line then a row → present with the row; the probe calls nvidia-smi with '--query-gpu=name,memory.total --format=csv,noheader'. A fake that sleeps 30 s is cut off after 10 s with the default limit; a fake that ignores SIGTERM ran 51 s with AVE_PROBE_SMI_TIMEOUT=1.
- Access construction (container) — a character device dri/renderD128 (226,128) with mode 0600 root:root, probed through setpriv as uid 65534: 'os user nobody (uid 65534)', 'accelerator: present (/tmp/acc094c/dri/renderD128)', while [ -r ] and [ -w ] on the node are false and opening it fails with 'Permission denied'.
- Candidate fix checked without privileges (container) — with symbolic links to /dev/null as node fixtures, a rule 'character device and name exactly nvidia<digits> or renderD<digits>' counts nvidia0, nvidia10 and dri/renderD128 and ignores a regular file, a FIFO, a dangling link, a directory, nvidia0.txt and dri/renderD128.bak; find -L <dir> -mindepth 1 -maxdepth 1 -type c -name 'nvidia[0-9]*' | grep -E '/nvidia[0-9]+$' prints the two nodes.
- node --check on each script of docs/workflows/ wrapped in an async function (container, Node 18.19.1) — 14 of 14 parse.
- Inspection commands — .claude/settings.json read (SessionStart and Stop hooks, allow and deny lists with Bash(git push --force *), worktree.baseRef head, no sandbox key); claude --version on the host: '2.1.282 (Claude Code)'; git worktree list in the main checkout: the worktree .claude/worktrees/ave-req-094-probe-evidence on its own branch at 8dd0004 (one commit after d4147d8, docs/ASSUMPTIONS.md only); .claude/settings.local.json absent; git grep for model identifiers outside the baseline: none (codec names only); commits 4e607de, 0bd46d9, 08237ac, 49ecb21, fcd97f0, bb94bf7, 486b3a0, 24499a6, 97a8d20, 90a1f2e, 6160278 exist; AVE-REQ-093 frontmatter status in-progress; TRACEABILITY.md row status verification; date -u +%F: 2026-10-06.
- ./scripts/dev-container.sh --stop (state absent afterwards) and rm -rf .claude/worktrees/verify-ave-req-094 — done; the main checkout is clean at 547754e and was never written. The harness and tables of the mutation runs: ...\scratchpad\r094\mut.py, table.txt, table-b2.txt; the result logs lived in the container's /tmp and went with it.
```

### Blocking findings (1)

1.

```text
location: scripts/probe-environment.sh:79-80 (task branch worktree: scripts\probe-environment.sh); docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:42-47 and :82; scripts/tests/test-probe-environment.sh:228, :292, :330-358
defect: AC-1, accelerator access: the node rule of the verdict is not the rule the requirement states, and the suite cannot tell the two apart. The probe counts every entry that is no directory and whose name starts with nvidia<digit> or renderD<digit> (find ... ! -type d -name 'nvidia[0-9]*' and 'renderD[0-9]*'). § Edge cases states 'only GPU devices count: a per-GPU node /dev/nvidia<N> and a render node /dev/dri/renderD<N> ... every other entry are listed on the device lines and never enter the verdict' and 'the probe prints accelerator: none (no device) whenever no GPU device node exists and nvidia-smi reports no GPU'; § Implementation evidence repeats the rule ('accelerator verdict from GPU device nodes'). Both statements are false at d4147d8 for entries that are no GPU device node. The repair closed the names the last review used (nvidia-readme.txt, nvidiactl, nvidia-caps, card0, by-path) and left their class open.
evidence: Pristine probe at d4147d8, --offline, in the container, AVE_PROBE_DEV_DIR on fixture directories, no nvidia-smi on PATH. Names: a file nvidia0.txt → 'accelerator: present (/tmp/acc094b/n1/nvidia0.txt)'; nvidia0-readme.txt → present; nvidia3d-vision.conf → present; dri/renderD128.bak → present; dri/renderD1-notes → present; the suite's own case nvidia-readme.txt → none. File types under the exact name nvidia0: FIFO → present; dangling symbolic link → present; symbolic link to a directory → present; block device → present; regular file → present; a dangling link dri/renderD128 → present. Suite side, mutants in a clone at /tmp/m inside the container (unmutated 133/133), each printing 'PROBE TOTAL: pass=133 fail=0': the stated rule itself (find output filtered by grep -E '/nvidia[0-9]+$', and by '/renderD[0-9]+$'); -name 'nvidia[0-9]' (one digit); -name 'nvidia0' and -name 'renderD128' (the two fixture names only; a container that is given GPU 1 alone holds /dev/nvidia1, and the pristine probe reads present for a character device nvidia1, nvidia12 or dri/renderD129, which no check shows); -name 'r*' in dri; -type f for either find (regular files only, so no real device node counts and the verdict reads none on every host whose GPU shows as a node). The mutant -type c (character devices only, the literal reading of 'only GPU devices count') fails 4 checks, first 'device node present: accelerator verdict names it': every node fixture of the suite is a regular file made with ': >', so the suite asserts present for a regular file named nvidia0. Weight: I know no stock driver that creates the suffixed names (nodes I know: nvidia<N>, nvidiactl, nvidia-uvm*, nvidia-modeset, nvidia-caps, card<N>, renderD<N>, controlD<N>, by-path; domain knowledge, not measured here), and the verdict of the current environment (none) is right. The finding is the false statement of the requirement file and the unpinned rule, the class of case (b) in handback part 5.
fix: In scripts/probe-environment.sh count an entry only when it is a character device and its whole name is nvidia<digits> or renderD<digits>, for example gpu_nodes from find -L "$DEV_DIR" -mindepth 1 -maxdepth 1 -type c -name 'nvidia[0-9]*' 2>/dev/null | grep -E '/nvidia[0-9]+$' | sort, and render_nodes the same way under "$DEV_DIR/dri" with '/renderD[0-9]+$'. Build the suite's node fixtures as symbolic links to /dev/null: a character device that needs no privilege (checked in the container: nvidia0, nvidia10 and dri/renderD128 count; a regular file, a FIFO, a dangling link, a directory, nvidia0.txt and dri/renderD128.bak do not). Add checks tagged AVE-REQ-094 AC-1: nvidia0.txt, nvidia3d-vision.conf, dri/renderD128.bak, a regular file named nvidia0 and a FIFO named nvidia0 → exactly 'accelerator: none (no device)'; nvidia1 alone, nvidia10 alone and dri/renderD129 alone → present naming the node. Rerun the eight surviving mutants of the node rule: each must fail. Then align § Edge cases, § Verification strategy and § Implementation evidence, the GPU row of docs/ENVIRONMENT_CAPABILITIES.md and ASM-015. Alternative when the lead keeps the name rule: state it as implemented in those sections (an entry that is no directory and whose name starts with nvidia<digit> or renderD<digit>; a regular file counts) and withdraw 'only GPU devices count' and 'every other entry'; the fixtures for other numbers and for a node that is no regular file are needed either way.
```

### Non-blocking findings (7)

1.

```text
location: docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:12 and :71
defect: The dependency AVE-REQ-093 has status in-progress at d4147d8; verify-requirement § 9 expects every dependency done.
evidence: grep '^status:' docs/requirements/AVE-REQ-093-*.md → 'status: in-progress'.
fix: The lead moves AVE-REQ-093 to done first, as planned, then AVE-REQ-094.
```

2.

```text
location: scripts/probe-environment.sh:85-90; docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:53-55; docs/ENVIRONMENT_CAPABILITIES.md:30
defect: Judgment on the stated limit against the criterion's words 'accelerator access': the verdict proves that a device node exists (or that nvidia-smi listed a GPU), which is less than access. For a render node of a software or virtual DRM driver the requirement, the GPU row and ASM-015 say so, the requirement that uses the device measures function, and the verdict of the current environment is none: I do not hold that limit against AC-1. Two gaps remain: the output itself says 'accelerator: present', the stronger claim, and the limit as written covers the driver only, while a node the probing user cannot open also reads present.
evidence: Container: a character device dri/renderD128 (226,128), mode 0600 root:root, probed as uid 65534 → 'accelerator: present (/tmp/acc094c/dri/renderD128)'; [ -r ] and [ -w ] on the node are false and opening it fails with 'Permission denied'. A Linux user outside the render group is in this position on an ordinary desktop or build host (domain knowledge). On such a host the capability report would contradict AT-30's 'no fake platform capability'.
fix: Test [ -r "$node" ] && [ -w "$node" ] for each counted node and print the state (present, or a node without access), or word the verdict by what it measures ('accelerator: device node present (...)'). Extend the Edge-case line and the GPU row to the access case, with a check that runs the probe on a node made unreadable (a symbolic link to a mode-000 file serves without privilege when the suite does not run as root).
```

3.

```text
location: scripts/tests/test-probe-environment.sh:295-369; scripts/probe-environment.sh:55-68
defect: Four mutants of the nvidia-smi row, a part of the compared verdict, pass the suite: the unit of the memory field, the stream, the position of the row and the default time limit are unpinned.
evidence: Each 133/133 in /tmp/m: row regex '^.*[^,[:space:]].*,[[:space:]]*[0-9]+.*$' (any text after the digits, so '<text>, 3 errors' would count); smi_query 2>&1 for 2>/dev/null (a row on stderr would count); 'head -n 1 | grep ...' (only the first answer line; the pristine probe reads present for a warning line followed by a row, which no check shows); ${AVE_PROBE_SMI_TIMEOUT:-600} (the suite sets the limit to 1 s, so the 10 s of § Edge cases is never observed; I measured 10 s on the pristine probe with a fake that sleeps 30 s).
fix: Add cases tagged AVE-REQ-094 AC-1: exit 0 with 'GPU 0 failed, 3 errors' → none; a row written to stderr only → none; a non-row line before a row → present naming the row; and pin the default limit with a fake timeout first on PATH that records its first argument (10) and then runs the command.
```

4.

```text
location: scripts/probe-environment.sh:56-60
defect: The time limit of the nvidia-smi query holds only for a process that ends on SIGTERM, and only where a timeout command exists.
evidence: A fake nvidia-smi that ignores SIGTERM ran 51 s with AVE_PROBE_SMI_TIMEOUT=1 (the verdict was none afterwards); the else branch of smi_query runs nvidia-smi without any limit. § Edge cases says the answer counts only 'within its time limit (10 s)'.
fix: Use timeout -k 2 "${AVE_PROBE_SMI_TIMEOUT:-10}" nvidia-smi ...; state in § Edge cases that a host without timeout runs the query unbounded, or report 'no GPU reported (timeout unavailable)' there.
```

5.

```text
location: docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:74 and :44-47
defect: § Verification strategy names the two device-list lines ('/dev/nvidia* devices', '/dev/dri devices'), the nvidia-smi line and the section headings in neither list (compared, or uncompared and inspected), although the suite compares them. The Edge-case sentence says every other entry is 'listed on the device lines'; null and sda are neither listed nor counted.
evidence: Checks at scripts/tests/test-probe-environment.sh:250, :269, :342, :344, :350, :352, :354; six mutants of the list lines and the heading mutant are killed. Fixture dev-plain prints both list lines as none.
fix: Name the list lines, the nvidia-smi line and the headings among the compared lines; word the Edge-case sentence as 'entries named nvidia* and the entries of dri are listed; no other entry is listed or counted'.
```

6.

```text
location: docs/ASSUMPTIONS.md:243-250 (ASM-015)
defect: At d4147d8 ASM-015 still states the rule of eb73896 (device nodes 'nvidia*', 'dri'), which disagrees with the probe of the same commit.
evidence: git show d4147d8:docs/ASSUMPTIONS.md lines 245-246; the task branch corrects it one commit later (8dd0004, docs/ASSUMPTIONS.md only).
fix: Have the next review start from a commit that includes 8dd0004, and update ASM-015 again with the repair of blocking finding 1.
```

7.

```text
location: docs/ASSUMPTIONS.md:107-116 (ASM-006), cited at docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md:87
defect: ASM-006, cited under Decisions, still describes the earlier cloud container ('no Hugging Face access', status confirmed 2026-10-01); on this host the probe and § Network policy read huggingface.co HTTP 200.
evidence: Live probe 2026-10-06T07:51:31Z: 'huggingface.co/api/models?limit=1 HTTP 200'; docs/ENVIRONMENT_CAPABILITIES.md:76.
fix: Add a dated note to ASM-006 (Hugging Face reachable anonymously since the move to the laptop; CI and verify.sh stay offline for models), or supersede it.
```

### Test quality

```text
AC-1, line by line (compared = the suite checks the line against a value it measures itself or drives through a fixture; mutants from my matrix of 125 in /tmp/m: 103 killed, 22 survived; strategy = what § Verification strategy says):
- Header with the run time, kernel, os, hwaccels, hw encoders, libx264/aac, filters, node, pnpm, docker, docker daemon: uncompared and named so in the strategy; the seven mutants of these lines survive as stated; the live values agree with docs/ENVIRONMENT_CAPABILITIES.md.
- Nine section headings: compared (heading removed: killed); the strategy does not name them.
- cpus: compared (host getconf and a fake getconf answering 3); fixed-to-host and nproc killed. Strategy: compared.
- cpu model: compared (cpuinfo fixture, lscpu fixture, '-' reads unknown); 4 killed. Strategy: compared.
- memory: compared (the suite's own integer oracle and the meminfo fixture, 2.8 GiB); 5 killed. Strategy: compared.
- disk (repository): compared (own df read before and after, a fake df that answers per directory); 4 killed. Strategy: compared.
- nvidia-smi line: compared (not installed, no GPU reported, first GPU row); 11 killed; 4 survive (unit of the memory field, stderr, first line only, default limit: non-blocking finding 3).
- /dev/nvidia* devices and /dev/dri devices: compared (none; control nodes listed; card0 and by-path listed); 6 killed. The strategy names them in neither list (non-blocking finding 5).
- accelerator verdict: compared; 21 killed, among them the three survivors of handback part 5 and both forms of the dropped memory test; 8 survive, all on the node rule, and the character-devices-only mutant is killed (blocking finding 1). Strategy: compared.
- ffmpeg, ffprobe, python3, uv, git: compared (real tool, hidden from PATH, fake first on PATH); 9 killed.
- PLAYWRIGHT_BROWSERS_PATH, chromium, chromium-browser, google-chrome, playwright browsers: compared; 7 killed (the chromium-browser gap of part 5 is closed).
- worktrees, branch: compared (the repository and a fixture with three worktrees); 5 killed.
- claude, os user, repository writable: compared (fake claude, fake id, AVE_PROBE_ROOT existing and missing); 8 killed.
- Four credential lines: compared (set, unset, no value printed, the exact name list against .env.example); 7 killed (the gap of part 5 is closed).
- Network (probes line, seven host lines): compared through the fake curl; 13 killed, with the unknown-option exit; a ranged GET survives because the strategy counts a bounded range as no body.
Checklist of § 8: assertion strength holds (exact lines); oracles are independent (getconf, /proc/meminfo with the suite's own arithmetic, df, each tool's own version output, git, .env.example; no expected value is read from the probe's output); the unit under test is the real script, with only external commands and the documented test inputs replaced; the suite executed in the release run (133 checks listed, none skipped; evidence.py credits AC-1); it carries '# AVE-REQ-094 AC-1' tag lines; determinism holds (the release run, three runs in a row, two baselines and two restorations in /tmp/m, all 133/133; the hang check allows 20 s for a 1 s limit). 'Fails without the behavior' and 'own constructions' fail for the node rule of the verdict: the suite pins it at the names nvidia0 and renderD128 on regular files only.
AC-1 inspections performed: .claude/settings.json holds the SessionStart and Stop hooks, the allow and deny lists the Permissions row names (deny rule Bash(git push --force *) present), worktree.baseRef head and no sandbox key; .claude/settings.local.json is absent in the main checkout; the refused attempt 'git push --force --dry-run origin HEAD:refs/heads/permission-probe' is recorded in docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-3.md (item 3 and the verification list); I did not repeat it, since a review never pushes; the Stop hook runs the fast tier; the stop-hook (98) and session-start (31) suites pass; claude --version on the host prints 2.1.282, equal to the version row; this session is a workflow agent whose system prompt and tool list equal .claude/agents/reviewer.md (workflow tool, subagents, custom agents); the main checkout lists the worktree ave-req-094-probe-evidence on its own branch (worktree isolation); the Models row agrees with the session (the model is named only in my system context; git grep finds no model identifier in repository files; the override probe is the Probe stage of docs/workflows/m0-fix-tracks-wf_164de68e-23b.js, lines 207-218); the Browser tools row agrees with this harness for the computer-use and Chrome-extension connectors, which appear as deferred tools that need the user's grants; the built-in browser pane lies outside a reviewer's tool list and stays the lead's observation of 97a8d20. The Models row gives the mechanism and no model or alias name, which follows the project's rule that repository files name no model.
AC-2, AC-3, AC-4: inspection only, as § Verification strategy states with a reason on each line; no tagged test is expected. The inspected artifacts exist and agree with the claims. Limit: run IDs are session data a reviewer cannot query; commits, handbacks and this run corroborate them.
AT-29 and AT-30 (final review): nothing contradicts AT-29. For AT-30 ('no fake platform capability') the capability report of the current environment is correct (accelerator: none); the present verdicts of blocking finding 1 and of non-blocking finding 2 would contradict the scenario on a host that holds such an entry or a node without access.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
