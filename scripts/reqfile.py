#!/usr/bin/env python3
"""One reader for the working EPIC, FEAT and REQ files of docs/requirements/.

scripts/check_baseline.py and scripts/evidence.py both read requirement files through this module,
so the status, the sections, the criteria and the Status log one gate sees are the ones the other
sees (AVE-REQ-093 AC-3, AC-4; AVE-REQ-097 AC-4). The reader accepts the canonical form of
docs/requirements/README.md § Canonical form and reports every other form as a problem, which
check_baseline.py turns into an error: a file both gates accept has one reading, and a Markdown
reader sees the frontmatter, the headings, the Description and the criteria the gates checked.

Canonical form, in short:
  characters   UTF-8 without a byte-order mark; line feeds only; every other character stands on
               the allow-list: U+0020 to U+007E and the signs of EXTRA_CHARACTERS below;
  frontmatter  line 1 is "---"; then "key: value" lines with the template's keys in the template's
               order, each once, unquoted; then "---", one blank line and the H1;
  headings     the H1 once, then every template heading "## <name>" once, in the template's
               order, written at column 0; no other heading: outside fenced blocks a line is
               judged after its leading spaces and again after each container marker (">", "-",
               "*", "+", "N.", "N)"), and what remains opens no ATX heading ("#" to "######"
               before a space or the line's end) and is no run of "=" or of "-" alone; no HTML
               heading tag;
  HTML         no comment, no line that starts with "<", and no tag ("<" before a letter, "/",
               "!" or "?") outside code spans; a code span opens and closes on one line;
  footnotes    none: "[^" and "^[" fail outside code spans and fenced blocks, so no footnote
               definition (a container whose first line opens a block), no footnote reference
               and no inline footnote exists;
  fences       one form: a line of exactly three backticks at column 0, alone or followed by
               one word of letters, digits, "_" or "-", opens a block, and a line of exactly
               three backticks at column 0 closes it; every other line that opens with three
               or more backticks or tildes, after its leading spaces or after a container
               marker, fails, inside a block too;
  criteria     "- [ ] AC-n <text>" or "- [x] AC-n <text>", and nothing else in that section;
  Status       dated log lines only, "- YYYY-MM-DD — <status> — <text>", dates never decreasing.

scripts/check_baseline.py judges docs/ROADMAP.md by the same fence rule (fence_like, FENCE_OPEN,
FENCE_CLOSE) and the same rules for one line outside fenced blocks (inline_problems).

Usage: read(path) returns a ReqFile; its problems list is empty for a canonical file.
Python 3.8+ standard library only; imports nothing from the repository.
"""

from __future__ import annotations

import datetime
import hashlib
import re
from collections import OrderedDict

STATUSES = (
    "proposed",
    "ready",
    "in-progress",
    "verification",
    "done",
    "blocked",
    "superseded",
    "deferred",
)
# Frontmatter keys per kind, in template order (docs/requirements/README.md § Templates).
KEYS = {
    "EPIC": ("id", "title", "status", "priority", "goals", "superseded_by"),
    "FEAT": ("id", "title", "status", "priority", "parent", "superseded_by"),
    "REQ": (
        "id",
        "title",
        "type",
        "status",
        "priority",
        "parent",
        "source",
        "scope",
        "primary_gate",
        "origins",
        "dependencies",
        "scenarios",
        "baseline",
        "superseded_by",
    ),
}
# Template headings per kind, in template order.
HEADINGS = {
    "EPIC": ("Goal", "Scope", "Features", "Success criteria", "Status"),
    "FEAT": (
        "Intent",
        "User journey",
        "Requirements",
        "Out of scope",
        "Feature acceptance",
        "Status",
    ),
    "REQ": (
        "Intent",
        "Description",
        "Acceptance criteria",
        "Edge cases",
        "Dependencies",
        "Verification strategy",
        "Implementation evidence",
        "Test evidence",
        "Status",
    ),
}
NAME = re.compile(r"^(AVE-(EPIC|FEAT|REQ)-(\d+))-[a-z0-9-]+\.md$")
FM_LINE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*): (\S(?:.*\S)?)$")
AC_LINE = re.compile(r"^- \[([ x])\] (AC-[1-9]\d*) (\S.*)$")
LOG_LINE = re.compile(r"^- (\d{4})-(\d{2})-(\d{2}) — ([a-z-]+) — (\S.*)$")
# What a line reads once its leading spaces and its container markers are gone (see readings).
ATX = re.compile(r"#{1,6}(?: |$)")
UNDERLINE = re.compile(r"(?:=+|-+) *$")
# A container marker: a quote sign, a bullet or an ordered-list number before a space or the end.
CONTAINER = re.compile(r">|[-*+](?= |$)|\d{1,9}[.)](?= |$)")
HTML_LINE = re.compile(r"^ {0,3}<")
HTML_HEADING = re.compile(r"</?h[1-6]\b", re.IGNORECASE)
# The one fence form: three backticks at column 0, alone or with one word, open a block and
# three backticks at column 0 close it. FENCE_RUN is what opens or closes a fenced block for a
# Markdown reader; fence_like finds it behind leading spaces and container markers, and every
# such line outside the one form fails.
FENCE_RUN = re.compile(r"`{3,}|~{3,}")
FENCE_OPEN = re.compile(r"^```[A-Za-z0-9_-]*$")
FENCE_CLOSE = "```"
# Footnote syntax: a definition "[^label]: ..." or a reference "[^label]" (GitHub), and the
# inline form "^[text]" that other Markdown readers add.
FOOTNOTE = re.compile(r"\[\^|\^\[")
# The characters of a working file besides the line feed and U+0020 to U+007E: the signs the
# working files held on 2026-10-06 (the baseline package is ASCII). Every other character fails,
# visible or invisible; a sign joins this list in a change of this file, which the diff shows.
EXTRA_CHARACTERS = {
    0x00A7: "section sign",
    0x00B1: "plus-minus sign",
    0x2013: "en dash",
    0x2014: "em dash",
    0x2192: "rightwards arrow",
    0x2265: "greater-than or equal to",
    0x2282: "subset of",
}
# Raw HTML outside code spans: "<" before a letter, "/", "!" or "?".
RAW_HTML = re.compile(r"<[A-Za-z/!?]")
# The characters a backslash makes plain text (CommonMark: ASCII punctuation).
ESCAPABLE = frozenset("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
# A marker reason says something: it holds a letter or a digit of U+0020 to U+007E.
REASON = re.compile(r"[A-Za-z0-9]")


def digest(text: str) -> str:
    """The sixteen-digit mark that ties a recorded change to the text it covers."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def bad_character(char: str) -> bool:
    """Whether a character stands outside the allow-list of a working file."""
    return not (char == "\n" or " " <= char <= "~" or ord(char) in EXTRA_CHARACTERS)


def readings(line: str):
    """The line after its leading spaces, then after each container marker in turn.

    A Markdown reader opens a heading inside a quote or a list item and on an indented
    continuation line of one, so every reading is judged, whatever the indentation.
    """
    rest = line.lstrip(" ")
    found = [rest]
    while True:
        match = CONTAINER.match(rest)
        if not match:
            return found
        rest = rest[match.end() :].lstrip(" ")
        found.append(rest)


def outside_code_spans(line: str):
    """(The text of a line outside its code spans, whether a run of backticks stays unpaired).

    A code span opens with a run of backticks and closes with the next run of the same length
    on the line; a backslash before a backtick outside a span makes that backtick plain text.
    The reader fails a line with an unpaired run, so no span reaches over a line end and the
    spans read here are the spans a Markdown reader pairs.
    """
    kept, position, unpaired = [], 0, False
    while position < len(line):
        char = line[position]
        if char == "\\" and line[position + 1 : position + 2] in ESCAPABLE:
            kept.append(line[position : position + 2])
            position += 2
            continue
        if char != "`":
            kept.append(char)
            position += 1
            continue
        end = position
        while line[end : end + 1] == "`":
            end += 1
        closer = None
        for run in re.finditer(r"`+", line[end:]):
            if len(run.group()) == end - position:
                closer = end + run.end()
                break
        if closer is None:
            unpaired = True
            kept.append(line[position:end])
            position = end
        else:
            kept.append(" ")
            position = closer
    return "".join(kept), unpaired


def fence_like(line: str) -> bool:
    """Whether a reading of the line opens with three or more backticks or tildes.

    A Markdown reader opens and closes a fenced block on such a line at column 0, behind up to
    three spaces and inside a quote or a list item; the canonical form admits the two lines of
    FENCE_OPEN and FENCE_CLOSE and fails every other one, so the reader and a Markdown reader
    agree on every line that opens or closes a block.
    """
    return any(FENCE_RUN.match(form) for form in readings(line))


def inline_problems(line: str):
    """The problems of one line outside fenced blocks that its code spans decide.

    A run of backticks unpaired on the line, raw HTML outside code spans and footnote syntax
    outside code spans; scripts/check_baseline.py applies the same list to docs/ROADMAP.md.
    Each problem is a text without its line number.
    """
    plain, unpaired = outside_code_spans(line)
    found = []
    if unpaired:
        found.append(
            "a run of backticks stays unpaired; a code span opens and closes on one line"
            f" ('{line[:50]}')"
        )
    if RAW_HTML.search(plain):
        found.append(
            f"raw HTML outside a code span ('{plain[RAW_HTML.search(plain).start() :][:30]}')"
        )
    if FOOTNOTE.search(plain):
        found.append(
            "footnote syntax ([^ or ^[) outside a code span; a footnote definition is a"
            " container that opens a block, and the file holds none"
            f" ('{plain[FOOTNOTE.search(plain).start() :][:30]}')"
        )
    return found


class ReqFile:
    """One working file: frontmatter, H1, sections, criteria, Status log and form problems."""

    def __init__(self, path):
        self.path = path
        match = NAME.match(path.name)
        self.id, self.kind, self.number = match.group(1), match.group(2), int(match.group(3))
        self.problems = []
        self.fm = OrderedDict()
        self.h1 = ""
        self.sections = OrderedDict()  # heading -> lines outside fenced blocks
        self.raw_sections = OrderedDict()  # heading -> every line, fenced ones included
        data = path.read_bytes()
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            self.problems.append("the file is no valid UTF-8 text")
            text = data.decode("utf-8", errors="replace")
        self.text = text
        self._characters(text)
        lines = text.split("\n")
        body = self._frontmatter(lines)
        self._criteria = OrderedDict()
        self._log = []
        self._body(lines, body)

    def _problem(self, message: str) -> None:
        if message not in self.problems:
            self.problems.append(message)

    def _characters(self, text: str) -> None:
        for number, line in enumerate(text.split("\n"), 1):
            for char in line:
                if bad_character(char):
                    name = "a carriage return" if char == "\r" else f"U+{ord(char):04X}"
                    self._problem(
                        f"line {number}: {name} is no character of a requirement file (line"
                        " feeds end lines; the allow-list holds U+0020 to U+007E and the signs"
                        " of EXTRA_CHARACTERS in scripts/reqfile.py)"
                    )
                    break

    def _frontmatter(self, lines) -> int:
        """Parses the block between the two --- lines; returns the index of the first body line."""
        if lines[0] != "---":
            self._problem("line 1 must read --- (the frontmatter opens the file)")
            return 0
        try:
            end = lines.index("---", 1)
        except ValueError:
            self._problem("the frontmatter has no closing --- line")
            return len(lines)
        allowed = KEYS[self.kind]
        position = -1
        for number, line in enumerate(lines[1:end], 2):
            match = FM_LINE.match(line)
            if not match:
                self._problem(
                    f"line {number}: a frontmatter line reads 'key: value' ('{line[:40]}')"
                )
                continue
            key, value = match.group(1), match.group(2)
            if key in self.fm:
                self._problem(f"line {number}: frontmatter key {key} is repeated")
                continue
            if key not in allowed:
                self._problem(
                    f"line {number}: frontmatter key {key} is no key of the {self.kind} template"
                )
                continue
            if allowed.index(key) < position:
                self._problem(
                    f"line {number}: frontmatter key {key} stands outside the template's order"
                )
            position = max(position, allowed.index(key))
            if value[0] in "\"'":
                self._problem(f"line {number}: frontmatter value of {key} is quoted")
            if ": " in value or " #" in value:
                self._problem(
                    f"line {number}: frontmatter value of {key} holds ': ' or ' #', which YAML"
                    " reads as a key or a comment"
                )
            self.fm[key] = value
        if len(lines) < end + 3 or lines[end + 1] != "" or not lines[end + 2].startswith("# "):
            self._problem("one blank line and the H1 follow the frontmatter's closing ---")
        return end + 1

    def _body(self, lines, start: int) -> None:
        wanted = HEADINGS[self.kind]
        current = None
        fenced = False
        if "<!--" in self.text:
            self._problem("an HTML comment (<!--) hides text from readers; the file holds none")
        for number, line in enumerate(lines[start:], start + 1):
            if fenced:
                if current is not None:
                    self.raw_sections[current].append(line)
                if line == FENCE_CLOSE:
                    fenced = False
                elif fence_like(line):
                    self._problem(
                        f"line {number}: a fenced block closes with ``` at column 0 and holds no"
                        " other fence line"
                    )
                continue
            if fence_like(line):
                # The one form opens a block; every other fence line is a problem and opens
                # none, so the lines behind it are judged as lines of the file.
                if FENCE_OPEN.match(line):
                    fenced = True
                else:
                    self._problem(
                        f"line {number}: a fence line reads ``` or ```<word> (letters, digits,"
                        f" _ or -) at column 0 ('{line[:20]}')"
                    )
                if current is not None:
                    self.raw_sections[current].append(line)
                elif self.h1:
                    self._problem(
                        f"line {number}: text between the H1 and the first heading belongs to no"
                        " section"
                    )
                continue
            for problem in inline_problems(line):
                self._problem(f"line {number}: {problem}")
            forms = readings(line)
            if ATX.match(forms[0]):
                # A heading at column 0 or behind leading spaces: the H1, a template heading, or
                # a problem (an indented line is none of the two).
                if line.startswith("# ") and not self.h1 and current is None:
                    self.h1 = line
                    continue
                name = line[3:]
                if not line.startswith("## ") or name not in wanted:
                    self._problem(
                        f"line {number}: '{line[:50]}' is no template heading of a {self.kind}"
                        " file (the H1 once, then '## <name>' at column 0)"
                    )
                    continue
                if name in self.sections:
                    self._problem(f"line {number}: heading '## {name}' is repeated")
                    continue
                if list(self.sections) != list(wanted[: wanted.index(name)]):
                    self._problem(
                        f"line {number}: heading '## {name}' stands outside the template's order"
                        " or follows a missing heading"
                    )
                current = name
                self.sections[name] = []
                self.raw_sections[name] = []
                continue
            if any(ATX.match(form) for form in forms[1:]):
                self._problem(
                    f"line {number}: a heading inside a list item or quote ('{line[:50]}')"
                )
            if any(UNDERLINE.match(form) for form in forms):
                self._problem(
                    f"line {number}: a line of = or - underlines a heading or draws a rule"
                    f" ('{line[:20]}')"
                )
            if HTML_LINE.match(line):
                self._problem(f"line {number}: a line that starts with < opens raw HTML")
            if HTML_HEADING.search(line):
                self._problem(f"line {number}: an HTML heading tag ('{line[:50]}')")
            if current is not None:
                self.sections[current].append(line)
                self.raw_sections[current].append(line)
            elif line and self.h1:
                self._problem(
                    f"line {number}: text between the H1 and the first heading belongs to no"
                    " section"
                )
        if fenced:
            self._problem("a fenced block stays open at the end of the file")
        missing = [name for name in wanted if name not in self.sections]
        if missing:
            self._problem("missing heading '## " + "', '## ".join(missing) + "'")
        self._read_criteria()
        self._status_log()

    def _read_criteria(self) -> None:
        found = OrderedDict()
        for line in self.criteria_extras():
            self._problem(
                "§ Acceptance criteria holds a line that is no criterion"
                f" ('{line.strip()[:60]}'); the section holds '- [ ] AC-n <text>' lines only, and"
                " a note belongs in Edge cases or the Description with a logged reason"
            )
        for line in self.sections.get("Acceptance criteria", []):
            match = AC_LINE.match(line)
            if not match:
                continue
            if match.group(2) in found:
                self._problem(f"acceptance criterion {match.group(2)} is repeated")
                continue
            found[match.group(2)] = (match.group(1) == "x", match.group(3))
        self._criteria = found

    def _status_log(self) -> None:
        entries = []
        previous = None
        for line in self.raw_sections.get("Status", []):
            if not line:
                continue
            match = LOG_LINE.match(line)
            if not match:
                self._problem(
                    "§ Status holds dated log lines only, '- YYYY-MM-DD — <status> — <text>'"
                    f" ('{line[:50]}')"
                )
                continue
            year, month, day, status, text = match.groups()
            try:
                date = datetime.date(int(year), int(month), int(day))
            except ValueError:
                self._problem(f"§ Status: {year}-{month}-{day} is no calendar date")
                continue
            if status not in STATUSES:
                self._problem(f"§ Status: '{status}' is no status ('{line[:50]}')")
                continue
            if previous is not None and date < previous:
                self._problem(
                    f"§ Status: the line dated {date.isoformat()} follows a later one; the log"
                    " runs oldest first"
                )
            previous = date
            entries.append((date.isoformat(), status, text))
        self._log = entries

    # ---------------------------------------------------------------------------------------------

    def get(self, key: str) -> str:
        return self.fm.get(key, "")

    def flow(self, key: str):
        """A flow list such as [AVE-REQ-001, AVE-REQ-002] as a list; None for any other value."""
        value = self.get(key)
        if not (value.startswith("[") and value.endswith("]")):
            return None
        inner = value[1:-1].strip()
        return [item.strip() for item in inner.split(",")] if inner else []

    def criteria(self):
        """AC ID -> (ticked, text) in file order; a repeated ID is a form problem."""
        return self._criteria

    def criteria_extras(self):
        """Non-blank lines of § Acceptance criteria that are no criterion line, fenced lines included."""
        return [
            line
            for line in self.raw_sections.get("Acceptance criteria", [])
            if line.strip() and not AC_LINE.match(line)
        ]

    def log(self):
        """The Status log as (date, status, text) in file order."""
        return list(self._log)

    def log_statuses(self):
        return [status for _date, status, _text in self.log()]

    def description(self) -> str:
        """The whole § Description, fenced blocks included."""
        return "\n".join(self.raw_sections.get("Description", [])).strip()

    def recorded(self, marker: str) -> str:
        """The reason of the Status-log line whose text starts with '<marker>: <reason>'.

        The marker opens the line's text, so a line that quotes the rule, names another requirement
        or continues an earlier sentence records nothing; a reason that starts with < is the
        template's placeholder, and a reason without a letter or a digit says nothing.
        """
        prefix = marker + ": "
        for _date, _status, text in self.log():
            if text.startswith(prefix):
                reason = text[len(prefix) :].strip()
                if not reason.startswith("<") and REASON.search(reason):
                    return reason
        return ""


def read(path) -> ReqFile:
    return ReqFile(path)
