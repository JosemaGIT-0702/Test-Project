---
paths:
  - "paper/**/*.tex"
  - "paper/**/*.bib"
---

# LaTeX rules (JHEP)

- One sentence per line in `.tex` files (clean git diffs).
- Default preamble (keep it): `xcolor`, `cite`, `fontenc` [T1], `babel`, `amsmath`/`mathtools`, `xspace`,
  `mathrsfs` (INSPIRE titles), `jheppub`, then `cleveref` [capitalise] last. Add other packages
  only when the text needs them, with a comment saying why.
- Notation only via `macros.tex`; add a macro rather than repeating raw markup.
- Abbreviations are `xspace` macros in `macros.tex`: `\eg`, `\ie`, `\cf`, `\etc`, `\etal`, `\wrt`
  (write `\eg the`, never `e.g.\ the`). Add one when an abbreviation recurs. Never use
  `\xspace` in a macro meant for math mode (it breaks subscripts, e.g. `\text{AdS}_{4+1}`).
- Numbers from calculations: `\val<Key>` only. Never type a computed number.
- Generated equations: `\input{generated/eq_<name>}` inside the math environment.
- Cross-references with `\cref{}` (`\cref{sec:x}` -> "Section 2", `\cref{eq:x}` -> "Eq. (2.1)",
  `\cref{eq:a,eq:b}` -> "Eqs. (2.1) and (2.2)", "Fig. 1", "Table 1", "Appendix A"); `\eqref`/`\ref`
  are fine too. Keep `\crefalias{section}{appendix}` after `\appendix` in `main.tex` (jheppub needs it). Labels prefixed `sec:`, `eq:`, `fig:`, `tab:`, `app:`.
- Every displayed equation that is referenced gets a `\label`; end displayed equations
  with punctuation (`\,.` / `\,,`) as part of the sentence.
- Citations: INSPIRE texkeys only (`Author:YYYYxx`). Never invent a key; use `/add-reference`.
- Notes are fine in drafts: `\todo{}`, one command per collaborator (`\JM{}`, ... declared with
  `\newauthornote{initials}{colour}` in `macros.tex`; add one for any new commenter). Sign your own notes with
  the user's initials; never delete another author's note unless asked. `\notesfalse` in `main.tex` hides all of them; `/build-paper` lists them.
- Do not edit `jheppub.sty`, `JHEP.bst`, or anything in `paper/generated/`.
- After edits, build with `make paper` and fix new warnings (undefined refs/citations,
  overfull boxes > 5pt).
- HEP style: italic for variables, roman for labels and operators (`\text{AdS}_{d+1}`, `\dd`, `\Tr`).
- Load `cite` and `babel` before `jheppub` (which loads hyperref), or `\cite` breaks on the first pass.
- Never edit INSPIRE BibTeX to make it compile: if a title uses a macro (e.g. `\mathscr`), load
  the package that provides it (`mathrsfs`) in `main.tex`, with a comment saying why.
