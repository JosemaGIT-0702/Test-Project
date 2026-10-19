"""EXAMPLE numerics (from arXiv:2605.16168; /init-project removes it).

Lowest normal-mode masses M^2 L^2 of the ghost fluctuation Z_eta on the example-1
wormhole, app. C: Chebyshev collocation on the Gauss-Lobatto grid for

    (1 - s^2) psi'' + A0(s) psi' + [B0(s) + M^2 B1(s)] psi = 0,   s in [-1, 1].

A0, B0, B1 are derived (and checked against the paper) in 02_ghost_fluctuations.wl.
The factor (1 - s^2) makes the endpoints regular singular points, so finiteness of
psi -- i.e. the normalisable/regular boundary conditions on z_eta -- needs no explicit
boundary rows. Checks: convergence between N = 100 and N = 200 collocation points, and
agreement with table 1 of the paper.

Outputs: results/03_ghost_spectrum.json
"""

import numpy as np
import scipy.linalg as la
from hepcalc import bridge
from hepcalc.results import export_values

N_MODES = 3
PAPER_TABLE_1 = [13.397, 53.933, 117.15]  # example 1, spectral


def cheb(n: int):
	"""Chebyshev differentiation matrix and Gauss-Lobatto points (Trefethen, Spectral Methods in MATLAB)."""
	x = np.cos(np.pi * np.arange(n + 1) / n)
	c = np.hstack([2, np.ones(n - 1), 2]) * (-1) ** np.arange(n + 1)
	dx = x[:, None] - x[None, :]
	d = np.outer(c, 1 / c) / (dx + np.eye(n + 1))
	return d - np.diag(d.sum(axis=1)), x


A0, B0, B1 = (bridge.lambdify(f"zeta_ex1_{k}", "s") for k in ("A0", "B0", "B1"))


def spectrum(n: int) -> np.ndarray:
	d, s = cheb(n)
	op = np.diag(1 - s**2) @ d @ d + np.diag(A0(s)) @ d + np.diag(B0(s))
	# op psi = -M^2 B1 psi; B1 vanishes at s = +-1, giving two infinite eigenvalues
	m2 = la.eig(op, -np.diag(B1(s)), right=False)
	m2 = m2[np.isfinite(m2)]
	m2 = m2[(abs(m2.imag) < 1e-8 * abs(m2.real)) & (m2.real > 0)].real
	return np.sort(m2)[:N_MODES]


coarse, fine = spectrum(100), spectrum(200)
assert np.allclose(coarse, fine, rtol=1e-8), f"not converged: {coarse} vs {fine}"
assert np.allclose(fine, PAPER_TABLE_1, rtol=5e-4), f"disagrees with table 1: {fine}"
assert np.all(fine > 0), "negative M^2: unstable mode"

export_values(
	"03_ghost_spectrum",
	{
		f"MSqExOne{label}": {"value": m2, "digits": 5}
		for label, m2 in zip(("First", "Second", "Third"), fine)
	},
)

print(f"03_ghost_spectrum: OK  M^2 L^2 = {np.array2string(fine, precision=6)}")
