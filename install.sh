#!/bin/bash
# =============================================================================
# Claude Code Toolkit — インタラクティブインストーラー
# =============================================================================
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
MEMORY_DIR=""  # プロジェクトパスに依存するため後で設定
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# --- カラー定義 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}🔧 Claude Code Toolkit セットアップ${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =============================================================================
# Step 1: ユーザー情報収集
# =============================================================================
echo -e "${BOLD}📝 あなたについて教えてください（CLAUDE.mdに反映します）${NC}"
echo ""

read -p "  あなたの名前（ニックネーム可）: " USER_NAME
if [ -z "$USER_NAME" ]; then
  USER_NAME="User"
fi

read -p "  役割は？（例: エンジニア、マーケター、経営者、学生）: " USER_ROLE
if [ -z "$USER_ROLE" ]; then
  USER_ROLE="Claude Code ユーザー"
fi

echo ""
echo "  Claude Codeで主にやりたいことは？"
echo "    [1] Web制作・開発"
echo "    [2] ビジネス・営業"
echo "    [3] リサーチ・分析"
echo "    [4] 全部入り"
read -p "  番号を選択 (1-4): " USE_CASE
case "$USE_CASE" in
  1) USE_CASE_TEXT="Web制作・開発" ;;
  2) USE_CASE_TEXT="ビジネス・営業" ;;
  3) USE_CASE_TEXT="リサーチ・分析" ;;
  *) USE_CASE_TEXT="汎用（全領域）"; USE_CASE="4" ;;
esac

echo ""
echo -e "${BOLD}📦 オプション${NC}"

INSTALL_WEB_REF="n"
if [ "$USE_CASE" = "1" ] || [ "$USE_CASE" = "4" ]; then
  INSTALL_WEB_REF="y"
  echo -e "  ${GREEN}✅${NC} Web制作リファレンス — 用途に基づき自動選択"
else
  read -p "  Web制作リファレンス（50+ライブラリカタログ）をインストールする？ [y/N]: " INSTALL_WEB_REF
  INSTALL_WEB_REF="${INSTALL_WEB_REF:-n}"
fi

read -p "  claude-peers（マルチインスタンス連携）をインストールする？ [y/N]: " INSTALL_PEERS
INSTALL_PEERS="${INSTALL_PEERS:-n}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}確認:${NC}"
echo "  名前: $USER_NAME"
echo "  役割: $USER_ROLE"
echo "  用途: $USE_CASE_TEXT"
echo "  Web制作リファレンス: $INSTALL_WEB_REF"
echo "  claude-peers: $INSTALL_PEERS"
echo ""
read -p "この内容でインストールしますか？ [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-y}"
if [[ ! "$CONFIRM" =~ ^[yY] ]]; then
  echo "キャンセルしました。"
  exit 0
fi

echo ""
echo -e "${CYAN}⚡ インストール開始...${NC}"
echo ""

# =============================================================================
# Step 2: ディレクトリ作成
# =============================================================================
mkdir -p "$HOOKS_DIR"
mkdir -p "$COMMANDS_DIR"
mkdir -p "$CLAUDE_DIR/instincts"
mkdir -p "$CLAUDE_DIR/session-summaries"
mkdir -p "$CLAUDE_DIR/session-saves"

# =============================================================================
# Step 3: 既存設定のバックアップ
# =============================================================================
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}${BACKUP_SUFFIX}"
  echo -e "  ${GREEN}✅${NC} 既存 settings.json をバックアップ → ${SETTINGS_FILE}${BACKUP_SUFFIX}"
fi

if [ -f "$HOME/CLAUDE.md" ]; then
  cp "$HOME/CLAUDE.md" "$HOME/CLAUDE.md${BACKUP_SUFFIX}"
  echo -e "  ${GREEN}✅${NC} 既存 CLAUDE.md をバックアップ"
fi

# =============================================================================
# Step 4: Hooks インストール
# =============================================================================
echo ""
echo -e "${BOLD}📂 Hooks をインストール中...${NC}"

HOOK_COUNT=0
for hook_file in "$TOOLKIT_DIR/hooks/"*.sh "$TOOLKIT_DIR/hooks/"*.py; do
  if [ -f "$hook_file" ]; then
    filename=$(basename "$hook_file")
    cp "$hook_file" "$HOOKS_DIR/$filename"
    chmod +x "$HOOKS_DIR/$filename"
    HOOK_COUNT=$((HOOK_COUNT + 1))
  fi
done
echo -e "  ${GREEN}✅${NC} ${HOOK_COUNT}個のHookをインストール"

# =============================================================================
# Step 5: スキル（Commands）インストール
# =============================================================================
echo -e "${BOLD}📂 スキルをインストール中...${NC}"

SKILL_COUNT=0
for cmd_file in "$TOOLKIT_DIR/commands/"*.md; do
  if [ -f "$cmd_file" ]; then
    filename=$(basename "$cmd_file")
    # README.md はスキップ
    if [ "$filename" = "README.md" ]; then
      continue
    fi
    cp "$cmd_file" "$COMMANDS_DIR/$filename"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  fi
done
echo -e "  ${GREEN}✅${NC} ${SKILL_COUNT}個のスキルをインストール"

# =============================================================================
# Step 6: settings.json のマージ
# =============================================================================
echo -e "${BOLD}⚙️  settings.json を設定中...${NC}"

# Python で既存設定とマージ（既存設定を壊さない）
python3 - "$SETTINGS_FILE" "$TOOLKIT_DIR/settings/settings.json.template" << 'PYEOF'
import sys, json, os

target_path = sys.argv[1]
template_path = sys.argv[2]

# 既存設定を読み込み（なければ空）
existing = {}
if os.path.exists(target_path):
    try:
        with open(target_path) as f:
            existing = json.load(f)
    except:
        existing = {}

# テンプレートを読み込み
with open(template_path) as f:
    template = json.load(f)

# hooks をマージ（既存のhookを壊さず追加）
if "hooks" not in existing:
    existing["hooks"] = {}

for event, event_hooks in template.get("hooks", {}).items():
    if event not in existing["hooks"]:
        existing["hooks"][event] = event_hooks
    else:
        # 既存のhookコマンドを収集
        existing_cmds = set()
        for group in existing["hooks"][event]:
            for h in group.get("hooks", []):
                existing_cmds.add(h.get("command", ""))
        # テンプレートから未登録のhookだけ追加
        for group in event_hooks:
            new_hooks = []
            for h in group.get("hooks", []):
                if h.get("command", "") not in existing_cmds:
                    new_hooks.append(h)
            if new_hooks:
                existing["hooks"][event].append({
                    "matcher": group.get("matcher", ""),
                    "hooks": new_hooks
                })

# language を設定（既存があれば上書きしない）
if "language" not in existing:
    existing["language"] = template.get("language", "Japanese")

# effortLevel
if "effortLevel" not in existing:
    existing["effortLevel"] = template.get("effortLevel", "high")

with open(target_path, "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)

print("OK")
PYEOF

echo -e "  ${GREEN}✅${NC} settings.json を更新（既存設定は保持）"

# =============================================================================
# Step 7: CLAUDE.md 生成
# =============================================================================
echo -e "${BOLD}📝 CLAUDE.md を生成中...${NC}"

# テンプレートを読み込み、プレースホルダーを置換
CLAUDE_MD_CONTENT=$(cat "$TOOLKIT_DIR/CLAUDE.md.template")
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USER_NAME\}\}/$USER_NAME}"
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USER_ROLE\}\}/$USER_ROLE}"
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USE_CASE\}\}/$USE_CASE_TEXT}"

# CLAUDE.md がまだない場合のみ生成
if [ ! -f "$HOME/CLAUDE.md" ] || [ -f "$HOME/CLAUDE.md${BACKUP_SUFFIX}" ]; then
  echo "$CLAUDE_MD_CONTENT" > "$HOME/CLAUDE.md"
  echo -e "  ${GREEN}✅${NC} ~/CLAUDE.md を生成"
else
  echo "$CLAUDE_MD_CONTENT" > "$HOME/CLAUDE.md.toolkit-generated"
  echo -e "  ${YELLOW}⚠️${NC}  既存CLAUDE.mdがあるため、CLAUDE.md.toolkit-generated として保存"
fi

# =============================================================================
# Step 8: メモリシステム初期化
# =============================================================================
echo -e "${BOLD}🧠 メモリシステムを初期化中...${NC}"

# プロジェクトディレクトリのメモリ
PROJECT_MEMORY_DIR="$CLAUDE_DIR/projects/-Users-$(whoami)/memory"
mkdir -p "$PROJECT_MEMORY_DIR"

if [ ! -f "$PROJECT_MEMORY_DIR/MEMORY.md" ]; then
  cp "$TOOLKIT_DIR/memory/MEMORY.md.template" "$PROJECT_MEMORY_DIR/MEMORY.md"
  echo -e "  ${GREEN}✅${NC} MEMORY.md を初期化"
else
  echo -e "  ${YELLOW}⚠️${NC}  既存のMEMORY.mdを保持"
fi

# =============================================================================
# Step 9: Web制作リファレンス（オプション）
# =============================================================================
if [[ "$INSTALL_WEB_REF" =~ ^[yY] ]]; then
  echo -e "${BOLD}🎨 Web制作リファレンスをインストール中...${NC}"

  REF_DIR="$PROJECT_MEMORY_DIR"
  REF_COUNT=0
  for ref_file in "$TOOLKIT_DIR/references/"*.md; do
    if [ -f "$ref_file" ]; then
      filename=$(basename "$ref_file")
      if [ "$filename" = "README.md" ]; then continue; fi
      cp "$ref_file" "$REF_DIR/$filename"
      REF_COUNT=$((REF_COUNT + 1))
    fi
  done
  echo -e "  ${GREEN}✅${NC} ${REF_COUNT}個のリファレンスをインストール"
fi

# =============================================================================
# Step 10: claude-peers（オプション）
# =============================================================================
if [[ "$INSTALL_PEERS" =~ ^[yY] ]]; then
  echo -e "${BOLD}🤝 claude-peers をセットアップ中...${NC}"

  if command -v bun &> /dev/null; then
    PEERS_DIR="$HOME/claude-peers-mcp"
    if [ ! -d "$PEERS_DIR" ]; then
      git clone https://github.com/louislva/claude-peers-mcp.git "$PEERS_DIR" 2>/dev/null
      cd "$PEERS_DIR" && bun install 2>/dev/null
      cd "$TOOLKIT_DIR"
      echo -e "  ${GREEN}✅${NC} claude-peers をインストール"
    else
      echo -e "  ${YELLOW}⚠️${NC}  claude-peers は既にインストール済み"
    fi

    # MCP設定を追加
    python3 -c "
import json, os
sf = os.path.expanduser('~/.claude/settings.json')
with open(sf) as f: s = json.load(f)
if 'mcpServers' not in s: s['mcpServers'] = {}
if 'claude-peers' not in s.get('mcpServers', {}):
    s['mcpServers']['claude-peers'] = {
        'command': 'bun',
        'args': [os.path.expanduser('~/claude-peers-mcp/server.ts')]
    }
    with open(sf, 'w') as f: json.dump(s, f, indent=2, ensure_ascii=False)
    print('OK')
else:
    print('SKIP')
" 2>/dev/null
    echo -e "  ${GREEN}✅${NC} claude-peers MCP設定を追加"
  else
    echo -e "  ${RED}❌${NC} bun が見つかりません。先にインストールしてください: curl -fsSL https://bun.sh/install | bash"
  fi
fi

# =============================================================================
# Step 11: .zshrc にエイリアス追加（context-switch用）
# =============================================================================
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  if ! grep -q "claude-dev" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# Claude Code context-switch aliases" >> "$ZSHRC"
    echo 'alias claude-dev="CLAUDE_MODE=DEV claude"' >> "$ZSHRC"
    echo 'alias claude-research="CLAUDE_MODE=RESEARCH claude"' >> "$ZSHRC"
    echo 'alias claude-review="CLAUDE_MODE=REVIEW claude"' >> "$ZSHRC"
    echo -e "  ${GREEN}✅${NC} コンテキストスイッチエイリアスを .zshrc に追加"
  fi
fi

# =============================================================================
# 完了
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}✅ セットアップ完了！${NC}"
echo ""
echo "  インストール内容:"
echo "    Hooks:   ${HOOK_COUNT}個 → ~/.claude/hooks/"
echo "    スキル:  ${SKILL_COUNT}個 → ~/.claude/commands/"
echo "    設定:    settings.json 更新済み"
echo "    CLAUDE.md: 生成済み"
echo ""
echo -e "  ${BOLD}次のステップ:${NC}"
echo "    1. Claude Code を再起動（新しいセッションを開始）"
echo "    2. /context と打って、環境の状態を確認"
echo "    3. /audit と打って、セットアップの品質をチェック"
echo ""
echo "  使い方ガイド:"
echo "    $(dirname "$0")/guides/getting-started.md"
echo ""
echo -e "  ${YELLOW}💡 Tip:${NC} 既存設定のバックアップ → ${SETTINGS_FILE}${BACKUP_SUFFIX}"
echo ""
