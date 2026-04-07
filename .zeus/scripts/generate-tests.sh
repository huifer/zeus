#!/usr/bin/env bash
# =============================================================================
# generate-tests.sh — Zeus AI 测试用例生成引擎
# 调用方式：bash .zeus/scripts/generate-tests.sh [选项]
# 选项：
#   --version    <name>              版本名（默认 main）
#   --platforms  <android,chrome,ios>  逗号分隔平台列表（默认 android,chrome,ios）
#   --task       <T-NNN>             仅为指定 task 生成（调试用）
#   --force                          覆盖已存在的 .test.json 文件
# =============================================================================

set -euo pipefail

# ---- 默认参数 ----
VERSION="main"
PLATFORMS="android,chrome,ios"
ONLY_TASK=""
FORCE=false

# ---- 解析参数 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)   VERSION="$2";    shift 2 ;;
    --platforms) PLATFORMS="$2";  shift 2 ;;
    --task)      ONLY_TASK="$2";  shift 2 ;;
    --force)     FORCE=true;      shift 1 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

# ---- 路径 ----
ZEUS_DIR=".zeus/${VERSION}"
TASK_FILE="${ZEUS_DIR}/task.json"
PRD_FILE="${ZEUS_DIR}/prd.json"
TESTS_DIR="${ZEUS_DIR}/tests"
SCHEMA_FILE=".zeus/schemas/test-flow.schema.json"
CONFIG_FILE="${ZEUS_DIR}/config.json"

# ---- 依赖检查 ----
if ! command -v claude &>/dev/null; then
  echo "❌ 未找到 claude CLI，请先安装: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "❌ 未找到 jq，请先安装: brew install jq" >&2
  exit 1
fi
for f in "$TASK_FILE" "$PRD_FILE" "$SCHEMA_FILE"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ 文件不存在: $f" >&2
    exit 1
  fi
done

mkdir -p "$TESTS_DIR"

# ---- 工具函数 ----

# 从 task.json 提取所有 pass=false 的 task（或指定 task）
get_tasks_json() {
  local filter='.tasks[]'
  if [[ -n "$ONLY_TASK" ]]; then
    filter=".tasks[] | select(.id == \"${ONLY_TASK}\")"
  fi
  jq -c "[${filter}]" "$TASK_FILE"
}

# 获取平台默认配置提示文本（注入到 prompt）
platform_hint() {
  local platform="$1"
  case "$platform" in
    android)
      echo 'Android 平台：使用 adb shell 命令操作设备。典型步骤示例：
- action: "adb -s emulator-5554 shell am start -n com.example.app/.MainActivity"
- action: "adb -s emulator-5554 shell input tap 540 960"
- action: "adb -s emulator-5554 shell input text \"hello@example.com\""
- assertion: "adb -s emulator-5554 shell dumpsys window windows | grep mCurrentFocus"
- expected: "com.example.app/.HomeActivity"'
      ;;
    chrome)
      echo 'Chrome 平台：使用 chrome-cli 或 Google Chrome DevTools Protocol (CDP) 命令。典型步骤示例：
- action: "chrome-cli open \"https://example.com/login\""
- action: "chrome-cli execute \"document.querySelector('"'"'#email'"'"').value='"'"'test@example.com'"'"'\""
- action: "chrome-cli execute \"document.querySelector('"'"'button[type=submit]'"'"').click()\""
- assertion: "chrome-cli execute \"document.title\""
- expected: "Dashboard — Example App"'
      ;;
    ios)
      echo 'iOS 平台：使用 xcrun simctl 命令操作模拟器，真机用 ideviceinstaller / libimobiledevice。典型步骤示例：
- action: "xcrun simctl launch booted com.example.app"
- action: "xcrun simctl io booted tap 195 420"
- action: "xcrun simctl spawn booted log stream --predicate '"'"'subsystem == \"com.example.app\"'"'"'"
- assertion: "xcrun simctl spawn booted defaults read com.example.app userLoggedIn"
- expected: "1"'
      ;;
  esac
}

# 为单个平台生成测试 JSON
generate_for_platform() {
  local platform="$1"
  local out_file="${TESTS_DIR}/${platform}.test.json"

  if [[ -f "$out_file" && "$FORCE" == "false" ]]; then
    echo "⏭  ${platform}.test.json 已存在，跳过（使用 --force 覆盖）"
    return 0
  fi

  echo "→  生成 ${platform} 测试用例..."

  # 读取上下文数据
  local tasks_json
  tasks_json=$(get_tasks_json)
  local prd_json
  prd_json=$(cat "$PRD_FILE")
  local north_star
  north_star=$(jq -r '.metrics.north_star // "未设置"' "$CONFIG_FILE" 2>/dev/null || echo "未设置")
  local schema_json
  schema_json=$(cat "$SCHEMA_FILE")
  local platform_guide
  platform_guide=$(platform_hint "$platform")

  local PROMPT
  PROMPT=$(cat <<EOF
你是 Zeus 测试用例生成代理（zeus-tester）。
根据下方 task.json、prd.json 和 test-flow schema，为 ${platform} 平台生成完整的测试流程 JSON。

## 规则

1. 只输出合法 JSON，不要输出任何 markdown 代码块包裹（不要 \`\`\`json），不要注释，不要解释文字。
2. 严格遵循 test-flow.schema.json 的字段定义。
3. 每个 task 至少生成 1 个 scenario，高优先级 story 对应的 task 生成 2~3 个 scenario（覆盖成功路径 + 1~2 个边界/失败路径）。
4. scenario.id 从 TC-001 开始递增。
5. steps 中 action 必须是可在真实 ${platform} 环境中直接执行的原生命令字符串。
6. passes 全部初始化为 false，run_at 初始化为 null。
7. generated_from 填写所有 task 的 id 数组。
8. generated_at 填写当前 ISO 时间：$(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 平台命令规范

${platform_guide}

## 北极星指标

${north_star}

## task.json（所有任务）

${tasks_json}

## prd.json（用户故事）

${prd_json}

## test-flow.schema.json（输出结构规范）

${schema_json}

## 输出

直接输出 ${platform}.test.json 的完整 JSON 内容，platform 字段值为 "${platform}"，version 字段值为 "${VERSION}"。
EOF
)

  local result
  result=$(claude --print "$PROMPT" 2>&1)

  # 校验输出是否为合法 JSON
  if ! echo "$result" | jq empty 2>/dev/null; then
    echo "❌  ${platform}: claude 输出不是合法 JSON，已保存原始输出到 ${out_file}.raw"
    echo "$result" > "${out_file}.raw"
    return 1
  fi

  echo "$result" > "$out_file"
  local scenario_count
  scenario_count=$(echo "$result" | jq '.scenarios | length')
  echo "✓  ${platform}.test.json 生成完成（${scenario_count} 个 scenario）"
}

# ---- 主流程 ----

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Zeus Test Generator  version=${VERSION}"
echo "═══════════════════════════════════════════════════"

# 分隔平台列表
IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"

total=${#PLATFORM_LIST[@]}
success=0
fail=0

for platform in "${PLATFORM_LIST[@]}"; do
  platform=$(echo "$platform" | tr -d '[:space:]')
  case "$platform" in
    android|chrome|ios)
      if generate_for_platform "$platform"; then
        (( success++ )) || true
      else
        (( fail++ )) || true
      fi
      ;;
    *)
      echo "⚠  未知平台: $platform（跳过）" >&2
      ;;
  esac
done

echo ""
echo "───────────────────────────────────────────────────"
echo "  完成：${success}/${total} 平台成功$([ "$fail" -gt 0 ] && echo "，${fail} 个失败" || echo "")"
echo "  输出目录：${TESTS_DIR}/"
echo "───────────────────────────────────────────────────"
echo ""

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
