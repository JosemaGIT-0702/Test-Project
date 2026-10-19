# Research log

Newest entries on top. One entry per working session: what was done, what was
found, what is open. Agents add entries here via `/log`.

## 2026-10-19
- Done: initialised the project from the HEP template (`/init-project`): removed the template's example paper
  (scripts 01-05, results, generated equations, figures, sections, bibliography);
  new paper skeleton (introduction, setup, results, conclusions, conventions appendix) with
  placeholder title, author, affiliation and abstract; project renamed in `pyproject.toml`.
- Goal: not yet specified (placeholder) -- write the one-paragraph physics goal here and in the
  introduction.
- Conventions: unchanged from the template (mostly-plus, AdS has $R<0$,
  $S = \frac{1}{16\pi G}\int\sqrt{-G}[R - \frac12(\partial\phi)^2 - V]$, $2\kappa^2 = 16\pi G$, AdS radius $L$);
  only the example-specific entries (the analytic extension to imaginary scalars) were dropped.
- Extra tools: none (Mathematica + Python only).
- Next: (1) set title, authors, affiliations (`paper/main.tex`) and one `\newauthornote` per author
  (`paper/macros.tex`); (2) state the physics goal; (3) first calculation with `/new-calc`.

