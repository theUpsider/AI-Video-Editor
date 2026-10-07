# Handback — M0 review round two, fixes, part 1: track A, the baseline gate (AVE-REQ-093)

Brief: [2026-10-07-m0-review-2-fixes.md](../2026-10-07-m0-review-2-fixes.md). Run `wf_6c06f19f-506` ([script](../../workflows/m0-review-2-fixes.js)), branch `m0-r2-fixes-a` from `07eceb1`, commit `574cc37`. The report below is the writer's, unedited apart from local paths, the level of its headings and the path of 2 links to the roadmap, which resolve from this directory. The host stood in standby from 00:38 to 09:52 local time on 2026-10-07; the run started tracks A and B1 again at 09:52 with new writers in the same worktrees.

## Report

### Result: COMPLETE

Track A of `docs/briefs/2026-10-07-m0-review-2-fixes.md` (AVE-REQ-093 AC-3). Branch `m0-r2-fixes-a`, commit `574cc37a97080b0be666ad3b74ad4ab49a4da5ee`, on base `07eceb1aa1693df708c240642f837d8838be175a` (confirmed with `git rev-parse HEAD` before the first change). Nothing pushed, merged or rebased; the worktree is clean.

### Requirements
- AVE-REQ-093 — Adopt and preserve the supplied requirements baseline — ACs done: AC-1, AC-2 (inspection, untouched), AC-3, AC-4; open: none — proposed status `verification` (the lead records it; frontmatter, criteria, Test evidence and Status log are untouched).

### Changes (file — purpose)
- `scripts/reqfile.py` — footnote rule (`FOOTNOTE`), one fence form (`FENCE_RUN`, `FENCE_OPEN`, `fence_like`), the line rules shared with the roadmap reader (`inline_problems`), `bad_character` made public.
- `scripts/check_baseline.py` — `read_roadmap()` rewritten (characters, reader's fence and line rules, one link form, headings, entry headings, Status lines and list labels by `roadmap_key`, list grammar, items of one line); successor status rule in `check_supersession`; docstring checks e and g.
- `scripts/tests/test-check-baseline.sh` — 305 cases before, 424 after; helpers `edge`, `m1_end`, `entry_end`, `list_line`; `successor()` now writes a `ready` replacement on the requirement list.
- `docs/requirements/README.md` — § Canonical form rules 3 and 5, § Superseding step 2.
- `docs/ROADMAP.md` — § Rules 8 (rule text only; no entry line changed).
- `docs/requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md` — § Edge cases, § Verification strategy, § Implementation evidence.

### Items of track A
1. **Footnotes — fixed.** `[^` fails outside code spans and fenced blocks in every working file; so does `^[` (the inline footnote of markdown-it, found by the differential check). Cases: "heading in a footnote definition fails" (the reviewer's reproduction), "heading behind a quote sign in a footnote definition fails", "heading behind a bullet in a footnote definition fails", "footnote reference fails", "inline footnote fails", "footnote definition in a feature file fails", "footnote syntax in a code span and in a fenced block passes"; roadmap: "footnote definition in the roadmap fails". Mutants N01 to N04.
2. **Fenced blocks by allow-list — fixed.** One form (three backticks at column 0, alone or with one word of letters, digits, `_`, `-`; closing line exactly three backticks at column 0); every other line whose reading behind leading spaces and container markers opens with three or more backticks or tildes fails, inside a block too, and opens no block. The info characters `+` and `.` left the allow-list (no working file used them). Same functions for `docs/ROADMAP.md`. Cases: the 21 fence cases of the canonical-form block (from "fence with a backtick in its info fails" to "fence with an info word of letters, digits, _ and - passes") and 10 roadmap fence cases. Mutants N05 to N14, C59 to C61. Comparison with CommonMark for the six forms the brief names: construct rows R36 to R49 and M56 to M61.
3. **Roadmap — fixed.** Decisions of the brief implemented: every line outside fenced blocks follows the reader's rules for raw HTML and backtick runs; characters by the reader's allow-list plus U+2026 (`ROADMAP_CHARACTERS`); Status lines and list labels found by normalization; exactly one Status line of the exact form; a heading that reads as an entry heading has the template form. Rules added because the differential check showed a difference (see Deviations): characters judged with character references resolved; footnote syntax; one link form; headings at column 0 and no line of `=` or `-` alone; entry runs to the next heading of level 1 to 3; requirement lists hold links only, Proposed lines links and plain words; a line the gate reads is a list item of one line; link targets and ticked task boxes leave the letters. Cases: the roadmap block from "underscore-bold second Status line fails" to "Proposed line with links and plain words passes" (88 new cases). Mutants C01 to C63, C67, C68.
4. **Successor status — fixed.** The end of the supersession chain of an imported requirement is never `proposed`; `blocked` stays reported. Cases: "successor in proposed fails", "chain that ends in a proposed requirement fails", "successor in blocked is reported". Mutants C64 to C66.
5. **Differential check — done.** cmarkgfm 2025.10.22 (cmark-gfm, footnotes option, raw HTML passed through) and markdown-it-py 4.2.0 with mdit-py-plugins 0.6.1 (footnote, tables, strike-through, task lists), installed with `uv pip install --target` under the container's `/tmp/ta093`. 188 constructs, each inserted into a copy of `AVE-REQ-001-…md` (86) or of `docs/ROADMAP.md` (102). On the committed tree: 149 refused by the gate, 39 shown by both renderers as the gate reads them, 0 differing. The same script on the gate of the base commit `07eceb1`: 93 refused, 52 the same, 43 differing (among them the reviewer's forms). Not viewed on github.com or in a browser; GitHub features beyond CommonMark and its Markdown specification were compared with no renderer (limit stated in § Edge cases).

### Mutation list
Run in the container on the committed tree: one replacement per private copy under `/tmp/ta093/mut/<id>`, every `__pycache__` directory deleted, then the copy's suite with the named cases and the control "clean import passes" (the case filter exists only in the copy's `run_case`). 240 mutants, 240 killed: every named case failed and the control passed. Reading: `<<old ==> new>>` is the replaced text, `//` a line end, `...` shortened context; leading spaces are left out (A54, A56 and A66 take the line with eight, eight and four leading spaces); `(+n)` further named cases that failed too. CB = `scripts/check_baseline.py`, RF = `scripts/reqfile.py`, IB = `scripts/requirements/import_baseline.py`. Notes: C21 has the control as its case; B48 and B54 change every imported file, so the control fails with the named case; B53 holds two changes (also `return load_source("import_baseline", IMPORTER)` replaced as in B01), since the isolated restart and the load from source each hold the cache off alone; A27 and B55 fail their case through an unhandled exception of the mutant.

```text
N01 RF if <<FOOTNOTE.search(plain) ==> False>>: | heading in a footnote definition fails (+6)
N02 RF FOOTNOTE = re.compile(r"\[\^<<|\^\[ ==> >>") | inline footnote fails
N03 RF FOOTNOTE = re.compile(r"\<<[\^|\ ==> >>^\[") | footnote reference fails (+1)
N04 RF kept.append(<<" " ==> line[position:closer]>>) // position = closer | footnote syntax in a code span and in a fenced block passes (+2)
N05 RF return <<any(FENCE_RUN.match(form) for form in readings ==> bool(FENCE_RUN.match>>(line)) | indented fence fails (+8)
N06 RF FENCE_RUN = re.compile(r"`{3,}<<|~{3,} ==> >>") | tilde fence fails (+3)
N07 RF FENCE_OPEN = re.compile(r"^```[A-Za-z0-<<9_ ==> 9_+.>>-]*$") | fence with a plus sign in its info word fails (+2)
N08 RF FENCE_OPEN = re.compile(r"^```[A-Za-z0-9_-]*<<$ ==> >>") | fence with a backtick in its info fails (+3)
N09 RF FENCE_OPEN = re.compile(r"^```[A-Za-<<z0-9_- ==> z>>]*$") | fence with an info word of letters, digits, _ and - passes
N10 RF else: // <<self ==> fenced = True // self>>._problem( // f"line {number}:... | line behind a refused fence line is judged
N11 RF if <<line ==> line.rstrip()>> == FENCE_CLOSE: | closing fence line with trailing spaces fails
N12 RF elif <<fence_like(line) ==> False>>: | fence line inside a fenced block fails (+4)
N13 RF if <<fenced ==> False>>: // self._problem("a fenced b... | unclosed fence fails
N14 RF if FENCE_OPEN.match(line): // fenced = <<True ==> False>> | plain fenced block in Edge cases passes (+1)
C01 CB if <<reqfile.bad_character(char) and ord(char) not in ROADMAP_CHARACTERS ==> False>>: | second Status line with a Cyrillic letter fails (+4)
C02 CB ROADMAP_CHARACTERS = {<<0x2026: "horizontal ellipsis" ==> >>} | horizontal ellipsis and the signs of the allow-list pass in the roadmap
C03 CB for char in <<html.unescape(line) ==> line>>: | Cyrillic letter as a character reference in the roadmap fails (+1)
C04 CB data = ROADMAP.<<read_bytes( ==> read_text(encoding="utf-8").encode("utf-8">>) | carriage returns in the roadmap fail
C05 CB <<problems.extend(f"line {number}: {problem}" for problem in reqfile.inline_problems(line)) ==> pass>> | roadmap Status line inside a processing instruction fails (+5)
C06 RF if <<RAW_HTML.search(plain) ==> False>>: | roadmap Status line inside a processing instruction fails (+7)
C07 RF if <<unpaired ==> False>>: | run of backticks unpaired on a roadmap line fails (+2)
C08 CB if <<LINK_MARKS.search(PLAIN_LINK.sub("", plain)) ==> False>>: | second Status line behind a link without words fails (+4)
C09 CB PLAIN_LINK = re.compile(r"(?<!!)\[[A-Za-z0-<<9][A-Za-z0-9 ==> 9>> .-]*\]\([A-Za-z0-9_./#:-]+\)") | second Status line behind a link without words fails
C10 CB PLAIN_LINK = re.compile(r"<<(?<!!) ==> >>\[[A-Za-z0-9][A-Za-z0-9 .-]*\]... | second Status line behind an image fails
C11 CB PLAIN_LINK = re.compile(r"(?<!!)\[...-]*\]\([A-Za-z0-9_./#:<< ==> () \">>-]+\)") | link whose target holds parentheses fails (+1)
C12 CB LINK_MARKS = re.compile(r"\]\(|!\[<<|\]\[ ==> >>") | second Status line behind a reference link fails
C13 CB PLAIN_LINK = re.compile(r"(?<!!)\[... .-]*\]\([A-Za-z0-9_./<<#: ==> >>-]+\)") | plain links in an entry pass
C14 CB shown = TASK_BOX.sub("", <<LINK_TARGET.sub("]", text) ==> text>>) | second Status line behind a plain link fails (+1)
C67 CB shown = <<TASK_BOX.sub("", LINK_TARGET.sub("]", text) ==> LINK_TARGET.sub("]", text>>) | second Status line behind a ticked task box fails (+1)
C68 CB TASK_BOX = re.compile(r"\[[<<xX ==> x>>]\]") | second Status line behind a task box ticked with a capital X fails
C15 CB return re.sub(kept, "", <<html.unescape(shown) ==> shown>>.lower()) | second Status line with a character reference fails (+2)
C16 CB kept = "[^a-z0-9]" if digits else "[^a-<<z ==> z`>>]" | second Status line with a code span as its label fails
C17 CB kept = "[^a-z0-9]" if digits else "[^a-<<z ==> z\\\\>>]" | second Status line behind escaped stars fails
C18 CB kept = "[^a-z0-9]" if digits else "[^a-<<z ==> z|>0-9.>>]" | second Status line in a quote fails (+2)
C19 CB return re.sub(kept, "", html.unescape(shown).<<lower( ==> replace("S", "s").replace("R", "r").replace("P", "p").replace("M", "m").replace("D", "d">>)) | upper-case second Status line fails (+1)
C20 CB if group == "milestone" and <<reads_as.startswith(STATUS_WORD ==> "**status" in line.lower(>>): | underscore-bold second Status line fails (+9)
C21 CB if <<group == "milestone" and reads_as ==> reads_as>>.startswith(STATUS_WORD): | clean import passes
C22 CB MILESTONE_STATUS = re.compile(r"^-...nned|in-progress|done)<<$ ==> >>") | milestone Status done with a full stop fails (+1)
C23 CB MILESTONE_STATUS = re.compile(r"^<< ==>  *>>- \*\*Status:\*\* (planned|in-... | indented milestone Status line fails
C24 CB MILESTONE_STATUS = re.compile(r"<< ==> (?i)>>^- \*\*Status:\*\* (planned|in... | capitalised milestone Status fails
C25 CB MILESTONE_STATUS = re.compile(r"^-... (planned|in-progress|<<done ==> done|complete>>)$") | unknown milestone Status word fails
C26 CB MILESTONE_STATUS = re.compile(r"^- \*\*Status:\*\* <<(planned|in-progress|done) ==> \**(planned|in-progress|done)\**>>$") | bold milestone Status word fails
C27 CB if name != "FUTURE" and entry["status_lines"] <<!= ==> >>> 1: | milestone without a Status line fails
C28 CB if name != "FUTURE" and entry["status_lines"] <<!= ==> <>> 1: | milestone with two Status lines fails (+1)
C29 CB if <<not NEXT_ITEM.match(line) ==> False>>: | continuation line under the Status line fails (+4)
C30 CB ) // read_line = "" // if fenced: (the line read_line = "" moved four spaces to the left) | paragraph behind a blank line under a requirement list fails
C31 CB NEXT_ITEM = re.compile(r"- <<|#{1,6}(?: |$) ==> >>") | heading right behind the Deferred list passes
C32 CB NEXT_ITEM = re.compile(r"<< ==>  *>>- |#{1,6}(?: |$)") | nested item under a requirement list fails
C33 CB <<read_line = line ==> pass>> | continuation line under the Status line fails (+1)
C34 CB <<read_line = label ==> pass>> | nested item under a requirement list fails (+2)
C35 CB LIST_WORDS = ("<<requirement ==> requirements>>", "proposed") | second list under a label in the singular fails
C36 CB LIST_WORDS = ("requirement",<< "proposed" ==> >>) | Proposed line under another label fails (+2)
C37 CB if not <<reads_as.startswith(LIST_WORDS ==> re.match(r"^ *[-*+] +\*\*(?:requirements|proposed)", line, re.IGNORECASE>>): | underscore-bold requirement list fails (+4)
C38 CB if found is None: // <<problems ==> continue // problems>>.append( | requirement list under another label fails (+6)
C39 CB if <<key in current["lists"] ==> False>>: | second requirement list in one entry fails (+1)
C40 CB if <<words is None and not LINKS_ONLY.fullmatch(rest) ==> False>>: | struck requirement link fails (+7)
C41 CB if <<words is not None and not words.fullmatch(ROADMAP_LINK.sub("", rest)) ==> False>>: | struck word on a Proposed line fails (+2)
C42 CB PLAIN_WORDS = re.compile(r"(?: [A-Za-z0-9 (),.;:<< ==> ~>>-]*)?") | struck word on a Proposed line fails
C43 CB PLAIN_WORDS = re.compile(r"(?: [A-Za-z0-9 (),.<<; ==> >>:-]*)?") | Proposed line with links and plain words passes
C44 CB if <<any(reqfile.UNDERLINE.match(form) for form in forms) ==> False>>: | underline in the roadmap fails (+1)
C45 CB if <<any(reqfile.UNDERLINE.match(form) for form in forms ==> reqfile.UNDERLINE.match(line>>): | underline in a quote of the roadmap fails
C46 CB if <<any(reqfile.ATX.match(form) for form in forms) ==> False>>: // problems.append( // f"lin... | roadmap heading in a quote fails (+2)
C47 CB if <<ENTRY_LIKE.match(roadmap_key(line, digits=True)) ==> False>>: | milestone heading with a hyphen fails (+9)
C48 CB ENTRY_LIKE = re.compile(r"<<\d* ==> >>(?:m\d|deferred)") | milestone heading behind a number fails (+1)
C49 CB ENTRY_LIKE = re.compile(r"\d*(?:m\<<d|deferred ==> d>>)") | Deferred heading with a colon fails
C50 CB MILESTONE = re.compile(r"^### (<<M(?:0|[1-9]\d*) ==> M\d+>>) — \S") | milestone heading with a leading zero fails
C51 CB MILESTONE = re.compile(r"^### (M(?:0|[1-9]\d*)) —<< \S ==> >>") | milestone heading without a name fails
C52 CB MILESTONE = re.compile(r"^#<<## ==> {2,4}>> (M(?:0|[1-9]\d*)) — \S") | milestone heading of level 4 fails (+1)
C53 CB MILESTONE = re.compile(r"^### (M(?:0|[1-9]\d*)) <<— ==> [—-]>> \S") | milestone heading with a hyphen fails
C54 CB DEFERRED = re.compile(r"^### <<Deferred — \S ==> Deferred>>") | Deferred heading with a colon fails
C55 CB if <<len(line) - len(line.lstrip("#")) <= 3 ==> True>>: | second Status line under a sub-heading of the entry fails
C56 CB if <<len(line) - len(line.lstrip("#")) <= 3 ==> False>>: | Status line under a phase heading is free text
C57 CB if <<reqfile.ATX.match(line ==> line.startswith("#">>): | hashes without a space end no entry
C58 CB if <<name in entries ==> False>>: | second entry for one milestone fails (+1)
C59 CB elif <<reqfile.fence_like(line) ==> False>>: | longer fence line inside a roadmap fence fails (+1)
C60 CB if <<reqfile.FENCE_OPEN.match(line) ==> True>>: // fenced = True // else: | tilde fence around a roadmap list fails (+4)
C61 CB if reqfile.FENCE_OPEN.match(line): // fenced = <<True ==> False>> // else: | roadmap list inside a fenced block is no list (+2)
C62 CB if <<"<!--" in text ==> False>>: // problems.append("an HTML ... | roadmap list inside an HTML comment fails
C63 CB if <<text_id != target_id ==> False>>: | roadmap link text naming another file fails
C64 CB if <<successor.get("status") == "proposed" ==> False>>: | successor in proposed fails (+1)
C65 CB successor, seen = <<chain_end(files, item.get("superseded_by") ==> (files.get(item.get("superseded_by"), [None])[0], [item.get("superseded_by")]>>) // if successor is None: | chain that ends in a proposed requirement fails (+1)
C66 CB if successor.get("status") <<== "proposed" ==> in ("proposed", "blocked")>>: | successor in blocked is reported
A01 CB if <<actual != digest ==> False>>: | edited package validator fails (+1)
A02 CB elif <<len(data) != size ==> False>>: | manifest with another size entry fails
A03 CB for name in <<sorted(entries.keys() - on_disk ==> (>>): | removed baseline file fails
A04 CB for name in <<sorted(on_disk - entries.keys() ==> (>>): | file added behind an edited validator fails
A05 CB if check_package_files(importer.PKG)<< ==>  or True>>: | edited package validator is never run
A06 CB if <<actual != BASELINE_MANIFEST_SHA256 ==> False>>: | edited MANIFEST.json fails (+2)
A07 CB if <<extra != manifest ==> False>>: | second MANIFEST.json in the package fails
A08 CB <<error(manifest, "baseline changed: the manifest is missing or unreadable") ==> pass>> | removed MANIFEST.json fails
A09 CB if <<entry.is_symlink() ==> False>>: | symbolic link added fails (+1)
A10 CB if <<result.returncode != 0 ==> False>>: | edited baseline requirement fails (+2)
A11 CB if <<item.get("title") != title ==> False>>: | changed title (+2)
A12 CB <<expect(item, "type", req["type"], "the mapped baseline") ==> pass>> | changed type
A13 CB <<expect(item, "priority", req["priority"], "the mapped baseline") ==> pass>> | demoted priority
A14 CB <<expect(item, "source", req["source"], "the origin-derived") ==> pass>> | changed source (+1)
A15 CB <<expect(item, "parent", req["feature"]) ==> pass>> | changed parent
A16 CB <<expect(item, "scope", req["scope"]) ==> pass>> | changed scope
A17 CB <<expect(item, "origins", req["origins"]) ==> pass>> | changed origins
A18 CB <<expect(item, "scenarios", req["scenarios"]) ==> pass>> | changed scenarios
A19 CB <<expect(item, "baseline", importer.baseline_req_path(req["id"])) ==> pass>> | changed baseline path
A20 CB if <<dependencies is None or ==> False and>> [ | baseline dependency added fails (+2)
A21 CB dep for dep in dependencies if <<dep in imported or dep.startswith(("AVE-FEAT", "AVE-EPIC")) ==> True>> | derived dependency added to a baseline requirement passes
A22 CB future = all(r["scope"] == "future...or r in f["reqs"]) // <<expect(item, "priority", "could" if future else "must") ==> pass>> | demoted epic priority fails (+1)
A23 CB future = all(r["scope"] == "future...n feature["reqs"]) // <<expect(item, "priority", "could" if future else "must") ==> pass>> | demoted feature priority fails
A24 CB <<expect(item, "goals", [epic["goal"]]) ==> pass>> | changed epic goal fails
A25 CB <<expect(item, "parent", feature["epic"]) ==> pass>> | changed feature parent
A26 CB found = files.get(item_id, []) // if len(found) <<!= ==> <>> 1: | duplicate working file (+1)
A27 CB found = files.get(item_id, []) // if len(found) <<!= ==> >>> 1: // where | missing working requirement (+2)
A28 CB if <<len({item.id for item in items}) > 1 ==> False>>: | second ID for one number fails (+1)
A29 CB if <<item.h1 != f"# {item.id} — {item.get('title')}" ==> False>>: | changed H1
A30 CB if <<item.get("id") != item.id ==> False>>: | changed frontmatter id
A31 CB if <<feature_file is not None and not lists_child(feature_file, item) ==> False>>: | feature no longer lists its requirement (+1)
A32 CB if <<parent is not None and not lists_child(parent, item) ==> False>>: | epic no longer lists its feature
A33 CB line.startswith("- [") and target ...ne for line in parent.<<sections.get(section, [] ==> text.split("\n">>) | requirement link moved to Out of scope fails
A34 CB if working is not <<None and working[1] == text ==> None>>: | altered criterion without log line (+1)
A35 CB if working is <<not None and ==> None or>> working[1] == text: | removed criterion without log line (+1)
A36 CB if <<description != req["statement"].strip() ==> False>>: | rewritten description without log line (+3)
A37 RF return "\n".join(self.<<raw_sections ==> sections>>.get("Description", [])).strip() | fenced block added to the description fails
A38 RF if <<text.startswith(prefix) ==> prefix in text>>: | log line quoting the rule does not count (+1)
A39 RF return hashlib.sha256(text.encode("utf-8")).hexdigest()[:<<16 ==> 8>>] | mark of eight digits does not count
A40 RF if not reason.startswith("<")<< and REASON.search(reason) ==> >>: | reason of punctuation alone does not count (+1)
A41 RF if <<not reason.startswith("<") and REASON ==> REASON>>.search(reason): | placeholder reason does not count
A42 RF if <<text.startswith(prefix ==> re.sub(r" \[[0-9a-f]{16}\]", "", text).startswith(re.sub(r" \[[0-9a-f]{16}\]", "", prefix)>>): | second rewording under the first line fails (+2)
A43 CB <<notes.append(f"Recorded change: {req['id']} {ac_id} {what} — {reason}") ==> pass>> | altered criterion with recorded change (+1)
A44 CB <<notes.append(f"Recorded change: {req['id']} Description {what} — {reason}") ==> pass>> | rewritten description with recorded change
A45 RF for line in <<self.criteria_extras ==> >>(): | continuation line under a criterion fails (+3)
A46 CB if <<ac_id in baseline_ids ==> True>>: // continue // marker = f"{a... | additional criterion without log line fails (+1)
A47 CB <<notes.append(f"Recorded addition: {req['id']} {ac_id} — {reason}") ==> pass>> | additional criterion with recorded addition
A48 RF for line in <<self.raw_sections.get("Status", []) ==> [l for s in self.raw_sections.values() for l in s if LOG_LINE.match(l) or s is self.raw_sections.get("Status")]>>: | log line outside ## Status does not count (+1)
A49 CB if <<req["scope"] == "future" and status not in ("deferred", "superseded") ==> False>>: | future requirement made ready
A50 CB if <<req["scope"] == "v1" and status == "deferred" ==> False>>: | version-one requirement deferred
A51 CB if <<status == "proposed" ==> False>>: | imported requirement set back to proposed fails
A52 CB if <<unfinished ==> False>>: | feature done while its requirements are unfinished fails (+2)
A53 CB if <<ticked and not (was_done and status in ("done", "superseded")) ==> False>>: | feature box ticked before done fails (+6)
A54 CB  // if <<ticked and not (was_done and status in ("done", "superseded")) ==> False>>: | ticked criterion on a ready requirement fails (+3)
A55 CB was_done = <<"done" in item.log_statuses() ==> True>> // if ticked and not | status done without a done log line fails (+1)
A56 CB  // if ticked and not (was_done and status in ("done",<< "superseded" ==> >>)): | superseded after done keeps its ticks
A57 CB if <<future != (item.get("status") == "deferred") ==> False>>: // error(item.path, "status ... (the epic loop) | future epic made ready
A58 CB if <<seen and (len(last) != 1 or last[0].kind != "REQ") ==> False>>: | superseded by a missing requirement fails
A59 CB if successor.get("scope") != "v1"<< or successor.get("status") == "deferred" ==> >>: | superseded by a deferred requirement fails
A60 CB if successor.get("<<scope") != "v1" or successor.get("status ==> status>>") == "deferred": | superseded by a future-scope requirement fails
A61 CB if <<PRIORITY_RANK.get(successor.get("priority"), 0) < PRIORITY_RANK.get(req["priority"], 0) ==> False>>: | superseded by a weaker requirement fails
A62 CB if <<successor.get("type") != req["type"] ==> False>>: | successor of another type fails
A63 CB if <<req["source"] == "human" and successor.get("source") != "human" ==> False>>: | derived successor of a human requirement fails
A64 CB for key in ("origins",<< "scenarios" ==> >>): | successor without the baseline scenarios fails
A65 CB for key in ("<<origins", "scenarios" ==> scenarios",>>): | successor without the baseline origins fails
A66 CB  // if <<description != req["statement"].strip() ==> False>>: | successor with another Description fails
A67 CB for ac_id, text in req["criteria"]: // if <<text in carried ==> True>>: | successor dropping a criterion unlogged fails (+2)
A68 CB if <<text in known ==> True>>: | successor adding a criterion unlogged fails
A69 CB if <<"superseded" not in item.log_statuses() ==> False>>: | superseded without a superseded log line fails
A70 CB if <<not flaws ==> False>>: | successor carrying every criterion is reported (+2)
A71 CB human_successors.<<update(seen ==> add(successor.id>>) | derived requirement in the middle of a human chain fails
A72 CB if <<successor.get("primary_gate") != req["gate"] ==> False>>: | successor under another milestone is reported
A73 CB if req["scope"] == "future" and ( // successor.get("<<scope") != "future" or successor.get("status ==> status>>") != "deferred" // ): | future requirement superseded by a deferred version-one requirement fails
A74 CB if req["scope"] == "future" and ( ...("scope") != "future" <<or successor.get("status") != "deferred"  ==> >>// ): | future requirement superseded by a ready future one fails
A75 CB if <<status != "superseded" ==> False>>: // error( // item.path, // f... | feature superseded while its requirements live fails (+1)
A76 CB <<notes.append ==> >>( // f"Recorded change: {req['id']} {ac_id} is absent from the successor... | successor dropping a criterion with a logged change
A77 CB if <<target.get("status") == "deferred" ==> False>>: | v1 requirement depends on a deferred one
A78 CB elif <<target.get("scope") == "future" ==> False>>: | v1 requirement depends on a superseded exclusion fails
A79 CB elif <<end is None or end.get("status") == "deferred" or end.get("scope") == "future" ==> False>>: | v1 requirement depends on one replaced by a deferred requirement fails (+1)
A80 CB if <<dep == item_id ==> False>>: | self-dependency fails
A81 CB if <<node == start ==> False>>: | dependency cycle fails
A82 CB if <<linked != set(dependencies) ==> False>>: | Dependencies section without the frontmatter dependency fails (+1)
A83 CB if <<item_id not in imported and not lists_child(parent, item) ==> False>>: | derived requirement missing from its parent's list fails
A84 CB if <<scope == "v1" and live and parent.get("status") == "deferred" ==> False>>: | successor under a deferred feature fails
A85 CB if <<item.get("source") != expected ==> False>>: | derived requirement must be source derived (+1)
A86 CB if target is None: // <<error(item.path, f"dependency {dep} has no working requirement file") ==> pass>> | dependency without a working file
A87 CB if status == "superseded"<< ==>  or not found>>: // continue // if len(found)... | requirement dropped from the roadmap fails (+3)
A88 CB if status == "superseded": // continue // if len(found) <<!= ==> <>> 1: | requirement listed twice fails
A89 CB elif <<name != gate ==> False>>: | roadmap milestone differs from primary_gate fails (+1)
A90 CB if <<name == "FUTURE" ==> False>>: // error(ROADMAP, f"the vers... | version-one requirement in the Deferred group fails
A91 CB if <<name != "FUTURE" ==> False>>: // error( // ROADMAP, // f"t... | exclusion on a version-one milestone list fails
A92 CB elif <<gate not in entries ==> False>>: | primary_gate naming no roadmap milestone fails
A93 CB elif <<entries[name]["status"] == "done" and status != "done" ==> False>>: | done milestone with an unfinished requirement fails
A94 CB elif <<key == "proposed" and status != "proposed" ==> False>>: | ready requirement on a Proposed line fails
A95 CB if item_id not in reqs: // <<error(ROADMAP, f"{item_id} is listed and has no working requirement file") ==> pass>> | listed requirement without a working file fails
A96 CB if <<item.get("primary_gate") != req["gate"] ==> False>>: | moved primary gate is reported
A97 CB if <<not ROADMAP.is_file() ==> False>>: | missing roadmap fails
A98 CB if <<not sys.flags.isolated ==> False>>: | hashlib beside the checker is ignored (+4)
A99 CB import <<os ==> __future__ // import os>> // import sys //  // if not s... | __future__ beside the checker is ignored (+2)
B01 CB <<return load_source("import_baseline", IMPORTER) ==> import importlib.util; spec = importlib.util.spec_from_file_location("import_baseline", IMPORTER); module = importlib.util.module_from_spec(spec); sys.modules["import_baseline"] = module; spec.loader.exec_module(module); return module>> | planted bytecode cache of the import tool is ignored
B02 RF if <<key in self.fm ==> False>>: | repeated status key fails (+2)
B03 RF if <<value[0] in "\"'" ==> False>>: | quoted status fails (+1)
B04 RF if key not in allowed: // <<self ==> continue // self>>._problem( | unknown frontmatter key fails
B05 RF if <<allowed.index(key) < position ==> False>>: | frontmatter key out of order fails
B06 RF if <<len(lines) < end + 3 or lines[end + 1] != "" or not lines[end + 2].startswith("# ") ==> False>>: | second block after the frontmatter fails
B07 RF if <<bad_character(char) ==> False>>: | frontmatter closed by --- and a no-break space fails (+13)
B08 RF <<0x2282: "subset of", //  ==> >> | signs of the allow-list pass
B09 RF return not (char == "\n" or " " <= char <= "<<~ ==> \x7f>>" or ord(char) in EXTRA_CHARAC... | delete character fails
B10 RF return not (char == "\n" or "<<  ==> \x1f>>" <= char <= "~" or ord(char) ... | unit separator fails
B11 RF if not line.startswith("## ") or name not in wanted: // <<self ==> continue // self>>._problem( | heading outside the template fails (+5)
B12 RF if <<name in self.sections ==> False>>: // self._problem( | second Acceptance criteria heading fails
B13 RF if <<list(self.sections) != list(wanted[: wanted.index(name)]) ==> False>>: | headings out of order fail
B14 RF if <<missing ==> False>>: | missing template heading fails
B15 RF if <<any(ATX.match(form) for form in forms[1:]) ==> False>>: | heading inside a list item fails (+8)
B16 RF rest = <<line.lstrip(" ") ==> line>> // found = [rest] | indented heading in another section fails (+2)
B17 RF CONTAINER = re.compile(r"<<>| ==> >>[-*+](?= |$)|\d{1,9}[.)](?= |$)") | heading inside a quote fails (+1)
B18 RF CONTAINER = re.compile(r">|[<<- ==> >>*+](?= |$)|\d{1,9}[.)](?= |$)") | heading inside a list item fails (+1)
B19 RF CONTAINER = re.compile(r">|[-<<* ==> >>+](?= |$)|\d{1,9}[.)](?= |$)") | heading behind a star bullet fails
B20 RF CONTAINER = re.compile(r">|[-*<<+ ==> >>](?= |$)|\d{1,9}[.)](?= |$)") | heading behind a plus bullet fails
B21 RF CONTAINER = re.compile(r">|[-*+](?= |$)|\d{1,9}[<<. ==> >>)](?= |$)") | heading behind an ordered marker fails
B22 RF CONTAINER = re.compile(r">|[-*+](?= |$)|\d{1,9}[.<<) ==> >>](?= |$)") | heading behind an ordered marker in a quote fails
B23 RF if <<any(UNDERLINE.match(form) for form in forms) ==> False>>: | underlined heading fails (+7)
B24 RF UNDERLINE = re.compile(r"(?:<<=+| ==> >>-+) *$") | underlined heading inside a quote fails (+1)
B25 RF UNDERLINE = re.compile(r"(?:=+<<|-+ ==> >>) *$") | underlined heading fails (+1)
B26 RF UNDERLINE = re.compile(r"(?:=+|-+)<< * ==> >>$") | underline with trailing spaces fails
B27 RF if <<"<!--" in self.text ==> False>>: | HTML comment around the criteria fails (+1)
B28 RF if <<HTML_LINE.match(line) ==> False>>: | HTML heading tag fails
B29 RF RAW_HTML = re.compile(r"<[A-Za-<<z/ ==> z>>!?]") | closing tag inside a line fails (+1)
B30 RF RAW_HTML = re.compile(r"<[A-Za-z/<<! ==> >>?]") | declaration inside a line fails
B31 RF RAW_HTML = re.compile(r"<[A-Za-z/!<<? ==> >>]") | processing instruction inside a line fails (+1)
B32 RF RAW_HTML = re.compile(r"<[<<A-Za-z ==> >>/!?]") | tag at the end of a line fails (+3)
B33 RF if <<HTML_HEADING.search(line) ==> False>>: | inline HTML heading tag fails (+2)
B34 RF HTML_HEADING = re.compile(r"</?h[<<1 ==> 2>>-6]\b", re.IGNORECASE) | heading tag of level 1 in a code span fails
B35 RF HTML_HEADING = re.compile(r"</?h[1-<<6 ==> 5>>]\b", re.IGNORECASE) | closing heading tag of level 6 in upper case in a code span fails
B36 RF HTML_HEADING = re.compile(r"</?h[1-6]\b"<<, re.IGNORECASE ==> >>) | closing heading tag of level 6 in upper case in a code span fails
B52 RF HTML_HEADING = re.compile(r"<<</?h ==> <h>>[1-6]\b", re.IGNORECASE) | closing heading tag of level 6 in upper case in a code span fails
B37 RF if <<char == "\\" and line[position + 1 : position + 2] in ESCAPABLE ==> False>>: | tag behind escaped backticks fails
B38 RF kept.append(<<line[position : position + 2] ==> "  ">>) // position += 2 | tag behind a backslash fails
B39 RF match = LOG_LINE.match(line) // if not match: // <<self ==> continue // self>>._problem( | text line in the Status log fails (+1)
B40 RF if <<previous is not None and date < previous ==> False>>: | Status-log dates out of order fail
B41 RF except ValueError: // <<self._problem(f"§ Status: {year}-{month}-{day} is no calendar date") ==> pass>> | Status-log line with an impossible date fails
B42 RF if status not in STATUSES: // <<self ==> continue // self>>._problem( | Status-log line with an unknown status fails
B43 CB if <<path.parent != WORKDIR ==> False>>: | requirement copy in a subdirectory fails
B44 RF elif <<line and self.h1 ==> False>>: // self._problem( | text before the first heading fails
B45 RF if <<match.group(2) in found ==> False>>: // self._problem( | duplicate criterion ID
B46 RF AC_LINE = re.compile(r"^- \[([ <<x ==> xX>>])\] (AC-[1-9]\d*) (\S.*)$") | capital-X tick fails
B47 CB elif <<importer.read_text(mapping) != importer.mapping_content(base) ==> False>>: | stale import mapping
B48 IB lines += [f"- [<<  ==> x>>] {cid} {text}" for cid, text ... | summary counts ticked criteria (+1)
B49 CB if <<status == "done" and "_TBD" in item.text ==> False>>: | done requirement with a fenced placeholder fails
B50 CB if <<not GATE.match(gate) ==> False>>: | invalid gate
B51 CB elif <<(gate == "FUTURE") != (scope == "future") ==> False>>: | FUTURE gate on a v1 requirement
A76b CB <<notes.append ==> >>( // f"Recorded change: {req['id']} Description differs in the successor... | successor with another Description and a logged change
A76c CB <<notes.append ==> >>( // f"Recorded addition: {name} {ac_id} beside the criteria... | successor adding a criterion with a logged addition
A100 CB if <<req["scope"] == "future" ==> False>> and ( | future requirement superseded into version one fails (+2)
B53 CB if <<not sys.flags.isolated ==> False>>: (plus the change of B01) | bytecode cache under PYTHONPYCACHEPREFIX is ignored
B54 IB STATUS_MAP = {"ready": "<<ready ==> done>>", "deferred": "deferred"} | summary counts statuses and gates (+1)
B55 CB if <<not mapping.is_file() ==> False>>: | missing import mapping
B56 IB if path.exists()<< ==>  and args.check>>: // kept += 1 | import never overwrites a working file
```

Nine further mutants for sentences about other tools, run on a copy of the tracked files (`scripts/evidence.py` EV with `python3 -B -m unittest -k <test> scripts/tests/test_evidence.py`; `scripts/check-project-control.sh` PC with the named case of `scripts/tests/test-checker.sh`); the unmutated copy passes every named test and case, each mutant fails the named ones:

```text
E01 EV if state in (<<"failed", ==> >>"contract-only", "missing"): | test_done_requirements_need_passing_non_contract_evidence
E02 EV if state in ("failed", <<"contract-only", ==> >>"missing"): | test_done_requirements_need_passing_non_contract_evidence
E03 EV if state in ("failed", "contract-only"<<, "missing" ==> >>): | test_a_done_requirement_without_evidence_fails_the_done_gate; test_the_done_gate_judges_every_tier
E04 EV elif <<tier == "release" and left ==> left>>: | test_the_done_gate_judges_every_tier
E05 EV elif <<tier == "release" and left ==> False>>: | test_the_done_gate_judges_every_tier
E06 EV problems = <<form_problems(known) ==> []>> // for requirement in known.values(): | test_a_spelling_that_hides_done_or_a_criterion_fails_the_done_gate (9 subtests)
E07 EV if requirement.status != "done"<< ==>  or True>>: // continue | test_a_done_requirement_without_evidence_fails_the_done_gate
P01 PC else if (<<!(v in owner) ==> 0>>) err(path[i], "superseded_by " v " has no file in docs/requirements/") | superseded_by missing file
P02 PC if (<<v == "" ==> 0>>) err(path[i], "status superseded requires frontmatter superseded_by") | superseded without superseded_by
```

### Statement audit (AVE-REQ-093, committed file)
Result: a = a named case fails under a mutant that was run; b = case added in this task; c = sentence reworded to the behavior that holds; d = stated as a limit or an inspection.

| Lines | Sentence (shortened) | Result | Cases or mutants |
|---|---|---|---|
| 36-39 | baseline file edited, added, removed; inventory, size and SHA-256; validator runs only when verified | a, b, c | A01 to A05, A10; new case "manifest with another size entry fails" |
| 40-42 | MANIFEST.json edited, removed, duplicated, re-hashed | a | A06, A07, A08 |
| 43-48 | working file missing, second file, changed identity, dependencies | a, b, c | A11 to A27, A29, A30, A36, A44; new cases "changed feature title fails", "changed epic title fails" |
| 49-50 | one number of a kind under two IDs | a, c | A28 (the IDs are the suite's) |
| 51-57 | criterion or Description changed without its marker line; what a marker counts for | a, c | A34 to A44, A48; 17 expectations extended to the marker error (see Deviations) |
| 58-69 | forms outside the canonical form that the suite pins; one reading for both gates | a, c | B02 to B14, B27, B28, B39 to B45, C06, C07, N01, N05, E06 |
| 70-74 | heading behind spaces and container markers, underline, HTML heading tag | a, b | B15 to B26, B33 to B36, B52; new cases for the tag in a code span (levels 1 and 6) |
| 75-77 | footnote syntax | b | N01 to N04 |
| 78-86 | one fence form; reader and Markdown reader agree on fence lines | b | N05 to N14 |
| 87-90 | tag inside a line; code span on one line | a, b | B29 to B32, B37, B38, C06, C07, N04; new case "tag behind a backslash fails" |
| 91-98 | what a Markdown reader shows beside what the gates read | d | inspection: construct table below; limits named in the sentence |
| 99-101 | text in § Acceptance criteria that is no criterion | a | A45, B46 |
| 102 | symbolic link inside the package | a | A09 |
| 103 | future requirement made ready, version-one requirement deferred | a | A49, A50 |
| 104-114 | supersession of a version-one requirement; chain; `proposed` closed, `blocked` reported | a, b, c | A58 to A72, A76, A76b, A76c, C64 to C66; new cases "superseded by a deferred requirement fails", "successor in proposed fails", "chain that ends in a proposed requirement fails", "successor in blocked is reported" |
| 115-116 | exclusion superseded | a, b | A73, A74, A100; new case "future requirement superseded by a deferred version-one requirement fails" |
| 117 | baseline feature or epic superseded while a child lives | a | A75 |
| 118-119 | criterion added | a | A46, A47 |
| 120-123 | placement on the roadmap lists | a, c | A87 to A95 |
| 124-132 | roadmap file: characters, comment, raw HTML, backticks, footnotes, fences, underline, links | b | C01 to C13, C44, C45, C59 to C62, C06, C07, N01, N05 to N07 |
| 133-140 | roadmap headings, entry headings, entry range | b | C46 to C58 |
| 141-149 | one Status line; lines whose letters open with `status`; continuation; Deferred group free | a, b | C14 to C34, C67, C68 |
| 150-158 | requirement lists: labels, links only, plain words, continuation, link text | a, b | C29, C30, C32, C34 to C43, C61, C63 |
| 159-166 | what a Markdown reader shows of the roadmap | d | inspection: construct table; limits named |
| 167-169 | back to `proposed`; epic or feature done or ticked early | a | A51, A52, A53 |
| 170-173 | dependencies | a | A77 to A84 |
| 174-175 | feature links a requirement only outside § Requirements | a | A31, A33 |
| 176-180 | free text outside the mechanical guard; the checker reports each recorded change | d, a | limit; A43, A44, A47 |
| 181-184 | a change to the gate itself | d | limit, judged in the diff |
| 185-192 | isolated start; restart as first statements; what the suite pins | a | A98, A99, B01, B53 |
| 192-196 | `sitecustomize`; trusted interpreter and tools; CI admits a commit | d | limit, unchanged since the first round |
| 197-199 | ticks only while `done`; superseded after done keeps them | a | A54, A55, A56 |
| 200 | statuses stay unverified | a | B48, B54 |
| 201 | bootstrap content kept | d | inspection (AC-2) |
| 202 | derived requirement superseded | a | P01, P02, A79 |
| 208 | Verification strategy AC-1 | a, c | A01 to A09, A26 to A28, A31 to A33, A98, A99, B01, B47, B53, B55; the verify step is named as inspection of `scripts/verify.d/10-requirements.sh` |
| 209 | AC-2 | d | inspection |
| 210 | AC-3: each form of § Edge cases is a suite case; groups; inspection parts | c, d | the rows above; the list of forms stands once, in § Edge cases |
| 211 | AC-4: suite part and done gate | a, c | B48, B54, A54, A55, B46, B03, B02, B12, A52, A53, E01 to E07; "every spelling" became "the nine spellings of its unit test", "in every tier" became what the two unit tests pin |
| 212 | acceptance scenarios at M7 | d | plan |
| 215 | package committed unchanged at `6160278` | d, a | `git diff --quiet 6160278 HEAD -- ai-video-editor-requirements` exit 0; A03, A04, A10 |
| 216-217 | what `check_baseline.py` and `reqfile.py` hold | a, c | the rows above; function names equal the tree |
| 218 | 131 imported files; the import keeps every existing file; mapping | a, c | B56, B47; "complete import: --check reports nothing" (kept 131); 134 `AVE-*.md` files, 3 derived |
| 219 | six documents | d | inspection (AC-2) |
| 220 | completion judged by the done gate, a verify step of its own | c, a | E03, E07; `scripts/verify.d/95-evidence.sh` |
| 221 | test files and tags | c | tag comment lines in the suite: AC-1 8, AC-3 32, AC-4 4; `test_evidence.py`: 3 |
| 222 | decisions | a | links resolve (`check-project-control.sh` passes) |

### Construct table (item 5)
F = the gate refuses the file (exit 1); S = the gate accepts it and cmark-gfm and markdown-it-py show the headings, the criteria list, the Status log and the Description (roadmap: entry headings, Status items, requirement links of the lists) as the gate reads them. No construct ends with a difference. Constructs marked "free text" pass by design and stand as limits in § Edge cases lines 95-98 and 163-166. On the gate of the base commit the same script reported a difference for R14 R15 R16 R17 R22 M02 M03 M04 M07 M08 M09 M15 M18 M19 M20 M22 M23 M24 M26 M28 M29 M32 M33 M36 M37 M38 M40 M41 M42 M43 M47 M48 M49 M50 M51 M54 M72 M74 M89 M90 M92 M98 M101. The script (`/tmp/ta093/diff.py`) stays in the container.

```text
Requirement file (inserted into a copy of AVE-REQ-001)
containers: R01 heading in a quote F; R02 heading behind a bullet F; R03 heading behind an ordered marker with a dot F; R04 with a parenthesis F; R05 heading in a list item in a quote F; R06 heading on a continuation line of a list item F; R07 heading behind one space F; R08 four spaces before hashes at the top level F; R09 ordered marker of ten digits (no list item to a renderer) S; R10 quote sign and five spaces before hashes F; R11 task-list item that holds hashes S; R12 criterion-like item in another section (free text) S; R13 alert in a quote with a heading F; R81 heading behind two quote signs without a space F; R85 quote directly before the next template heading S; R86 list item directly before the next template heading S
footnotes: R14 heading on the first line of a footnote definition F; R15 quote and heading in a definition F; R16 bullet and heading in a definition F; R17 definition of plain text with its reference F; R18 reference without a definition F; R19 definition without a reference F; R20 footnote syntax inside a code span S; R21 inside a fenced block S; R22 inline footnote (markdown-it only) F; R23 definition behind a backslash F
raw HTML: R24 heading tag on its own line F; R25 details tag inside a line F; R26 comment F; R27 processing instruction F; R28 declaration F; R29 character data section F; R30 autolink in angle brackets F; R31 tag behind a backslash F; R32 tag written with character references (text to a renderer) S; R33 tag in a quote F
fences: R34 the one fence form around a heading line S; R35 with an info word S; R36 fence indented by four spaces F; R37 by one space F; R38 opening of four backticks, closing of three F; R39 backtick in the info string F; R40 tilde fence F; R41 text behind the closing backticks F; R42 spaces behind the closing backticks F; R43 closing line of four backticks F; R44 fence in a quote F; R45 fence in a list item F; R46 info string with a plus sign F; R47 info word behind a space F; R48 fence that stays open F; R49 code span of three backticks at a line start F; R50 two tildes at a line start (strike-through) S
emphasis: R51 bold line that imitates a heading (free text) S; R52 strike-through around hashes S; R53 emphasis around hashes S
link reference definitions: R54 definition (shows nothing) S; R55 definition whose title opens before the next heading S; R56 comment written as a link definition S
tables: R57 table cell that holds hashes S; R58 table directly before the next template heading S; R59 table directly before a criterion line F
character references: R60 hashes as numeric references S; R61 hash as a named reference S; R62 reference inside a criterion F
backslash escapes: R63 hashes behind a backslash S; R64 bullet behind a backslash S; R65 backslash inside a criterion F
hard line breaks: R66 two spaces at the end of a criterion line F; R67 backslash at the end of a line before hashes F; R68 two spaces at the end of a Status-log line S
tabs: R69 tab before hashes F; R70 tab behind a bullet F; R71 tab before a fence F
underlines: R72 line of = under text F; R73 line of - under text F; R74 line of = in a quote F; R83 rules of stars and of spaced hyphens F; R84 line of = behind a blank line F
ATX forms: R75 seven hashes S; R76 hashes without a space S; R77 closing hashes on a template heading F; R78 space at the end of a template heading F; R79 bold template heading F; R82 one hash alone behind three spaces F
GitHub only: R80 math delimiters around text (rendered by neither renderer) S

docs/ROADMAP.md
control: M01 the roadmap as committed S
Status lines: M02 second line in underscore bold F; M03 in star emphasis F; M04 without emphasis F; M05 colon behind the bold F; M06 Cyrillic letter F; M07 numeric reference F; M08 named reference F; M09 escaped stars F; M10 star bullet F; M11 ordered marker F; M12 in a quote F; M13 nested item F; M14 without a bullet F; M15 continuation line under the Status line F; M16 behind a hard break of another item F; M17 in a table row F; M18 with a bold tag F; M19 code span as label F; M20 link as label F; M21 the Status line struck through F; M22 the Status line inside a processing instruction beside a second one F; M25 the Status line in a fenced block beside another one S; M73 spaced letters F; M74 Status word in a nested item of the exit criteria F; M75 Status text in the middle of another item (free text) S; M81 behind a link without words F; M82 behind an image F; M83 behind a link of one digit F; M84 behind a link whose target holds parentheses F; M85 behind a reference link without words F; M86 Cyrillic letter as a reference F; M87 no-break space reference F; M88 zero-width space reference F; M91 written as a link definition in an item F; M94 another word for the label (free text) S; M95 behind an image with words F; M96 behind a ticked task box F; M97 the word Status behind another word (free text) S; M102 the Status line of the Deferred group in another form (free text) S
raw HTML, comment, characters: M23 the M1 entry inside details F; M24 inside a processing instruction F; M40 requirement link inside a processing instruction F; M62 comment around the M1 entry F; M66 tab behind the Status label F; M67 tab before a second Status line F; M77 no-break space behind the Status label F; M78 carriage returns at the line ends F
headings: M26 second M0 heading with a hyphen F; M27 leading zero F; M28 level 4 F; M29 level 2 F; M30 behind one space F; M31 in a quote F; M32 bold F; M33 digit as a reference F; M34 underlined text F; M35 closing hashes on the M0 heading S; M36 sub-heading before a second Status line F; M37 hashes without a space before a second Status line F; M38 second Deferred heading with a colon F; M39 duplicate M0 heading F; M76 bold line that imitates an entry heading (free text) S; M79 Deferred heading of level 4 inside the M1 entry F; M80 rule of three hyphens F; M89 behind a link without words F; M90 behind an image F; M93 other milestone number with the name of M0 (free text) S; M98 letter as a reference F; M99 behind a number F; M100 another word before the milestone number (free text) S
lists: M41 requirement link struck through F; M42 in a code span F; M43 behind a backslash F; M44 with a title F; M45 as a reference link with its definition F; M46 bracket as a reference F; M47 as an image F; M48 indented line with a link under the list F; M49 line with a link at column 0 under the list F; M50 nested item with a link F; M51 paragraph with a link behind a blank line F; M52 second list under another label F; M53 label in underscore bold F; M54 label in the singular F; M55 list line in a quote F; M65 two spaces at the end of the list F; M70 struck link on a Proposed line F; M71 code span on a Proposed line F; M72 continuation line under a Proposed line F; M92 second list behind a link without words F; M101 second list behind a ticked task box F
fences: M56 the M1 entry in the one fence form F; M57 in a tilde fence F; M58 in a fence of four backticks F; M59 in a fence in a quote F; M60 in a fence behind two spaces F; M61 in a fence with a dotted info string F
footnotes: M63 Status line in a footnote definition F; M64 entry heading in a footnote definition F
tables and definitions: M68 table directly before the Status line S; M69 definition whose title opens before the Status line S
```

### Commands run with results
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` — before the change `BASELINE TOTAL: pass=305 fail=0`; after it `BASELINE TOTAL: pass=424 fail=0` (standalone run, and again inside the release run on the committed tree).
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` on the committed tree — exit 0, `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`; 104 working requirements, 0 of 404 criteria ticked, no Recorded change, Gate change or Supersession line.
- `./scripts/dev-container.sh bash scripts/check-project-control.sh` — exit 0, 0 warnings.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests` — `Ran 37 tests`, OK.
- `./scripts/verify.sh --tier release` after `git add -A`, on the tree that became the commit — exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`: project control files, ignored files, baseline integrity, evidence unit tests, backend format, lint, type check, unit tests (125 passed), media and population tests (399 s), tooling suites (checker 1090, baseline 424, stop hook 145, session start 56, verify tiers 65, probe 155), done requirements, working tree unchanged, evidence manifest.
- Mutation: 240 of 240 killed (baseline gate, committed tree); 9 of 9 killed (evidence tool and project checker).
- Differential check: 188 constructs, 149 refused, 39 shown as read, 0 differing (committed tree); 43 differing on the base commit's gate.
- `git status --short` empty after the commit; `git ls-files -s`: `scripts/check_baseline.py` and `scripts/tests/test-check-baseline.sh` mode 100755.

### Forced edits
None. Every tracked working file and `docs/ROADMAP.md` passed the new rules as they stood; the roadmap change is the text of § Rules 8.

### Proposed text for documents outside my paths
- `docs/requirements/README.md` § Enforced checks item 10, old: "and a roadmap entry outside the form the gate reads ([ROADMAP.md](../../ROADMAP.md) § Rules 8): a milestone entry without exactly one Status line `- **Status:** planned`, `in-progress` or `done`, a list line under another label than the template's, a second list of one kind in an entry, a fence line outside [Canonical form](#canonical-form) rule 5, or an HTML comment;" — new: "and a roadmap outside the form the gate reads ([ROADMAP.md](../../ROADMAP.md) § Rules 8, which holds the rules in full): a character outside the allow-list and the horizontal ellipsis, an HTML comment, raw HTML, an unpaired run of backticks, footnote syntax, a fence line outside [Canonical form](#canonical-form) rule 5, a line of `=` or of `-` alone, a link outside the one form; a heading away from column 0, a heading that reads as an entry heading outside the template form, a second entry; a milestone entry without exactly one Status line `- **Status:** planned`, `in-progress` or `done`, a second line whose letters open with `status`, a list line under another label than the template's, a second list of one kind, a requirement list that holds anything besides its links, a Proposed line that holds anything besides links and plain words, or a continuation of a line the gate reads;".
- `docs/ASSUMPTIONS.md`, new entry: "Working files hold no footnote syntax and one fence form" — assumption: `[^` and `^[` fail outside code spans and fenced blocks; a fenced block opens with three backticks at column 0, alone or with one word of letters, digits, `_` or `-`. Reason: a footnote definition is a container GitHub renders, and one fence form keeps the reader and a Markdown reader agreed on every fence line. Impact: no file held either form; an info word with `+` or `.` now fails; a character class such as a caret in brackets belongs in a code span.
- `docs/ASSUMPTIONS.md`, new entry: "The roadmap is read by the letters a line opens with" — assumption: in a milestone entry a line whose letters open with `status`, `requirement` or `proposed` is a line of the template's exact form; a requirement list holds links only, a Proposed line links and plain words (letters, digits, spaces and `( ) , . ; : -`); each such line is a list item of one line; links have one form; headings stand at column 0; milestone numbers carry no leading zero; no line of `=` or `-` alone. Reason: 43 constructs showed a reader something the gate read otherwise. Impact: a note on a Proposed line uses plain words; a rule in the roadmap is drawn with stars; words before the word Status stay free text.
- `docs/ASSUMPTIONS.md`, new entry: "The replacement of an imported requirement is never proposed" — assumption: the end of a supersession chain of an imported requirement is `ready` or later, `blocked` or (for an exclusion) `deferred`. Reason: the lifecycle holds no move back to `proposed` for an imported requirement. Impact: a replacement reaches Ready before the old file is set to `superseded`.
- AVE-REQ-093 Status log (lead), proposed line: "- 2026-10-07 — in-progress — fixes of the second review round on branch `m0-r2-fixes-a` (track A of the fix brief): no footnote syntax and one fence form in working files, the roadmap read by the reader's rules with Status lines and lists found by their letters, the replacement of an imported requirement never `proposed`; § Edge cases names every pinned form and the limits (lead)".
- `docs/TRACEABILITY.md`: the AVE-REQ-093 row keeps its files; no cell changes.

### Deviations and discovered work
- Rules beyond the decisions the brief lists for item 3, each added because the differential check showed a difference that the listed decisions left open, and each with cases and mutants: character references resolved before the character check; one link form (an image or a link without words put letters a reader does not see before a label); requirement lists of links only and Proposed lines of links and plain words (a struck link, a link in a code span); items of one line (a continuation line added a word to the Status or a link to a list); headings at column 0 and no underline in the roadmap; entries end at headings of level 1 to 3; ticked task boxes left out of the letters; the label prefix `requirement` (singular); milestone numbers without a leading zero; `^[`. The lead may want to confirm them as assumptions (entries above).
- 17 existing expectations of the suite were extended from "AC-2 differs from the baseline text" (and four like it) to the marker error "... and the Status log has no line": mutants A41 and A48 showed that the short text also matched the note of a change that counted as recorded. The tests are stricter; no test was weakened or removed.
- Existing cases changed because of item 4: `successor()` writes a `ready` replacement on the requirement list, so "future requirement superseded into version one fails" and "... by a ready future one fails" now expect status 'ready'; "superseded by a future-scope requirement fails" now isolates the scope (status `ready`), with the new "superseded by a deferred requirement fails" for the other half. "milestone heading with its digit as a character reference" was replaced by the letter form, which the mutant of the reference handling fails.
- Open for the lead, outside track A: non-blocking finding 2 of part 1 (no skill names the reader of the `Recorded change`, `Gate change` and `Supersession` notes).
- Discovered, not changed: the reviewer's probe "package directory replaced by a link to an identical copy" still passes; line 102 of the requirement file speaks of a link inside the package. Proposed follow-up under AVE-FEAT-019 or a limit sentence: "the package directory itself as a link is shown by Git as a type change".
- Merge note: the new canonical-form rules judge the requirement files of the other tracks once merged: `[^` or `^[` outside code spans and a fence with `+` or `.` in its info word fail there too, and `python3 -I -B scripts/check_baseline.py` names the line.
- The baseline suite now holds 424 cases and runs about four and a half minutes in the container (305 cases, about three minutes before).
- Limits that stay, stated in § Edge cases: GitHub rendering beyond CommonMark and its Markdown specification (math delimiters, diagrams, emoji shortcodes) compared with no renderer; the frontmatter shown by GitHub as its own table; words before the word Status or before a milestone number; another word for a label; bold text that imitates a heading; an entry under another milestone number.
- Pre-existing failures: none met.
