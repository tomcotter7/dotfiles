---
name: designing-tufte-graphics
description: Use when the user asks for help with a graph, chart, plot, figure, dashboard, or data visualization, or with the design/redesign/critique of one (for a deck, paper, notebook, or report). Covers matplotlib/seaborn/plotly choices, chart type selection, axes, gridlines, colour, labels, legends, and styling.
---

# Designing Tufte Graphics

## Overview

When helping with any graph, design one **Edward Tufte** would approve of, and say which of his principles you are applying. Tufte's thesis: *a graphic is an instrument for reasoning about quantitative data*, not decoration. **"Above all else show the data."**

Always name the principle you're invoking (e.g. "maximising the data-ink ratio", "this would be a Tufte *duck*") so the reasoning is visible, not just the result.

## The principles to apply

1. **Show the data; maximise data density.** Present many numbers in a small space, make large sets coherent, reveal data at several levels of detail (overview → fine structure).
2. **Maximise the data-ink ratio.** Most ink should carry data. Erase non-data ink (heavy frames, dense gridlines, tick clutter, backgrounds) and erase *redundant* data-ink (don't encode the same number as line + marker + fill + label all at once).
3. **No chartjunk.** Remove decoration that carries no data: gradient/area fills under lines, 3D effects, moiré/vibrating patterns, heavy grids, and *ducks* (graphics that are mostly ornament).
4. **Graphical integrity / tell the truth.** The visual representation must be proportional to the numbers (low *lie factor*). Integrity comes from *proportional encoding and clear labelling*, **not** from a forced zero origin. Don't distort, don't cherry-pick scales to exaggerate.
5. **Nearly always multivariate; encourage comparison.** The best graphics show relationships, comparisons, context (prior period, benchmark, small multiples). A lone series bouncing over time is usually the weakest design — ask what variable would make it a comparison.
6. **Multifunctioning elements & layering.** Make elements do double duty (a range-frame axis that also shows min/max/quartiles; direct labels instead of a legend). Layer with subtle visual hierarchy.
7. **Integrate words, numbers, and the graphic.** Descriptive title that states the finding; label things in place.

Touchstone examples from the book: **Minard's Napoleon's-march** map (6 variables, "may well be the best statistical graphic ever drawn"), **Anscombe's quartet** (why you must *plot*, not just compute), the **cancer-mortality maps**, **Playfair**, **Marey's train schedule**.

## Tufte's exact vocabulary (use these terms by name)

- **Lie Factor** = (size of effect shown in graphic) ÷ (size of effect in the data). Should be between **0.95 and 1.05**; outside that is distortion. The visual must be proportional to the numbers.
- **Show data variation, not design variation.** Don't let scales, 3D, or perspective create change the data doesn't have. For money over time, use **deflated/standardised units**. The number of information-carrying dimensions must not exceed the number of dimensions in the data (no gratuitous 3D/area).
- **Data-ink ratio** = data-ink ÷ total ink = proportion of ink showing non-redundant data = **1.0 − the share you could erase** without losing information.
- **The five principles (Ch4, verbatim):** *Above all else show the data. Maximize the data-ink ratio. Erase non-data-ink. Erase redundant data-ink. Revise and edit.*
- **Three species of chartjunk (Ch5):** (1) **moiré / vibration** — hatching, dense patterns, busy fills that shimmer; (2) **the grid** — the "data prison"; mute it, push it behind the data, or use a *white grid*; (3) **the duck** — a graphic so encrusted with decoration that ornament overwhelms data.
- **Range-frame** — draw each axis spine only across the data's min–max (and you can notch it at the quartiles/median). The frame becomes a data element; "nearly always better than the conventionally framed scatterplot." Related: erased **box/quartile plots**, **dot-dash** marginal plots.
- **Data density** = data entries ÷ graphic area. Maximise within reason. **Shrink principle:** most graphics can be shrunk much smaller and still read.
- **Small multiples** — repeated small frames of the same design, varying one variable across them. "At the heart of all great statistical graphics"; the best way to show change/comparison.
- **Friendly graphics (Ch9):** words spelled out (no cryptic codes), running left-to-right, upper-and-lowercase; colours legible to colour-blind readers; elements that **multifunction** (one mark, several jobs).
- **Proportion / aspect ratio:** if the data suggest a shape, follow it; otherwise make the graphic **~50% wider than tall** (near the Golden Rectangle). Put the **causal/explanatory variable on the horizontal**.

## Workflow

1. State the **question** the graphic answers and the **comparison** it should enable.
2. Pick the form that shows the data most directly (time-series, scatter/relational, small multiples, dot plot, slopegraph). Scatterplots and small multiples are Tufte favourites; pie charts and stacked bars rarely are.
3. Draft, then **subtract**: remove every mark that isn't data until removing more would lose information.
4. Add comparison/context to make it multivariate where honest.
5. Label directly; write a finding-oriented title.
6. Name the Tufte principles behind each choice.

## One worked example (matplotlib)

A Tufte-minimal time-series. Note what is *absent* as much as what is present.

```python
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
this_year = [1.45,1.52,1.60,1.68,1.55,1.30,1.12,1.18,1.40,1.62,1.74,1.80]
last_year = [1.20,1.25,1.31,1.36,1.30,1.18,1.05,1.10,1.22,1.34,1.40,1.46]  # multivariate: a comparison

fig, ax = plt.subplots(figsize=(9, 5))

# Two thin lines, no markers/fill: line alone encodes the value (no redundant data-ink, no chartjunk fill)
ax.plot(months, this_year, color="#111111", linewidth=1.6)
ax.plot(months, last_year, color="#999999", linewidth=1.2)

# Direct labels at the line ends, NOT a legend (multifunctioning, integrates words+graphic)
ax.text(11.1, this_year[-1], "2023", color="#111111", va="center", fontsize=10)
ax.text(11.1, last_year[-1], "2022", color="#999999", va="center", fontsize=10)

# Erase non-data ink: drop top/right/left spines, vertical grid, tick marks
for s in ["top","right","left"]:
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_color("#BBBBBB")
ax.tick_params(length=0)
ax.set_xlim(-0.3, 12.5)

# Range that REVEALS the variation — do NOT force a zero baseline on a line chart.
# Integrity is preserved by clear scale + honest proportional encoding.
ax.set_ylim(1.0, 1.9)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v,_: f"{v:.1f}M"))
ax.set_yticks([1.0,1.2,1.4,1.6,1.8])
ax.grid(axis="y", color="#EEEEEE", linewidth=0.8)  # faint, behind data
ax.set_axisbelow(True)

ax.set_title("Active sellers fell over summer but ended above 2022",
             loc="left", fontsize=14, fontweight="bold", pad=16)
fig.tight_layout()
```

## Common Mistakes (and the Tufte fix)

| Mistake | Why it's not Tufte | Fix |
|---|---|---|
| Gradient/area fill under a line | Decorative ink carrying no data — a *duck* / chartjunk | Remove the fill; the line alone shows the value |
| Line + marker + area + value-label on every point | Redundant data-ink; same number encoded 4× | Keep one encoding; label only the key points |
| "Force the y-axis to zero for honesty" on a line chart | Confuses bar-chart convention with integrity; hides the variation | Use the range that reveals structure; integrity = proportional encoding + clear labels |
| Single series bouncing over time | Misses "nearly always multivariate" | Add prior period, benchmark, or small multiples |
| Heavy gridlines, full box frame, 3D, drop shadows | Low data-ink ratio; chartjunk | Erase non-data ink; faint grid at most |
| Legend off to the side | Forces eye round-trips | Direct-label series in place |
| Pie / stacked bar for comparisons | Poor for accurate comparison | Dot plot, bar, slopegraph, or small multiples |
| Generic title ("MAS 2023") | Misses words+graphic integration | Title states the finding |
| 3D bars/pie, perspective, shadows | *Design variation*, not data variation; inflates the Lie Factor; extra dimensions the data don't have | Flat 2D; one info-carrying dimension per data dimension |
| Full box frame around the plot | Non-data ink; the "data prison" | **Range-frame**: spines only across the data min–max |
| Cryptic codes, ALL-CAPS, sideways labels | Unfriendly graphic | Spell words out, upper/lowercase, read left-to-right |
| Tall, narrow chart by default | Ignores proportion guidance | Follow the data's shape, else ~50% wider than tall |

## Red flags — stop and reconsider

- You added something to make it "pop" → probably chartjunk.
- You can't say which Tufte principle a mark serves → it's probably non-data ink.
- The chart shows one variable with no comparison → push for multivariate.
- You're about to force a zero baseline on a line "to be honest" → wrong tool for integrity.
