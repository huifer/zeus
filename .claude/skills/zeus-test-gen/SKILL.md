---
name: zeus-test-gen
description: Generate AI-authored platform test flows (android.test.json, chrome.test.json, ios.test.json) from task.json and prd.json using generate-tests.sh. Can be triggered manually or automatically after zeus-plan. Supports --version flag and --platforms filter.
argument-hint: [--version vN] [--platforms android,chrome,ios]
shell: bash
---

# Zeus Test Gen — AI Test Flow Generation

Generate platform-specific end-to-end test scenarios from Zeus planning artifacts.
AI (zeus-tester agent) authors the test cases. Humans do not write scenarios manually.

## Preconditions

- `.zeus/{version}/task.json` exists and has at least one task.
- `.zeus/{version}/prd.json` exists and has at least one story.
- `.zeus/schemas/test-flow.schema.json` exists.
- `.zeus/{version}/config.json` exists.
- `generate-tests.sh` is executable.
- `claude` CLI is installed and reachable.

## Optional arguments

- `--version vN` — target Zeus version folder (default: `main`)
- `--platforms android,chrome,ios` — subset of platforms to generate (default: all three)

## Deterministic workflow

### 1) Check preconditions

Verify all required files exist. If any is missing, print a clear error and abort.

```bash
for f in .zeus/{version}/task.json .zeus/{version}/prd.json .zeus/schemas/test-flow.schema.json; do
  [[ -f "$f" ]] || { echo "❌ Missing: $f"; exit 1; }
done
```

### 2) Show generation plan

Print a preview before executing:

```
Platform(s) to generate : android, chrome, ios
Task source             : .zeus/{version}/task.json  (N tasks)
Story source            : .zeus/{version}/prd.json   (N stories)
Output directory        : .zeus/{version}/tests/
```

Require user confirmation to proceed (yes/no).

### 3) Run generate-tests.sh

```bash
bash .zeus/scripts/generate-tests.sh \
  --version {version} \
  --platforms {platforms}
```

Stream output to the user in real time.

### 4) Validate generated files

For each output file:

```bash
jq empty .zeus/{version}/tests/{platform}.test.json && echo "✓ valid JSON"
```

Report scenario counts per platform.

### 5) Print coverage report

After generation succeeds, output a coverage table:

```
Platform  | Scenarios | Tasks covered | Coverage
----------|-----------|---------------|----------
android   |         8 |           5/6 |      83%
chrome    |         6 |           5/6 |      83%
ios       |         7 |           5/6 |      83%
```

Coverage = scenarios that reference a task_id / total task count.

### 6) Commit test files

```bash
git add .zeus/{version}/tests/
git commit -m "test(zeus): generate {platform} test flows for {version}"
```

One commit per platform generated.

### 7) Write AI log

Create `.zeus/{version}/ai-logs/{ISO-ts}-test-gen.md` with the 3-section contract:

```markdown
## 决策理由
Which platforms were targeted and why, what task coverage gaps exist.

## 执行摘要
Files written, scenario counts, commit SHAs.

## 目标预期
How test coverage supports the north star metric by catching regressions early.
```

### 8) Report summary

Return:

- scenario count per platform,
- task coverage percentage,
- recommended next step: `/zeus:execute` or run tests with platform toolchain.

## Regeneration behavior

- By default, existing `{platform}.test.json` files are **skipped** (not overwritten).
- To regenerate, pass `--force` to the underlying script via:

```bash
bash .zeus/scripts/generate-tests.sh --version {version} --platforms {platforms} --force
```

## Agent collaboration

Delegates test content generation to `zeus-tester` agent (invoked inside `generate-tests.sh` via `claude --print`).
Use `zeus-researcher` to inspect task coverage gaps before generation if needed.
