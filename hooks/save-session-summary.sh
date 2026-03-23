#!/bin/bash
# =============================================================================
# セッション要約自動保存スクリプト
# =============================================================================
# Claude Code の Stop hook から呼ばれる。
# セッションのトランスクリプト（JSONL）を解析して、
# 何をやったかの要約を自動生成し、ファイルに保存する。
#
# 保存先: ~/.claude/session-summaries/YYYY-MM-DD_HHMMSS.md
#
# トランスクリプトの取得方法（優先順）:
#   1. stdin の JSON に含まれる transcript_path
#   2. ~/.claude/projects/ 内の最新 .jsonl ファイル
# =============================================================================

# --- 設定 ---
SUMMARIES_DIR="$HOME/.claude/session-summaries"
HOOKS_DIR="$HOME/.claude/hooks"
MAX_SUMMARIES=50  # 保存する要約ファイルの最大数（古いものから自動削除）

# --- ディレクトリ作成 ---
mkdir -p "$SUMMARIES_DIR"

# --- stdinからJSONを読み取る（Claude Codeがhookに渡すデータ） ---
STDIN_DATA=$(cat 2>/dev/null || true)

# --- トランスクリプトのパスを取得 ---
TRANSCRIPT_PATH=""

# 方法1: stdinのJSONから取得
# 注意: インラインPythonのクォート問題を回避するため、
# 一時ファイル経由でPythonスクリプトを実行する
if [ -n "$STDIN_DATA" ]; then
  _PY_SCRIPT=$(mktemp /tmp/parse_stdin_XXXXXX.py)
  cat > "$_PY_SCRIPT" <<'PYEOF'
import sys, json
try:
    data = json.loads(sys.argv[1])
    print(data.get("transcript_path", ""))
except Exception:
    print("")
PYEOF
  TRANSCRIPT_PATH=$(python3 "$_PY_SCRIPT" "$STDIN_DATA" 2>/dev/null)
  rm -f "$_PY_SCRIPT"
fi

# 方法2: フォールバック — ~/.claude/projects/ 内の最新 .jsonl を探す
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_PATH=$(find "$HOME/.claude/projects" -name "*.jsonl" -type f -mmin -10 2>/dev/null | \
    while read -r f; do
      echo "$(stat -f "%m" "$f" 2>/dev/null || stat -c "%Y" "$f" 2>/dev/null) $f"
    done | sort -rn | head -1 | cut -d' ' -f2-)
fi

# トランスクリプトが見つからない場合は終了
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# --- Pythonスクリプトで要約を生成 ---
SUMMARY=$(python3 "$HOOKS_DIR/parse-transcript.py" "$TRANSCRIPT_PATH" 2>/dev/null)

# 要約が空なら何もしない
if [ -z "$SUMMARY" ]; then
  exit 0
fi

# --- ファイルに保存 ---
TIMESTAMP=$(date "+%Y-%m-%d_%H%M%S")
SUMMARY_FILE="${SUMMARIES_DIR}/${TIMESTAMP}.md"
printf '%s\n' "$SUMMARY" > "$SUMMARY_FILE"

# --- 最新の要約へのシンボリックリンクを更新 ---
LATEST_LINK="${SUMMARIES_DIR}/latest.md"
rm -f "$LATEST_LINK"
ln -s "$SUMMARY_FILE" "$LATEST_LINK"

# --- 古い要約を自動削除（MAX_SUMMARIES を超えた分） ---
FILE_COUNT=$(ls -1 "$SUMMARIES_DIR"/*.md 2>/dev/null | grep -v "latest.md" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -gt "$MAX_SUMMARIES" ]; then
  DELETE_COUNT=$((FILE_COUNT - MAX_SUMMARIES))
  ls -1t "$SUMMARIES_DIR"/*.md 2>/dev/null | grep -v "latest.md" | tail -n "$DELETE_COUNT" | while read -r old_file; do
    rm -f "$old_file"
  done
fi

exit 0
