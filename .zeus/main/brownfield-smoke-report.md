# Brownfield Smoke Report

Date: 2026-04-07
Scope: Step 2 validation for brownfield integration

## Checks

1. Required files present
- PASS: `.claude/skills/zeus-discover/SKILL.md`
- PASS: `.zeus/schemas/codebase-map.schema.json`
- PASS: `.zeus/schemas/existing-modules.schema.json`
- PASS: `.zeus/schemas/config.schema.json`
- PASS: `.zeus/schemas/task.schema.json`
- PASS: `.claude/skills/zeus-init/SKILL.md`
- PASS: `.claude/skills/zeus-brainstorm/SKILL.md`
- PASS: `.claude/skills/zeus-plan/SKILL.md`
- PASS: `.claude/skills/zeus-execute/SKILL.md`
- PASS: `.claude/skills/zeus-status/SKILL.md`
- PASS: `README.md`
- PASS: `README.zh-CN.md`

2. JSON schema parse checks
- PASS: `.zeus/schemas/codebase-map.schema.json` (jq parse)
- PASS: `.zeus/schemas/existing-modules.schema.json` (jq parse)
- PASS: `.zeus/schemas/config.schema.json` (jq parse)
- PASS: `.zeus/schemas/task.schema.json` (jq parse)

3. Brownfield hook presence
- PASS: `--import-existing` documented in init skill
- PASS: `existing-modules.json` intake in brainstorm skill
- PASS: `refactor_of` and `depends_on_existing` documented in plan skill
- PASS: minimal-intrusion refactor contract in execute skill
- PASS: discover/import recommendations in status skill
- PASS: discover command and brownfield workflow in both READMEs

## Working Tree Snapshot

Modified:
- `.claude/skills/zeus-brainstorm/SKILL.md`
- `.claude/skills/zeus-execute/SKILL.md`
- `.claude/skills/zeus-init/SKILL.md`
- `.claude/skills/zeus-plan/SKILL.md`
- `.claude/skills/zeus-status/SKILL.md`
- `.zeus/schemas/config.schema.json`
- `.zeus/schemas/task.schema.json`
- `README.md`
- `README.zh-CN.md`

Untracked:
- `.claude/skills/zeus-discover/`
- `.zeus/schemas/codebase-map.schema.json`
- `.zeus/schemas/existing-modules.schema.json`
- `image.png`

## Result

Step 2 is complete for static validation.

## Remaining for runtime acceptance

1. Run `/zeus:discover --version main --depth auto` on a real brownfield repo.
2. Run `/zeus:init --import-existing --version main` and verify inferred defaults are shown.
3. Run `/zeus:brainstorm --feature <name> --version main` and verify reuse/extend/rewrite classification appears.
4. Run `/zeus:plan --version main` and verify `refactor_of` / `depends_on_existing` appear when applicable.
