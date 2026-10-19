import importlib.util
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
_spec = importlib.util.spec_from_file_location("nbstrip", ROOT / "tools" / "nbstrip.py")
nbstrip = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(nbstrip)

TRACKED = subprocess.run(
	["git", "ls-files", "*.nb"], cwd=ROOT, capture_output=True, text=True, check=True
).stdout.split()

SAMPLE = r"""(* Content-type: application/vnd.wolfram.mathematica *)

(*** Wolfram Notebook File ***)
(* CreatedBy='Mathematica 14.1' *)
(*CacheID: 234*)
(* NotebookDataPosition[       158,          7] *)
Notebook[{
Cell[CellGroupData[{
Cell["Title (* not a comment *) \"q\"", "Title",
 CellChangeTimes->{{3.9*^9, 3.9*^9}},ExpressionUUID->"aaaa"],
Cell[CellGroupData[{
Cell[BoxData[
 RowBox[{"Print", "[", "\"\<hi]\>\"", "]"}]], "Input",
 CellLabel->"In[1]:=",ExpressionUUID->"bbbb"],
Cell[BoxData["\<\"hi]\"\>"], "Print",
 CellLabel->"During evaluation of In[1]:=",ExpressionUUID->"cccc"]
}, Open  ]],
Cell[CellGroupData[{
Cell[BoxData[RowBox[{"1", "+", "1"}]], "Input",
 CellLabel->"In[2]:=",ExpressionUUID->"dddd"],
Cell[BoxData["2"], \
"Output", CellLabel->"Out[2]=",ExpressionUUID->"eeee"],
Cell[CellGroupData[{
Cell[BoxData["x"], "Echo",\
CellChangeTimes->{3.9*^9}],
Cell[BoxData["y"], "Echo"]
}, Open  ]]
}, Open  ]]
}, Open  ]]
},
WindowSize->{808, 911},
WindowMargins->{{4, Automatic}, {Automatic, 4}},
FrontEndVersion->"14.1 for Mac OS X ARM (64-bit) (July 16, 2024)",
StyleDefinitions->"Default.nb",
ExpressionUUID->"ffff"
]
(* End of Notebook Content *)

(* Internal cache information *)
(*CellTagsOutline
CellTagsIndex->{}
*)
"""


def test_strips_outputs_cache_and_metadata():
	out = nbstrip.strip_notebook(SAMPLE)
	for gone in (
		"Output",
		'], "Print"',
		"CellChangeTimes",
		"ExpressionUUID",
		"CellLabel",
		"WindowSize",
		"FrontEndVersion",
		"CacheID",
		"Internal cache",
	):
		assert gone not in out, gone
	for kept in (
		'"Title"',
		"(* not a comment *)",
		r"\"\<hi]\>\"",
		'"1", "+", "1"',
		'StyleDefinitions->"Default.nb"',
	):
		assert kept in out, kept
	assert out.count("CellGroupData") == 1  # input-only groups unwrapped, output-only group dropped
	assert ", ," not in out.replace("\n", " ") and ",\n\n}" not in out
	assert nbstrip.strip_notebook(out) == out


def test_rejects_non_notebook():
	with pytest.raises(ValueError):
		nbstrip.strip_notebook('Notebook[{Cell["x", "Input"]')


@pytest.mark.parametrize("path", TRACKED)
def test_committed_notebooks_are_stripped(path):
	"""Fails if a notebook was committed from a clone without `make setup` (no git filter)."""
	blob = subprocess.run(
		["git", "show", f":{path}"], cwd=ROOT, capture_output=True, check=True
	).stdout
	text = blob.decode("latin-1")
	assert nbstrip.strip_notebook(text) == text, (
		f"{path}: run `make setup && git add --renormalize '*.nb'`"
	)
