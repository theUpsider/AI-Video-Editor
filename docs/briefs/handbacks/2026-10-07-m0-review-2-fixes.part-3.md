# Handback — M0 review round two, fixes, part 3: track B1, run environment and hooks (AVE-REQ-097, AVE-REQ-098)

Brief: [2026-10-07-m0-review-2-fixes.md](../2026-10-07-m0-review-2-fixes.md). Run `wf_6c06f19f-506` ([script](../../workflows/m0-review-2-fixes.js)), branch `m0-r2-fixes-b1` from `07eceb1`, commit `bde7989`. The report below is the writer's, unedited apart from local paths and the level of its headings. The host stood in standby from 00:38 to 09:52 local time on 2026-10-07; the run started tracks A and B1 again at 09:52 with new writers in the same worktrees.

## Report

### Result: COMPLETE

Track B1 of `docs/briefs/2026-10-07-m0-review-2-fixes.md` (run environment and hooks). Branch `m0-r2-fixes-b1`, commit `bde798984f2cf609f00b87a6a23869403fae2758`, parent `07eceb1aa1693df708c240642f837d8838be175a` (the base the prompt names; `git rev-parse HEAD` printed exactly that hash before any change). Worktree `.claude/worktrees/m0-r2-fixes-b1`. Nothing pushed, merged or rebased.

Start state, for the record: the worktree was at the base commit and held uncommitted edits in `scripts/verify.sh` and `scripts/verify.d/20-backend.sh` plus four helper scripts under the ignored `var/b1/`, dated 2026-10-07 00:29 to 00:38 local time: an earlier run of this track that was cut off. I read them as earlier partial work (skill step 4), re-measured every statement they made, kept the three ruff options, and replaced the list and the step by the form below. The helper scripts and my own are removed; `git status --porcelain --ignored` of the worktree shows `!! var/` only.

### Requirements
- AVE-REQ-097 — Verification gates that cannot pass as placeholders — ACs done: AC-1, AC-2, AC-3, AC-4 (this round: blocking findings 1 and 2 of AC-2 and AC-4, non-blocking 2, 3 (fingerprint half) and 4); open: none — proposed status `verification`.
- AVE-REQ-098 — Persistent progress and bounded autonomous continuation — B1's share (AC-4: the failed-attempt counter, part 5 non-blocking 6 third item and 10) done; the requirement file belongs to track B2 and the lead — proposed status: with the lead, after track B2.
- Skill precondition 3 holds in the brief's sense only: the dependency AVE-REQ-093 has status `in-progress` (track A works on it in parallel); the order of the `done` transitions stays the lead's.

### Items of track B1

#### 1. Ignored files by allow-list — fixed, with a wider mechanism than the decision names
- `scripts/verify.sh`: the step is now "No file outside the fingerprint and the listed paths" (`check_files_outside_fingerprint`). It walks the tree (`find`, every entry that is no directory, outside the `.git` entry at the root), subtracts the listing of the fingerprint (`vstate_listing`, the listing function of the fingerprint itself) and fails on every remaining path that the list does not admit. Every path of `git ls-files --others --ignored --exclude-per-directory=.gitignore` is such a path, so the decision of the brief holds. The walk also finds what Git lists nowhere; measured in a fixture: `docs/.git/hidden-note.md` (a directory named `.git` below the root), a file named `.git`, a FIFO and a socket appear in `git status --porcelain --ignored`, in `ls-files --others` and in `ls-files --others --ignored` not at all, while `find docs -name '*.md'` of the checker and `rglob("AVE-*.md")` of `scripts/check_baseline.py` read below such a directory. That is the neighbouring form of finding 1(c), and the reason for the walk.
- The list: `IGNORED_DIRECTORIES` (8 directories, admitted as a whole, the walk stops at them, a non-directory under such a name is judged as a file) and `IGNORED_FILES` (8 expressions matched against the whole path under `LC_ALL=C`), each entry with its reason in a comment.

| Entry | Reason in the comment | Shown by |
|---|---|---|
| `var` | output of the runs; evidence in a directory the run creates; fixture cache read under a key of specification, generator digest and FFmpeg version; a hand-written entry is local state | run P: 6 planted files, none read |
| `data` | no step names the directory | run P |
| `.claude/worktrees` | trees of their own; the link check passes the directory over | run P (conftest, verify.sh, settings.json, broken link planted) |
| `.serena` | state of an agent tool | run P |
| `backend/.venv` | the environment in CI (trusted toolchain); unread where `UV_PROJECT_ENVIRONMENT` names another directory | run P: every entry point of a planted environment records a hit; control with the variable unset: `Querying Python at backend/.venv/bin/python3 failed with exit status 97`, hit recorded; in the run: no hit |
| `backend/.pytest_cache`, `backend/.ruff_cache`, `backend/.mypy_cache` | hand-run caches; steps start pytest with `-p no:cacheprovider`, ruff with `--no-cache`, mypy with a scratch cache directory | run P: the caches of a real hand run plus `bad.py`, a failing test and a `conftest.py` in each, none read; suite case with a stale ruff cache |
| `.claude/settings.local.json`, `CLAUDE.local.md` | read by Claude Code, by no step | run P (bypass mode and `disableAllHooks` planted; broken link planted) |
| `.env`, `.env.local`, `.env.*.local` at the root | `uv` starts with `--no-env-file`; no step opens them | run P (`PYTHONPATH`, `PYTEST_ADDOPTS`, `AVE_FFMPEG`, `UV_PROJECT_ENVIRONMENT` planted; no hit) |
| a `.pyc` file directly inside a `__pycache__` directory | unread under `PYTHONPYCACHEPREFIX`; isolated scripts load repository modules from source text | run P: 177 poisoned bytecode files with valid headers for both interpreters and for pytest's tag; control without the prefix: `poisoned bytecode ran: .../backend/src/ave/__init__.py` and `.../scripts/reqfile.py`; in the run: no hit |
| `.DS_Store`, `Thumbs.db` at any depth | no step takes code or configuration from them | run P: 34 planted; read: `scripts/tests/.DS_Store` and `scripts/tests/Thumbs.db` (the evidence tool scans that directory for tags) |

- A bytecode file outside a `__pycache__` directory (the third form the brief names): `backend/ave.pyc` compiled from a module that ends the process: `git status --porcelain` empty; `pytest tests/unit/test_rates.py` prints `backend/ave.pyc ran in place of the package`; `./scripts/verify.sh` exits 1 with `<== FAIL: No file outside the fingerprint and the listed paths` and the line `backend/ave.pyc`.
- One `.gitignore`: a second one that the fingerprint names (tracked or untracked, also force-added inside a listed directory) fails the step by its own line; an ignored one is a file outside the fingerprint and fails unless it lies inside a listed directory. Git reads no ignore file inside an ignored directory (measured: `var/.gitignore` with `!keep.py` leaves `var/keep.py` ignored), and `uv` writes `backend/.venv/.gitignore` in CI.
- Tools: `scripts/verify.d/20-backend.sh` starts ruff with `--config pyproject.toml --no-respect-gitignore --no-cache` (format check and lint), mypy with `--config-file pyproject.toml`; pytest kept `-c pyproject.toml -p no:cacheprovider`.
- Every tool a step starts, checked for a configuration file it would find first (measured with ruff 0.16.9, mypy 2.3.1, pytest 9.1.1, uv 0.8.17 in copies under the container's `/tmp`; a source file with a format, lint and type error):

| Tool | Found first without the option | With the step's options |
|---|---|---|
| ruff | `backend/ruff.toml` and `backend/.ruff.toml` (exclude src, tests): format and lint exit 0; `backend/src/ruff.toml`: read (exit 2 from its content); `backend/src/ave/pyproject.toml` with a ruff table: lint exit 0 | exit 1 in every case |
| ruff, ignore files | a rule in `.git/info/exclude` that names a tracked file: `54 files already formatted`, lint exit 0; an `.ignore` file above the tree and one in `backend/`: lint exit 0; `core.excludesFile`: no effect | `--no-respect-gitignore`: exit 1 |
| ruff, user configuration under `HOME` | - | unread under `--config` (exit 1) |
| mypy | `backend/mypy.ini`, `backend/.mypy.ini` (`files = tests/__init__.py`): `Success: no issues found in 1 source file`; `setup.cfg`: ranks after `pyproject.toml` | exit 1 |
| pytest | `backend/.pytest.ini` (`addopts = --collect-only`): `3 tests collected`; `tox.ini`: ranks after `pyproject.toml`; a `conftest.py` above `backend/`: not loaded | `-c pyproject.toml`: `3 passed` |
| uv | `backend/uv.toml` (parse error on an unknown field: it is read ahead of the `[tool.uv]` table), `backend/.python-version` (`The Python request from .python-version resolved to Python 3.9.23 ...`); a `uv.toml` and a `.python-version` above the tree: unread; a `pyproject.toml` above the tree that declares a workspace with `backend/` as member: `Unable to find lockfile at uv.lock` | no option added: the two in-tree files are files of the tree (fingerprinted, or failing the step when ignored); the workspace above the tree is stated as local state |
| python3, git, awk variants, sed, find, sort, comm, jq, node (`-e`), flock, ffmpeg, ffprobe | no file of the tree found by search: their variables are outside the named set; isolated start and source-text loading for the gate scripts; the fingerprint reads raw bytes | unchanged |

- Named cases, `scripts/tests/test-verify-tiers.sh` § "files outside the fingerprint": `an ignored backend/ave.pyc fails the run and is named`; `a backend/.gitignore that lists itself, mypy.ini and ruff.toml fails the run, and the three are named`; `a docs/.gitignore that lists itself and a link target fails the run, and both are named`; `ignored paths outside the list fail the run while Git reports the tree clean` with 22 checks `an ignored <path> is named` (the four directories of the earlier step; `.env`, `.env.local`, `.env.test.local`, `CLAUDE.local.md`, `.serena`, `.venv` and the three cache directories at another place; a `.py` file and a nested `.pyc` file inside `__pycache__`; `.coverage`, `htmlcov`, `node_modules`, `dist`, `playwright-report`, `test-results`); `control: the two listings of Git hold a file that a rule ignores`; `a file inside a directory named .git below the root and a FIFO fail the run, and no listing of Git holds them`; `a FIFO under the name of a listed directory fails the run`; `a settings.local.json outside .claude/ fails the run`; `a name with a line feed is printed on one line, as the shell quotes it`; `an untracked .gitignore below the root fails the run and is named`; `a tracked .gitignore below the root fails the run and is named`; `a tracked .gitignore inside a directory of the list fails the run and is named`; `control: under the UTF-8 locale of this case an expression does not match that byte by itself`; `every path of the list passes the step, under a UTF-8 locale too` with 18 checks `the list admits <path>` (one or more per entry); `the files of an untracked embedded repository count as named`; `the files below a gitlink count as named`; `a repository that Git cannot read fails the step`; `a listing that Git cannot produce fails the step`; `the restored repository passes the step`; `a directory without a repository skips the step`.
- Named cases, same suite § "the real backend step file": `the format check and the lint are the two ruff commands of the step file`; `both ruff commands take their configuration from pyproject.toml by name`; `both ruff commands read no ignore file`; `both ruff commands read and write no cache`; `the type checker takes its configuration from pyproject.toml by name`; and with the real ruff and mypy of the backend environment, started with the options read from the step file in a project that holds a failing source file: `control: the real format check, lint and type check fail the source file`; `a ruff.toml and a mypy.ini beside pyproject.toml change no result`; `control: without the option each tool takes the file beside pyproject.toml and passes (000)`; `an ignore file that names the source file changes no result`; `control: without the option ruff passes the source file over (00)`.

#### 2. Caches — fixed
- ruff starts with `--no-cache` in both steps. Cases: `both ruff commands read and write no cache`; `control: with its cache ruff passes an edited file that kept its time stamp (0000)` (finding 2 reproduced with the real ruff); `a cache written for an earlier text changes no result`; `the tools leave no cache in the project`.
- `check_tree_unchanged` runs the walk again after the steps, so a file that a step leaves outside the list fails the run that wrote it, in a fresh checkout too. Cases: `a file that a step leaves outside the list fails the working-tree step of the same run` (tiers suite); `a step that leaves a file under an ignore rule of its own fails the last step too` and `output below var/ passes` (stop-hook suite; the earlier case `output to a .gitignore-d path passes` is replaced by these two, because an ignore rule for an output file outside `var/` is the form the new rule fails).
- Listing after a release run in a fresh checkout (run C, no `UV_PROJECT_ENVIRONMENT`, `uv sync --frozen --directory backend`): before the run `!! backend/.venv/`; after the run `!! backend/.venv/` and `!! var/`, nothing else (4716 files in `backend/.venv/`, 34 in `var/fixtures/`, 69 in `var/test-artifacts/`, 12 in `var/verify/`).

#### 3. Comment and docstring — fixed
`scripts/verify.d/20-backend.sh` and the docstring of `backend/tests/unit/test_fast_tier_media_tools.py` name both ways (an absolute path, a `PATH` of its own) and the stand-ins on `PATH`; § Edge cases of the requirement likewise.

#### 4. Fingerprint variables — fixed
`scripts/tests/test-stop-hook.sh`: five checks `<VARIABLE> of the caller does not redirect the gate (cache hit for this tree)` for `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_COMMON_DIR`, `GIT_NAMESPACE`; `control: the stand-in ran and saw the Git variables of the suite itself`; nine checks `the run of the gate sees no <VARIABLE> of the caller`. Measured by the mutants L1 to L9: the reviewer's S5 (`GIT_INDEX_FILE`, here L3) fails the cache-hit case; `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_COMMON_DIR` and `GIT_NAMESPACE` change no listing and no hash that Git 2.55 gives the fingerprint, so their cache-hit cases pass with and without the unset, and the nine checks on the environment of the gate's run are the ones that fail. The suite comment says so.

#### 5. Generator digest — fixed (24 lines of code for the closure)
`backend/src/ave/fixtures/generate.py`: `generator_sources()` reads every `import` and `from ... import` statement (any depth, relative forms) starting from the three modules of `ave.fixtures` and returns the 12 modules of the closure with the packages above each; `generator_digest()` hashes name, length and bytes of each. Cases in `backend/tests/unit/test_fixture_cache_key.py`: `test_the_generator_sources_are_its_modules_and_every_ave_module_they_import` (against a written list), `test_the_generator_digest_is_the_hash_of_the_generator_sources`, `test_every_ave_module_that_the_generator_loads_is_among_its_sources` (a fresh interpreter), `test_an_edit_to_an_imported_helper_changes_the_digest[ave/proc.py | ave/media/probe.py | ave/errors.py]`, `test_a_copy_of_the_sources_has_the_same_digest_and_an_edit_outside_them_keeps_it`, `test_imports_inside_functions_and_in_relative_form_join_the_sources`. Limit, stated in § Edge cases: a module loaded by a computed name lies outside the digest. The digest value changed, so the first media run regenerates the fixtures once.

#### 6. Failed-attempt counter — fixed
`.claude/hooks/stop-verify.sh` `count_failed_attempt`: one or two decimal digits count, read with base 10 (`08` is eight); every other content counts as 0; the counter stops at 99, so the gate writes no value that it would read as 0 (without that, the hundredth continued stop would block again). Cases: `a counter of 08 reads as eight (attempt 9 of 10 blocks)`; `a counter of 09 reads as nine (the tenth attempt releases)`; `a counter of 007 | 9223372036854775807 | abc counts as 0 (attempt 1 of 3 blocks)`; `a counter of 99 stays at 99, and every further continued stop releases`. The suite comment names the two cases for a counter that reads back as another value (a directory at its path) and for one that cannot be stored (`the counter cannot be stored: a fresh stop blocks once, a continued stop releases`, with a stand-in for `mv` that fails for the counter file alone, and its control). Before the change a counter of `08` with a limit of 10 ended the arithmetic of the function with an error (`08: value too great for base`).

### Changes (file — purpose)
- `scripts/verify.sh` — the walk step, the two lists with reasons, the second walk in `check_tree_unchanged`, header § "Files outside the fingerprint", messages (outputs go below `var/`).
- `scripts/verify.d/20-backend.sh` — ruff and mypy options; header and fast-tier comment.
- `.claude/hooks/stop-verify.sh` — counter reading.
- `backend/src/ave/fixtures/generate.py` — `generator_sources`, `generator_digest` over the import closure.
- `backend/tests/unit/test_fixture_cache_key.py` — 9 cases (was 2).
- `backend/tests/unit/test_fast_tier_media_tools.py` — docstring.
- `scripts/tests/test-verify-tiers.sh` — 133 checks (was 65); needs `uv` and the backend environment for the real-tool cases; `AVE_VAR_DIR` joins the caller's variables of the named-set case.
- `scripts/tests/test-stop-hook.sh` — 174 checks (was 145).
- `docs/requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md` — § Edge cases, § Verification strategy, § Implementation evidence (18 replacements, one new Edge case); frontmatter, criteria, Test evidence and Status log untouched; `python3 -I -B scripts/check_baseline.py` prints `OK: baseline intact`.
- Unchanged though allowed: `scripts/lib/verify-state.sh`, `scripts/tests/make-fixture.sh`, `.gitignore` (the list needs no new entry).

### Tests (AVE-REQ-NNN AC-n → test location)
- AVE-REQ-097 AC-1 → `scripts/tests/test-verify-tiers.sh` (tier membership, selection, usage errors, step files; unchanged cases).
- AVE-REQ-097 AC-2 → `scripts/tests/test-verify-tiers.sh` §§ "files outside the fingerprint", "the real backend step file"; `scripts/tests/test-stop-hook.sh` §§ "local Git states leave an edit visible in the fingerprint", "the fingerprint reads bytes, executable bits and index modes"; `backend/tests/unit/test_fixture_cache_key.py`.
- AVE-REQ-097 AC-3 → `scripts/tests/test-stop-hook.sh` §§ "a counter written by hand", "a counter that cannot be read back or stored"; `backend/tests/unit/test_fast_tier_media_tools.py`.
- AVE-REQ-097 AC-4 → `scripts/tests/test-verify-tiers.sh` § "files outside the fingerprint" (same cases, both tags); `scripts/tests/test-stop-hook.sh` § "verify.sh: working tree unchanged by verification".
- AVE-REQ-098 AC-4 → `scripts/tests/test-stop-hook.sh` §§ "a counter written by hand", "a counter that cannot be read back or stored".

### Mutation list
159 one-swap mutants, each in a fresh copy of the tree (tracked and untracked files) under the container's `/tmp`, own backend environment and own bytecode prefix per slot, emptied per run; 157 fail a named case. Survivors: S06 (equivalent: a counter that was not stored reads back as its earlier value, so the read-back alone takes the same branch) and A54 (a guard for a `readlink` that fails; no sentence of the requirement states it and no fixture can stage it). Controls on unmutated copies: tiers `pass=132 fail=0`, stop-hook `pass=169 fail=0`, cache-key file `9 passed` at the time of the first batch.

Order of the runs: V01 to G10 (83 mutants) ran before four suite additions; three survivors of the runs led to added cases and were run again (W8: `a settings.local.json outside .claude/ fails the run`; A44: `another index mode of the one file of a tree changes the fingerprint`, because the order of the sorted entries follows the modes and stood in for the mode in every tree with two modes; A55: `a directory at the path of the deleted file changes the fingerprint again`). G01 to G10 were run again after the last change to the test file. After the last mutant run only comments of the two suites and one planted file name changed. No production file changed after the first batch.

File letters: V `scripts/verify.sh`, B `scripts/verify.d/20-backend.sh`, H `.claude/hooks/stop-verify.sh`, L `scripts/lib/verify-state.sh`, G `backend/src/ave/fixtures/generate.py`, P `backend/tests/evidence_plugin.py`, R `scripts/tests/run.sh`. Suites: V, D, F, W, B, T1 and A01 to A24 against `test-verify-tiers.sh` (V03, V13, A57 also against `test-stop-hook.sh`, V15 against it alone, A21 and A22 against `test_fast_tier_media_tools.py`); S, L and A30 to A56 against `test-stop-hook.sh`; G against `test_fixture_cache_key.py`; P against `test_evidence_plugin.py`; R against `python3 -B scripts/evidence.py unittest scripts/tests`. In a swap `<LF>` marks a line feed and leading blanks are left out. Each D and F row also fails `every path of the list passes the step, under a UTF-8 locale too`.

| Mutant | File | Swap (old -> new) | Failing cases |
|---|---|---|---|
| V01 | V | `[ -n "$outside$nested" ] \|\| exit 0 <LF>` -> `exit 0 <LF>` | an ignored backend/ave.pyc fails the run and is named; a backend/.gitignore that lists itself, mypy.ini and ruff.toml fails the run, and the three are named (+31 more) |
| V02 | V | `run_step "No file outside the fingerprint and the listed paths" check_files_outside_fingerprint <LF>` -> `(removed)` | the clean fixture passes the step; an ignored backend/ave.pyc fails the run and is named (+17 more) |
| V03 | V | `fi <LF> check_files_outside_fingerprint <LF> }` -> `fi <LF> return 0 <LF> }` | a file that a step leaves outside the list fails the working-tree step of the same run; a step that leaves a file under an ignore rule of its own fails the last step too |
| V04 | V | `export LC_ALL=C <LF>` -> `(removed)` | every path of the list passes the step, under a UTF-8 locale too |
| V05 | V | `printf -v path '%q' "$path" <LF> outside+=` -> `outside+=` | a name with a line feed is printed on one line, as the shell quotes it |
| V06 | V | `if ! vstate_listing >"$work/listing"; then` -> `if vstate_listing >"$work/listing"; false; then` | a listing that Git cannot produce fails the step |
| V07 | V | `printf 'Skipped: outside a Git work tree (no .git here or above).\n' <LF> exit 0` -> `... <LF> exit 1` | a directory without a repository skips the step |
| V08 | V | `git rev-parse --is-inside-work-tree 2>&1 <LF> exit 1` -> `... <LF> exit 0` | a repository that Git cannot read fails the step |
| V09 | V | `-o ! -type d -printf` -> `-o -type f -printf` | a file inside a directory named .git below the root and a FIFO fail the run, and no listing of Git holds them; a FIFO under the name of a listed directory fails the run |
| V10 | V | `prune+=(-o -path "./$path" -type d)` -> `prune+=(-o -path "./$path")` | a FIFO under the name of a listed directory fails the run |
| V11 | V | `prune+=(-o -path "./$path" -type d)` -> `prune+=(-o -name "${path##*/}" -type d)` | an ignored docs/.serena/project.yml is named; an ignored .venv/lib/site.py is named (+4 more) |
| V12 | V | `*:*/.gitignore) <LF>` -> `*:*/.gitignore-none) <LF>` | an untracked .gitignore below the root fails the run and is named; a tracked .gitignore below the root fails the run and is named (+1 more) |
| V13 | V | `*:*/) repositories+=("$path") ;; <LF>` -> `(removed)` | the files of an untracked embedded repository count as named; Stop runs verify.sh there (+1 more) |
| V14 | V | `160000:*) repositories+=("$path/") ;; <LF>` -> `(removed)` | the files below a gitlink count as named |
| V15 | V | `elif [ "$(tree_state)" != "$1" ]; then` -> `elif false; then` | a step that leaves an untracked file fails the last step |
| V16 | V | `[[ $path =~ $admitted ]] && continue <LF>` -> `(removed)` | every path of the list passes the step, under a UTF-8 locale too; the list admits .claude/settings.local.json (+9 more) |
| V17 | V | `prune=(-path ./.git)` -> `prune=(-path ./.git -o -name .git)` | a file inside a directory named .git below the root and a FIFO fail the run, and no listing of Git holds them |
| D1.var | V | `var <LF>` -> `(removed)` | default tier is fast; --tier media adds the media steps (+22 more) |
| D2.data | V | `data <LF>` -> `(removed)` | the list admits data/media/clip.py |
| D3.worktrees | V | `.claude/worktrees <LF>` -> `(removed)` | the list admits .claude/worktrees/x/conftest.py |
| D4.serena | V | `.serena <LF>` -> `(removed)` | the list admits .serena/project.yml |
| D5.venv | V | `backend/.venv <LF>` -> `(removed)` | the list admits backend/.venv/lib/site.py |
| D6.pytest_cache | V | `backend/.pytest_cache <LF>` -> `(removed)` | the list admits backend/.pytest_cache/v/cache/lastfailed |
| D7.ruff_cache | V | `backend/.ruff_cache <LF>` -> `(removed)` | the list admits backend/.ruff_cache/content/x |
| D8.mypy_cache | V | `backend/.mypy_cache <LF>` -> `(removed)` | the list admits backend/.mypy_cache/3.11/x.json |
| F1.settings_local | V | `'\.claude/settings\.local\.json' <LF>` -> `(removed)` | the list admits .claude/settings.local.json |
| F2.claude_local | V | `'CLAUDE\.local\.md' <LF>` -> `(removed)` | the list admits CLAUDE.local.md |
| F3.env | V | `'\.env' <LF>` -> `(removed)` | the list admits .env |
| F4.env_local | V | `'\.env\.local' <LF>` -> `(removed)` | the list admits .env.local |
| F5.env_x_local | V | `'\.env\.[^/]*\.local' <LF>` -> `(removed)` | the list admits .env.test.local |
| F6.pycache | V | `'(.*/)?__pycache__/[^/]*\.pyc' <LF>` -> `(removed)` | the list admits scripts/__pycache__/evidence.cpython-312.pyc (+2 more) |
| F7.ds_store | V | `'(.*/)?\.DS_Store' <LF>` -> `(removed)` | the list admits scripts/tests/.DS_Store |
| F8.thumbs | V | `'(.*/)?Thumbs\.db' <LF>` -> `(removed)` | the list admits docs/Thumbs.db |
| W1.env_any_depth | V | `'\.env' <LF>` -> `'(.*/)?\.env' <LF>` | an ignored docs/.env is named |
| W2.env_local_any_depth | V | `'\.env\.local' <LF>` -> `'(.*/)?\.env\.local' <LF>` | an ignored backend/.env.local is named |
| W3.env_x_local_any_depth | V | `'\.env\.[^/]*\.local' <LF>` -> `'(.*/)?\.env\.[^/]*\.local' <LF>` | an ignored docs/.env.test.local is named |
| W4.claude_local_any_depth | V | `'CLAUDE\.local\.md' <LF>` -> `'(.*/)?CLAUDE\.local\.md' <LF>` | an ignored docs/CLAUDE.local.md is named |
| W5.pycache_any_file | V | `'(.*/)?__pycache__/[^/]*\.pyc' <LF>` -> `'(.*/)?__pycache__/[^/]*' <LF>` | an ignored scripts/__pycache__/helper.py is named |
| W6.pycache_any_depth_below | V | `'(.*/)?__pycache__/[^/]*\.pyc' <LF>` -> `'(.*/)?__pycache__/.*\.pyc' <LF>` | an ignored scripts/__pycache__/sub/helper.cpython-312.pyc is named |
| W7.pyc_anywhere | V | `'(.*/)?__pycache__/[^/]*\.pyc' <LF>` -> `'(.*/)?[^/]*\.pyc' <LF>` | an ignored backend/ave.pyc fails the run and is named; an ignored scripts/unittest.pyc is named (+4 more) |
| W8.settings_any_depth | V | `'\.claude/settings\.local\.json' <LF>` -> `'(.*/)?settings\.local\.json' <LF>` | a settings.local.json outside .claude/ fails the run |
| B01 | B | `ruff format --check --config pyproject.toml \ <LF> --no-respect-gitignore --no-cache .` -> `ruff format --check \ <LF> --no-respect-gitignore --no-cache .` | both ruff commands take their configuration from pyproject.toml by name; a ruff.toml and a mypy.ini beside pyproject.toml change no result |
| B02 | B | `ruff check --config pyproject.toml --no-respect-gitignore --no-cache .` -> `ruff check --no-respect-gitignore --no-cache .` | both ruff commands take their configuration from pyproject.toml by name; a ruff.toml and a mypy.ini beside pyproject.toml change no result |
| B03 | B | `ruff format --check --config pyproject.toml \ <LF> --no-respect-gitignore --no-cache .` -> `ruff format --check --config pyproject.toml \ <LF> --no-cache .` | both ruff commands read no ignore file; an ignore file that names the source file changes no result |
| B04 | B | `ruff check --config pyproject.toml --no-respect-gitignore --no-cache .` -> `ruff check --config pyproject.toml --no-cache .` | both ruff commands read no ignore file; an ignore file that names the source file changes no result |
| B05 | B | `ruff format --check --config pyproject.toml \ <LF> --no-respect-gitignore --no-cache .` -> `ruff format --check --config pyproject.toml \ <LF> --no-respect-gitignore .` | both ruff commands read and write no cache; a cache written for an earlier text changes no result (+1 more) |
| B06 | B | `ruff check --config pyproject.toml --no-respect-gitignore --no-cache .` -> `ruff check --config pyproject.toml --no-respect-gitignore .` | both ruff commands read and write no cache; a cache written for an earlier text changes no result (+1 more) |
| B07 | B | `backend_uv mypy --config-file pyproject.toml \ <LF> --cache-dir=` -> `backend_uv mypy \ <LF> --cache-dir=` | the type checker takes its configuration from pyproject.toml by name; a ruff.toml and a mypy.ini beside pyproject.toml change no result |
| B08 | B | `--cache-dir="$AVE_RUN_SCRATCH/mypy-cache"` -> `--cache-dir="$PWD/backend/.mypy_cache"` | the type checker reads no cache from the tree |
| B09 | B | `backend_uv pytest -c pyproject.toml -q` -> `backend_uv pytest -q` | the pytest steps take their configuration from pyproject.toml alone, and uv reads no environment file |
| B10 | B | `-p no:cacheprovider --forbid-skips` -> `--forbid-skips` | the pytest steps take their configuration from pyproject.toml alone, and uv reads no environment file |
| B11 | B | `uv run --frozen --quiet --no-env-file --directory backend` -> `uv run --frozen --quiet --directory backend` | every uv call of the backend steps passes --no-env-file (+11 more) |
| B12 | B | `export PATH="$tools:$PATH" AVE_FFMPEG="$stub" AVE_FFPROBE="$stub"` -> `export AVE_FFMPEG="$stub" AVE_FFPROBE="$stub"` | the fast tier's tests resolve ffmpeg on PATH to a stand-in that exits 1; the fast tier's tests resolve ffprobe on PATH to a stand-in that exits 1 |
| B13 | B | `export PATH="$tools:$PATH" AVE_FFMPEG="$stub" AVE_FFPROBE="$stub"` -> `export PATH="$tools:$PATH"` | the fast tier's tests see media tools that refuse to run |
| B14 | B | `python3 -B scripts/evidence.py check-report --file "$report"` -> `true` | a pytest step that left no report fails |
| B15 | B | `--forbid-skips \ <LF>` -> `\ <LF>` | the pytest steps take their configuration from pyproject.toml alone, and uv reads no environment file |
| S01 | H | `[0-9] \| [0-9][0-9]) attempts=$((10#$attempts)) ;;` -> `[0-9] \| [0-9][0-9]) attempts=$((attempts)) ;;` | a counter of 08 reads as eight (attempt 9 of 10 blocks); a counter of 09 reads as nine (the tenth attempt releases) |
| S02 | H | `[0-9] \| [0-9][0-9]) attempts=` -> `[0-9] \| [0-9][0-9] \| [0-9][0-9][0-9]) attempts=` | a counter of 007 counts as 0 (attempt 1 of 3 blocks) |
| S03 | H | `[0-9] \| [0-9][0-9]) attempts=$((10#$attempts)) ;; <LF> *) attempts=0 ;;` -> `"" \| *[!0-9]*) attempts=0 ;; <LF> *) attempts=$((10#$attempts)) ;;` | a counter of 007 counts as 0 (attempt 1 of 3 blocks); a counter of 9223372036854775807 counts as 0 (attempt 1 of 3 blocks) |
| S04 | H | `[ "$attempts" -ge 99 ] \|\| attempts=$((attempts + 1))` -> `attempts=$((attempts + 1))` | a counter of 99 stays at 99, and every further continued stop releases (02) |
| S05 | H | `if ! vstate_set attempts "$attempts" \|\| [ "$(vstate_get attempts)" != "$attempts" ]; then` -> `if vstate_set attempts "$attempts"; false; then` | the counter path is a directory: a fresh stop blocks once, a continued stop releases (222); the counter cannot be stored: a fresh stop blocks once, a continued stop releases (222) |
| S06 | H | same line -> `if vstate_set attempts "$attempts"; [ "$(vstate_get attempts)" != "$attempts" ]; then` | SURVIVED (equivalent) |
| S07 | H | same line -> `if ! vstate_set attempts "$attempts"; then` | the counter path is a directory: a fresh stop blocks once, a continued stop releases (222) |
| S08 | H | `*) attempts=0 ;; <LF> esac <LF> [ "$attempts" -ge 99 ]` -> `*) attempts=1 ;; <LF> esac <LF> [ "$attempts" -ge 99 ]` | a counter of 007 counts as 0 (attempt 1 of 3 blocks) (+2 more) |
| L1.GIT_DIR | L | `unset GIT_DIR GIT_WORK_TREE` -> `unset GIT_WORK_TREE` | GIT_DIR and GIT_WORK_TREE of another repository do not redirect the gate (cache hit for this tree) (+10 more) |
| L2.GIT_WORK_TREE | L | `unset GIT_DIR GIT_WORK_TREE` -> `unset GIT_DIR` | GIT_DIR and GIT_WORK_TREE of another repository do not redirect the gate (cache hit for this tree); the run of the gate sees no GIT_WORK_TREE of the caller |
| L3.GIT_INDEX_FILE | L | `GIT_INDEX_FILE GIT_OBJECT_DIRECTORY` -> `GIT_OBJECT_DIRECTORY` | GIT_INDEX_FILE of the caller does not redirect the gate (cache hit for this tree); the run of the gate sees no GIT_INDEX_FILE of the caller |
| L4.GIT_OBJECT_DIRECTORY | L | `GIT_INDEX_FILE GIT_OBJECT_DIRECTORY` -> `GIT_INDEX_FILE` | the run of the gate sees no GIT_OBJECT_DIRECTORY of the caller |
| L5.GIT_ALTERNATE_OBJECT_DIRECTORIES | L | `GIT_ALTERNATE_OBJECT_DIRECTORIES \` -> `\` | the run of the gate sees no GIT_ALTERNATE_OBJECT_DIRECTORIES of the caller |
| L6.GIT_COMMON_DIR | L | `GIT_COMMON_DIR GIT_NAMESPACE` -> `GIT_NAMESPACE` | the run of the gate sees no GIT_COMMON_DIR of the caller |
| L7.GIT_NAMESPACE | L | `GIT_COMMON_DIR GIT_NAMESPACE` -> `GIT_COMMON_DIR` | the run of the gate sees no GIT_NAMESPACE of the caller |
| L8.GIT_CONFIG_COUNT | L | `GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS` -> `GIT_CONFIG_PARAMETERS` | control: the stand-in ran and saw the Git variables of the suite itself; the run of the gate sees no GIT_DIR of the caller (+9 more) |
| L9.GIT_CONFIG_PARAMETERS | L | `GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS` -> `GIT_CONFIG_COUNT` | control: the stand-in ran and saw the Git variables of the suite itself; the run of the gate sees no GIT_DIR of the caller (+9 more) |
| G01 | G | `pending.extend(target for target in targets if target.split(".")[0] == "ave") <LF>` -> `(removed)` | test_the_generator_sources_are_its_modules_and_every_ave_module_they_import; test_the_generator_digest_is_the_hash_of_the_generator_sources (+5 more) |
| G02 | G | `pending.append(name.rpartition(".")[0] or name) <LF>` -> `(removed)` | test_the_generator_sources_are_its_modules_and_every_ave_module_they_import; test_the_generator_digest_is_the_hash_of_the_generator_sources (+2 more) |
| G03 | G | `digest.update(f"{name}\0{len(data)}\0".encode() + data)` -> `digest.update(f"{name}\0".encode())` | test_the_generator_digest_is_the_hash_of_the_generator_sources; test_an_edit_to_an_imported_helper_changes_the_digest[ave/proc.py] (+2 more) |
| G04 | G | `[*(above if node.level else []),` -> `[*[],` | test_imports_inside_functions_and_in_relative_form_join_the_sources |
| G05 | G | `for node in ast.walk(ast.parse(path.read_bytes())):` -> `for node in ast.parse(path.read_bytes()).body:` | test_imports_inside_functions_and_in_relative_form_join_the_sources |
| G06 | G | `"sources": generator_digest(), <LF>` -> `(removed)` | test_the_cache_key_changes_with_the_generator_sources |
| G07 | G | `targets = [module, *(f"{module}.{alias.name}" for alias in node.names)]` -> `targets = [module]` | test_imports_inside_functions_and_in_relative_form_join_the_sources |
| G08 | G | `_GENERATOR_MODULES = ("ave.fixtures.barcode", "ave.fixtures.generate", "ave.fixtures.standard")` -> `_GENERATOR_MODULES = ("ave.fixtures.barcode", "ave.fixtures.generate")` | test_the_generator_sources_are_its_modules_and_every_ave_module_they_import; test_the_generator_digest_is_the_hash_of_the_generator_sources (+2 more) |
| G09 | G | `for name, path in sorted(generator_sources(package_root).items()):` -> `... .items())[:6]:` | test_the_generator_digest_is_the_hash_of_the_generator_sources; test_an_edit_to_an_imported_helper_changes_the_digest[ave/proc.py] (+1 more) |
| G10 | G | `len(package.split(".")) - max(node.level - 1, 0)]` -> `len(package.split("."))]` | test_imports_inside_functions_and_in_relative_form_join_the_sources |
| A01 | V | `PWD \| SHLVL \| _) ;;` -> `PWD \| SHLVL \| _ \| AVE_VAR_DIR) ;;` | the steps see the named set, the run's own variables and no other name |
| A02 | V | `[ -z "$REPLY" ] \|\| unset -f -- "$REPLY"` -> `:` | an exported function of the caller stands in for no command of a step (+6 more) |
| A03 | V | `export PYTHONSAFEPATH=1 PYTHONNOUSERSITE=1 PYTEST_DISABLE_PLUGIN_AUTOLOAD=1` -> `export PYTHONNOUSERSITE=1 PYTEST_DISABLE_PLUGIN_AUTOLOAD=1` | the steps see the named set, the run's own variables and no other name; the run sets its own Python and pytest variables and passes on the values of the named set |
| A04 | V | same line -> `export PYTHONSAFEPATH=1 PYTEST_DISABLE_PLUGIN_AUTOLOAD=1` | no step loads a module from a user site directory (+2 more) |
| A05 | V | same line -> `export PYTHONSAFEPATH=1 PYTHONNOUSERSITE=1` | the steps see the named set, the run's own variables and no other name; the run sets its own Python and pytest variables and passes on the values of the named set |
| A06 | V | `export PYTHONPYCACHEPREFIX="$AVE_RUN_SCRATCH/pycache" <LF>` -> `(removed)` | the steps read bytecode from the run's scratch directory only (+1 more) |
| A07 | V | `environment_is_named \|\| return 1 <LF>` -> `(removed)` | an environment entry that the shell cannot unset fails the run before any step |
| A08 | V | `\|\| ! mkdir "$AVE_EVIDENCE_DIR"; then` -> `\|\| ! mkdir -p "$AVE_EVIDENCE_DIR"; then` | a run directory prepared by the caller is never reused |
| A09 | V | `trap 'rm -rf "$AVE_RUN_SCRATCH"' EXIT <LF>` -> `(removed)` | the scratch directory is gone after the run |
| A10 | V | `unset VERIFY_TIER # the steps see` -> `: # the steps see` | VERIFY_TIER selects the tier; --tier overrides VERIFY_TIER (+7 more) |
| A11 | V | `. "./$step_file" \|\| run_step "Load $step_file" false` -> `. "./$step_file" \|\| true` | a step file that cannot be loaded fails the tier |
| A12 | V | `sed -n 's\|^\(scripts/verify\.d/[A-Za-z0-9_.-]*\.sh\)$\|\1\|p' scripts/check-project-control.sh` -> `ls scripts/verify.d/*.sh` | an unregistered step file is never sourced and fails the control step |
| A13 | V | `media:media \| media:release) return 0 ;;` -> `media:*) return 0 ;;` | default tier is fast; --tier overrides VERIFY_TIER (+3 more) |
| A14 | V | `TIER="${VERIFY_TIER:-fast}"` -> `TIER="${VERIFY_TIER:-media}"` | default tier is fast (+3 more) |
| A15 | V | `*) printf 'verify.sh: unknown tier: %s\n' "$TIER" >&2; usage >&2; exit 2 ;;` -> `*) TIER=fast ;;` | unknown tier exits 2 |
| A16 | V | `"$FAILED_STEPS" <LF> return 1` -> `"$FAILED_STEPS" <LF> return 0` | a step file that cannot be loaded fails the tier; media tier fails with exit 1 and names the step (+17 more) |
| A17 | V | `unset "$1" 2>/dev/null \|\| export -n "$1"` -> `:` | the steps see the named set, the run's own variables and no other name (+99 more) |
| A18 | V | `unset OLDPWD <LF>` -> `(removed)` | the steps see the named set, the run's own variables and no other name (+6 more) |
| A19 | V | `release:release) return 0 ;;` -> `release:*) return 0 ;;` | default tier is fast; --tier media adds the media steps (+11 more) |
| A20 | `scripts/verify.d/95-evidence.sh` | `fast_step "Done requirements evidenced by this run"` -> `release_step "Done requirements evidenced by this run"` | the fast tier fails a done requirement that this run does not evidence |
| A21 | `scripts/lib/media-tier-only.sh` | `exit 1` -> `exit 0` | the fast tier's tests resolve ffmpeg on PATH to a stand-in that exits 1; the stand-in exits 1 and names the media tier; test_a_media_tool_call_fails_under_the_fast_tier_stub (+2 more) |
| A22 | `backend/src/ave/proc.py` | `override = os.environ.get(f"AVE_{name.upper()}")` -> `override = None` | test_a_media_tool_call_fails_under_the_fast_tier_stub[ffmpeg]; test_a_media_tool_call_fails_under_the_fast_tier_stub[ffprobe] |
| A23 | B | `fast_pytest() ( <LF>` -> `fast_pytest() { <LF>` and its closing `)` -> `}` | the media tier's tests resolve ffmpeg on PATH outside the stand-ins; the media tier's tests resolve ffprobe on PATH outside the stand-ins (+1 more) |
| A24 | V | `PWD \| SHLVL \| _) ;;` -> `PWD \| SHLVL \| _ \| GIT_DIR \| GIT_WORK_TREE) ;;` | the steps see the named set, the run's own variables and no other name |
| A30 | H | `./scripts/verify.sh --tier fast >"$1" 2>&1 </dev/null` -> `./scripts/verify.sh >"$1" 2>&1 </dev/null` | gate ran the fast tier despite VERIFY_TIER=release; gate ran no media or release marker step |
| A31 | H | `[1-9] \| 10) ;;` -> `[1-9] \| 1[0-9]) ;;` | CLAUDE_VERIFY_MAX_ATTEMPTS=11 falls back to 3 |
| A31b | H | `[1-9] \| 10) ;;` -> `[2-9] \| 10) ;;` | CLAUDE_VERIFY_MAX_ATTEMPTS=1 releases on the first failure |
| A32 | H | `if (depth == 1 && substr(text, i + 1, j - i - 1) == key) {` -> `if (substr(text, i + 1, j - i - 1) == key) {` | the outermost key decides: false after nested true is a fresh stop |
| A33 | H | `"FAIL "*" $fingerprint") ;;` -> `"NEVER "*" $fingerprint") ;;` | a cached pass never overrules the recorded failure of the same tree |
| A34 | H | `if [ "$stop_active" = "false" ]; then vstate_set attempts 0 \|\| true; fi` -> `if [ "$stop_active" != "true" ]; then ...` | empty stdin counts as a continued stop (attempt 2); missing key with failing verify: blocks 2,2 then releases 0 (222) (+1 more) |
| A35 | H | `if [ "$attempts" -lt "$max" ]; then` -> `if [ "$attempts" -le "$max" ]; then` | attempt 3 releases with exit 0; release prints valid JSON systemMessage (+9 more) |
| A36 | H | `if [ ! -x ./scripts/verify.sh ]; then` -> `if false; then` | non-executable verify.sh fails the gate |
| A37 | H | `if [ -n "$fingerprint" ] && [ "$fingerprint" = "$(vstate_get last-pass)" ]; then` -> `if [ "$fingerprint" = "$(vstate_get last-pass)" ]; then` | plain dir: pass path exit 0, state in temp dir; plain dir: no caching (verify reruns) (+1 more) |
| A38 | H | `if [ "$stop_active" = "false" ]; then attempts=1; else attempts="$max"; fi` -> `attempts=1` | the counter path is a directory: a fresh stop blocks once, a continued stop releases (222); the counter cannot be stored: a fresh stop blocks once, a continued stop releases (222) |
| A39 | H | same line -> `attempts="$max"` | the same two cases (000) |
| A56 | H | `} >&2 <LF> exit 2 <LF>` -> `} >&2 <LF> exit 0 <LF>` | exit 2 on failure; skip-worktree entry: the gate runs verify.sh and blocks (+30 more) |
| A40 | L | `git hash-object --no-filters --stdin-paths 2>/dev/null)" \|\| exit 1` -> `git hash-object --stdin-paths 2>/dev/null)" \|\| exit 1` | clean filter from .git/info/attributes: the edit changes the fingerprint; clean filter from .git/info/attributes: the gate runs verify.sh and blocks (+4 more) |
| A41 | L | `vstate_ls_files --others --exclude-per-directory=.gitignore \| while` -> `vstate_ls_files --others --exclude-standard \| while` | file hidden by .git/info/exclude: the edit changes the fingerprint; file hidden by .git/info/exclude: the gate runs verify.sh and blocks (+2 more) |
| A42 | L | `printf '%s%s\n' "$entries" "$hashes" \| git hash-object --stdin` -> `printf '%s\n' "$entries" \| git hash-object --stdin` | modified tracked file reruns verify; skip-worktree entry: the edit changes the fingerprint (+61 more) |
| A43 | L | `if [ "$no_mode_bits" = 1 ] \|\| [ -x "$path" ]; then state="file-x"; else state="file--"; fi` -> `state="file-x"` | a file that lost its executable bit changes the fingerprint (+2 more) |
| A44 | L | `entries+="$mode"$'\t'"$state"$'\t'"$path"$'\n'` -> `entries+="$state"$'\t'"$path"$'\n'` | another index mode of the one file of a tree changes the fingerprint |
| A45 | L | `state="link $state"` -> `state="link"` | another link text changes the fingerprint |
| A46 | L | `[ "$mode" != 160000 ] \|\| return 1 <LF>` -> `(removed)` | a tree with a gitlink in its index has no fingerprint |
| A47a | L | `*/ \| '"'* \| *$'\n'* \| *$'\r') return 1 ;;` -> `'"'* \| *$'\n'* \| *$'\r') return 1 ;;` | a tree holding an embedded repository has no fingerprint; Stop runs verify.sh there (+1 more) |
| A47b | L | same line without `'"'*` | a path that no line can name leaves the tree without a fingerprint (\"quoted.txt\") |
| A47c | L | same line without `*$'\n'*` | a path that no line can name leaves the tree without a fingerprint ($'first\nsecond') |
| A47d | L | same line without `*$'\r'` | a path that no line can name leaves the tree without a fingerprint ($'first\r') |
| A48 | L | `[ "$complete" -eq 1 ] \|\| exit 1 <LF>` -> `(removed)` | a repository whose index Git cannot read has no fingerprint |
| A49 | L | `MINGW* \| MSYS* \| CYGWIN*) no_mode_bits=1 ;;` -> `... no_mode_bits=0 ;;` | on a host without mode bits every regular file counts as executable |
| A51 | L | `cd "./$(git rev-parse --show-cdup 2>/dev/null)" 2>/dev/null \|\| exit 1` -> `:` | the fingerprint is the whole tree's from a directory below the root |
| A52 | L | `git hash-object --no-filters --stdin-paths 2>/dev/null)" \|\| exit 1` -> `... \|\| true` | a listed file that cannot be hashed leaves the tree without a fingerprint |
| A53 | L | `printf 'untracked\t%s\0' "$record"` -> `printf '100644\t%s\0' "$record"` | staging an untracked file changes the fingerprint |
| A54 | L | `... \| git hash-object --stdin 2>/dev/null)" <LF> [ -n "$state" ] \|\| return 1 <LF>` -> the first line alone | SURVIVED (guard without a stated behavior) |
| A55 | L | `state="missing"` -> `state="other"` | a directory at the path of the deleted file changes the fingerprint again |
| A57 | V | `--tier "$TIER" --fingerprint "$1"` -> `--tier "$TIER" --fingerprint ""` | the run left a manifest tied to the tree fingerprint; GIT_DIR and GIT_WORK_TREE of another repository: the manifest names this tree |
| T1 | `scripts/tests/test-checker.sh` | `if [ "$AWKS_RUN" -ge 1 ]; then` -> `if true; then` | test-checker.sh --all-awks without any of its awk implementations fails |
| R1 | R | `elif [ "$checks" -lt 1 ]; then` -> `elif false; then` | test_evidence.py::test_run_sh_records_each_listed_suite_and_a_tagged_file_it_never_runs_stops_the_tool |
| R2 | R | `elif [ "$failed" -ge 1 ]; then` -> `elif false; then` | the same test |
| R3 | R | `if ! record_suite "$name" "$status" "$checks" "$failed"; then` -> `if record_suite ...; false; then` | test_evidence.py::test_the_suite_runner_fails_when_a_suite_result_cannot_be_recorded |
| R4 | R | `if git -C "$SCRATCH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then` -> `if false; then` | test_evidence.py::test_the_suite_runner_stops_when_its_temp_dir_lies_inside_a_work_tree |
| P1a | P | `_NOT_RUN = ("skipped", "xfailed", "xpassed")` -> `_NOT_RUN = ("xfailed", "xpassed")` | test_forbid_skips_fails_a_session_with_a_test_that_did_not_run[skip-only], [module-level-skip], [importorskip] |
| P1b | P | same line -> `("skipped", "xpassed")` | test_forbid_skips_fails_a_session_with_a_test_that_did_not_run[xfail-only] |
| P1c | P | same line -> `("skipped", "xfailed")` | test_forbid_skips_fails_a_session_with_a_test_that_did_not_run[xpass-only] |
| P2 | P | `if self.config.getoption("--forbid-skips") and (not_run or never):` -> `... and not_run:` | test_forbid_skips_fails_a_session_whose_selected_tests_never_ran[pytest.exit-with-status-0], [collect-only], [setup-plan] |
| P3 | P | `if report.skipped:` in `pytest_collectreport` -> `if False:` | test_forbid_skips_fails_a_session_with_a_test_that_did_not_run[module-level-skip], [importorskip] |
| P4 | P | `record["outcome"] = "deselected"` -> `record["outcome"] = "passed"` | test_a_deselected_test_is_recorded_and_evidences_nothing |
| P5 | P | `if narrowed:` -> `if False:` | test_a_verification_session_selects_by_marker_expression_only[deselect], [keyword] |
| P6 | P | `if config.pluginmanager.is_blocked(RECORDER):` -> `if False:` | test_the_recorder_cannot_be_blocked |
| P7 | P | `if hidden:` -> `if False:` | test_a_test_file_that_git_ignores_stops_the_session |
| P8 | P | `and Path(module_file).name == "conftest.py"` -> `... == "no-conftest.py"` | test_a_test_file_that_git_ignores_stops_the_session |
| P9 | P | `if completed.returncode != 1:` -> `if False:` | test_a_git_that_fails_inside_a_repository_stops_the_session |
| P10 | P | `except OSError as error: <LF> raise pytest.UsageError(` -> `except OSError as error: <LF> return [] <LF> raise pytest.UsageError(` | test_a_git_that_fails_inside_a_repository_stops_the_session |
| P11 | P | `if not inside or not _in_repository(GIT_ROOT):` -> `if not inside:` | test_a_git_that_fails_inside_a_repository_stops_the_session |
| P12 | P | `if problems: <LF> raise pytest.UsageError("invalid evidence tags` -> `if False: ...` | test_unknown_or_malformed_tags_stop_the_session (4 parameter sets) |
| P13 | P | `"contract": item.get_closest_marker("contract") is not None,` -> `"contract": False,` | test_report_records_tags_outcomes_and_contract_flags |
| P14 | P | `"args": [str(arg) for arg in self.config.invocation_params.args],` -> `"args": [],` | test_report_records_tags_outcomes_and_contract_flags |

### Statement audit
Lines of the committed `docs/requirements/AVE-REQ-097-...md`. Results: a = a named case fails under the mutant listed; b = case added in this task; c = sentence reworded to the behavior that holds; d = worded as a limit with its inspection. "B2" marks a sentence about the checker or the evidence tool, which the brief gives to track B2; track A's reader sentences are marked likewise.

| Line | Sentence (shortened) | Result | Case or mutant |
|---|---|---|---|
| 36 | skipped, expected-to-fail, unexpectedly passing test; module skipped at collection; importorskip | a | P1a, P1b, P1c, P3 |
| 36 | selected test that never ran (`pytest.exit`, `--collect-only`, `--setup-plan`) | a | P2 |
| 36 | forms of `evidence.py unittest` | B2 | - |
| 37 | deselected test recorded, evidences nothing (plugin half) | a | P4; `show` and done gate: B2 |
| 38 | pytest step without a report fails | a | B14 |
| 38 | blocking the recorder is a usage error | a | P6 |
| 39, 41, 43 to 46 | tags, suite results, IDs, manifests, staleness | B2 | - |
| 40 | listed suite without a check or with a failed check fails `run.sh` | a | R1, R2 |
| 40 | `test-checker.sh --all-awks` without an awk implementation fails | a | T1; missing `jq` or `node`: B2 |
| 42 | tag with a criterion that does not exist stops the test run | a | P12; tooling half: B2 |
| 47 | index flags and fsmonitor leave the edit visible | a | A42 |
| 47 | filter, ident attribute, line-end conversion: raw bytes | a | A40 |
| 47 | ignore rule outside the `.gitignore` files | a | A41 |
| 47 | `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS` | a | L8, L9 |
| 47 | an entry holds the index mode or `untracked`, the executable bit, the raw bytes | a, b | A43, A42; A44 and A53 with the cases added |
| 47 | the Stop gate runs `verify.sh` | a | A42, A56; "evidence reads stale": B2 |
| 48 | gitlink, embedded repository, quote, line feed, carriage return, failing listing: no fingerprint | a | A46, A47a, A47b, A47c, A47d, A48 |
| 48 | a listed file that cannot be read: no fingerprint | b | A52, case `a listed file that cannot be hashed leaves the tree without a fingerprint` (a stand-in for git ends `hash-object --stdin-paths` as Git does for such a file; the suite runs as root) |
| 48 | the Stop gate runs `verify.sh` there | a | A37, V13 |
| 48 | a symbolic link enters with its link text | a | A45 |
| 48 | staging changes the entry | b | A53, case `staging an untracked file changes the fingerprint` |
| 49 | the plugin asks `git check-ignore` about every collected test file and loaded `conftest.py` | c, a | reworded (the clause "evidence comes only from files of the fingerprinted tree" is gone); P7, P8 |
| 49 | Git status other than 0 or 1; Git does not start; no repository | a | P9, P10, P11 |
| 50 | a file outside the fingerprint fails the step of every tier unless the list admits it | b, c | V01, V02, V09, V17, V16; D1 to D8, F1 to F8 (entries), W1 to W8, V10, V11 (bounds) |
| 50 | a second `.gitignore` fails; the last step walks again; embedded repository and gitlink count as named | b | V12; V03; V13, V14 |
| 51 | `verify.sh` sets `PYTHONSAFEPATH` for every step | a | A03; restart of the two scripts: B2 and track A |
| 52 | digest of the three modules and of every `ave` module their imports reach | b, c | G01 to G10; computed-name load: d, diff review |
| 53 | fast-tier stand-ins through the two variables and on `PATH` | a | B12, B13, A21, A22, A23 |
| 53 | absolute path or own `PATH` reach the real tool | c, d | reworded to both forms; `verify-requirement` section 8 |
| 54 | cached pass over a recorded failure decides nothing | a | A33 |
| 55 | a run starts in a new directory | a | A08; "recorded once": B2 |
| 56 | variables outside the named set and exported functions reach no step; the three variables; `--no-env-file`; a name that is no identifier | a, b | A01 (with `AVE_VAR_DIR` added to the caller's variables of the case), A24, A17, A02, A18, A03, A04, A05, B11, A07 |
| 57 | caches, configuration found first, ignore files change no result; the options | b, c | A06, B01 to B10, A05, P5; real-tool cases |
| 57 | `uv` finds `backend/uv.toml` and `backend/.python-version` first: files of the tree | d | measured by hand (table above); the walk step covers an ignored one (V01) |
| 58 | new: a tracked file below a directory that a tool passes over takes no part | d | measured (below); commit review |
| 59 | step file that cannot be loaded; unregistered entry never sourced | a | A11, A12; checker half: B2 |
| 60 | contract marker recorded | a | P13; gate half: B2 |
| 61 | fast tier under a heavier request; limit 1 to 10; limit 1; nested key | a | A30, A31, A31b, A32 |
| 61 | counter that cannot be stored or reads back as another value | a, b | S05, S07, A38, A39 |
| 61 | one or two digits, leading zero, 99 | b | S01, S02, S03, S04, S08 |
| 62, 65, 67 to 69 | settings file, entry points, `record`, inspection lines | B2 | - |
| 63 | `VERIFY_TIER` selects the tier and reaches no step | a | A10, A14 |
| 64 | a failing step fails the tier with exit 1 | a | A16 |
| 66 | done step in every tier | a | A20; evidence half: B2 |
| 70 | gate files | c | "the pytest, ruff and mypy configuration" |
| 71 | local state | c, d | listed paths, hand-written fixture under a valid key, directories above the tree (measured) |
| 77 | AC-1: membership, selection, usage errors, step files | a | A13, A19, A10, A14, A15, A11, A12; check 2 and `run.sh` temp dir: B2 (R4 fails its case) |
| 78 | AC-2, plugin clauses | a | P12, P14, P7, P9, P10, P11 |
| 78 | AC-2, cache key clauses | b | G01 to G10 |
| 78 | AC-2, stop-hook clauses (manifest fingerprint, states, bytes, bit, mode, deleted file, link, staging, no-fingerprint forms, redirect variables, nine variables) | a, b | A57, A40 to A49, A52, A53, A55, L1 to L9 |
| 78 | AC-2, tiers clauses (names, identifier, user site, env file, bytecode, foreign `GIT_DIR`, run directory, files outside the fingerprint, options, real tools) | a, b | A01, A24, A17, A02, A07, A04, B11, A06, A57, A08, V, D, F, W, B01 to B07 |
| 79 | AC-3, stop-hook and fast-tier clauses | a, b | A30, A37, A34, A35, A31, A32, A33, S01 to S05, S07, B12, B13, A21, A22, A23; check 12: B2 |
| 80 | AC-4, plugin clauses | a | P1a to P1c, P3, P2, P4, P5, P6, P13 |
| 80 | AC-4, tiers and stop-hook clauses | a, b | A16, A56, B14, V01, V06, V08, V07, T1; `test_evidence.py` clauses: B2 |
| 85 | `verify.sh` and step files | c | reworded; A, V and B series |
| 86 | evidence tool and plugin | a | plugin: P series; tool: B2 |
| 87 | generator | c | G series |
| 88 | stand-ins | a | B12, B13, A21 |
| 89 | fingerprint; nine variables | c | A40 to A55, L1 to L9 |
| 90 | Stop gate; counter | c | A30 to A39, S01 to S08; check 12: B2 |
| 92 | `-c`, `--forbid-skips`, `check-report`, done step | a | B09, B15, B14, A20 |
| 93 | `run.sh` | a | R1, R2, R3; evidence tool: B2 |
| 94 | tags per test file | a | `grep -o 'AVE-REQ-097 AC-[0-9]'` on the seven files equals the line |

Counts and names: eight directories and eight file forms (the two arrays), nine Git variables (the `unset` line), the variables of line 56 (all in the caller's set of the case now).

### Probe runs (container, copies under `/tmp`, removed afterwards)
- Run P, release tier on a copy with a file planted at every entry (287 files, access time set to 2001, own environment in `UV_PROJECT_ENVIRONMENT`): `git status --porcelain` empty before the run; `verify.sh: PASS — tier release (13 of 13 steps passed)`; hits of the poison: none; planted files whose access time moved: `scripts/tests/.DS_Store`, `scripts/tests/Thumbs.db` (tag scan of the evidence tool) and `backend/src/ave/.DS_Store`, `backend/src/ave/Thumbs.db` (copied by the package-copy helper of the new cache-key test; the helper copies sources only since then; run P was not repeated after that change).
- Run C: see item 2.
- Folder files where a check reads the directory fail closed: `scripts/verify.d/.DS_Store` (`is no registered component step file`), `ai-video-editor-requirements/Thumbs.db` (`baseline changed: the file is absent from the manifest`), `scripts/tests/.DS_Store` holding a tag line (the tooling unit tests and the evidence tool stop).
- Built-in exclusions, a tracked file in `backend/src/ave/<name>/` or `backend/tests/unit/<name>/` (exit 1 or a failing test means read): ruff reads `plain`, `build`, `.hidden`, `__pycache__` and passes over `dist`, `venv`, `node_modules`, `_build`, `site-packages`; mypy reads `plain`, `dist`, `build`, `venv`, `_build` and passes over `node_modules`, `site-packages`, `.hidden`, `__pycache__`; pytest collects `plain`, `_build`, `site-packages` and nothing below `dist`, `build`, `venv`, `node_modules`, `.hidden`.
- The step run read-only against the main checkout as it stands (its files, this branch's lists): exit 0 in 393 ms; the hand-run caches, bytecode directories, `.serena`, `backend/.venv`, worktrees and `var/` there are all admitted. Walk time in this worktree: under 1 s.

### Verification (command — result)
- `./scripts/verify.sh --tier release` on the staged tree (after `git add -A`) — PASS, `verify.sh: PASS — tier release (13 of 13 steps passed)`: `Ran 37 tests`; `132 passed, 84 deselected`; `84 passed, 132 deselected in 342.56s`; CHECKER TOTAL pass=1090 fail=0; BASELINE 305/0; STOP HOOK 174/0; SESSION START 56/0; VERIFY TIERS 133/0; PROBE 155/0.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --require-complete --tier release` after the commit — exit 0, `Freshness: FRESH`, AC-1 to AC-4 passed.
- `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh` — `VERIFY TIERS TOTAL: pass=133 fail=0`.
- `./scripts/dev-container.sh bash scripts/tests/test-stop-hook.sh` — `STOP HOOK TOTAL: pass=174 fail=0`.
- `. scripts/lib/verify-state.sh && vstate_fingerprint` under Git Bash and in the container — both `d92a5b1eb45b98e25894eac895ef476409a56d79`.
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` — `OK: baseline intact`; `./scripts/check-project-control.sh` — `OK: 51 required files ...; 0 warning(s)`.
- ruff format, ruff lint, mypy with the step's options — exit 0 each; `pytest tests/unit/test_fixture_cache_key.py tests/unit/test_fast_tier_media_tools.py` — 11 passed.
- Run P and run C (release tier in copies) — PASS, 13 of 13 each.
- `git status --short` after the commit — empty; `git diff --cached --summary` before it — no mode change; index modes 100755 for `scripts/verify.sh`, the two suites and the hook.
- CI was not run (nothing pushed).

### Forced edits
None.

### Proposed text for documents outside my paths
1. `docs/ARCHITECTURE.md`, § Verification pipeline item 2 — old: "`--tier fast` (default): project control files, no ignored file among sources, tests, scripts and hooks, requirements baseline integrity," — new: "`--tier fast` (default): project control files, no file outside the fingerprint and the listed ignored paths, requirements baseline integrity,".
2. Same item — old: "keeps bytecode and the type checker's cache in a scratch directory outside the tree, keeps the directory of a script out of every Python module path" — new: "keeps bytecode and the type checker's cache in a scratch directory outside the tree, starts ruff without a cache and without an ignore file, names `backend/pyproject.toml` as the configuration of ruff, mypy and pytest, keeps the directory of a script out of every Python module path".
3. `docs/ARCHITECTURE.md` item 7 and `CLAUDE.md` § Verification — old: "(outputs go to gitignored paths)" — new: "(outputs go below `var/`)"; an ignored path outside the list now fails the run.
4. `docs/ASSUMPTIONS.md` ASM-023 — old: "`verify.sh` starts its steps from a named set of variables and reads no cache from the tree; a replaced" — new: "`verify.sh` starts its steps from a named set of variables, reads no cache from the tree and admits outside the fingerprint only the listed ignored paths (`IGNORED_DIRECTORIES` and `IGNORED_FILES` in `scripts/verify.sh`); what lies at those paths, a fixture written by hand under a valid cache key among it, is local state; a replaced".
5. `docs/ASSUMPTIONS.md` ASM-030 — old: "as in the ignored-file step." — new: "as in the step \"No file outside the fingerprint and the listed paths\".".
6. `docs/requirements/AVE-REQ-098-...md` § Edge cases — old: "→ the gate still releases: a fresh stop blocks once and a continued stop releases (AC-4)." — new: "→ the gate still releases: a fresh stop blocks once and a continued stop releases. A counter file counts when it holds a decimal number of one or two digits, read as decimal also with a leading zero; every other content counts as 0, and the counter stops at 99 (AC-4)."
7. Same file § Verification strategy AC-4 — old: "a counter that is stored and reads back as another value still ends in a release" — new: "a counter that is stored and reads back as another value, or that cannot be stored, still ends in a release; a counter file written by hand counts as a decimal number of one or two digits and as 0 otherwise".
8. `backend/tests/evidence_plugin.py` (outside every track) — docstring, old: "so evidence comes only from files of the tree the fingerprint names." — new: "so every test file and conftest.py of a session is a file that the fingerprint names; scripts/verify.sh fails on every other file outside the fingerprint."; message, old: "test files that Git ignores (evidence comes only from files of the tree the fingerprint names):" — new: "test files that Git ignores (a session takes its test files from paths the fingerprint names):". The plugin test asserts the first four words only.
9. `scripts/tests/run.sh` header — old: "test-verify-tiers.sh    tier selection, exit codes and heavy-media lock of scripts/verify.sh" — new: the same line plus "; the files outside the fingerprint; the options of the backend step file with the real ruff and mypy (needs uv)".

### Shared-document updates for the lead
- `docs/TRACEABILITY.md` — AVE-REQ-097 row (reviewer's non-blocking 5): Implementation adds `scripts/check-project-control.sh`, `scripts/lib/media-tier-only.sh`, `backend/src/ave/fixtures/generate.py`; Tests adds `scripts/tests/test-checker.sh`, `backend/tests/unit/test_fixture_cache_key.py`, `backend/tests/unit/test_fast_tier_media_tools.py`.
- `docs/ASSUMPTIONS.md` — new entry: The list of ignored paths admits what hand runs and agent tools leave — assumption: eight directories and eight file forms pass outside the fingerprint; the three hand-run cache directories of `backend/` are among them — reason: documented hand commands leave them and no step reads them (run P, the stale-cache case) — impact: an ignored path anywhere else fails every tier until it is removed or listed with a run that shows no step reads it.
- `docs/ASSUMPTIONS.md` — new entry: The step walks the tree — assumption: a file counts by being on disk outside the fingerprint, whatever Git lists — reason: Git lists nothing inside a directory named `.git` below the root and no special file — impact: one `find` over the tree at the start and at the end of each run; listed directories are not entered.
- `docs/ASSUMPTIONS.md` — new entry: The generator digest reads import statements — assumption: the closure of `import` statements stands for what the generator runs — reason: the same in every process — impact: a module loaded by a computed name needs the diff review.
- `docs/ASSUMPTIONS.md` — new entry: The failed-attempt counter has two digits and stops at 99 — reason: the limit is at most 10; a value the gate would read as 0 restarts the blocks — impact: none in normal use.
- `docs/requirements/AVE-REQ-097-...md` — Status log line for this fix round and the transition; AC ticks and Test evidence after `verify-requirement`.
- `docs/PROGRESS.md` — branch `m0-r2-fixes-b1` at `bde7989` (local only until pushed).

### Deviations, open issues, follow-up requirements
- Deviation, item 1: the step walks the tree and so fails on a superset of the listing the decision names. Reason: the measured forms that no Git listing holds. Recommended resolution: keep it; the alternative is the literal listing plus a limit sentence for `.git` directories and special files.
- Deviation, item 1: an ignored `.gitignore` inside a listed directory passes with the directory (CI holds `backend/.venv/.gitignore`); one that the fingerprint names fails everywhere.
- Decision for the lead, item 2: the three cache directories are on the list, so a cache left by a hand run passes; the reviewer's sentence "a cache left in backend/ fails the run by itself" does not hold for them. Dropping the three entries is a three-line change; then every hand run of pytest, ruff or mypy in `backend/` fails the next run until the directory is removed, and the main checkout, which holds `backend/.mypy_cache` and `backend/.ruff_cache` today, fails at its first stop after the merge.
- Added beyond the brief: the second walk after the steps; the stop at 99; the real-tool cases (the tiers suite now needs `uv` and the backend environment, which the release tier and the container provide); five fingerprint cases found by the audit; a new Edge case line for the built-in exclusions.
- Limit, new Edge case line 58 (discovered work): ruff, mypy and pytest pass over tracked files below directories of certain names. No tracked path under `backend/` is such a path today. Proposed follow-up requirement under AVE-FEAT-019: "Tracked backend files lie where every backend tool reads them" — a checker rule that fails a tracked path under `backend/src` or `backend/tests` with a component named `dist`, `build`, `venv`, `node_modules`, `_build`, `site-packages`, `__pycache__` or beginning with a dot; rationale: a failing test or an unlinted module there passes all steps while the diff shows only a new file.
- Limit: files above the tree (a uv workspace that names `backend/` as a member) are local state; stated in line 71. `uv --no-config` would also take the user-level and system-level uv configuration out; not added, because line 71 already names the files under `HOME` as local state.
- Follow-up for the stack: the root `.gitignore` holds `node_modules/`, `dist/`, `playwright-report/`, `test-results/`, `.coverage`, `htmlcov/` and nested `.env` files; each fails the step today. The requirement that brings the frontend toolchain adds its entries to the list with a run that shows no step reads them, or sends the output below `var/`.
- A failing start walk also fails the step "Working tree unchanged by verification" of the same run (the list of paths is printed twice).
- Pre-existing failures: none met.
