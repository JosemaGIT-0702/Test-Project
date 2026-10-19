# Other languages

Add a directory per tool, following the same pattern as `calc/python`:

```
calc/<tool>/scripts/NN_name.<ext>   # numbered, reproducible, part of the pipeline
calc/<tool>/...                     # sources, packages, build files
```

Then teach `tools/run-calcs.sh` how to run `<ext>` (Julia `.jl` and shell `.sh` are
already wired). Scripts should write their outputs as `results/<name>.json` in the
`{"Key": {"value": x, "digits": n, "unit": "pb"}}` format so `make values` picks them
up. Typical additions in HEP:

- **FORM** (`calc/form/`): large traces/expansions; export results as Mathematica
  syntax (`Format Mathematica;`) into `results/analytic/` and re-import in a `.wl` script.
- **FeynArts/FeynCalc/Package-X/xAct**: just Mathematica packages. Installed ones: `Needs[...]` after
  `ScriptBegin` in each script that uses them; single-file packages: copy into
  `calc/mathematica/packages/` and `LoadPackage["name"]` (see its README).
- **Julia** (`calc/julia/`): `Project.toml` there; `run-calcs.sh` uses `--project=calc/julia`.
- **C++/Fortran** (`calc/cpp/`): CMake project; add an `NN_run.sh` script that builds and runs it.
- **MadGraph/Pythia/etc.**: cards in `calc/<tool>/cards/`, a `NN_run.sh` wrapper, outputs to `data/processed/`.

Also add a rule in `.claude/rules/` describing how agents should use the tool.
