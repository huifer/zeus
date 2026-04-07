# Zeus - AI Project Evolution Operating System

[![Language](https://img.shields.io/badge/language-English%20%7C%20中文-blue)](README.zh-CN.md)
[![Workflow](https://img.shields.io/badge/workflow-init%E2%86%92brainstorm%E2%86%92plan%E2%86%92execute%E2%86%92feedback-green)](#workflow)
[![Status](https://img.shields.io/badge/status-active-success)](#)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](#license)

Structured, version-aware AI delivery framework for long-running projects.

Zeus combines:
- deterministic planning artifacts (`spec`, `prd`, `task`, `roadmap`),
- wave-based execution with atomic commits,
- mandatory attribution loop from production feedback to roadmap evolution.

Language: [English](README.md) | [简体中文](README.zh-CN.md)

## Quick Start

```bash
# 1) Install the commit message hook (one-time)
cp .zeus/hooks/commit-msg .git/hooks/commit-msg

# 2) Initialize the Zeus project workspace
/zeus:init

# 3) Build the first design spec
/zeus:brainstorm --full

# 4) Convert approved spec to executable artifacts
/zeus:plan

# 5) Run pending tasks in dependency waves
/zeus:execute
```

## Workflow

English workflow diagram:

![Zeus Workflow EN](assets/zeus-workflow.en.svg)

Chinese workflow diagram:

![Zeus Workflow ZH](assets/zeus-workflow.zh-CN.svg)

## Skill Commands

| Command | Purpose | Main Output |
|---|---|---|
| `/zeus:init` | Initialize Zeus workspace and north star metrics | `.zeus/main/config.json`, `evolution.md` |
| `/zeus:brainstorm --full` | Full-scope design dialogue and spec authoring | `.zeus/main/specs/*.md` |
| `/zeus:brainstorm --feature <name>` | Single-feature design loop | feature spec |
| `/zeus:plan [--version v2]` | Convert spec to user stories and tasks | `prd.json`, `task.json`, `roadmap.json` |
| `/zeus:execute [--version v2]` | Execute pending tasks wave by wave | atomic commits, task pass states |
| `/zeus:test-gen [--version v2] [--platforms android,chrome,ios]` | AI-generate platform test flows from task/prd artifacts | `{version}/tests/*.test.json` |
| `/zeus:feedback` | Capture feedback and run attribution | `feedback/*.json`, evolution entry |
| `/zeus:evolve` | Create a new version branch/folder model | `.zeus/vN/*` |
| `/zeus:status` | Render global status report and next action | health snapshot + recommendation |

## Repository Layout

```text
.zeus/
  main/
    config.json
    prd.json
    task.json
    roadmap.json
    evolution.md
    feedback/
    ai-logs/
    specs/
    tests/
      android.test.json   ← AI-generated, do not edit manually
      chrome.test.json
      ios.test.json
  v2/ ... vN/
  schemas/
    config.schema.json
    prd.schema.json
    task.schema.json
    roadmap.schema.json
    spec.schema.json
    feedback.schema.json
    ai-log.schema.json
    test-flow.schema.json
  scripts/
    zeus-runner.sh
    generate-tests.sh
    collect-metrics.sh
  hooks/
    commit-msg

.claude/
  skills/zeus-*/SKILL.md
  agents/*.md

assets/
  zeus-workflow.en.svg
  zeus-workflow.zh-CN.svg
```

## Agent Model

Zeus uses phase-specific agents under `.claude/agents`:

- `zeus-researcher`: context discovery and dependency checks
- `zeus-planner`: spec decomposition and artifact shaping
- `zeus-executor`: wave execution orchestration with quality gates
- `zeus-analyst`: attribution confidence and evolution decisions
- `zeus-docs`: bilingual consistency and docs quality checks
- `zeus-tester`: AI test case authoring for android / chrome / ios platforms

Skills should delegate intentionally:
- brainstorming -> researcher
- plan -> planner
- execute -> executor
- test generation -> tester (via `generate-tests.sh`)
- feedback/evolve -> analyst
- docs quality checks -> docs

## Testing

Zeus uses AI-generated test flows. **Do not write test cases manually.**

```bash
# Generate test flows for all platforms (after zeus:plan)
bash .zeus/scripts/generate-tests.sh --version main --platforms android,chrome,ios

# Or via skill
/zeus:test-gen

# Target a single platform
/zeus:test-gen --platforms chrome

# Regenerate (overwrite existing)
bash .zeus/scripts/generate-tests.sh --version main --force
```

Generated files live at `.zeus/{version}/tests/{platform}.test.json` and conform to `.zeus/schemas/test-flow.schema.json`.

Test execution uses the native platform toolchain directly:

| Platform | Toolchain |
|---|---|
| Android | `adb shell` |
| Chrome | `chrome-cli` / Chrome DevTools Protocol |
| iOS | `xcrun simctl` / `libimobiledevice` |

Test flows are regenerated automatically when `/zeus:test-gen` is invoked, and optionally after each execution wave completes.

## AI Log Contract

Each skill execution must append one markdown log in `ai-logs/`:

```markdown
## Decision Rationale
Why this approach was selected.

## Execution Summary
What changed and where.

## Target Impact
Expected impact on the north star metric.
```

## Commit Convention

```text
feat(T-003): implement user registration form
fix(T-007): correct session token expiry
docs(zeus): update prd from auth-design spec
chore(zeus): initialize v2 evolution
```

## Troubleshooting

- If `/zeus:*` commands are not discovered, restart your AI runtime session.
- If execution stalls, verify `.zeus/scripts/zeus-runner.sh` is executable.
- If task updates fail, check JSON validity in `.zeus/*/task.json`.
- If commit hook fails, re-copy `.zeus/hooks/commit-msg` into `.git/hooks/`.

## Contributing

1. Keep prompt specs deterministic and artifact-driven.
2. Keep shell snippets in English only.
3. Preserve backward compatibility for core `.zeus` schema files.
4. Add docs updates for any workflow changes.

## Contact / 交流群

<p align="center">
  <img src="assets/image.png" alt="交流群" width="300" />
</p>

## License

MIT License — see [LICENSE](LICENSE).
