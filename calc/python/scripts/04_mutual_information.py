"""EXAMPLE numerics (from arXiv:2605.16168; /init-project removes it).

Holographic mutual information of a strip between the two boundaries of the
wormholes of examples 1, 2, 5 (sec. 4.2): eqs. (4.15) and (4.16) evaluated
numerically with u = r/L, for warp factors e^{2A(u)} exported by
01_wormhole_backgrounds.wl, followed by a linear fit at large width,

    I / (C V) = m * Delta l / L + n ,   C = L / G_{d+1} .

Checks: the fitted slopes reproduce the analytic large-width result (4.21),
m = e^{(d-1)A(0)}/2 (computed in 01_wormhole_backgrounds.wl), and the
intercepts agree with the values quoted in the paper.

Outputs: results/04_mutual_information.json, paper/figures/mutual_information.pdf
"""

import mpmath as mp
import numpy as np
from hepcalc import bridge, plotting
from hepcalc.results import export_values, load_values

U_MAX = 40.0  # integrands decay like e^{-d A} ~ e^{-d u}; the tail beyond u* + U_MAX is < 1e-60
FIT_WINDOW = (3.0, 6.0)  # Delta l / L range used for the large-width fit
mp.mp.dps = 40  # near the throat A(u) - A(u*) cancels catastrophically in double precision
# quadrature nodes closer to u* than this contribute < 1e-12 to the integrals
TINY = mp.mpf("1e-35")

EXAMPLES = {
	# key: (d, label, colour, number in the paper, intercept quoted in the paper)
	"ex1": (4, r"1. Coulomb branch $\mathcal{N}=4$ SYM", "tab:blue", "One", -0.66611),
	"ex2": (3, "2. Coulomb branch ABJM", "tab:red", "Two", -1.06581),
	"ex5": (4, "5. GPPZ", "tab:green", "Five", -0.87333),
}


def strip(d: int, warp, u_star: float) -> tuple[float, float]:
	"""(width / L, I / (C V)) for the disconnected surfaces turning at u_star > 0.

	With y = e^{2(d-1)(A* - A)}: the bracket of (4.15) is e^{(d-2)A} [1/sqrt(1-y) - 1] and the
	integrand of (4.16) is sqrt(y) e^{-A} / sqrt(1-y). tanh-sinh quadrature handles the
	integrable 1/sqrt singularity at u_star.
	"""
	us = mp.mpf(u_star)
	w_star = warp(us)

	def y(u):
		return (w_star / warp(u)) ** (d - 1)

	def area(u):
		gap = 1 - y(u)
		return warp(u) ** (mp.mpf(d - 2) / 2) * (1 / mp.sqrt(gap) - 1) if gap > TINY else 0

	def width(u):
		gap = 1 - y(u)
		return mp.sqrt(y(u) / (warp(u) * gap)) if gap > TINY else 0

	nodes = [us, us + mp.mpf("1e-3"), us + 1, us + U_MAX]
	throat = mp.quad(lambda u: warp(u) ** (mp.mpf(d - 2) / 2), [0, us])
	info = mp.quad(area, nodes) - throat
	return 2 * float(mp.quad(width, nodes)), max(float(info), 0.0)


analytic_slopes = load_values("01_wormhole_backgrounds")
values, curves = {}, {}
for key, (d, label, colour, name, n_paper) in EXAMPLES.items():
	warp = bridge.lambdify(f"warp_{key}", "u", modules="mpmath")
	u_stars = np.geomspace(1e-7, 3.0, 160)
	width, info = np.array([strip(d, warp, us) for us in u_stars]).T
	curves[key] = (width, info)

	sel = (width > FIT_WINDOW[0]) & (width < FIT_WINDOW[1])
	assert sel.sum() > 10, f"{key}: too few points in the fit window"
	m, n = np.polyfit(width[sel], info[sel], 1)
	m_analytic = analytic_slopes[f"MISlopeAnalyticEx{name}"]
	assert abs(m / m_analytic - 1) < 1e-4, f"{key}: slope {m} vs analytic {m_analytic}"
	assert abs(n - n_paper) < 2e-3, f"{key}: intercept {n} vs paper {n_paper}"
	values[f"MISlopeEx{name}"] = {"value": m, "decimals": 5}
	values[f"MIInterceptEx{name}"] = {"value": n, "decimals": 5}
	curves[key] += (m, n)

export_values("04_mutual_information", values)

plotting.use_paper_style()
fig, ax = plotting.figure(width=0.7)
for key, (d, _label, colour, *_) in EXAMPLES.items():
	width, info, m, n = curves[key]
	shown = width < 3.0
	ax.plot(width[shown], info[shown], "o", ms=2.5, color=colour)
	w = np.linspace(1.0, 3.0, 50)
	ax.plot(w, m * w + n, "--", lw=0.9, color=colour)
ax.set_xlim(0, 3)
ax.set_ylim(-0.1, 4)
ax.set_xlabel(r"$\Delta\ell(\mathrm{A})/L$")
ax.set_ylabel(r"$I(\mathrm{A})/(\mathcal{C}\,V)$")
plotting.save(fig, "mutual_information")

print(
	"04_mutual_information: OK  "
	+ ", ".join(f"{k}: m = {curves[k][2]:.6f}, n = {curves[k][3]:.5f}" for k in EXAMPLES)
)
