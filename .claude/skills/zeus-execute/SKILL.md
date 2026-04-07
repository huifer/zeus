---
name: zeus-execute
description: Execute all pending tasks in task.json using the zeus-runner.sh shell loop. Tasks are grouped into dependency waves and run with fresh claude CLI subagents. Each task gets an atomic git commit and a mandatory ai-log entry. Supports --version flag for v2/v3/v4 execution.
argument-hint: [--version vN] [--task T-###] [--wave N]
shell: bash
---

# Zeus Execute - Wave Orchestration Engine

Run pending tasks with dependency awareness, strict quality gates, and atomic commits.

## Preconditions

- `.zeus/{version}/config.json` exists.
- `.zeus/{version}/task.json` exists and contains pending tasks unless filtered by `--task`.
- `.zeus/scripts/zeus-runner.sh` exists and is executable.
- `claude` CLI is installed and reachable.

## Optional filters

- `--task T-###`
- `--wave <N>`
- `--version vN`

## Deterministic workflow

### 1) Build execution plan

Load pending tasks and group by `wave`.

Show preview summary before running:

- total task count
- wave count
- per-wave task list

Require user confirmation to proceed.

### 2) Launch runner

```bash
bash .zeus/scripts/zeus-runner.sh \
  --task-file .zeus/{version}/task.json \
  --log-dir .zeus/{version}/ai-logs \
  --version {version}
```

### 3) Monitor and report

Track runner output and report progress by wave:

- started
- completed
- failed/retry state
- commit SHA for completed tasks

### 4) Validate completion

After run, verify:

- all targeted tasks now have `passes: true`,
- `commit_sha` is filled,
- milestone status can be promoted to `completed` when all related tasks pass.

### 5) Persist post-run updates

Update relevant roadmap milestone status and write summary log.

### 6) Write execution AI log

Create `.zeus/{version}/ai-logs/{ISO-ts}-execute.md`.

## Per-task execution contract

Each task completion must include:

1. Quality checks (typecheck/lint/tests when configured)
2. Atomic commit with format `{type}({task_id}): {description}`
3. `task.json` update (`passes`, `commit_sha`, optional `ai_log_ref`)
4. Task-level AI log `.zeus/{version}/ai-logs/{ISO-ts}-{task_id}.md`
5. Progress append to `.zeus/{version}/progress.txt`

Brownfield extension:

- If task includes `refactor_of`, switch to minimal-intrusion strategy:
  1. Add or update tests around existing behavior first.
  2. Apply smallest safe change in existing modules.
  3. Preserve backward compatibility or provide migration notes.
- Include `refactor_of` details in task-level AI log execution summary.

## Failure policy

- quality check failure: pause and surface error details,
- repeated failure (`>3` retries): stop current wave and request task split,
- interruption: resume by skipping already passed tasks.

## Output contract

- execution summary by wave,
- list of completed tasks + commit SHAs,
- recommended next action (`/zeus:feedback` or `/zeus:status`).

## Optional post-wave test refresh

After each wave completes, offer:

```
Wave N complete. Refresh test flows for completed tasks? [yes/no]
(Runs: bash .zeus/scripts/generate-tests.sh --version {version} --force)
```

This regenerates `{platform}.test.json` scenarios for tasks marked `passes: true` in the current wave, keeping test coverage aligned with shipped code.

## Agent collaboration

Use `zeus-executor` to supervise multi-wave execution status and enforce completion gates.
Use `zeus-tester` (via `/zeus:test-gen`) after execution waves to generate or refresh platform test flows.
