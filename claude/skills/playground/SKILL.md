---
name: playground
description: >
  Turn a complex piece of pandas, Spark, numpy or torch code into a runnable sandbox file with
  small dummy data, so the user can run each step and change it to learn what it does. Use when the
  user says "playground", "let me play with this", "help me understand this transform", or pastes
  or points at dense dataframe or tensor code.
---

Goal: the user learns the code by running it and changing it. Do not explain the code.

## Input

A pasted snippet, or a file path with a line range. If the range is unclear, ask once.

## Steps

1. **Read the code.** If given a path, read the file now. Do not use earlier copies.
2. **Split it into steps.** One named variable per step (`df1`, `df2`, ...). Keep the original
   operations. Do not simplify or "fix" them.
3. **Infer the inputs.** List the columns, dtypes, join keys, group keys and tensor shapes the
   code needs.
4. **Build dummy data.** About 10 rows, or small tensors. Hard-code it in the file. Include rows that hit the edge cases:
   - nulls and NaN
   - duplicate keys
   - ties (for sort, rank, top-k)
   - a group with one row, and a group that is empty after a filter
   - a join key that exists on one side only
   - for torch: a batch of 1, and a dimension of size 1
   Mark each edge-case row with a comment that says which case it is.
5. **Write the file** to `/Users/thomas.cotter/Documents/claudes-sandbox/playground/<short_name>.py`
   in `# %%` cell format. One cell per step. After each step, print the result:
   - pandas: `.head(20)` and `.shape`
   - Spark: `.show(truncate=False)` and `.count()`
   - numpy and torch: the value, `.shape` and `.dtype`
6. **Put questions at the top** as a comment block: 3-5 prediction questions about the data, for
   example "How many rows after the join? Which rows disappear?". Do not give the answers.
7. **Add a `# try:` cell at the end** that is empty, for the user's own changes.
8. **Run it once** to check that it works:
   `uv run --directory /Users/thomas.cotter/Documents/claudes-sandbox python playground/<short_name>.py`
   If it fails, fix the file. Do not show the output as an explanation.
9. **Tell the user the path and how to run it.** Then stop. Do not explain the code.
   If the user asks what a step does, follow the Critical thinking rules in `CLAUDE.md`
   (ask guiding questions first).

## Rules

- **Spark:** use `DatabricksSession` from `databricks-connect` (profile `depop-databricks-production`,
  serverless). Build data with `spark.createDataFrame(...)`. The sandbox has no standalone `pyspark`,
  and it cannot be installed with `databricks-connect`.
- **Read only.** Never write to tables or volumes. Never read real tables unless the user asks.
  Real tables can hold customer PII, so use dummy data by default.
- **Python deps:** use what the sandbox already has. If `pandas` or `numpy` do not import, tell the
  user. Do not add dependencies without asking.
- **UDFs and Delta:** if the code uses a UDF, a Delta feature or a window with an unusual frame, say so
  in one line at the end. Dummy data may not show the same behaviour as production.
- **Limit:** dummy data can miss the case the user cares about. Say this in one line at the end,
  and say which edge cases the data covers.
