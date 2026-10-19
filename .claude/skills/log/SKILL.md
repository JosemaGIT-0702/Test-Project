---
name: log
description: Append a dated entry to the research log notes/log.md summarising the session - what was done, results, open questions, next steps. Use at the end of a work session or when the user says log/record progress.
argument-hint: "[extra notes]"
---

# Update the research log

Extra notes from the user: `$ARGUMENTS`

1. Gather what happened this session: conversation context, `git status`,
   `git diff --stat`, `git log --oneline -10`, changed values in `results/*.json`.
2. Add an entry at the **top** of `notes/log.md` (below the header) under today's date
   (`date +%F`); merge into an existing entry for today if there is one:
   - **Done** -- concrete actions (files/scripts, not vague verbs);
   - **Results** -- numbers/expressions obtained, with the script that produced them, and
     whether they are verified;
   - **Problems / open questions**;
   - **Next** -- the next 1-3 concrete steps.
3. Keep it terse and factual; no claims that weren't actually checked.
