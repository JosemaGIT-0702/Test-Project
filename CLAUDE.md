# CLAUDE.md

High-energy theory research project: a JHEP paper plus the analytic (Mathematica) and
numerical (Python) calculations behind it. The goal is that **every equation, number and
figure in the paper is produced by a script in `calc/`**, so the whole paper can be
regenerated with `make all`.

@notes/conventions.md

## Layout

| Path | What lives there |
|---|---|
| `paper/` | JHEP LaTeX. `main.tex` + `sections/*.tex`, notation in `macros.tex`, INSPIRE BibTeX in `references.bib` |
| `paper/generated/` | **Generated** by calc scripts: `values.tex` (`\val...` macros), `eq_<name>.tex`. Never edit by hand |
| `paper/figures/` | **Generated** figures (PDF) |
| `paper/images/` | Hand-made artwork (diagrams, sketches): the only figures not produced by a script |
| `calc/mathematica/Project.wl` | Pipeline infrastructure only: script isolation (`ScriptBegin`), checks (`AssertZero`), `ExportAnalytic`, `ExportValues`, package loaders (`LoadPackage`, `LoadGeometry`) |
| `calc/mathematica/packages/` | Physics packages shared by notebooks and scripts, copied unchanged (`supergrav.wl`: curvature for a given metric); see its README |
| `calc/mathematica/scripts/NN_*.wl` | Reproducible analytic calculations (run in order) |
| `calc/mathematica/notebooks/` | Exploratory notebooks -- not part of the pipeline; committed without outputs (git filter `tools/nbstrip.py`) |
| `calc/python/hepcalc/` | Python package: `bridge` (load Mathematica results), `results`, `plotting`, `constants`, `paths` |
| `calc/python/scripts/NN_*.py` | Reproducible numerical calculations |
| `calc/python/tests/` | pytest |
| `calc/python/notebooks/` | Exploratory Jupyter notebooks -- not part of the pipeline |
| `calc/other/` | README only: how to add other languages (FORM, Julia, C++...) as sibling `calc/<tool>/` directories |
| `results/` | `*.json` numerical results, `analytic/*.json` exported expressions |
| `data/raw/` | External inputs (read-only). `data/processed/` is generated |
| `notes/` | `conventions.md`, `log.md` (research log), `derivations/` (hand derivations in Markdown/LaTeX) |
| `literature/` | Paper notes, one Markdown file per INSPIRE texkey |
| `tools/` | `run-calcs.sh` (used by `make calc`), `make-arxiv.sh`, `nbstrip.py` (notebook git filter) |
| `.claude/` | `rules/` (instructions, mostly path-scoped), `skills/`, `settings.json` (permissions, hooks) |

## The pipeline

```
calc/*/scripts/NN_*.{wl,py}  ->  results/*.json, results/analytic/*.json
                             ->  paper/generated/, paper/figures/
make values                  ->  paper/generated/values.tex
make paper                   ->  paper/main.pdf
```

Scripts are numbered globally across languages (`01_*.wl`, `02_*.py`, ...) and run
in that order; a later script may consume anything an earlier one wrote.

## Commands

- `make paper` -- build the PDF (latexmk). `make watch` for continuous builds.
- `make calc-py` / `make calc ONLY=03` -- run calculations.
- `make test`, `make lint`.
- Python: always `uv run ...`, never bare `python` or `pip`. Add deps with `uv add`.
- **Mathematica: use the official Wolfram MCP server (installed globally per user, server `Wolfram`, tools `mcp__Wolfram__*`; setup in README; the project ships no `.mcp.json`), not the `wolframscript` CLI.**
  Run a pipeline script with `WolframLanguageEvaluator` and the code
  `Get["<abs path>/calc/mathematica/scripts/NN_x.wl"]`, then `make values`. Scripts isolate
  themselves with `ScriptBegin`/`ScriptEnd` (private context, state restored even after a failed
  check), so they behave the same here and under `wolframscript` (`make calc`). Explore and check
  derivations with the same tool (`Simplify[lhs - rhs]`, numerics at random points).
  (`make calc` uses wolframscript and is for humans/CI.)

## Rules for working in this repo

1. **No hand-typed results.** Numbers in the paper are `\val<Key>` macros; equations
   that come from a calculation are `\input{generated/eq_<name>}`. If you need a new
   number, add it to a script's `ExportValues`/`export_values` call.
2. **Cross-check everything.** Each new analytic result gets at least one independent
   check (equations of motion, constraints, asymptotics, symmetry, numerics, literature).
   Scripts must fail loudly (`AssertZero`/`CheckFailed` / `assert`) when a check fails.
3. **Conventions are law.** Use `notes/conventions.md`. If a reference uses different
   conventions, convert explicitly and note it in the derivation.
4. **Never cite from memory.** BibTeX comes from INSPIRE (`/add-reference`). If you
   cannot verify a claim from a paper, say so instead of guessing.
5. **Log progress.** After meaningful work, add an entry to `notes/log.md` (newest on top; `/log`).
6. Generated files (`paper/generated/`, `paper/figures/`, `results/`) ARE committed so
   coauthors/Overleaf/CI can build the paper without Mathematica. Regenerate, never edit.
7. Do not delete or overwrite `data/raw/`.
8. **Indent with tabs** in all code, LaTeX and JSON (`.editorconfig`); spaces only to align
   within a line. Exceptions: YAML and Markdown (spaces), vendored/INSPIRE files.

## Skills (`.claude/skills/`)

`/new-calc` scaffold a calculation ·
`/verify` cross-check a derivation · `/build-paper` compile and fix · `/sync-results`
regenerate everything and check consistency · `/add-reference` INSPIRE BibTeX ·
`/referee` critical review of the draft · `/log` update the research log.
