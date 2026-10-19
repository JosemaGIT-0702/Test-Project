---
paths:
  - "calc/python/**"
  - "tools/*.py"
  - "pyproject.toml"
---

# Python rules

- Run everything with `uv run` (`uv run python ...`, `uv run pytest`); add dependencies
  with `uv add <pkg>` (dev tools: `uv add --dev`). Never `pip install`.
- Pipeline scripts: `calc/python/scripts/NN_name.py`, run top-to-bottom, no CLI args needed.
- Reusable code goes in the `hepcalc` package, with a test in `calc/python/tests/`.
- Constants from `hepcalc.constants` only; analytic inputs from `hepcalc.bridge`
  (Mathematica exports) and numbers from `hepcalc.results.load_values` rather than re-typed formulas.
- Results via `hepcalc.results.export_values`; figures via `hepcalc.plotting`
  (`use_paper_style()`, `figure()`, `save()` -> `paper/figures/<name>.pdf`).
- Every numerical result carries an error estimate or a check (`assert`) against an
  analytic limit / independent method. Report integration/MC uncertainties.
- Vectorise with numpy; for expensive scans cache to `data/processed/` and note it.
- Run `make format`, `make test` and `make lint` before declaring a task done.
