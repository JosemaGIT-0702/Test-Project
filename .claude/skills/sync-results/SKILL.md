---
name: sync-results
description: Regenerate all calculation outputs and the paper end-to-end, and check that the paper, results and scripts are consistent. Use after changing a calculation, before sending a draft, or when the user asks if everything is up to date.
---

# Regenerate and check consistency

1. Run every pipeline script in numeric order (`ls calc/*/scripts/[0-9]*` sorted by basename):
   - `.wl` -> Wolfram MCP `WolframLanguageEvaluator` with
     `Get["<absolute path>"]`; check it printed `OK`
     and no `CHECK FAILED` (in the MCP kernel a failed check aborts, returning `$Aborted`);
   - `.py` -> `uv run python <file>`;
   - other extensions -> as in `tools/run-calcs.sh`.
   Stop at the first failure and report it.
2. `make values`, `make test`, `make paper`.
3. Consistency checks, report each:
   - `git diff --stat results/ paper/generated/ paper/figures/` -- which outputs changed,
     and for changed numbers show old -> new values (`git diff results/*.json`);
   - every `\val<Key>` used in `paper/` exists in `values.tex`, and list keys that are
     defined but never used;
   - every `\input{generated/...}` and `\includegraphics{...}` target exists;
   - orphan files in `paper/generated/` or `paper/figures/` that no script produces anymore
     (hand-made artwork lives in `paper/images/` and is exempt);
   - no hand-typed numbers that look like computed results in `paper/sections/*.tex`
     (decimals with >= 3 significant digits not inside `\val`): list for review.
4. Summarise what changed physically (not just which files), and suggest a commit message.
