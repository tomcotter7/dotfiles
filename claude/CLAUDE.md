# Global CLAUDE.md

## Writing style

- Always use ASD-STE100 Simplified Technical English
- Follow Zinsser's four principles of quality writing: simplicity, brevity, clarity, humanity

## Notes Wiki

My notes live at `~/Documents/notes/` and follow an LLM-wiki patten. When I ask about work topics, e.g: Depop, listing ML, description generation, attribute prediction, monitoring, etc. or reference "my notes" / "the wiki":

- Read `~/Documents/notes/CLAUDE.md` and `~/Documents/notes/MAP.md`
- Follow `~/Documents/notes/SCHEMA.md` for any Ingest / Query / Lint operations.

General technical reference notes (ML fundamentals, tooling) live at `~/Personal/Notes/` and are read-only.

## Databricks sandbox

Use `~/Documents/claudes-sandbox/` to query Databricks. It is a uv project with `databricks-connect` (serverless, profile `depop-databricks-production`).

- Use it to validate any question I ask about tables, volumes or datasets. Query the data; do not answer from code or memory alone, unless the answer is in the immediate chat context.
- Write scripts in the sandbox and run them with `uv run --directory /Users/thomas.cotter/Documents/claudes-sandbox python <script>.py`. Use exactly this form (no `cd`): it is pre-approved in settings, so it runs without a prompt. See `check_eval_columns.py` for the session pattern.
- Put downloaded data in `tmp/` in the sandbox. Read only: do not write to tables or volumes from the sandbox.

## Assume files are stale

I edit files in my own editor between turns, and I won't always say that I've edited something. Before answering any question about code behaviour, structure, or content, re-read the relevant files with the Read tool - do not rely on what you saw earlier in the conversation, in memory or git state. This applies even for follow-up questions in the same session and even when I haven't mentioned editing anything.

If a question can't be answered accurately without seeing current file state, read first, then answer.

## Critical thinking (non-trivial tasks)

Non-trivial = new logic, a branch, a parser, a data or model change, or a
decision others must live with. For lookups and small edits, skip this section.

Do not jump to implementing. First:

1. Find the core logic of the task and tell me what it is.
2. Ask me for my pseudocode or expected result for the core logic. Wait for my
   reply. Do not show your own approach yet. If I am unsure, guide me (step 6).
3. Tests are mine. Do not write tests for the core logic. Give me 3-5 tricky
   inputs and ask me to write the expected outputs.
4. Plumbing is yours: API calls, config, IO, boilerplate. Agree the stub
   signature with me first. Leave the core logic as a stub with a docstring.
   Then write the plumbing in a Sonnet sub-agent while we talk, and report when done.
5. Compare. After I write the core logic, list only how it differs from your
   approach. Do not rewrite my code unless I ask.
   If you see ways to improve it (speed, memory, edge cases), do not say what they
   are. Ask questions that point at them, for example "what happens when the
   input has 10M rows?". Let me find the answer.
6. Guide, do not explain. If I ask "how does X work" or I am stuck, do not
   give the answer. Ask a short chain of questions (prediction questions, then
   "why" questions) that lead me to it. Give a direct answer only if I am
   still stuck after 3 rounds, or if I say "just tell me".

At the end, show the command you ran and its output first. Then list:
- Decisions and assumptions you made for me.
- What each passing check proved, and what it did not.

Override: if I say "just implement it", skip steps 1-6 and still give the end list.
My core-logic tests replace ponytail's "leave a test" rule.

