#!/bin/bash
# Continuous Learning Observer v2.1
# 全ツール使用を観察し、パターンをJSONLに蓄積
# PreToolUse / PostToolUse 両方で呼ばれる
# 要件: 高速（<100ms）、絶対にブロックしない、append-only

INSTINCT_DIR="$HOME/.claude/instincts"
OBS_FILE="$INSTINCT_DIR/observations.jsonl"
MAX_LINES=1000

mkdir -p "$INSTINCT_DIR"

# stdinからツール情報を読む
INPUT=$(cat)

# python3でJSONをパースして1行のJSONL観察レコードを生成
RECORD=$(echo "$INPUT" | python3 -c "
import sys, json, os
from datetime import datetime

try:
    data = json.load(sys.stdin)
except:
    sys.exit(0)

tool = data.get('tool_name', 'unknown')
tool_input = data.get('tool_input', {})

# ツールごとにアクションの要約を生成
action = ''
if tool == 'Read':
    path = tool_input.get('file_path', '')
    action = f'read:{os.path.basename(path)}' if path else 'read:unknown'
elif tool == 'Write':
    path = tool_input.get('file_path', '')
    action = f'write:{os.path.basename(path)}' if path else 'write:unknown'
elif tool == 'Edit':
    path = tool_input.get('file_path', '')
    action = f'edit:{os.path.basename(path)}' if path else 'edit:unknown'
elif tool == 'Bash':
    cmd = tool_input.get('command', '')
    first_word = cmd.split()[0] if cmd.split() else 'unknown'
    action = f'bash:{first_word}'
elif tool == 'Glob':
    pattern = tool_input.get('pattern', '')
    action = f'glob:{pattern[:50]}'
elif tool == 'Grep':
    pattern = tool_input.get('pattern', '')
    action = f'grep:{pattern[:50]}'
elif tool == 'Skill':
    skill = tool_input.get('skill', '')
    action = f'skill:{skill}'
elif tool == 'WebFetch':
    url = tool_input.get('url', '')
    action = f'fetch:{url[:60]}'
elif tool == 'WebSearch':
    query = tool_input.get('query', '')
    action = f'search:{query[:60]}'
else:
    action = f'{tool.lower()}'

# 作業ディレクトリ
cwd = os.environ.get('PWD', os.getcwd())

# ファイルパスを抽出（あれば）
file_path = ''
if tool in ('Read', 'Write', 'Edit'):
    file_path = tool_input.get('file_path', '')

record = {
    'ts': datetime.now().isoformat(),
    'tool': tool,
    'action': action,
    'cwd': cwd,
}
if file_path:
    record['file'] = file_path

print(json.dumps(record, ensure_ascii=False))
" 2>/dev/null) || true

# レコードが空なら終了
if [ -z "$RECORD" ]; then
    exit 0
fi

# append-only で書き込み
echo "$RECORD" >> "$OBS_FILE" 2>/dev/null || true

# 行数チェック（MAXを超えたら古い行を削除）
LINE_COUNT=$(wc -l < "$OBS_FILE" 2>/dev/null || echo "0")
LINE_COUNT=$(echo "$LINE_COUNT" | tr -d ' ')

if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
    TAIL_LINES=800
    TEMP_FILE="$OBS_FILE.tmp.$$"
    tail -n "$TAIL_LINES" "$OBS_FILE" > "$TEMP_FILE" 2>/dev/null && \
        mv "$TEMP_FILE" "$OBS_FILE" 2>/dev/null || \
        rm -f "$TEMP_FILE" 2>/dev/null
fi

# 常に成功で終了（ブロックしない）
exit 0
