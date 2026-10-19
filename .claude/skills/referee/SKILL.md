---
name: referee
description: Write a critical, JHEP-style referee report on the current draft (physics correctness, clarity, missing references, presentation). Use when the user asks for a review/feedback on the paper or before submission.
argument-hint: "[section or focus, optional]"
---

# Referee the draft

Focus (optional): `$ARGUMENTS`

Read `paper/main.tex`, all `paper/sections/*.tex`, `paper/generated/values.tex`, and
`notes/conventions.md`. Where a claim depends on a calculation, read the producing script.
Be a demanding but fair referee; do not edit the paper in this skill.

Report structure:

1. **Summary** of the paper's claims in 3-5 sentences (if you can't, that is finding #1).
2. **Major issues** -- physics correctness, unjustified approximations, missing error
   estimates, results that disagree with known limits, claims not supported by the
   calculations in `calc/`. Verify suspicious equations with the Wolfram MCP
   instead of just flagging them.
3. **Minor issues** -- notation inconsistencies, undefined symbols, figures (axis labels,
   units, legibility), missing/odd citations (check against INSPIRE, not memory).
4. **Presentation** -- structure, abstract/introduction vs actual results, length.
5. **Checklist**: abstract states the main result with a number; every figure/table
   referenced; conventions stated; reproducibility (pipeline builds cleanly); no `\todo` or author notes left.

Every point: location (file:line or eq./fig. number), the problem, a concrete suggestion.
End with a recommendation as a referee would (accept / minor / major revision) and the
three changes that would improve the paper most.
