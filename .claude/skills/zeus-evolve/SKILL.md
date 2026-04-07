---
name: zeus-evolve
description: Create a new version folder (.zeus/v2/, .zeus/v3/ etc.) when user feedback reveals needs that can't be met by the main version. Inherits main config and declares differences. Records everything in evolution.md.
argument-hint: [--version vN] [--reason <text>]
shell: bash
---

# Zeus Evolve - Version Split Protocol

Create a new version track when feedback indicates structural divergence from current roadmap.

## Preconditions

- Evolution rationale exists (from feedback or direct input).
- `.zeus/main/config.json` exists and is writable.
- New version identifier is not already used.

## Deterministic workflow

### 1) Confirm evolution rationale

Collect:

- target segment,
- unmet needs,
- why current version cannot absorb this via normal iteration.

### 2) Resolve next version ID

Detect latest existing `vN` and choose next available by default.

If `--version` is provided, validate uniqueness.

### 3) Confirm creation plan

Display summary and require user confirmation.

### 4) Create folder structure

```bash
mkdir -p .zeus/v{N}/feedback
mkdir -p .zeus/v{N}/ai-logs
mkdir -p .zeus/v{N}/specs
```

### 5) Write version config

Create `.zeus/v{N}/config.json` with:

- `inherits: main`,
- project/version metadata,
- version-specific north star,
- `overrides.description` documenting strategic difference.

### 6) Initialize empty artifacts

Create:

- `prd.json`
- `task.json`
- `roadmap.json`
- `ui-design.md`
- `evolution.md`

### 7) Register version in main config

Update `.zeus/main/config.json` `versions.active` and `versions.folders`.

### 8) Append evolution records

- append `EVOLVE` entry to `.zeus/main/evolution.md`
- write `INIT` entry in `.zeus/v{N}/evolution.md`

### 9) Optional branch creation

If user opts in:

```bash
git checkout -b zeus/v{N}-{slug}
```

### 10) Commit changes

```bash
git add .zeus/v{N}/ .zeus/main/config.json .zeus/main/evolution.md
git commit -m "chore(zeus): initialize v{N} evolution - {reason}"
```

### 11) Write AI log

Create `.zeus/v{N}/ai-logs/{ISO-ts}-evolve.md` with 3-section contract.

## Output contract

- new `.zeus/vN/` workspace,
- updated main version registry,
- dual evolution timeline entries,
- explicit next step recommendation.

## Agent collaboration

Use `zeus-analyst` to verify evolution confidence and boundary rationale.
