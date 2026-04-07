---
name: zeus-feedback
description: Record user feedback (natural language or structured data), perform AI attribution analysis linking results to past tasks, update evolution.md, and ask the user whether to start a new version. This is the core feedback loop skill.
argument-hint: [--version vN]
shell: bash
---

# Zeus Feedback - Attribution and Evolution Trigger

Use this skill to convert real-world feedback into traceable product decisions.

## Core rule

Never recommend roadmap actions before attribution analysis is complete.

## Preconditions

- `.zeus/{version}/task.json` exists.
- `.zeus/{version}/feedback/` is writable.
- `.zeus/{version}/evolution.md` is writable.

## Deterministic workflow

### 1) Capture raw feedback

Accept natural language, structured metrics, or mixed input.

### 2) Fill missing context

If essential details are missing, ask one question at a time:

- time window,
- observed metric deltas,
- user segment affected.

### 3) Optional metrics enrichment

If `.zeus/scripts/collect-metrics.sh` exists, ask for permission and run:

```bash
bash .zeus/scripts/collect-metrics.sh
```

Merge output into feedback evidence.

### 4) Run attribution analysis

Read:

- completed tasks in `.zeus/{version}/task.json`
- recent `.zeus/{version}/ai-logs/*`
- previous feedback history
- recent git commits (`git log --oneline -20`)

Compute candidate task attribution with confidence score:

- high >= 0.80
- medium 0.50-0.79
- low < 0.50

### 5) Evaluate evolution signal

Set `requires_new_version` true when:

- gap is structural (not a normal iteration),
- repeated unmet need appears across feedback cycles,
- target segment diverges from current version strategy.

### 6) Write feedback artifact

Create `.zeus/{version}/feedback/{YYYY-MM-DD-HHmmss}.json` including:

- raw data,
- attribution list,
- evolution signal,
- roadmap absorption flag.

### 7) Append evolution timeline

Append a `FEEDBACK` record in `.zeus/{version}/evolution.md`.

### 8) Write AI log

Create `.zeus/{version}/ai-logs/{ISO-ts}-feedback.md`.

### 9) Ask for decision

If evolution signal is true, offer:

- A) start `/zeus:evolve`
- B) backlog in current roadmap
- C) ignore suggestion

### 10) Apply selected action

- A: invoke evolve with gap context
- B: append roadmap backlog item
- C: record-only outcome

## Output contract

- one feedback JSON artifact,
- one evolution entry,
- one AI log,
- one explicit next-step decision.

## Agent collaboration

Use `zeus-analyst` for attribution scoring and version-evolution recommendation quality.
