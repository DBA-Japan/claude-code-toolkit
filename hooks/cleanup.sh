#!/bin/bash
# =============================================================================
# セッション終了時クリーンアップ
# =============================================================================
# Stop hook から呼ばれる。ゾンビプロセス掃除 + 一時ファイル削除。
# =============================================================================

# --- stdin読み捨て ---
cat > /dev/null 2>/dev/null || true

# --- 1. 孤立したMCPプロセスを掃除 ---
# 親プロセスが死んだbrowser-useのゾンビを検出して kill
for pid in $(pgrep -f "uvx.*browser-use.*--mcp" 2>/dev/null); do
  PARENT_PID=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  # 親プロセスが1(init)または存在しない = ゾンビ
  if [ "$PARENT_PID" = "1" ] || ! ps -p "$PARENT_PID" > /dev/null 2>&1; then
    kill "$pid" 2>/dev/null
  fi
done

# --- 2. /tmp のデバッグログ削除（1日以上前のもの） ---
find /tmp -name "claude-*.log" -type f -mtime +0 -delete 2>/dev/null
find /tmp -name "mcp-debug-*.py" -type f -mtime +0 -delete 2>/dev/null
find /tmp -name "parse_stdin_*.py" -type f -mmin +60 -delete 2>/dev/null

# --- 3. 古いセッション要約を整理（50件超を削除） ---
SUMMARIES_DIR="$HOME/.claude/session-summaries"
if [ -d "$SUMMARIES_DIR" ]; then
  FILE_COUNT=$(ls -1 "$SUMMARIES_DIR"/*.md 2>/dev/null | grep -v "latest.md" | wc -l | tr -d ' ')
  if [ "$FILE_COUNT" -gt 50 ]; then
    DELETE_COUNT=$((FILE_COUNT - 50))
    ls -1t "$SUMMARIES_DIR"/*.md 2>/dev/null | grep -v "latest.md" | tail -n "$DELETE_COUNT" | while read -r f; do
      rm -f "$f"
    done
  fi
fi

exit 0
