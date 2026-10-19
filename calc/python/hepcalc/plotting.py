"""Matplotlib style for paper figures (JHEP text width ~ 15 cm)."""

import matplotlib as mpl
import matplotlib.pyplot as plt

from .paths import FIGURES

TEXT_WIDTH_IN = 5.9


def use_paper_style() -> None:
	mpl.rcParams.update(
		{
			"font.family": "serif",
			"font.size": 10,
			"axes.labelsize": 10,
			"legend.fontsize": 9,
			"xtick.direction": "in",
			"ytick.direction": "in",
			"xtick.top": True,
			"ytick.right": True,
			"mathtext.fontset": "cm",
			"savefig.bbox": "tight",
		}
	)


def figure(width: float = 0.6, aspect: float = 0.75):
	"""New figure whose width is a fraction of the JHEP text width."""
	w = width * TEXT_WIDTH_IN
	return plt.subplots(figsize=(w, aspect * w))


def save(fig, name: str) -> None:
	"""Save to paper/figures/<name>.pdf."""
	FIGURES.mkdir(parents=True, exist_ok=True)
	fig.savefig(FIGURES / f"{name}.pdf")
	plt.close(fig)
