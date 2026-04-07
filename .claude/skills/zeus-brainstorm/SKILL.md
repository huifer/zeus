---
name: zeus-brainstorm
description: Brainstorm features or run full project planning through structured dialogue. Use --full for initial project-wide planning (includes north star metrics if not set), or --feature <name> for a single feature. Always asks one question at a time. Invokes zeus-plan automatically after spec is approved.
argument-hint: --full | --feature <name> [--version vN]
shell: bash
---

# Zeus Brainstorm - Design-First Planning Loop

Use this skill to transform broad requests into approved design specs before implementation.

## Guardrails

1. Never skip design, even for "small" features.
2. Ask exactly one clarifying question at a time.
3. Propose 2-3 options before selecting final architecture.
4. Require explicit user approval before planning artifacts are generated.

## Preconditions

- `.zeus/main/config.json` exists and is valid.
- Target version folder exists (`main` by default, optional `vN`).
- You can read prior artifacts (`prd`, `task`, `roadmap`, `specs`, `ai-logs`).

## Context intake

Read first:

- `.zeus/{version}/config.json`
- `.zeus/{version}/prd.json`
- `.zeus/{version}/task.json`
- `.zeus/{version}/roadmap.json`
- `.zeus/{version}/specs/*` (recent entries)
- `.zeus/{version}/existing-modules.json` (if present)
- `.zeus/{version}/architecture.md` (if present)

If config is missing, stop and instruct user to run `/zeus:init`.

## Deterministic workflow

### 1) Silent context exploration

Perform read-only exploration and summarize current baseline:

- existing stories/tasks that overlap this request,
- known constraints,
- existing architectural boundaries.
- existing modules that can be reused or extended.

### 2) Scope fit check

Classify request as:

- single feature,
- multi-feature bundle,
- multi-system program.

If too broad, decompose into independent design tracks and ask user which track to start with.

### 3) Clarifying question loop

Ask one question per turn. Focus on:

- success criteria,
- constraints,
- user roles,
- non-goals.

Prefer multiple-choice when practical.

### 4) Approach options (2-3)

Present options with trade-offs and recommendation tied to `north_star` impact.

For brownfield projects, each option must explicitly classify implementation strategy:

- Reuse existing module
- Extend existing module
- Rewrite with migration plan

### 5) Section-by-section design review

Present and confirm each section before moving on:

1. Architecture and boundaries
2. Components and interfaces
3. Data contracts
4. Error and fallback strategy
5. Validation and test strategy
6. Acceptance criteria

### 6) Write spec file

Write to:

`.zeus/{version}/specs/{YYYY-MM-DD}-{topic}-design.md`

Minimum structure:

```markdown
# {Feature} Design Spec
## Background and Goals
## Option Analysis
## Final Architecture
## Components and Interfaces
## Data Model and Contracts
## Error Handling
## Testing Plan
## Acceptance Criteria
```

### 7) Spec self-review

Run quick checks and fix inline:

1. Placeholder scan (`TODO`, `TBD`)
2. Internal consistency
3. Scope fit
4. Ambiguity resolution

### 8) User review gate

Ask user to review the saved spec path and wait for approval.

### 9) AI log write

Create `.zeus/{version}/ai-logs/{ISO-ts}-brainstorm.md`.

### 10) Hand-off to planning

After approval, trigger `/zeus:plan --spec <spec-file> --version <version>`.

## Output contract

- approved spec file,
- AI log entry,
- explicit hand-off command to planning.

## Failure handling

- no user response: send concise follow-up question;
- unresolved ambiguity: keep questioning loop active;
- conflicting constraints: surface explicit trade-off matrix.

## Agent collaboration

Use `zeus-researcher` for broad repository/context discovery before option design.
