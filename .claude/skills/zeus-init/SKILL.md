---
name: zeus-init
description: Initialize a new Zeus project. Creates .zeus/main/ directory structure, sets up config.json with north star metrics, and writes the first evolution.md entry. Use this FIRST before any other zeus skill.
argument-hint: [project-context]
shell: bash
---

# Zeus Init - Bootstrap Contract

Use this skill as the mandatory first step before any other `/zeus:*` workflow.

## Non-negotiable rules

1. Ask one question per message and wait for the user's response.
2. Never create planning artifacts before config baseline is valid.
3. Always append an AI log after write operations.
4. If initialization already exists, require explicit user confirmation before overwrite.

## Preconditions

- Workspace contains `.zeus/` scaffold and schema files.
- You can write under `.zeus/main/`.
- Git repository is available (or can be initialized).

## Required context files

- `.zeus/schemas/config.schema.json`
- `.zeus/main/config.json` (if already present)
- `.zeus/main/evolution.md` (if already present)

## Deterministic workflow

### 1) Initialization state check

Inspect whether `.zeus/main/config.json` exists and has a non-empty `project.name`.

- If initialized: explain current state and ask whether to re-initialize.
- If user declines: stop and suggest `/zeus:status`.
- If not initialized: continue.

### 2) Collect baseline inputs (single question loop)

Collect, in this exact order:

1. Project name
2. Primary domain (optional)
3. Technology stack
4. Version intent (single version or future `v2/v3` tracks)

### 3) North star metric proposal

Propose one recommended metric bundle with rationale and editable weights.

Output template:

```text
Recommended metric strategy:

North star: {metric_name}
Weights:
- {metric_a}: {weight} ({reason})
- {metric_b}: {weight} ({reason})

Choose one:
A) Accept
B) Adjust weights
C) Fully customize
```

### 4) Write `.zeus/main/config.json`

Write schema-compatible configuration with:

- `project` metadata
- `metrics` north star and weights
- `git` commit format policy
- `versions` active set and folder mapping

If user declares future versions, register them in `versions` only. Do not create folders here.

### 5) Append evolution init record

Append a new `INIT` entry to `.zeus/main/evolution.md` describing:

- date
- project
- north star + weights
- stack snapshot

### 6) Commit baseline

```bash
git add .zeus/
git commit -m "chore(zeus): initialize zeus project structure"
```

If git is not initialized:

```bash
git init
git add .zeus/
git commit -m "chore(zeus): initialize zeus project structure"
```

### 7) Write AI log (mandatory)

Create `.zeus/main/ai-logs/{ISO-ts}-init.md` using this contract:

```markdown
## Decision Rationale
## Execution Summary
## Target Impact
```

### 8) Completion message

Report created artifacts and recommend next commands:

- `/zeus:brainstorm --full`
- `/zeus:brainstorm --feature <name>`
- `/zeus:status`

## Failure handling

- Schema validation failure: stop writes, fix payload, validate again.
- Missing `.zeus/schemas`: abort and explain missing prerequisites.
- Permission denied: report exact file path and required fix.

## Agent collaboration

Delegate read-only discovery tasks to `zeus-researcher` when repository state is unclear.
