---
name: verify
description: Independently cross-check a derivation, equation or numerical result (limits, symmetries, dimensions, numerics, literature) using Mathematica. Use when the user says verify/check a result, or before a result goes into the paper.
argument-hint: "<equation label, file, or description of the result>"
---

# Verify a result

Target: `$ARGUMENTS`

Act as a skeptical second author. The goal is to find errors, not to confirm.

1. **Locate** the result: the paper equation (`\label`), the script that produces it, any
   derivation in `notes/derivations/`. State it precisely with all conventions
   (`notes/conventions.md`).
2. **Step check**: if there is a chain of steps, check each equality with the Wolfram MCP
   `WolframLanguageEvaluator` (`Simplify[lhs - rhs]`,
   and numerically at random rational points when `Simplify` is inconclusive).
3. **Independent checks** -- do as many as apply, each as an actual computation:
   - equations of motion: plug the solution into the full second-order equations, with
     curvature computed from the metric (`packages/supergrav.wl`), not only the first-order/BPS ones;
   - constraints and identities: Hamiltonian constraint, Bianchi identities, flux equations;
   - dimensional analysis / scaling weights of every term;
   - asymptotics and limits: AdS/flat ends, near-boundary falloffs vs. conformal dimensions,
     IR behaviour, special members of a family of solutions;
   - symmetries (diffeomorphism/gauge invariance of fluctuations, parity, Ward identities);
   - positivity / unitarity / reality where required (spectra, entropies, BF bounds);
   - independent re-derivation by a different route (different gauge, different
     parametrisation, numerical evaluation vs analytic);
   - literature: compare with a published result, converting conventions explicitly.
     Only use papers you can actually read (INSPIRE/arXiv); never quote from memory.
4. **Report** a table: check | method | result (PASS / FAIL / INCONCLUSIVE) | notes.
   For any FAIL, locate the first wrong step and propose a fix -- do not silently change
   the result.
5. Offer to turn the useful checks into permanent asserts in the producing script, and
   log the outcome in `notes/log.md`.
