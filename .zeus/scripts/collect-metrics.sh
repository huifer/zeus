#!/usr/bin/env bash
# =============================================================================
# collect-metrics.sh — 数据指标采集示例脚本
# 
# 使用方式：bash .zeus/scripts/collect-metrics.sh
# 输出：JSON 格式的指标数据，可被 zeus-feedback 读取
#
# 修改这个脚本以适配你的项目数据源。
# 目前包含以下采集示例：
#   1. 从环境变量/本地 SQLite 查询
#   2. 从 PostgreSQL 查询
#   3. 从 Google Analytics 导出文件解析（手动放置）
#   4. 通用 HTTP API 查询
# =============================================================================

set -euo pipefail

OUT_FILE=".zeus/collected-metrics-$(date +%Y%m%d%H%M%S).json"

echo "📡 Zeus 指标采集中..." >&2

# ---- 初始化输出结构 ----
pv=""
uv=""
conversion_rate=""
revenue=""
notes=""
source_detail=""

# ============================================================
# 示例 1：从本地 SQLite 数据库查询
# 取消注释并修改 SQL 以适配你的 schema
# ============================================================
# DB_PATH="./db.sqlite"
# if [[ -f "$DB_PATH" ]] && command -v sqlite3 &>/dev/null; then
#   pv=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM page_views WHERE created_at > datetime('now', '-7 days')")
#   uv=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT user_id) FROM page_views WHERE created_at > datetime('now', '-7 days')")
#   conversion_rate=$(sqlite3 "$DB_PATH" "SELECT ROUND(CAST(COUNT(DISTINCT user_id) AS FLOAT) / NULLIF((SELECT COUNT(DISTINCT visitor_id) FROM sessions WHERE created_at > datetime('now', '-7 days')), 0) * 100, 2) FROM users WHERE created_at > datetime('now', '-7 days')")
#   source_detail="SQLite: $DB_PATH"
# fi

# ============================================================
# 示例 2：从 PostgreSQL 查询
# 需要设置 DATABASE_URL 环境变量
# ============================================================
# if [[ -n "${DATABASE_URL:-}" ]] && command -v psql &>/dev/null; then
#   pv=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM page_views WHERE created_at > NOW() - INTERVAL '7 days'" | tr -d ' ')
#   uv=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(DISTINCT user_id) FROM sessions WHERE created_at > NOW() - INTERVAL '7 days'" | tr -d ' ')
#   source_detail="PostgreSQL"
# fi

# ============================================================
# 示例 3：解析手动放置的 GA 导出 CSV
# 将 GA 导出的 CSV 放到 .zeus/ga-export.csv
# ============================================================
# GA_CSV=".zeus/ga-export.csv"
# if [[ -f "$GA_CSV" ]]; then
#   pv=$(awk -F',' 'NR==2{print $2}' "$GA_CSV" | tr -d '"')
#   uv=$(awk -F',' 'NR==2{print $3}' "$GA_CSV" | tr -d '"')
#   source_detail="Google Analytics CSV export"
# fi

# ============================================================
# 示例 4：从任意 HTTP API 查询
# ============================================================
# API_ENDPOINT="${METRICS_API_URL:-}"
# API_TOKEN="${METRICS_API_TOKEN:-}"
# if [[ -n "$API_ENDPOINT" ]] && command -v curl &>/dev/null; then
#   response=$(curl -s -H "Authorization: Bearer $API_TOKEN" "$API_ENDPOINT/metrics?period=7d")
#   pv=$(echo "$response" | jq -r '.pv // empty')
#   uv=$(echo "$response" | jq -r '.uv // empty')
#   conversion_rate=$(echo "$response" | jq -r '.conversion_rate // empty')
#   revenue=$(echo "$response" | jq -r '.revenue // empty')
#   source_detail="HTTP API: $API_ENDPOINT"
# fi

# ---- 如果没有配置任何数据源，输出提示 ----
if [[ -z "$pv" && -z "$uv" && -z "$conversion_rate" && -z "$revenue" ]]; then
  notes="未配置数据源。请编辑 .zeus/scripts/collect-metrics.sh 接入实际数据。"
  source_detail="none"
fi

# ---- 生成 JSON 输出 ----
cat > "$OUT_FILE" <<JSON
{
  "collected_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source_detail": "${source_detail}",
  "metrics": {
    "pv": ${pv:-null},
    "uv": ${uv:-null},
    "conversion_rate": ${conversion_rate:-null},
    "revenue": ${revenue:-null},
    "notes": "${notes}"
  }
}
JSON

echo "✅ 指标数据已写入：$OUT_FILE" >&2
cat "$OUT_FILE"
