---
name: zeus-status
description: Display a full status report of the Zeus project — all active versions, task progress, recent feedback attribution, evolution history, and next recommended action.
argument-hint: [--version vN] [--brief]
shell: bash
---

# Zeus Status - Global Health Report

Render a deterministic snapshot across active versions and recommend the next best action.

## Preconditions

- `.zeus/main/config.json` exists.
- All referenced version folders are readable.

## Deterministic workflow

### 1) Load project state

Read:

- `.zeus/main/config.json`
- each active version's `config.json`, `prd.json`, `task.json`, `feedback/*`, `evolution.md`
- recent AI logs (up to 5)

### 2) Compute report metrics

For each version compute:

- story totals and pass state,
- task totals and completion percentage,
- current/next pending wave,
- recent completed task titles.

For global scope compute:

- latest feedback attributions,
- latest evolution events,
- latest AI log highlights.

### 3) Select next-action recommendation

Decision table:

- missing config -> `/zeus:init`
- codebase map exists but config not imported -> `/zeus:init --import-existing`
- no tasks -> `/zeus:brainstorm --full`
- pending tasks -> `/zeus:execute`
- tasks complete but no feedback -> `/zeus:feedback`
- evolution signal unresolved -> `/zeus:evolve`
- stable -> `/zeus:brainstorm --feature <next-feature>`

Brownfield freshness recommendation:

- if `.zeus/{version}/codebase-map.json` is stale relative to recent repository changes, recommend `/zeus:discover --version {version}` before planning.

### 4) Render output

Render concise or full format depending on `--brief`.

### 5) Optional health index

If metric weights and enough feedback data exist, compute weighted health score trend.

## Output contract

- clear version-by-version progress,
- clear recommendation with rationale,
- no ambiguous next step.

## Agent collaboration

Use `zeus-docs` for consistency checks on report terminology and formatting quality.
