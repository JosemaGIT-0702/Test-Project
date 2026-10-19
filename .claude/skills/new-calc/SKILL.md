---
name: new-calc
description: Scaffold a new reproducible calculation (Mathematica .wl or Python .py) in the numbered pipeline, wired to export results to the paper. Use when starting a new analytic or numerical computation.
argument-hint: "<short_name> [mathematica|python] [what it computes]"
---

# Scaffold a calculation

Arguments: `$ARGUMENTS`

1. Choose the language: analytic/symbolic -> Mathematica; numerics, fits, plots -> Python.
   If unclear, ask.
2. Pick the next free global number: list `calc/*/scripts/[0-9]*` and take max+1
   (two digits). Filename `NN_<short_name>.wl` or `.py`, snake_case.
3. Create the script from the matching template below, with a header stating: what it
   computes, assumptions/approximations, inputs (which earlier scripts / `data/raw`
   files), outputs (exact files and value keys).
4. Implement the calculation **with at least one built-in check** that aborts on failure
   (see `.claude/rules/physics.md`). Develop heavy symbolic steps interactively with
   `WolframLanguageEvaluator` first and time them: a script that runs for minutes blocks the MCP kernel.
5. Run it (Mathematica via Wolfram MCP `WolframLanguageEvaluator` with `Get["<abs path>"]`; Python via `uv run python <file>`),
   then `make values`.
6. If results belong in the paper, use them via `\val<Key>` / `\input{generated/eq_<name>}`
   and run `make paper`.
7. Add a line to today's entry in `notes/log.md` (newest entries on top; create the entry
   as `/log` does if there is none).

## Mathematica template

```mathematica
(* ::Package:: *)
(* NN_name.wl -- <what it computes>
   Assumptions: ...
   Inputs: ...
   Outputs: results/analytic/<name>.json, results/NN_name.json *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Project.wl"}]];
ScriptBegin["ScriptNN"];     (* private context + clean state: same behaviour under MCP and wolframscript *)
$Assumptions = L > 0 && Element[r, Reals];
(* physics from calc/mathematica/packages/ (same as the notebooks), at top level before any definition
   that uses it: LoadGeometry[{r, t, x1, x2, x3}, metric] -> RicciTensor, Einstein, scalarLaplacian, ...
   (supergrav.wl); LoadPackage["name"] for other packages; Needs["..."] for installed ones *)

result = ...;

(* checks: AssertZero[label, expr] (Simplify <= 10 s, then 40-digit numerics), or
   CheckFailed[msg] for any other condition. Both stop the script; in the MCP kernel they Abort[]. *)
AssertZero["<what is checked>", <expression that must vanish>];
If[!TrueQ[<condition>], CheckFailed["<what>"]];

ExportAnalytic["<name>", result];
ExportValues["NN_name", <|"<Key>" -> <|"value" -> ..., "digits" -> 4|>|>];
Print["NN_name: OK"];
ScriptEnd[];
```

## Python template

```python
"""NN_name -- <what it computes>

Assumptions: ...
Inputs: ...
Outputs: results/NN_name.json, paper/figures/<fig>.pdf
"""

from hepcalc import bridge, plotting
from hepcalc.results import export_values, load_values

# f = bridge.lambdify("<analytic name>", "u")           # expression from ExportAnalytic
# m = load_values("NN_earlier_script")["<Key>"]        # number from ExportValues
...
assert ..., "check failed: <what>"

export_values("NN_name", {"<Key>": {"value": ..., "digits": 4}})
print("NN_name: OK")
```
