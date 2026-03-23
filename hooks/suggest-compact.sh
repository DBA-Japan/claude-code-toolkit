#!/bin/bash
# Suggest-Compact Hook: 論理的なタイミングでコンパクトを提案
#
# フック種別: PostToolUse
# タイミング: 各ツール使用後に発火
# 目的: ツール使用回数が一定数に達したら /compact を提案

set -euo pipefail

# stdin を読み捨て
cat > /dev/null 2>&1 || true

COUNT_FILE="$HOME/.claude/.tool-count"
THRESHOLD=40

# --- カウントファイルが古い場合（2時間以上）はリセット ---
if [ -f "$COUNT_FILE" ]; then
  FILE_AGE_SEC=$(( $(date +%s) - $(stat -f %m "$COUNT_FILE" 2>/dev/null || echo "0") ))
  if [ "$FILE_AGE_SEC" -gt 7200 ]; then
    rm -f "$COUNT_FILE"
  fi
fi

# --- カウント読み取り & インクリメント ---
if [ -f "$COUNT_FILE" ]; then
  COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo "0")
  # 数値でなければリセット
  if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    COUNT=0
  fi
else
  COUNT=0
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNT_FILE"

# --- 閾値チェック（THRESHOLD の倍数で提案） ---
if [ $((COUNT % THRESHOLD)) -eq 0 ] && [ "$COUNT" -gt 0 ]; then
  echo "💡 ツール使用回数が${COUNT}回に達しました。論理的な区切りで \`/compact\` を実行すると品質が維持されます。"
fi

exit 0
