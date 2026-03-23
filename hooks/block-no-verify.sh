#!/bin/bash
# =============================================================================
# block-no-verify.sh — PreToolUse Hook (Bash)
# gitフックのスキップ（--no-verify / --no-gpg-sign）を防止するセーフティネット
# dangerouslySkipPermissions=true 環境での安全策
# =============================================================================

# stdin から Claude Code の PreToolUse JSON を読み取る
# 形式: {"tool_name": "Bash", "tool_input": {"command": "..."}}
INPUT=$(cat)

# python3 で command フィールドを抽出
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

# コマンドが空なら何もせず通過
if [ -z "$COMMAND" ]; then
    exit 0
fi

# --no-verify または --no-gpg-sign を検出
if echo "$COMMAND" | grep -qE '\-\-no-verify|\-\-no-gpg-sign'; then
    echo "⛔ --no-verify は禁止されています。pre-commitフックをスキップせず、根本原因を修正してください。"
    exit 2
fi

# 問題なし — 通過
exit 0
