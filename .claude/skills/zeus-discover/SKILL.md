---
name: zeus-discover
description: Map an existing (brownfield) codebase into deterministic Zeus artifacts under .zeus/{version}/ so downstream skills can reuse real project context.
argument-hint: [--project-root <path>] [--depth quick|auto|full] [--version vN]
shell: bash
---

# Zeus Discover - Brownfield Codebase Mapper

Use this skill to analyze an existing project and generate reusable codebase context before planning and execution.

## Preconditions

- `.zeus/{version}/` exists (default `main`).
- You can write to `.zeus/{version}/`.
- The target project root is readable.

## Inputs

- `--project-root <path>` (optional, default current workspace root)
- `--depth quick|auto|full` (optional, default `auto`)
- `--version vN` (optional, default `main`)

## Security rules

- Never read or print secret values from `.env*`, `*secret*`, `*credential*`, key/cert files.
- For sensitive files, only record existence and path.
- Output must contain no credentials or token-like strings.

## Deterministic workflow

### 1) Resolve scope

Resolve version folder and project root:

- output base: `.zeus/{version}/`
- map target: `{project-root}`

### 2) Collect structural inventory

Collect and summarize:

- top-level directories and key entry points,
- package/runtime manifests,
- test config and test file patterns,
- major module directories and size hotspots,
- TODO/FIXME/HACK markers.

### 3) Collect dependency and integration signals

Extract from manifests and imports:

- language/runtime/framework set,
- critical dependencies and tooling,
- external integration candidates (SDK/API clients),
- datastore/auth/observability hints when present.

### 4) Build module map

Generate module-level records with:

- path,
- role classification (`api`, `frontend`, `infra`, `data`, `shared`, `test`, `unknown`),
- approximate LOC,
- key dependency links,
- risk markers (`large-file`, `todo-density`, `high-fan-in`).

### 5) Write brownfield artifacts

Write these files to `.zeus/{version}/`:

1. `codebase-map.json`
2. `existing-modules.json`
3. `tech-inventory.md`
4. `architecture.md`

### 6) Validate and summarize

- Validate JSON structure against schemas when available.
- If schema file is missing, continue and note validation skipped.
- Return concise summary with artifact paths and record counts.

## Artifact contracts

### codebase-map.json

Must include:

- `schema_version`
- `generated_at`
- `project_root`
- `scan_depth`
- `summary`
- `languages`
- `runtimes`
- `frameworks`
- `dependencies`
- `entry_points`
- `module_hotspots`
- `concerns`

### existing-modules.json

Must include:

- `schema_version`
- `generated_at`
- `version`
- `modules` (array of module descriptors used by brainstorm/plan)

## Output contract

- four artifacts written to `.zeus/{version}/`,
- no secret leakage,
- clear recommendation for next step:
  - `/zeus:init --import-existing --version {version}` if config is not aligned,
  - otherwise `/zeus:brainstorm --feature <name> --version {version}`.

## Agent collaboration

Use `zeus-researcher` for large repositories where deeper read-only exploration is required before writing final artifacts.
