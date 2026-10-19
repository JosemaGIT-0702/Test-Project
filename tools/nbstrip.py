"""Strip a Mathematica notebook down to its inputs, for version control.

Git clean filter (registered by `make setup`, enabled for *.nb in .gitattributes): reads a
notebook on stdin and writes the stripped notebook to stdout, so what gets committed has

- no header comments or trailing cache (the front end rebuilds them on save);
- no output cells (Output, Print, Message, Echo, ...); groups left with one cell are unwrapped;
- no volatile options (CellChangeTimes, ExpressionUUID, CellLabel, WindowSize, ...).

The working copy keeps its outputs. Stripping is idempotent; stdlib only (runs without
Mathematica). `uv run python tools/nbstrip.py --check FILE...` exits 1 if a file is not stripped.
"""

import re
import sys

OUTPUT_STYLES = {
	"Output",
	"Print",
	"Message",
	"MSG",
	"Echo",
	"EchoTiming",
	"PrintTemporary",
	"PrintUsage",
}
DROP_OPTIONS = (
	"CellChangeTimes",
	"ExpressionUUID",
	"CellLabel",
	"FrontEndVersion",
	"WindowSize",
	"WindowMargins",
)
HEADER = "(* Content-type: application/vnd.wolfram.mathematica *)\n\n"

_SPECIAL = re.compile(r'"|\(\*|[\[\]{}(),]')
_STRING = re.compile(r'"(?:[^"\\]|\\.)*"', re.DOTALL)
_HEAD = re.compile(r"([A-Za-z$][\w$`]*)\s*$")
_OPTION = re.compile(r"\s*(?:" + "|".join(DROP_OPTIONS) + r")\s*(?:->|:>)")
_CLOSE = {"[": "]", "{": "}", "(": ")"}
_COMMENT_DELIM = re.compile(r"\(\*|\*\)")
_CONTINUATION = re.compile(r"\\\r?\n")  # the front end wraps long lines with backslash-newline


class Group:
	"""A bracketed expression: `head` is the symbol right before `open` ('' if none)."""

	def __init__(self, head, open_, args):
		self.head, self.open, self.args = head, open_, args

	def text(self):
		return self.open + ",".join(_text(a) for a in self.args) + _CLOSE[self.open]


def _text(pieces):
	return "".join(p if isinstance(p, str) else p.text() for p in pieces)


def _code(text):
	"""Text with line continuations removed, for matching symbols and styles."""
	return _CONTINUATION.sub("", text)


def _comment_end(s, i):
	depth = 0
	while True:
		m = _COMMENT_DELIM.search(s, i)
		if not m:
			raise ValueError("unterminated comment")
		depth += 1 if m.group() == "(*" else -1
		i = m.end()
		if depth == 0:
			return i


def _parse(s, i, close):
	"""Parse comma-separated args up to `close`; each arg is a list of str / Group pieces."""
	args, pieces = [], []
	while True:
		m = _SPECIAL.search(s, i)
		if not m:
			if close:
				raise ValueError("unbalanced brackets")
			pieces.append(s[i:])
			args.append(pieces)
			return args, len(s)
		j, tok = m.start(), m.group()
		if tok == '"':
			sm = _STRING.match(s, j)
			if not sm:
				raise ValueError("unterminated string")
			pieces.append(s[i : sm.end()])
			i = sm.end()
		elif tok == "(*":
			end = _comment_end(s, j)
			pieces.append(s[i:end])
			i = end
		elif tok in _CLOSE:
			before = s[i:j]
			pieces.append(before)
			head = _HEAD.search(_code(before))
			sub, i = _parse(s, j + 1, _CLOSE[tok])
			pieces.append(Group(head.group(1) if head else "", tok, sub))
		elif tok == ",":
			pieces.append(s[i:j])
			args.append(pieces)
			pieces, i = [], j + 1
		elif tok == close:
			pieces.append(s[i:j])
			args.append(pieces)
			return args, j + 1
		else:
			raise ValueError(f"unexpected {tok!r} at offset {j}")


def _groups(pieces):
	return [p for p in pieces if isinstance(p, Group)]


def _only_group(pieces):
	"""The single Group making up an arg (ignoring whitespace), else None."""
	gs = _groups(pieces)
	rest = _code("".join(p for p in pieces if isinstance(p, str)))
	if len(gs) == 1 and re.fullmatch(r"\s*" + re.escape(gs[0].head) + r"\s*", rest):
		return gs[0]
	return None


def _is_output_cell(arg):
	g = _only_group(arg)
	if not g or g.head != "Cell" or g.open != "[" or len(g.args) < 2:
		return False
	style = _code(_text(g.args[1])).strip()
	return style.startswith('"') and style.strip('"') in OUTPUT_STYLES


def _unwrap(arg):
	"""Cell[CellGroupData[{c}, ...]] -> c; None if the group lost all its cells."""
	g = _only_group(arg)
	if g and g.head == "Cell" and len(g.args) == 1:
		inner = _only_group(g.args[0])
		if inner and inner.head == "CellGroupData" and inner.args:
			cells = _only_group(inner.args[0])
			if cells and cells.open == "{" and len(cells.args) == 1:
				cell = _text(cells.args[0]).strip()
				if not cell:
					return None
				return [re.match(r"\s*", _text(arg)).group() + cell]
	return arg


def _strip_group(g):
	args = []
	for arg in g.args:
		for p in _groups(arg):
			_strip_group(p)
		if g.head in ("Cell", "Notebook") and g.open == "[" and _OPTION.match(_code(_text(arg))):
			continue
		if g.open == "{":
			if _is_output_cell(arg):
				continue
			arg = _unwrap(arg)
			if arg is None:
				continue
		args.append(arg)
	g.args = args or [[""]]


def strip_notebook(text):
	top, _ = _parse(text, 0, None)
	nbs = [g for g in _groups(top[0]) if g.head == "Notebook"] if len(top) == 1 else []
	if len(nbs) != 1:
		raise ValueError("expected exactly one top-level Notebook[...] expression")
	_strip_group(nbs[0])
	newline = "\r\n" if "\r\n" in text else "\n"
	return HEADER.replace("\n", newline) + "Notebook" + nbs[0].text() + newline


def main(argv):
	# latin-1 round-trips arbitrary bytes; the front end writes notebooks as ASCII anyway
	if argv[:1] == ["--check"]:
		dirty = []
		for path in argv[1:]:
			with open(path, encoding="latin-1", newline="") as f:
				text = f.read()
			if strip_notebook(text) != text:
				dirty.append(path)
		for path in dirty:
			print(f"not stripped: {path}", file=sys.stderr)
		return 1 if dirty else 0
	with open(sys.stdin.fileno(), encoding="latin-1", newline="", closefd=False) as f:
		text = f.read()
	try:
		out = strip_notebook(text)
	except ValueError as e:
		print(f"nbstrip: cannot parse notebook ({e}); not staging it", file=sys.stderr)
		return 1
	with open(sys.stdout.fileno(), "w", encoding="latin-1", newline="", closefd=False) as f:
		f.write(out)
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
