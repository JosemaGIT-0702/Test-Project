# Conventions

Single source of truth for notation and conventions. `calc/mathematica/Project.wl`,
`calc/python/hepcalc/constants.py` and `paper/macros.tex` must agree with this file.
Fill in / change at project start (`/init-project`), then treat as frozen; any later
change must be propagated to all three places and noted in `log.md`.

The entries below are those of the example paper (arXiv:2605.16168); keep the
headings, replace the content.

## Spacetime and curvature
- Bulk dimension $d+1$; boundary dimension $d$.
- Mostly-plus signature $(-,+,\dots,+)$.
- Indices: $M,N,\dots$ all bulk directions; $\mu,\nu,\dots$ parallel to the boundary;
  $i,j,\dots$ spatial boundary directions.
- Riemann $R^a{}_{bcd} = \partial_c\Gamma^a_{db} - \partial_d\Gamma^a_{cb} + \Gamma^a_{ce}\Gamma^e_{db} - \Gamma^a_{de}\Gamma^e_{cb}$,
  Ricci $R_{bd} = R^a{}_{bad}$: AdS has $R<0$ (as computed by `calc/mathematica/packages/supergrav.wl`,
  whose `Riemann[[m, n, b, a]]` $= R^a{}_{bnm}$).
- Domain-wall ansatz $\dd s^2 = \dd r^2 + e^{2A(r)}\eta_{\mu\nu}\dd x^\mu\dd x^\nu$; AdS radius $L$;
  dimensionless radial coordinate $u = r/L$ in numerics.

## Action and normalisations
- $S_{d+1} = \frac{1}{16\pi G_{d+1}}\int\dd^{d+1}x\sqrt{-G}\,\big[R - \tfrac12(\partial\phi^I)^2 - V\big]$,
  $2\kappa_{d+1}^2 = 16\pi G_{d+1}$.
- Superpotential: $V = \tfrac12(\partial_{\phi^I}W)^2 - \frac{d}{4(d-1)}W^2$;
  BPS: $\phi' = \partial_\phi W$, $A' = -\frac{W}{2(d-1)}$. Sign of $W$ chosen so that the AdS
  boundary at the origin of field space sits at $r\to-\infty$.
- Analytic extension $\phi^a = i\eta^a$: ghosts $\eta^a$, $\eta' = -\partial_\eta W$.
- Holographic dictionary: $\phi \sim \phi_\pm + \alpha_\pm e^{\pm(d-\Delta)r/L} + \beta_\pm e^{\pm\Delta r/L}$
  at $r\to\mp\infty$; ordinary quantisation: $\alpha$ source, $\beta$ vev.
- String/M-theory units when needed: $\ell_s$, $\alpha' = \ell_s^2$, $g_s$; state any
  other choice (e.g. $L$ vs. $g = 2/L$ in refs. [Khavaev:2000gb, Bobev:2010de]) explicitly.

## Symbol names across tools
| Physics | Mathematica | Python (sympy) | LaTeX |
|---|---|---|---|
| radial coordinate $r$, $u = r/L$ | `r`, `u` | `r`, `u` | `r`, `u` |
| AdS radius $L$ | `L` | `L` | `L` |
| ghost scalar(s) $\eta$, $\eta^{1,2}$ | `eta`, `eta1`, `eta2` | `eta`, `eta1`, `eta2` | `\eta`, `\eta^1` |
| warp factor $e^{2A}$ | `E^(2 A)`, `warp*` | `warp` | `e^{2A}` |
| boundary dimension $d$ | `d` | `d` | `d` |
| Chebyshev variable $s$ | `s` | `s` | `s` |
