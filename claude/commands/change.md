Review the most recent file change shown in the system reminders (the diff between the previous assistant message and the user's current message — NOT a git diff).

If multiple files changed, review each.

Focus on:
- Bugs introduced (typos, wrong config keys, off-by-one, swapped args)
- Naming consistency (variable name vs what the value actually represents)
- API mismatches (param renames not propagated to callers, signature changes not reflected at call sites)
- Anything that needs a follow-up edit elsewhere in the file (re-read the file if the diff is truncated)

Output format: short bullet list, with `file:line` refs. Lead with bugs, then naming/clarity, then follow-ups. Skip categories with nothing to report.

If no recent file change is visible in system reminders, say so and stop.
