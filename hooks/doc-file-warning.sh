#!/bin/bash
# =============================================================================
# doc-file-warning.sh — PreToolUse Hook (Write)
# 不要なドキュメントファイル(.md / .txt)の増殖を警告する
# ブロックはしない（exit 0）が、注意喚起メッセージを表示
# =============================================================================

# stdin から Claude Code の PreToolUse JSON を読み取る
# 形式: {"tool_name": "Write", "tool_input": {"file_path": "...", "content": "..."}}
INPUT=$(cat)

# python3 で file_path フィールドを抽出
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# パスが空、または .md/.txt でなければ通過
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# 拡張子チェック — .md と .txt のみ対象
if ! echo "$FILE_PATH" | grep -qiE '\.(md|txt)$'; then
    exit 0
fi

# ファイル名を抽出
FILENAME=$(basename "$FILE_PATH")

# ---- 許可リスト: これらは常に許可（警告なし） ----

# 標準的なプロジェクトドキュメント
case "$FILENAME" in
    README.md|CLAUDE.md|CONTRIBUTING.md|CHANGELOG.md|MEMORY.md)
        exit 0
        ;;
esac

# ~/.claude/ 配下のファイルは全て許可
if echo "$FILE_PATH" | grep -q "$HOME/.claude/"; then
    exit 0
fi

# commands/, hooks/, memory/ ディレクトリ内のファイルは許可
if echo "$FILE_PATH" | grep -qE '/(commands|hooks|memory)/'; then
    exit 0
fi

# ---- 上記に該当しない .md/.txt → 警告を表示 ----
echo "⚠️ ドキュメントファイルの作成: ${FILENAME}。本当に必要ですか？不要なファイル増殖に注意してください。"

# 警告のみ — ブロックしない
exit 0
