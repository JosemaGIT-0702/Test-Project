.DEFAULT_GOAL := help
PAPER := paper/main

.PHONY: help setup calc calc-py values paper watch test lint format all clean distclean arxiv

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n",$$1,$$2}'

setup: ## Create the Python env (uv), register the notebook git filter, check tools
	uv sync
	git config filter.nbstrip.clean 'uv run --no-project --quiet python -I tools/nbstrip.py'
	git config filter.nbstrip.required true
	@command -v latexmk >/dev/null || echo "WARNING: latexmk not found"
	@command -v wolframscript >/dev/null || echo "WARNING: wolframscript not found (Mathematica scripts will not run headless)"

calc: ## Run all numbered calculations in calc/*/scripts (ONLY=03 to filter)
	tools/run-calcs.sh $(ONLY)

calc-py: ## Run only the Python calculations
	LANGS=py tools/run-calcs.sh $(ONLY)

values: ## Rebuild paper/generated/values.tex from results/*.json
	uv run python -m hepcalc.results

paper: values ## Build paper/main.pdf
	cd paper && latexmk main.tex

watch: ## Rebuild the paper continuously
	cd paper && latexmk -pvc main.tex

test: ## Run Python tests
	uv run pytest -q

lint: ## Lint Python, check its formatting, and check LaTeX with chktex (if installed)
	uv run ruff check calc/python tools
	uv run ruff format --check calc/python tools
	@command -v chktex >/dev/null && cd paper && chktex -q -n8 -n24 main.tex sections/*.tex || true

format: ## Auto-format Python (ruff format: tabs, quotes, line breaks)
	uv run ruff format calc/python tools

all: calc paper ## Full pipeline: calculations -> values -> paper

arxiv: paper ## Make a flat arXiv tarball in build/arxiv.tar.gz
	tools/make-arxiv.sh

clean: ## Remove LaTeX build files
	cd paper && latexmk -c

distclean: clean ## Also remove the PDF and build/
	cd paper && latexmk -C
	rm -rf build
