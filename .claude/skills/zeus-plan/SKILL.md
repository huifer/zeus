---
name: zeus-plan
description: Convert a spec document into structured prd.json user stories and task.json execution units. Called automatically by zeus-brainstorm, but can also be invoked directly. Supports --version flag to target v2/v3/v4 folders.
argument-hint: [--spec <file>] [--version vN]
shell: bash
---

# Zeus Plan - Spec to Executable Artifacts

Convert an approved spec into version-scoped stories and tasks with deterministic IDs and dependency waves.

## Preconditions

- Target spec exists and is approved.
- `.zeus/{version}/config.json` exists.
- `.zeus/{version}/prd.json`, `task.json`, and `roadmap.json` are writable.

## Inputs

- `--spec <filename>` (optional, default latest spec)
- `--version vN` (optional, default `main`)

## Deterministic workflow

### 1) Load context and reserve IDs

Read:

- selected spec
- version config
- existing `prd.json`
- existing `task.json`

Reserve next IDs:

- `US-{NNN}` from `prd.json`
- `T-{NNN}` from `task.json`
- `M-{NNN}` from `roadmap.json` milestones

### 2) Create user stories

Extract from acceptance criteria and role/goal language in spec.

Required story shape:

```json
{
  "id": "US-001",
  "title": "One-line story title",
  "description": "As a <role>, I need <capability> so that <outcome>",
  "acceptance_criteria": ["Given/When/Then style criterion"],
  "priority": "high",
  "version_scope": "main",
  "passes": false,
  "created_from_spec": "2026-04-07-auth-design.md",
  "created_at": "2026-04-07T00:00:00.000Z"
}
```

Priority policy:

- high: direct north star impact
- medium: critical support path
- low: optimization or edge behavior

### 3) Create executable tasks

Generate small, independently executable units.

Task types:

- `infra`
- `api`
- `frontend`
- `docs`

Task schema:

```json
{
  "id": "T-001",
  "story_id": "US-001",
  "type": "api",
  "title": "Implement POST /api/auth/login",
  "description": "Include validation, error mapping, and audit logging.",
  "files": ["src/app/api/auth/login/route.ts"],
  "depends_on": [],
  "passes": false,
  "commit_sha": null,
  "ai_log_ref": null,
  "wave": null,
  "created_at": "2026-04-07T00:00:00.000Z"
}
```

### 4) Compute wave plan

Build dependency DAG from `depends_on` and assign wave numbers:

- wave 1: no dependencies
- wave N: depends only on lower waves

Reject cyclic dependencies and force correction before write.

### 5) Update roadmap milestone

Add or update milestone with:

- title from spec
- `spec_ref`
- generated story/task ID lists
- `status: planned`

### 6) Persist artifacts

Write updated:

- `.zeus/{version}/prd.json`
- `.zeus/{version}/task.json`
- `.zeus/{version}/roadmap.json`

### 7) Commit planning artifacts

```bash
git add .zeus/{version}/prd.json .zeus/{version}/task.json .zeus/{version}/roadmap.json
git commit -m "docs(zeus): update prd and task from {spec-name}"
```

### 8) Write AI log

Create `.zeus/{version}/ai-logs/{ISO-ts}-plan.md` with the 3-section contract.

### 9) Report summary

Return:

- story count,
- task count,
- wave distribution,
- recommended next step: `/zeus:execute`.

### 10) Offer test generation

After printing the summary, prompt the user:

```
Generate test flows now? [yes/no]
(Platforms: android, chrome, ios — runs /zeus:test-gen automatically)
```

- If **yes**: invoke `/zeus:test-gen --version {version}` immediately.
- If **no**: remind the user they can run `/zeus:test-gen` at any time before executing.

## Quality gates

- no duplicate story/task IDs,
- no empty acceptance criteria,
- no task without a valid story link,
- no wave assignment with unresolved dependency.

## Agent collaboration

Use `zeus-planner` for decomposition quality checks and dependency sanity verification.
