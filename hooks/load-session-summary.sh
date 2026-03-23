#!/bin/bash
# =============================================================================
# セッション要約読み込みスクリプト
# =============================================================================
# Claude Code の SessionStart hook から呼ばれる。
# 最新のセッション要約を読み込んで stdout に出力する。
# → Claude Code がこの出力をコンテキストとして取り込む。
#
# 仕組み:
#   ~/.claude/session-summaries/latest.md（シンボリックリンク）を読む
# =============================================================================

SUMMARIES_DIR="$HOME/.claude/session-summaries"
LATEST_LINK="${SUMMARIES_DIR}/latest.md"

# --- stdinを読み捨てる（hookの仕様上、stdinにJSONが来る） ---
cat > /dev/null

# --- 最新の要約ファイルが存在するか確認 ---
if [ ! -L "$LATEST_LINK" ] && [ ! -f "$LATEST_LINK" ]; then
  # まだ要約がない場合（初回起動時など）
  echo "前回のセッション要約はありません。新しいセッションを開始します。"
  exit 0
fi

# --- シンボリックリンクの先が存在するか確認 ---
if [ ! -f "$LATEST_LINK" ]; then
  echo "前回のセッション要約はありません。新しいセッションを開始します。"
  exit 0
fi

# --- 要約ファイルの更新日時を確認（3日以上前なら古い警告を出す） ---
if [ "$(uname)" = "Darwin" ]; then
  # macOS
  FILE_EPOCH=$(stat -f "%m" "$LATEST_LINK" 2>/dev/null || echo 0)
else
  # Linux
  FILE_EPOCH=$(stat -c "%Y" "$LATEST_LINK" 2>/dev/null || echo 0)
fi

NOW_EPOCH=$(date +%s)
AGE_SECONDS=$((NOW_EPOCH - FILE_EPOCH))
AGE_DAYS=$((AGE_SECONDS / 86400))

# --- 要約を出力 ---
echo "=== 前回のセッション要約 ==="
echo ""

if [ "$AGE_DAYS" -ge 3 ]; then
  echo "（注意: この要約は ${AGE_DAYS} 日前のものです）"
  echo ""
fi

cat "$LATEST_LINK"

echo ""
echo "=== 前回の要約ここまで ==="

# --- 直近3件の要約ファイル一覧も表示 ---
RECENT_FILES=$(ls -1t "$SUMMARIES_DIR"/*.md 2>/dev/null | grep -v "latest.md" | head -3)
if [ -n "$RECENT_FILES" ]; then
  echo ""
  echo "直近のセッション要約ファイル:"
  echo "$RECENT_FILES" | while read -r f; do
    BASENAME=$(basename "$f")
    echo "  - $BASENAME"
  done
fi

exit 0
