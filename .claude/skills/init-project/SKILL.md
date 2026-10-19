---
name: init-project
description: Turn a fresh copy of the HEP project template into a real project - set title, authors, conventions, remove the example paper, verify the build. Use right after creating a repo from the template.
disable-model-invocation: true
---

# Initialise a new project from the template

Interview the user briefly (one round of questions, using AskUserQuestion), then apply.

1. **Ask**: working title; authors + affiliations + emails; one-paragraph physics goal;
   conventions that differ from `notes/conventions.md` (signature, curvature sign,
   action normalisation / $\kappa$ vs. $G$, form and spinor conventions, units such as
   $\ell_s$, $\alpha'$, $L$); existing Mathematica packages of theirs to use in notebooks and
   scripts (paths); extra tools needed (xAct, FeynCalc, FORM, Julia, ...);
   whether to keep the example paper (arXiv:2605.16168) for reference.
2. **Paper**: set `\title`, `\author`, `\affiliation`, `\emailAdd`, `\abstract` and
   `\acknowledgments` in `paper/main.tex`; remove the "EXAMPLE paper" comment. In `paper/macros.tex`
   replace the example's `\newauthornote` lines by one per author (initials as the command name,
   if it is not an existing LaTeX command; distinct `xcolor` base colours: teal, orange, magenta,
   violet, olive, brown, cyan; never red, used by `\todo`).
3. **Example**: unless kept, remove it completely:
   - delete `calc/mathematica/scripts/01_wormhole_backgrounds.wl`,
     `calc/mathematica/scripts/02_ghost_fluctuations.wl`,
     `calc/python/scripts/03_ghost_spectrum.py`, `calc/python/scripts/04_mutual_information.py`,
     `calc/python/scripts/05_ghost_spectrum_ex2.py`;
   - delete every file in `results/` and `results/analytic/`, every `paper/generated/eq_*.tex`,
     `paper/figures/mutual_information.pdf`, `paper/images/tachyoncondensation.png`
     (keep the `.gitkeep` files, so the emptied folders stay in git);
   - delete all of `paper/sections/*.tex` and create `introduction.tex`, `setup.tex`,
     `results.tex`, `conclusions.tex` and `appendix.tex`, each with only its `\section{}` +
     `\label{}` and one `\todo{}` derived from the physics goal; update the `\input`s in
     `main.tex` to match;
   - reset `paper/references.bib` to its 3-line header comment;
   - keep the preamble of `main.tex` (packages, `\crefalias`) as is; in `paper/macros.tex` keep every
     generic block (abbreviations, general, quantum mechanics / field theory, editing) and delete only
     the lines marked "example paper";
   - in `README.md`, replace the paragraph about the example and its table of scripts (search for
     "2605.16168", up to "`/init-project` removes the example.") by one sentence saying that the
     calculations are listed in run order in `calc/*/scripts/` and logged in `notes/log.md`;
   - in `CLAUDE.md`, delete the "## The example" section;
   - reset `notes/log.md` to its header (everything above the first `## ` entry); step 8 writes the
     project's first entry;
   - run `make values`: `values.tex` must then contain only its header comment.
4. **Conventions**: rewrite `notes/conventions.md` with the project's conventions (keep its
   headings; drop the sentence about the example paper's entries), and propagate to
   `calc/mathematica/Project.wl` (header comment), `calc/mathematica/packages/README.md` (how each package's conventions map to the project's: never edit the packages themselves; if the
   signature or curvature sign differs from `supergrav.wl`'s, state the conversion there and in
   `.claude/rules/mathematica.md`), `calc/python/hepcalc/constants.py`
   and `paper/macros.tex`. Put a short conventions paragraph in `sections/appendix.tex`.
5. **Extra tools**: follow `calc/other/README.md` for each (directory, runner entry in
   `tools/run-calcs.sh`, a rule file in `.claude/rules/`). For Mathematica packages:
   the user's own single-file packages are copied unchanged into `calc/mathematica/packages/`, added
   to the table in its README (loaded with `LoadPackage["name"]`), and their conventions checked
   numerically against `notes/conventions.md` via the Wolfram MCP (record the result in the README);
   installed packages (xAct, FeynCalc, ...) are loaded with `Needs[...]` after `ScriptBegin` in the
   scripts that use them (note this in `.claude/rules/mathematica.md`) and checked to load via the
   Wolfram MCP. Do not put physics in `Project.wl`.
6. **Python and tooling**: rename the project in `pyproject.toml` (`name`, keep package `hepcalc`),
   then run `make setup`: `uv sync` (this updates `uv.lock`, which is committed), registers the
   `nbstrip` git filter for notebooks, and warns if `latexmk` or `wolframscript` is missing (report
   any warning to the user).
7. **Verify**: `make calc-py`, `make test` and `make paper` all succeed (with no
   calculations yet, `make calc-py` just prints a note). Unless the example was kept,
   `git grep -lI --untracked -E "2605\.16168|wormhole|ghost|warp_ex|valMI|valMSq" -- paper calc notes CLAUDE.md README.md`
   must find nothing (`git grep` skips ignored build files such as `main.aux`); every hit is a
   leftover of the example: fix it. Report what changed.
8. Write the project's first entry in `notes/log.md` (date, goal, conventions, next steps). In
   `README.md`: replace the title and first paragraph with the project's; in "Quick start", replace
   the "Use this template" instructions (and the `gh repo create --template` note) by what a
   coauthor does: clone this repository, `make setup`, `make all`, `claude`; keep the
   requirements and the Wolfram MCP setup. Check `git log` (the user may already have committed),
   then offer to make the initial commit.
