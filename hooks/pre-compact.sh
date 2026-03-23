#!/bin/bash
# Pre-Compact Hook: セッション状態をコンパクト前に保存
# 圧縮で失われる可能性のある情報を救済する
#
# フック種別: PreCompact
# タイミング: /compact 実行直前に自動発火
# 目的: 圧縮で消える中間状態（作業ディレクトリ、最近の変更ファイル等）を保存

# stdin を読み捨て（PreCompact は意味のあるデータを渡さない）
cat > /dev/null 2>&1 || true

STATE_FILE="$HOME/.claude/pre-compact-state.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CWD=$(pwd)

# --- 最近変更されたファイル（最大5件） ---
RECENT_FILES=""
IS_GIT=false
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  IS_GIT=true
  RECENT_FILES=$(git diff --name-only HEAD 2>/dev/null | head -5 || true)
  if [ -z "$RECENT_FILES" ]; then
    RECENT_FILES=$(git log --pretty=format: --name-only -1 2>/dev/null | head -5 || true)
  fi
fi

# Git で取れなければ filesystem から（最終更新順）
if [ -z "$RECENT_FILES" ]; then
  if [ -f /tmp/.claude-session-marker ]; then
    RECENT_FILES=$(find "$CWD" -maxdepth 2 -type f \
      -not -path '*/node_modules/*' \
      -not -path '*/.git/*' \
      -not -path '*/.*' \
      -newer /tmp/.claude-session-marker 2>/dev/null | head -5 || true)
  fi
  # マーカーがなければ直近30分以内のファイル
  if [ -z "$RECENT_FILES" ]; then
    RECENT_FILES=$(find "$CWD" -maxdepth 2 -type f \
      -not -path '*/node_modules/*' \
      -not -path '*/.git/*' \
      -mmin -30 2>/dev/null | head -5 || true)
  fi
fi

# --- Git ブランチ情報 ---
GIT_BRANCH=""
GIT_STATUS=""
if [ "$IS_GIT" = true ]; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  GIT_STATUS=$(git status --short 2>/dev/null | head -10 || true)
fi

# --- ACTIVE_PROJECTS.md から現在のアクティブプロジェクト ---
ACTIVE_PROJECTS=""
if [ -f "$HOME/Desktop/ACTIVE_PROJECTS.md" ]; then
  ACTIVE_PROJECTS=$(grep -E '^\s*[-*]' "$HOME/Desktop/ACTIVE_PROJECTS.md" 2>/dev/null | head -5 || true)
fi

# --- 最近のファイルをMarkdown箇条書きに変換 ---
RECENT_FILES_MD=""
if [ -n "$RECENT_FILES" ]; then
  RECENT_FILES_MD=$(echo "$RECENT_FILES" | while read -r f; do [ -n "$f" ] && echo "- \`$f\`"; done)
else
  RECENT_FILES_MD="- (検出なし)"
fi

# --- Git状態をMarkdownに変換 ---
GIT_STATUS_MD=""
if [ -n "$GIT_STATUS" ]; then
  GIT_STATUS_MD=$(printf '```\n%s\n```' "$GIT_STATUS")
else
  GIT_STATUS_MD="(変更なし or Git外)"
fi

# --- アクティブプロジェクトをMarkdownに ---
ACTIVE_PROJECTS_MD=""
if [ -n "$ACTIVE_PROJECTS" ]; then
  ACTIVE_PROJECTS_MD="$ACTIVE_PROJECTS"
else
  ACTIVE_PROJECTS_MD="- (ACTIVE_PROJECTS.md なし)"
fi

# --- ファイルに書き出し（50行以内に収める） ---
cat > "$STATE_FILE" << EOF
# Pre-Compact State Snapshot
> 自動保存: ${TIMESTAMP}

## セッション情報
- **日時**: ${TIMESTAMP}
- **作業ディレクトリ**: ${CWD}
- **Git ブランチ**: ${GIT_BRANCH:-N/A}

## 最近変更されたファイル
${RECENT_FILES_MD}

## Git 変更状態
${GIT_STATUS_MD}

## アクティブプロジェクト
${ACTIVE_PROJECTS_MD}

---
*このファイルはコンパクト前に自動保存されます。圧縮後にClaudeが参照できます。*
EOF

# セッションマーカーを更新（次回の「最近のファイル」検出用）
touch /tmp/.claude-session-marker 2>/dev/null || true

exit 0
