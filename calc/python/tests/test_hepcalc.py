import json

import pytest
import sympy as sp
from hepcalc import bridge, results
from hepcalc.paths import ANALYTIC

ANALYTIC_EXPORTS = sorted(ANALYTIC.glob("*.json")) if ANALYTIC.exists() else []


def test_value_formatting():
	assert results._fmt({"value": 868.5447, "digits": 4, "unit": "pb"}) == r"868.5\,\mathrm{pb}"
	assert results._fmt({"value": 1.2e-12, "digits": 2}) == r"1.2\times 10^{-12}"
	assert results._fmt({"value": 2.000003, "decimals": 5}) == "2.00000"


@pytest.mark.parametrize("path", ANALYTIC_EXPORTS, ids=lambda p: p.stem)
def test_analytic_export_is_complete(path):
	record = json.loads(path.read_text())
	assert record["mathematica"] and record["tex"], path.name


@pytest.mark.parametrize("path", ANALYTIC_EXPORTS, ids=lambda p: p.stem)
def test_analytic_export_parses_in_sympy(path):
	"""Every Mathematica export must be loadable by hepcalc.bridge (symbol names, functions)."""
	expr = bridge.load(path.stem)
	assert isinstance(expr, sp.Expr)
	# Unparsed Mathematica heads (e.g. PolyLog -> undefined function) show up here
	unknown = {
		f.func.__name__
		for f in expr.atoms(sp.Function)
		if isinstance(f.func, sp.core.function.UndefinedFunction)
	}
	assert not unknown, f"{path.name}: sympy does not know {unknown}"


def test_values_tex_builds(tmp_path, monkeypatch):
	"""values.tex generation works and rejects bad keys."""
	monkeypatch.setattr(results, "RESULTS", tmp_path / "results")
	monkeypatch.setattr(results, "GENERATED", tmp_path / "generated")
	results.export_values("demo", {"Foo": 1.5})
	text = results.build_values_tex().read_text()
	assert r"\newcommand{\valFoo}" in text
	results.export_values("bad", {"Foo2": 1.0})
	with pytest.raises(ValueError):
		results.build_values_tex()
