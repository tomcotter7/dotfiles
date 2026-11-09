---
name: brag-document
description: Analyze plan files for a given month/quarter and suggest brag document entries by cross-referencing Jira and GitHub for completion status.
---

# Brag Document Suggestions

Generate brag document suggestions from the user's plan files for a given time period.

## Input

The user provides either:
- A **month** (e.g. "May 2026", "2026-05")
- A **quarter** (e.g. "Q2 2026")

Map quarters to standard calendar months: Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec.

## Steps

1. **Read plan files** from `~/.termflow/plans/` for the requested date range. Files are named `YYYY-MM-DDdepop.plan`. Each file contains tasks separated by `---` with fields: Task ID, Title, Full Description, Created on.

2. **Identify candidates** — look for tasks that suggest:
   - Completed projects (checkboxes marked `[X]` or `[x]`, language indicating completion)
   - Hack week work
   - Proposals or documents produced
   - PRs or work outside typical ML scope (e.g. Scala, infrastructure, cross-functional)
   - Cost savings or efficiency improvements
   - Leadership or mentoring activities

3. **Cross-reference for completion status** — use Jira (`searchJiraIssuesUsingJql`), Confluence (`searchConfluenceUsingCql`, `getConfluencePage`), and GitHub (`gh` CLI) to determine whether candidate items are truly completed or just sub-tasks of larger in-progress work. Confluence is useful for finding proposal docs, experiment write-ups, and architectural decisions the user authored. Only suggest items that are done or nearly done.

4. **Read existing brag doc** at `~/.termflow/brag<year>.md` to avoid suggesting things already documented.

5. **Output suggestions** — present as a list of suggestions, each with:
   - A short title
   - Why it's brag-worthy (impact, scope, novelty)
   - Key evidence/links found (Jira tickets, PRs, metrics)
   - What's missing that the user might want to add (experiment results, impact numbers)

## Output Format

Present suggestions conversationally, not as pre-written brag entries. The user writes their own entries. Group by theme if multiple suggestions exist (e.g. "Infrastructure & Cost", "New Models", "Cross-functional").

## Notes

- The user works on ML at Depop.
- Proposals, documents, and architectural decisions are brag-worthy even if the implementation is ongoing.
- Hack week projects are always worth suggesting.
- Cost savings should include dollar amounts when available.
- Cross-functional work (e.g. writing Scala PRs for BE, leading projects across teams) is notable.
