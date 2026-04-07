#!/usr/bin/env bash
# =============================================================================
# zeus-runner.sh — Zeus 执行引擎（类 ralph.sh）
# 调用方式：bash .zeus/scripts/zeus-runner.sh [选项]
# 选项：
#   --task-file  <path>   task.json 路径（默认 .zeus/main/task.json）
#   --log-dir    <path>   ai-logs 目录（默认 .zeus/main/ai-logs）
#   --version    <name>   版本名（默认 main）
#   --max-iter   <N>      最大迭代次数（默认 50）
#   --task       <T-NNN>  仅执行指定 task（调试用）
#   --wave       <N>      仅执行指定波次（调试用）
# =============================================================================

set -euo pipefail

# ---- 默认参数 ----
TASK_FILE=".zeus/main/task.json"
LOG_DIR=".zeus/main/ai-logs"
VERSION="main"
MAX_ITER=50
ONLY_TASK=""
ONLY_WAVE=""
ITER=0

# ---- 解析参数 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-file)  TASK_FILE="$2";  shift 2 ;;
    --log-dir)    LOG_DIR="$2";    shift 2 ;;
    --version)    VERSION="$2";    shift 2 ;;
    --max-iter)   MAX_ITER="$2";   shift 2 ;;
    --task)       ONLY_TASK="$2";  shift 2 ;;
    --wave)       ONLY_WAVE="$2";  shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

# ---- 依赖检查 ----
if ! command -v claude &>/dev/null; then
  echo "❌ 未找到 claude CLI，请先安装: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "❌ 未找到 jq，请先安装: brew install jq" >&2
  exit 1
fi
if [[ ! -f "$TASK_FILE" ]]; then
  echo "❌ task.json 不存在: $TASK_FILE" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

# ---- 工具函数 ----

# 获取未完成的 task 列表（JSON 数组）
get_pending_tasks() {
  local filter='. | .tasks[] | select(.passes == false)'
  if [[ -n "$ONLY_TASK" ]]; then
    filter=". | .tasks[] | select(.passes == false and .id == \"$ONLY_TASK\")"
  elif [[ -n "$ONLY_WAVE" ]]; then
    filter=". | .tasks[] | select(.passes == false and .wave == $ONLY_WAVE)"
  fi
  jq -c "[$filter]" "$TASK_FILE"
}

# 获取当前最小未完成 wave
get_current_wave() {
  jq '[.tasks[] | select(.passes == false) | .wave // 999] | min' "$TASK_FILE"
}

# 获取指定 wave 的未完成任务
get_wave_tasks() {
  local wave="$1"
  jq -c "[.tasks[] | select(.passes == false and .wave == $wave)]" "$TASK_FILE"
}

# 标记 task 完成
mark_task_done() {
  local task_id="$1"
  local commit_sha="$2"
  local log_ref="$3"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local tmp
  tmp=$(mktemp)
  jq --arg id "$task_id" \
     --arg sha "$commit_sha" \
     --arg ref "$log_ref" \
     --arg ts "$now" \
     '(.tasks[] | select(.id == $id)) |= 
       (.passes = true | .commit_sha = $sha | .ai_log_ref = $ref | .completed_at = $ts)' \
     "$TASK_FILE" > "$tmp" && mv "$tmp" "$TASK_FILE"
}

# 构建单个 task 的 claude 提示词
build_task_prompt() {
  local task_json="$1"
  local task_id
  local task_type
  local task_title
  local task_desc
  local task_files
  local north_star
  task_id=$(echo "$task_json" | jq -r '.id')
  task_type=$(echo "$task_json" | jq -r '.type')
  task_title=$(echo "$task_json" | jq -r '.title')
  task_desc=$(echo "$task_json" | jq -r '.description')
  task_files=$(echo "$task_json" | jq -r '.files | join(", ")')
  north_star=$(jq -r '.metrics.north_star // "conversion"' ".zeus/${VERSION}/config.json" 2>/dev/null || echo "conversion")

  cat <<PROMPT
你是 Zeus 执行代理，负责完成以下单个任务。每个任务必须在本次上下文窗口内完全完成。

## 当前任务

任务 ID：${task_id}
类型：${task_type}
标题：${task_title}
描述：${task_desc}
涉及文件：${task_files}
北极星指标：${north_star}

## 执行要求

1. 实现上述任务，遵循项目现有的代码风格和架构模式
2. 如有 typecheck/lint/test 配置，运行并保证通过
3. 完成后立即进行原子 git commit，格式严格遵守：
   ${task_type == "api" && echo "feat" || echo "feat"}(${task_id}): ${task_title}
   （type 根据实际情况选：feat/fix/docs/chore/test/refactor）
4. 将 task.json 中此任务的 passes 字段更新为 true，填写 commit_sha
5. 在 ${LOG_DIR}/ 目录写入三段式 ai-log 文件，文件名格式：
   $(date -u +"%Y-%m-%dT%H%M%S")-${task_id}.md
   
   三段式内容：
   ## 决策理由
   （实现时的关键技术选择，为什么这样做）
   
   ## 执行摘要
   （改了哪些文件，新增了什么，commit SHA）
   
   ## 目标预期
   （此 task 如何贡献北极星指标 ${north_star}，尽量量化）
   
6. 追加一行到 .zeus/${VERSION}/progress.txt（若不存在则创建）：
   [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ${task_id} 完成：${task_title}。学到：{你发现的关键规律或注意事项}

完成后输出：<done>${task_id}</done>
PROMPT
}

# ---- 主循环 ----

echo "🚀 Zeus Runner 启动（版本：${VERSION}，最大迭代：${MAX_ITER}）"
echo "   task.json: ${TASK_FILE}"
echo ""

while true; do
  ITER=$((ITER + 1))
  if [[ $ITER -gt $MAX_ITER ]]; then
    echo "⚠️  已达最大迭代次数 ${MAX_ITER}，停止执行"
    break
  fi

  # 检查是否有待执行任务
  pending_count=$(jq '[.tasks[] | select(.passes == false)] | length' "$TASK_FILE")
  if [[ "$pending_count" -eq 0 ]]; then
    echo ""
    echo "✅ 所有任务已完成！"
    echo ""
    # 输出完成的任务列表
    echo "📋 完成摘要："
    jq -r '.tasks[] | select(.passes == true) | "  ✅ \(.id) [\(.type)] \(.title) → \(.commit_sha // "无commit")"' "$TASK_FILE"
    echo ""
    echo "<promise>COMPLETE</promise>"
    break
  fi

  # 获取当前波次
  current_wave=$(get_current_wave)
  if [[ "$current_wave" == "null" || "$current_wave" == "999" ]]; then
    echo "⚠️  存在未分配波次的任务，请重新运行 /zeus:plan"
    exit 1
  fi

  wave_tasks=$(get_wave_tasks "$current_wave")
  wave_count=$(echo "$wave_tasks" | jq 'length')

  echo "▶ Wave ${current_wave} — ${wave_count} 个任务（$(echo "$wave_tasks" | jq -r '[.[].id] | join(", ")')）"

  # 逐个执行（Wave 内串行；如需并行，可改为 & 后台 + wait）
  while IFS= read -r task_json; do
    task_id=$(echo "$task_json" | jq -r '.id')
    task_title=$(echo "$task_json" | jq -r '.title')

    echo "  ⏳ 执行 ${task_id}: ${task_title}"

    # 构建提示词
    prompt=$(build_task_prompt "$task_json")

    # 调用 claude CLI（--dangerously-skip-permissions 适用于全自动模式）
    output=$(claude --print "$prompt" 2>&1)

    # 检查是否成功完成
    if echo "$output" | grep -q "<done>${task_id}</done>"; then
      commit_sha=$(git log --oneline -1 --format="%H" 2>/dev/null || echo "unknown")
      log_ref="${task_id}.md"
      mark_task_done "$task_id" "$commit_sha" "$log_ref"
      echo "  ✅ ${task_id} 完成（commit: ${commit_sha:0:7}）"
    else
      echo "  ❌ ${task_id} 执行失败，输出如下："
      echo "$output" | tail -20
      echo ""
      echo "  可以手动修复后重新运行 /zeus:execute --task ${task_id}"
      # 失败时停止当前 wave，等待人工介入
      break 2
    fi

  done < <(echo "$wave_tasks" | jq -c '.[]')

  echo ""
done

echo "Zeus Runner 退出（共 ${ITER} 次迭代）"
