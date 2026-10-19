"""EXAMPLE numerics (from arXiv:2605.16168; /init-project removes it).

Lowest normal-mode masses M^2 L^2 of the ghost fluctuation Z_eta on the example-2 wormhole
(ABJM Coulomb branch, d = 3): table 1, row "Example 2 (analytical)". Follows the original
notebook (github.com/JosemaGIT-0702/Wormhole-Spectrum, Stability_Analysis_Examples_1_2_5.nb,
example 2), with L = 1, r0 = 0 and lambda = M^2 L^2:

  1. Z_eta equation in r (notebook cell eqZeta, = app. C of the paper) -> compact coordinate
     r = log((1+v)/(1-v)); checked against eq. (C.4) of the paper.
  2. Closed-form solution of that equation (found by the notebook authors with Mathematica 11),
     z = pref(v) [8 sqrt(4+lam) |lam| C1 e^{Phi(v)} + i C2 e^{-Phi(v)}];
     checked here to solve the v-equation numerically.
  3. Regularity at the throat v = 0 (no 1/v term) fixes C2/C1; checked against the notebook's
     C2 = 8 i sqrt(4+lam) |lam| C1.
  4. Near the boundary z = C1' (1+v) + C2' (1+v)^2 + ...; in the alternative quantization a normal
     mode has no source, C2'/C1' = 0. Its zeros in lambda are the spectrum.

Checks: steps 1-3 above, no negative eigenvalues (stability), agreement with table 1.
Outputs: results/05_ghost_spectrum_ex2.json
"""

import mpmath as mp
import numpy as np
import sympy as sp
from hepcalc.results import export_values
from scipy.optimize import brentq

mp.mp.dps = 30
N_MODES = 3
PAPER_TABLE_1 = [8.148, 57.26, 137.4]  # example 2, analytical
LAM_SCAN = np.arange(0.5, 160.0, 0.5)  # where to look for roots of C2'/C1'
LAM_NEGATIVE = np.arange(-3.9, -0.05, 0.05)  # instability would show up here

# ---------------------------------------------------------------- 1. the equation
r, v, lam, eta = sp.symbols("r v lam eta")
W = 4 * sp.cos(eta / 2)
d = 3
V = sp.simplify(-sp.Rational(1, 2) * sp.diff(W, eta) ** 2 - sp.Rational(d, 4 * (d - 1)) * W**2)
eta0 = 4 * sp.atan(sp.exp(r))
a = 4 * sp.cosh(r) ** 2
dV, ddV = sp.diff(V, eta).subs(eta, eta0), sp.diff(V, eta, 2).subs(eta, eta0)
de, da = sp.diff(eta0, r), sp.diff(a, r)
# notebook eqZeta: Z'' + p1 Z' + p0 Z = 0
p1 = 3 * da / (2 * a)
p0 = lam / a - 2 * a * dV * de / da - sp.Rational(3, 2) * de**2 - a**2 * de**4 / (2 * da**2) + ddV
# compactification r = log((1+v)/(1-v)): z'' + (p1 r_v - r_vv/r_v) z' + p0 r_v^2 z = 0
rv = sp.log((1 + v) / (1 - v))
r_v, r_vv = sp.diff(rv, v), sp.diff(rv, v, 2)
q1 = sp.lambdify((v, lam), p1.subs(r, rv) * r_v - r_vv / r_v, "mpmath")
q0 = sp.lambdify((v, lam), p0.subs(r, rv) * r_v**2, "mpmath")


def q1_paper(v, lam):  # eq. (C.4)
	return 2 * v * (v**2 - 5) / (v**4 - 1)


def q0_paper(v, lam):
	return lam / (v**2 + 1) ** 2 - 2 * (v**4 - 6 * v**2 + 1) / (v**2 * (v**2 - 1) ** 2)


rng = np.random.default_rng(1)
for vv, ll in zip(rng.uniform(-0.95, -0.05, 8), rng.uniform(0.5, 150, 8)):
	vv, ll = mp.mpf(vv), mp.mpf(ll)
	assert abs(q1(vv, ll) - q1_paper(vv, ll)) < 1e-20, "z' coefficient differs from (C.4)"
	assert abs(q0(vv, ll) - q0_paper(vv, ll)) < 1e-20 * abs(q0_paper(vv, ll)), (
		"z coefficient differs"
	)


# ---------------------------------------------------------------- 2. the notebook's solution
def phi(v, lam):
	"""Phase Phi(v) of the notebook solution (exponent of e^{+-Phi})."""
	sl, s4 = mp.sqrt(lam), mp.sqrt(4 + lam)
	km, kp = mp.sqrt(2 + lam - sl * s4), mp.sqrt(2 + lam + sl * s4)
	bracket = 2 * (4 + lam) * mp.atan(v) + mp.sqrt(2) * (
		(-4 - lam + sl * s4) * mp.atan(mp.sqrt(2) * v / km) / km
		- (4 + lam + sl * s4) * mp.atan(mp.sqrt(2) * v / kp) / kp
	)
	return 1j * lam * bracket / (2 * mp.sqrt(lam**2 * (4 + lam)))


def pref(v, lam):
	sl, s4 = mp.sqrt(lam), mp.sqrt(4 + lam)
	return (
		-(v**2 - 1)
		* mp.sqrt(2 + 2 * v**2 + lam - sl * s4)
		* mp.sqrt(2 + 2 * v**2 + lam + sl * s4)
		/ (8 * v * (1 + v**2) * s4 * abs(lam))
	)


def z_sol(v, lam, c1, c2):
	return pref(v, lam) * (
		8 * mp.sqrt(4 + lam) * abs(lam) * c1 * mp.exp(phi(v, lam)) + 1j * c2 * mp.exp(-phi(v, lam))
	)


def residual(z, v, lam):
	return mp.diff(z, v, 2) + q1(v, lam) * mp.diff(z, v) + q0(v, lam) * z(v)


for vv, ll in zip(rng.uniform(-0.9, -0.1, 6), rng.uniform(0.5, 150, 6)):
	for c1, c2 in ((1, 0), (0, 1)):

		def z(x, ll=ll, c1=c1, c2=c2):
			return z_sol(x, mp.mpf(ll), c1, c2)

		scale = abs(mp.diff(z, mp.mpf(vv), 2)) + abs(z(mp.mpf(vv)))
		assert abs(residual(z, mp.mpf(vv), mp.mpf(ll))) < 1e-15 * scale, "notebook solution fails"


# ---------------------------------------------------------------- 3. regularity at the throat
def throat_residue(lam, c1, c2):
	"""Coefficient of 1/v at v -> 0^-."""
	return mp.limit(lambda x: x * z_sol(x, lam, c1, c2), 0, direction=-1)


def regular_c2(lam):
	"""C2/C1 such that the 1/v term cancels (C1 = 1)."""
	r1, r2 = throat_residue(lam, 1, 0), throat_residue(lam, 0, 1)
	return -r1 / r2


def notebook_c2(lam):
	"""The notebook's closed form of the regularity condition, C2 = 8 i sqrt(4+lam) |lam| C1."""
	return 8j * mp.sqrt(4 + lam) * abs(lam)


for ll in (mp.mpf("0.9"), mp.mpf("3.7"), mp.mpf("42.1"), mp.mpf("131.3")):
	assert abs(regular_c2(ll) / notebook_c2(ll) - 1) < 1e-15, (
		"regularity condition differs from notebook"
	)


# ---------------------------------------------------------------- 4. boundary fall-offs
def source_ratio(lam: float) -> complex:
	"""C2'/C1' of the regular solution at the boundary, z = C1' x + C2' x^2 + ..., x = 1 + v."""
	lam = mp.mpf(lam)
	c2 = notebook_c2(lam)  # verified against the numerical throat expansion above

	def z(x):  # as a function of x = 1 + v
		return z_sol(x - 1, lam, 1, c2)

	d1, d2 = mp.diff(z, 0, 1), mp.diff(z, 0, 2)
	return complex(d2 / (2 * d1))


def f(lam: float) -> float:
	ratio = source_ratio(lam)
	assert abs(ratio.imag) < 1e-12 * max(1.0, abs(ratio.real)), f"C2'/C1' not real at {lam}"
	return ratio.real


values = np.array([f(x) for x in LAM_SCAN])
roots = []
for i in np.nonzero(np.sign(values[:-1]) != np.sign(values[1:]))[0]:
	root = brentq(f, LAM_SCAN[i], LAM_SCAN[i + 1], xtol=1e-12, rtol=1e-14)
	if abs(f(root)) < 1e-8:  # a genuine zero, not a pole of the cotangent
		roots.append(root)
roots = np.array(roots[:N_MODES])

negative = np.array([f(x) for x in LAM_NEGATIVE])
assert np.all(np.sign(negative) == np.sign(negative[0])), (
	"C2'/C1' changes sign at M^2 < 0: unstable mode"
)
assert len(roots) == N_MODES, f"found {roots}"
assert np.allclose(roots, PAPER_TABLE_1, rtol=5e-4), f"disagrees with table 1: {roots}"

export_values(
	"05_ghost_spectrum_ex2",
	{
		f"MSqExTwo{label}": {"value": m2, "digits": 4}
		for label, m2 in zip(("First", "Second", "Third"), roots)
	},
)

print(f"05_ghost_spectrum_ex2: OK  M^2 L^2 = {np.array2string(roots, precision=6)}")
