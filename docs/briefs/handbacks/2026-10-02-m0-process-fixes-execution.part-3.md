# Handback — M0 process fixes, part 3 (checker, hooks and probe): items 3, 12, 13, 15, 22, 23, 24, 25

Brief: `docs/briefs/2026-10-02-m0-process-fixes-execution.md` (part 3) with the findings of
`docs/briefs/2026-10-02-m0-process-verification-fixes.md`. Branch `m0-process-fixes` (worktree
`.claude/worktrees/m0-process-fixes`), built on parts 1 (`fb61875`) and 2 (`3f7c44d`). Commit: the commit that
adds this file, subject "AVE-REQ-094, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098: measure permissions and models,
harden the checker, hooks and probe"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-3.md`).

Result: PARTIAL. Every item is done except one rule of item 15 (a commit in § Input revision), which the
forbidden paths block; see Open questions 1.

Mutations: `var/mutations/part3.py` (gitignored) applies each mutation to one file, deletes `__pycache__`
directories, runs one suite inside the development container, restores the file from its in-memory copy and
asserts the restored SHA-256 equals the original. `git diff` after the runs holds the intended change only.

## Items

### Item 3 — AVE-REQ-094 AC-1: permissions and models measured (done)
- Change: `docs/ENVIRONMENT_CAPABILITIES.md` § Claude Code capabilities — new **Permissions** row (permission
  mode; the allow and deny lists of `.claude/settings.json`; the deny rule `Bash(git push --force *)` enforced:
  this agent attempted `git push --force --dry-run origin HEAD:refs/heads/permission-probe` and the permission
  system refused it before it ran; launcher-level settings: none visible beyond `.claude/settings.json`,
  `.claude/settings.local.json` absent; no bypass, enforced by check 12 (item 23); host OS user without
  elevation (`id -G` on the host: no group 544), container root with the checkout writable (probe); no sandbox
  configured, network as in § Network policy) and new **Models** row (session model named only in the system
  context; subagents and workflow agents inherit it; Agent tool `model` override from a fixed tier-alias list;
  Workflow `agent()` `opts.model`; checked by the run of this workflow: an agent launched with an explicit
  override from the tier-alias list completed and returned its structured result). The old "Model" row is
  replaced. Intro paragraph names the new probe measurements. `scripts/probe-environment.sh` — new section
  "Claude Code and session": `claude --version` (or "not installed"), `os user` (`id -un`, uid), `repository
  writable` (yes/no and the root). AVE-REQ-094 § Verification strategy AC-1 names permissions and models;
  § Edge cases (no `claude` in the container; a deny rule recorded as enforced only after a refused attempt);
  § Implementation evidence.
- Test: `scripts/tests/test-probe-environment.sh` (`AVE-REQ-094 AC-1`): "claude absent from PATH: not
  installed", "claude on PATH: its version is reported" (fake `claude` printing `9.9.9 (Claude Code)`), "os
  user is the user running the probe" (equals `id -un` and `id -u`), "repository writability matches the file
  system (yes)" (equals `[ -w <repo> ]`). The rows themselves: inspection against the session.
- Mutation M4 (os user and writability lines removed): 2 FAIL (`os user …`, `repository writability …`).
- Session observations behind the row: the deny-rule attempt was refused ("Permission to use Bash with command
  … has been denied"); a later shell call measuring host network and writability was refused by the classifier
  with a stated reason, and this agent continued; host network and writability therefore come from § Network
  policy and the container probe.

### Item 12 — AVE-REQ-094 AC-1: the probe test asserts measurements (done)
- Change: `scripts/probe-environment.sh` — device nodes searched in `${AVE_PROBE_DEV_DIR:-/dev}`; empty device
  lists print "none"; a verdict line `accelerator: none (no device)` when no device node exists and
  `nvidia-smi` reports no GPU, else `accelerator: present (<GPU name and device nodes>)`; FFmpeg's built-in
  encoders never count.
- Test: `scripts/tests/test-probe-environment.sh` (`AVE-REQ-094 AC-1`) runs the probe with `nvidia-smi` and
  `claude` hidden from PATH (`path_without`, mirrors a PATH directory without them) and an empty device
  directory: "cpus equals getconf _NPROCESSORS_ONLN (8)", "memory is a GiB value", "disk reports free and
  total space", "no device, no nvidia-smi: nvidia-smi not installed", "no device, no nvidia-smi: accelerator:
  none (no device)", "exactly one accelerator verdict", "no line claims a GPU"; second run with a device node
  `nvidia0`: "device node present: accelerator verdict names it".
- Mutation M1 (the finding's probe: cpus, memory, disk and device-node lines removed, verdict replaced by
  `GPU available (h264_nvenc)`): 7 FAIL (cpus, memory, disk, `accelerator: none`, one verdict, no GPU claim,
  device present). Mutation M2 (verdict ignores device nodes): 1 FAIL ("device node present …").

### Item 13 — AVE-REQ-094: Claude Code version, resume re-probe, completed runs only (done)
- Change: `scripts/probe-environment.sh` reports `claude --version` (item 3). `docs/ENVIRONMENT_CAPABILITIES.md`
  version row: 2.1.282, measured with `claude --version` on the host on 2026-10-02 (equal to the lead's
  value; the container has no `claude`). Native dynamic workflows row cites the three completed runs with their
  results (`wf_5493b930-f7c`: 2 writers, integrated as `486b3a0`, `24499a6`; `wf_1a23bf0d-2a0`: PASS;
  `wf_b0c34bba-a20`: all five FAIL) and drops the uncited bootstrap count and the in-flight "M0 runs" claim.
  AVE-REQ-094 § Verification strategy AC-2 adds the results. `.claude/skills/resume-project/SKILL.md` step 6:
  "Environment" bullet — run `./scripts/probe-environment.sh --offline` (container form plus `claude --version`
  on the host when verification runs in the container), update the differing rows of
  ENVIRONMENT_CAPABILITIES.md with the date, commit `docs: re-measure the environment`.
- Test: probe cases of item 3; resume-project step: inspection.
- Mutation M3 (`version claude --version` removed): 2 FAIL ("claude absent …", "claude on PATH …").

### Item 15 — AVE-REQ-096 AC-1: check 11 covers every heading and the brief's structure (partial)
- Change: `scripts/check-project-control.sh` check 11 (`AWK_BRIEF`): every template heading present, once and
  in template order ("heading 'X' follows 'Y' …"), no empty section ("section 'X' is empty"), at least one
  `AVE-REQ-NNN` under Requirements; an H1 or another H2 ends a section, so an extra section after the template
  passes. Header comment. `docs/briefs/README.md` § Template states what check 11 enforces. AVE-REQ-096
  § Verification strategy AC-1, § Implementation evidence.
- Test: `scripts/tests/test-checker.sh` (`AVE-REQ-096 AC-1`): a loop over all seven headings with "brief
  without '<heading>'" and "brief with an empty '<heading>'" (14 cases), "brief headings out of order",
  "brief with a repeated heading", "brief requirements without an ID", "brief ID outside Requirements",
  "brief with an extra section after the template" (accepted), plus the existing "complete task brief
  accepted" and "brief heading only in a fence".
- Mutation M5 (the finding's mutation: `BRIEF_HEADINGS` reduced to Test commands and Handback schema): 14 FAIL
  (the ten missing/empty cases of the five other headings, order, repeat, both ID cases); the old suite passed
  this mutation. M6 (order check off): 2 FAIL (out of order, repeated heading). M7 (empty-section check off):
  7 FAIL (every "brief with an empty …" case). M8 (requirement-ID check off): 2 FAIL (both ID cases).
- Open: the rule "a 7–40-hex commit in Input revision" is not implemented (Open questions 1).

### Item 22 — AVE-REQ-097 AC-3: the Stop-gate tier check sees real steps (done)
- Change: `scripts/tests/test-stop-hook.sh` — the fixture's `scripts/verify.d/20-backend.sh` registers one
  marker step per tier (`Marker fast step`, `Marker media step`, `Marker release step`); the vacuous check is
  replaced by "gate ran the fast marker step" and "gate ran no media or release marker step". AVE-REQ-097
  § Verification strategy AC-3.
- Test: those two checks (`AVE-REQ-097 AC-3`, under `VERIFY_TIER=release`).
- Mutation M9 (`scripts/verify.sh`: `media_step` and `release_step` run in every tier): 1 FAIL ("gate ran no
  media or release marker step"); "gate ran the fast tier despite VERIFY_TIER=release" still passes under M9
  (the summary line names the fast tier), and so did the replaced check, whose step names the fixture never
  registers.

### Item 23 — AVE-REQ-098 AC-2, AC-4: settings policy (done)
- Change: `scripts/check-project-control.sh` check 12 (`check_settings_policy`, Python program
  `PY_SETTINGS_POLICY`; a warning without python3, like check 3): fails on `permissions.defaultMode`
  `bypassPermissions` or `dontAsk`; any `skip…PermissionPrompt` key set (`skipDangerousModePermissionPrompt`,
  `skipAutoPermissionPrompt`); a hook command containing `while true`/`while :`, `sleep`, `nohup`, `disown`,
  `setsid`, a background `&` (a single `&` outside `&&`, `>&`, `&>`, `|&`) or `--dangerously-skip-permissions`;
  no SessionStart hook running `.claude/hooks/session-start.sh`, or one whose matcher excludes startup, resume
  or compact (Claude Code's matcher rules: none, "" or "*" match all; letters, digits, `_`, `-`, spaces, `,`
  and `|` form a list of exact names; anything else is an unanchored regular expression). Header comment;
  `docs/ENVIRONMENT_CAPABILITIES.md` Project hooks and Permissions rows; AVE-REQ-098 § Edge cases,
  § Verification strategy AC-2/AC-4, § Implementation evidence.
- Test: `scripts/tests/test-checker.sh` — `AVE-REQ-098 AC-4`: "settings: bypassPermissions default mode",
  "settings: dontAsk default mode", "settings: skipped bypass-mode prompt", "settings: skipped auto-mode
  prompt", seven "hook command: …" cases (`while true`, `sleep 600`, `nohup`, `disown`, `setsid`, trailing `&`,
  `--dangerously-skip-permissions`); controls accepted: "settings: auto default mode accepted", "settings:
  prompt kept (false)", "hook command with redirects and && accepted". `AVE-REQ-098 AC-2`: "SessionStart
  matcher startup only", "SessionStart matcher without compact", "SessionStart regex matcher without resume",
  "SessionStart hook removed"; accepted: exact list, regex, `*`. Without python3: "no python3: settings policy
  warning".
- Mutations: M10 (bypass default modes accepted): 2 FAIL. M11 (skipped prompts accepted): 2 FAIL. M12 (hook
  commands never scanned): 7 FAIL (every "hook command: …" case). M13 (SessionStart coverage and registration
  ignored): 4 FAIL (three matcher cases, "SessionStart hook removed"). M14 (check 12 never runs): 16 FAIL (all
  policy cases and the python3 warning).

### Item 24 — AVE-REQ-098 AC-1, AC-2: the SessionStart block lists the changed files (done)
- Change: `.claude/hooks/session-start.sh` — `print_uncommitted_paths`: after the count line, "- Uncommitted
  (git status --short):" and at most 20 lines of `git -c color.status=false status --short`, then
  "[N more; run git status --short]". Header comment. AVE-REQ-098 § Verification strategy AC-1 maps "changed
  files" to the commits (`git log --stat`) and this list; AC-2 names the list.
- Test: `scripts/tests/test-session-start.sh` (`AVE-REQ-098 AC-1`, `AVE-REQ-098 AC-2`): "clean tree: no
  uncommitted list", "uncommitted list names the modified and the untracked file", "uncommitted list capped
  at 20 lines with the remainder counted" (26 paths: 20 lines, "[6 more; …]").
- Mutation M15 (list never printed): 2 FAIL (both list cases). M16 (bound 1000): 1 FAIL (the cap case).

### Item 25 — AVE-REQ-098 AC-3: variables and unblock actions (done; the PROGRESS.md part is proposed)
- Change: `.env.example` (new) — runtime variables (`AVE_VAR_DIR`, `AVE_FFMPEG`, `AVE_FFPROBE`) and provider
  credentials (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `HF_TOKEN`) with purpose, where to
  obtain them and the requirement that needs them; the Codex adapter's variable joins with the adapter.
  `scripts/check-project-control.sh` — `.env.example` is a required file; `scripts/tests/make-fixture.sh`
  copies it. `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (new) — one unblock action per gap (Anthropic
  key, OpenAI-compatible endpoint, Codex credential, GPU device, speech models, vision model); § Limits item 4
  points to it. AVE-REQ-098 § Edge cases, § Verification strategy AC-3, § Implementation evidence.
  `scripts/tests/run.sh` header names what the probe suite checks.
- Test: `scripts/tests/test-checker.sh` "missing .env.example" (`AVE-REQ-098 AC-3`);
  `scripts/tests/test-probe-environment.sh` "every reported credential variable is listed in .env.example"
  (`AVE-REQ-098 AC-3`; it failed before `.env.example` existed: "missing: ANTHROPIC_API_KEY OPENAI_API_KEY
  OPENAI_BASE_URL HF_TOKEN").
- Mutations: M17 (`.env.example` dropped from the required files): 1 FAIL ("missing .env.example"). M18
  (`HF_TOKEN=` removed from `.env.example`): 1 FAIL ("… listed in .env.example (missing: HF_TOKEN)").
- PROGRESS.md § Blockers and § Verification status belong to the lead: proposed below.

## Commands and results
- `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh` — before `.env.example` existed:
  27 pass, 1 FAIL ("… listed in .env.example (missing: ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL
  HF_TOKEN)"); after: `PROBE TOTAL: pass=28 fail=0`.
- `./scripts/dev-container.sh ./scripts/probe-environment.sh --offline` — container: cpus 8, memory 7.5 GiB,
  `accelerator: none (no device)`, `claude not installed`, `os user root (uid 0)`, `repository writable yes`.
- `claude --version` on the host — `2.1.282 (Claude Code)`.
- `git push --force --dry-run origin HEAD:refs/heads/permission-probe` — refused by the permission system
  before it ran.
- `./scripts/dev-container.sh ./scripts/check-project-control.sh` — OK on the worktree (every existing brief
  passes check 11, `.claude/settings.json` passes check 12).
- `./scripts/dev-container.sh python3 -B scripts/check_baseline.py` — "OK: baseline intact".
- `./scripts/dev-container.sh python3 -B var/mutations/part3.py` — M1–M18 each caught (results above); every
  file restored with its original SHA-256.
- `./scripts/verify.sh` (fast tier) — first run FAIL on two links of this handback's draft (relative links to
  `ENVIRONMENT_CAPABILITIES.md`, fixed); rerun `verify.sh: PASS — tier fast (9 of 9 steps passed)`.
- `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` — `scripts/tests/run.sh: PASS (6 suites)`
  (CHECKER 673/0 over mawk, gawk, original-awk and busybox; BASELINE 75/0; STOP HOOK 72/0; SESSION START 31/0;
  VERIFY TIERS 12/0; PROBE 28/0).

## Proposed updates for the lead-owned documents
- `docs/PROGRESS.md` § Blockers — the external gaps point to `ENVIRONMENT_CAPABILITIES.md` § External gaps
  (each with its unblock action) in place of § Limits.
- `docs/PROGRESS.md` § Verification status — name the commit and tier, for example "`./scripts/verify.sh --tier
  release` PASS at `2bd616d` in the development container (arm64; 12 of 12 steps; 104 unit, 62 media and
  population tests); CI (x86_64) release tier green at `bd12fe8`", and after part 4's release run the new hash.
- `docs/ENVIRONMENT_CAPABILITIES.md` Models row — add the run ID of this workflow run after it completes (the
  execution brief's decision).
- `docs/TRACEABILITY.md` — AVE-REQ-094 row: Implementation adds `.claude/skills/resume-project/SKILL.md`.
  AVE-REQ-098 row: Implementation adds `scripts/check-project-control.sh`, `.env.example`,
  `docs/ENVIRONMENT_CAPABILITIES.md`; Tests become `scripts/tests/test-session-start.sh` (AC-1, AC-2),
  `scripts/tests/test-checker.sh` (AC-2, AC-3, AC-4), `scripts/tests/test-probe-environment.sh` (AC-3),
  `scripts/tests/test-stop-hook.sh` (AC-4), inspection (AC-1, AC-3, AC-4). AVE-REQ-096 and AVE-REQ-097 rows
  unchanged.
- `docs/ASSUMPTIONS.md` — new entry: check 12 evaluates hook matchers by Claude Code's documented rules, with
  Python's `re.search` standing in for JavaScript's unanchored `RegExp.test` — reason: the checker runs without
  Claude Code — impact: an exotic regex construct can differ between the two engines.
- `docs/ASSUMPTIONS.md` — new entry: the SessionStart hook must run on startup, resume and compact; `clear` and
  `fork` stay optional — reason: AVE-REQ-098 AC-2 names compaction and a new session — impact: a matcher
  without `clear` passes check 12.
- `docs/ASSUMPTIONS.md` — new entry: the probe's accelerator verdict counts device nodes under `/dev` and a GPU
  that `nvidia-smi` reports; built-in FFmpeg encoders never count — reason: AVE-REQ-094 edge case — impact: a
  host with `/dev/dri` nodes reports `present` before any hardware encode is tested; AVE-REQ-076 still needs a
  test encode.
- `docs/ASSUMPTIONS.md` — new entry: `.env.example` lists the product's runtime and credential variables;
  development-tool variables (`VERIFY_TIER`, `CLAUDE_VERIFY_*`, `AVE_EVIDENCE_DIR`, `AVE_PROBE_DEV_DIR`) stay
  documented in their scripts — reason: the fix brief asks for the product variables — impact: none on the
  product.
- `docs/ARCHITECTURE.md` § Verification pipeline item 5 (outside this part's allowed section): "reports the
  uncommitted paths (bounded list), the last verification result …".
- AVE-REQ-094, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098 § Status — optional log lines: Edge cases, Verification
  strategy and Implementation evidence updated for fix brief items 3, 12, 13 (094), 15 (096), 22 (097), 23, 24,
  25 (098); statuses stay `in-progress`.
- `docs/PROGRESS.md` — part 3 of the M0 process fixes committed on `m0-process-fixes`.

## Open questions
1. Item 15, rule "a 7–40-hex commit in Input revision": two existing briefs name no commit at all
   (`2026-10-02-m1-backend-core.md`, `2026-10-02-m2-synchronization.md`: "the launching prompt names its
   hash"), and four name it only as the self-reference
   `git log -1 --format=%h -- docs/briefs/<this brief>` (`2026-10-02-m0-media-core-follow-ups-execution.md`,
   `2026-10-02-m0-media-core-round-3-follow-ups.md`, `2026-10-02-m0-process-fixes-execution.md`,
   `2026-10-02-m0-process-verification-fixes.md`); existing briefs are forbidden paths, so the rule would fail
   `./scripts/verify.sh`. Measured with a delimited match (`[0-9a-f]{7,40}` with no letter, digit, `_` or `-`
   on either side; a plain regex also matches `af7078da` inside the branch name `ccr-af7078da-q8r8mf`, which is
   no commit). Recommended: the lead writes new M1 and M2 briefs with the closing M0 hash when it launches them
   (or edits them before launch), decides whether the self-reference counts as a commit, then adds to
   `AWK_BRIEF`: under `## Input revision` a delimited 7–40-hex token (or the self-reference to the brief's own
   path), error "section '## Input revision' names no commit (7–40 hex digits)", with test-checker cases
   "input revision without a commit", "branch name only", "abbreviated hash accepted" (and "self-reference
   accepted" when chosen).
2. Check 12 leaves hooks with `"async": true` alone (Claude Code runs them in the background without enforcing
   their timeout); the finding does not name them. Recommended: a follow-up rule in check 12 or an assumption
   that async hooks need a review.
3. Check 12 reads `.claude/settings.json` only: `.claude/settings.local.json`, user and managed settings lie
   outside the repository and verify.sh stays identical locally and in CI. The Permissions row records the local
   file as absent.
4. The Codex unblock line names the action (sign in with the Codex SDK's documented authentication); the exact
   command joins when the AVE-REQ-052 adapter is built.
