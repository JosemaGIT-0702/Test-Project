# Physics working rules

- State assumptions explicitly (truncation, ansatz, which fields are switched on, gauge,
  approximations, regime of validity) in the script header and in the paper.
- Before trusting a new result, check at least one of:
  - **equations of motion**: a solution of first-order (BPS) equations must solve the full
    second-order equations; compute curvature from the metric (`LoadGeometry` + `RicciTensor`
    etc. from `calc/mathematica/packages/supergrav.wl`), not from hand-reduced equations;
  - **consistency**: Bianchi identities, constraints (e.g. the $rr$ Einstein equation),
    flux quantisation, gauge/diffeomorphism invariance of fluctuations;
  - **asymptotics and limits**: AdS/flat asymptotics, near-boundary expansions and
    conformal dimensions, IR behaviour, known special cases of a family;
  - **holography**: counterterms cancel divergences, Ward identities, $c$-/$a$-theorem
    monotonicity where expected, positivity of entropies and mutual information;
  - **stability**: normal-mode spectra, BF bounds, energy conditions (state which are violated);
  - **numerics**: convergence in resolution/cutoffs, agreement between two methods;
  - **literature**: compare with a published result (quote equation numbers and convert
    conventions explicitly).
- When comparing with a paper, record in `literature/<texkey>.md` the conventions it
  uses and how they map to `notes/conventions.md`.
- Distinguish clearly between what was computed/verified and what is conjectured or
  recalled from memory. Never present an unverified formula as established.
- Signs and factors of 2, π, i are the usual failure points (curvature sign conventions,
  $\kappa$ vs. $G$, the $i$ from analytic continuation): track them explicitly and test them numerically.
