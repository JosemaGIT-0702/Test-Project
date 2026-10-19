# Mathematica packages

The physics toolkit of the project: the same packages are used in the exploratory notebooks
(`../notebooks/`) and in the pipeline scripts (`../scripts/`), so a calculation moves from a
notebook into a script without being rewritten. `../Project.wl` only provides the pipeline
infrastructure (script isolation, checks, exports) and the loaders below.

Packages are copied here **unchanged** from where they are developed, so coauthors and CI
need nothing outside the repository. To update one, copy the new version over and rerun
`make calc`. Installed packages (xAct, FeynCalc, ...) are not copied: load them with
`Needs[...]` (see `../../other/README.md`).

| Package | What it provides | Loaded with |
|---|---|---|
| `supergrav.wl` | tensor calculus for one fixed metric: `Christoffel`, `Riemann`, `RicciTensor`, `RicciScalar`, `Einstein`, `Weyl`, `covariant`, `divergence`, `scalarLaplacian`, `Lie`, `raise`, `lower`, `contract`, `symmetrize`, ... (context `Supergravity``) | `LoadGeometry[coords, metric]` |
| *other* `name.wl` | | `LoadPackage["name"]` |

## Using them

**In a notebook**, as usual:

```mathematica
coord = {r, t, x1, x2, x3};
metric = DiagonalMatrix[{1, -E^(2 A[r]), E^(2 A[r]), E^(2 A[r]), E^(2 A[r])}];
Get[FileNameJoin[{NotebookDirectory[], "..", "packages", "supergrav.wl"}]];
RicciTensor
```

**In a pipeline script**, scripts run in a private context (`ScriptBegin`), so do not set
`Global`coord`/`Global`metric` yourself; `LoadGeometry` does it:

```mathematica
LoadGeometry[{r, t, x1, x2, x3}, metric];   (* at top level, BEFORE defining functions that use RicciTensor etc. *)
ricci = RicciTensor;
f[...] := Module[{...}, LoadGeometry[coords2, metric2]; ... RicciTensor ...];   (* reload for another metric *)
```

Mathematica resolves a symbol's context when a definition is *read*: a function defined
before the first `LoadGeometry`/`LoadPackage` refers to a script-private `RicciTensor`, not to
the package's. Load once at the top of the script, then reload whenever the metric changes.

## supergrav.wl

- **Interface**: reads `Global`coord` (list of plain symbols, not `x[i]`) and `Global`metric`
  when loaded; curvature is for that metric only. Reloading for a new metric is supported
  (`LoadGeometry` handles the protected symbols and the cached sign of `det g`).
- **Conventions** (checked numerically against an independent implementation on a 3D
  Lorentzian metric with off-diagonal terms, 2026-10-19): `RicciTensor`, `RicciScalar`,
  `Einstein`, `scalarLaplacian` agree with `notes/conventions.md` (AdS has $R<0$).
  `Riemann` has a different index layout: `Riemann[[m, n, b, a]]` $= R^a{}_{bnm}$
  (first three indices down, last up).
- **Side effects** (they outlive `ScriptEnd`): adds definitions to `Part`, `Extract` and `**`
  (indices may be given by coordinate name, `**` is the outer product), and `Protect`s the
  coordinate symbols: never assign to them.
- **Cost**: almost every operation calls `Simplify`; fine for domain walls, slow for metrics
  with many functions of several variables.
- **Origin**: based on Matthew Headrick's `diffgeo.m` package, adapted by the author of this
  template.
