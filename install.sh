#!/bin/bash
# =============================================================================
# Claude Code Toolkit — インストーラー
# =============================================================================
# 使い方:
#   対話モード:  bash install.sh
#   クイック:    bash install.sh --quick
#   カスタム:    bash install.sh --quick --name "太郎" --role "エンジニア" --use-case 1
#   全部入り:    bash install.sh --quick --all
# =============================================================================
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# --- カラー定義 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# 引数パース
# =============================================================================
QUICK_MODE=false
ALL_MODE=false
USER_NAME=""
USER_ROLE=""
USE_CASE=""
INSTALL_WEB_REF=""
INSTALL_PEERS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --quick|-q)       QUICK_MODE=true; shift ;;
    --all|-a)         ALL_MODE=true; QUICK_MODE=true; shift ;;
    --name)           USER_NAME="$2"; shift 2 ;;
    --role)           USER_ROLE="$2"; shift 2 ;;
    --use-case)       USE_CASE="$2"; shift 2 ;;
    --web-ref)        INSTALL_WEB_REF="$2"; shift 2 ;;
    --peers)          INSTALL_PEERS="$2"; shift 2 ;;
    --help|-h)
      echo "使い方:"
      echo "  bash install.sh                対話モード"
      echo "  bash install.sh --quick        デフォルト設定でインストール"
      echo "  bash install.sh --all          全コンポーネント入り"
      echo ""
      echo "オプション:"
      echo "  --name NAME       名前（CLAUDE.mdに反映）"
      echo "  --role ROLE       役割（例: エンジニア、学生）"
      echo "  --use-case N      1=Web制作 2=ビジネス 3=リサーチ 4=全部"
      echo "  --web-ref y/n     Web制作リファレンス"
      echo "  --peers y/n       claude-peers"
      exit 0 ;;
    *) echo "不明なオプション: $1（--help で使い方を表示）"; exit 1 ;;
  esac
done

# --all は全部入り
if [ "$ALL_MODE" = true ]; then
  USE_CASE="${USE_CASE:-4}"
  INSTALL_WEB_REF="${INSTALL_WEB_REF:-y}"
  INSTALL_PEERS="${INSTALL_PEERS:-y}"
fi

echo ""
echo -e "${CYAN}${BOLD}🔧 Claude Code Toolkit セットアップ${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =============================================================================
# Step 1: ユーザー情報収集（対話 or クイック）
# =============================================================================
if [ "$QUICK_MODE" = true ]; then
  # --- クイックモード: デフォルト値を使用 ---
  USER_NAME="${USER_NAME:-User}"
  USER_ROLE="${USER_ROLE:-Claude Code ユーザー}"
  USE_CASE="${USE_CASE:-4}"
  INSTALL_WEB_REF="${INSTALL_WEB_REF:-y}"
  INSTALL_PEERS="${INSTALL_PEERS:-n}"

  case "$USE_CASE" in
    1) USE_CASE_TEXT="Web制作・開発" ;;
    2) USE_CASE_TEXT="ビジネス・営業" ;;
    3) USE_CASE_TEXT="リサーチ・分析" ;;
    *) USE_CASE_TEXT="汎用（全領域）"; USE_CASE="4" ;;
  esac

  echo -e "${BOLD}⚡ クイックモード${NC}"
  echo "  名前: $USER_NAME"
  echo "  役割: $USER_ROLE"
  echo "  用途: $USE_CASE_TEXT"
  echo "  Web制作リファレンス: $INSTALL_WEB_REF"
  echo "  claude-peers: $INSTALL_PEERS"
  echo ""

else
  # --- 対話モード ---
  echo -e "${BOLD}📝 あなたについて教えてください（CLAUDE.mdに反映します）${NC}"
  echo ""

  if [ -z "$USER_NAME" ]; then
    read -p "  あなたの名前（ニックネーム可）: " USER_NAME
  fi
  USER_NAME="${USER_NAME:-User}"

  if [ -z "$USER_ROLE" ]; then
    read -p "  役割は？（例: エンジニア、マーケター、経営者、学生）: " USER_ROLE
  fi
  USER_ROLE="${USER_ROLE:-Claude Code ユーザー}"

  if [ -z "$USE_CASE" ]; then
    echo ""
    echo "  Claude Codeで主にやりたいことは？"
    echo "    [1] Web制作・開発"
    echo "    [2] ビジネス・営業"
    echo "    [3] リサーチ・分析"
    echo "    [4] 全部入り"
    read -p "  番号を選択 (1-4): " USE_CASE
  fi
  case "$USE_CASE" in
    1) USE_CASE_TEXT="Web制作・開発" ;;
    2) USE_CASE_TEXT="ビジネス・営業" ;;
    3) USE_CASE_TEXT="リサーチ・分析" ;;
    *) USE_CASE_TEXT="汎用（全領域）"; USE_CASE="4" ;;
  esac

  echo ""
  echo -e "${BOLD}📦 オプション${NC}"

  if [ -z "$INSTALL_WEB_REF" ]; then
    if [ "$USE_CASE" = "1" ] || [ "$USE_CASE" = "4" ]; then
      INSTALL_WEB_REF="y"
      echo -e "  ${GREEN}✅${NC} Web制作リファレンス — 用途に基づき自動選択"
    else
      read -p "  Web制作リファレンス（50+ライブラリカタログ）をインストールする？ [y/N]: " INSTALL_WEB_REF
      INSTALL_WEB_REF="${INSTALL_WEB_REF:-n}"
    fi
  fi

  if [ -z "$INSTALL_PEERS" ]; then
    read -p "  claude-peers（マルチインスタンス連携）をインストールする？ [y/N]: " INSTALL_PEERS
    INSTALL_PEERS="${INSTALL_PEERS:-n}"
  fi

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
fi

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
BACKED_UP_SETTINGS=false
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}${BACKUP_SUFFIX}"
  BACKED_UP_SETTINGS=true
  echo -e "  ${GREEN}✅${NC} 既存 settings.json をバックアップ"
fi

BACKED_UP_CLAUDE_MD=false
if [ -f "$HOME/CLAUDE.md" ]; then
  cp "$HOME/CLAUDE.md" "$HOME/CLAUDE.md${BACKUP_SUFFIX}"
  BACKED_UP_CLAUDE_MD=true
  echo -e "  ${GREEN}✅${NC} 既存 CLAUDE.md をバックアップ"
fi

# =============================================================================
# Step 4: Hooks インストール（既存は上書きしない）
# =============================================================================
echo ""
echo -e "${BOLD}📂 Hooks をインストール中...${NC}"

HOOK_COUNT=0
HOOK_SKIP=0
for hook_file in "$TOOLKIT_DIR/hooks/"*.sh "$TOOLKIT_DIR/hooks/"*.py; do
  if [ -f "$hook_file" ]; then
    filename=$(basename "$hook_file")
    if [ "$filename" = "README.md" ]; then continue; fi
    target="$HOOKS_DIR/$filename"
    if [ -f "$target" ]; then
      HOOK_SKIP=$((HOOK_SKIP + 1))
    else
      cp "$hook_file" "$target"
      chmod +x "$target"
      HOOK_COUNT=$((HOOK_COUNT + 1))
    fi
  fi
done

if [ "$HOOK_SKIP" -gt 0 ]; then
  echo -e "  ${GREEN}✅${NC} ${HOOK_COUNT}個の新規Hook追加（${HOOK_SKIP}個は既存のため保持）"
else
  echo -e "  ${GREEN}✅${NC} ${HOOK_COUNT}個のHookをインストール"
fi

# =============================================================================
# Step 5: スキル（Commands）インストール（既存は上書きしない）
# =============================================================================
echo -e "${BOLD}📂 スキルをインストール中...${NC}"

SKILL_COUNT=0
SKILL_SKIP=0
for cmd_file in "$TOOLKIT_DIR/commands/"*.md; do
  if [ -f "$cmd_file" ]; then
    filename=$(basename "$cmd_file")
    if [ "$filename" = "README.md" ]; then continue; fi
    target="$COMMANDS_DIR/$filename"
    if [ -f "$target" ]; then
      SKILL_SKIP=$((SKILL_SKIP + 1))
    else
      cp "$cmd_file" "$target"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
  fi
done

if [ "$SKILL_SKIP" -gt 0 ]; then
  echo -e "  ${GREEN}✅${NC} ${SKILL_COUNT}個の新規スキル追加（${SKILL_SKIP}個は既存のため保持）"
else
  echo -e "  ${GREEN}✅${NC} ${SKILL_COUNT}個のスキルをインストール"
fi

# =============================================================================
# Step 6: settings.json のマージ（既存を壊さない）
# =============================================================================
echo -e "${BOLD}⚙️  settings.json を設定中...${NC}"

python3 - "$SETTINGS_FILE" "$TOOLKIT_DIR/settings/settings.json.template" << 'PYEOF'
import sys, json, os

target_path = sys.argv[1]
template_path = sys.argv[2]

existing = {}
if os.path.exists(target_path):
    try:
        with open(target_path) as f:
            existing = json.load(f)
    except:
        existing = {}

with open(template_path) as f:
    template = json.load(f)

if "hooks" not in existing:
    existing["hooks"] = {}

for event, event_hooks in template.get("hooks", {}).items():
    if event not in existing["hooks"]:
        existing["hooks"][event] = event_hooks
    else:
        existing_cmds = set()
        for group in existing["hooks"][event]:
            for h in group.get("hooks", []):
                existing_cmds.add(h.get("command", ""))
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

if "language" not in existing:
    existing["language"] = template.get("language", "Japanese")

if "effortLevel" not in existing:
    existing["effortLevel"] = template.get("effortLevel", "high")

with open(target_path, "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)

print("OK")
PYEOF

echo -e "  ${GREEN}✅${NC} settings.json を更新（既存設定は保持）"

# =============================================================================
# Step 7: CLAUDE.md 生成（既存がある場合は別ファイルに保存）
# =============================================================================
echo -e "${BOLD}📝 CLAUDE.md を生成中...${NC}"

CLAUDE_MD_CONTENT=$(cat "$TOOLKIT_DIR/CLAUDE.md.template")
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USER_NAME\}\}/$USER_NAME}"
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USER_ROLE\}\}/$USER_ROLE}"
CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT//\{\{USE_CASE\}\}/$USE_CASE_TEXT}"

if [ "$BACKED_UP_CLAUDE_MD" = true ]; then
  echo "$CLAUDE_MD_CONTENT" > "$HOME/CLAUDE.md.toolkit-generated"
  echo -e "  ${YELLOW}⚠️${NC}  既存CLAUDE.mdがあるため、CLAUDE.md.toolkit-generated として保存"
  echo -e "     中身を確認して、使いたい部分を既存CLAUDE.mdに追記してください"
else
  echo "$CLAUDE_MD_CONTENT" > "$HOME/CLAUDE.md"
  echo -e "  ${GREEN}✅${NC} ~/CLAUDE.md を生成"
fi

# =============================================================================
# Step 8: メモリシステム初期化
# =============================================================================
echo -e "${BOLD}🧠 メモリシステムを初期化中...${NC}"

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
      target="$REF_DIR/$filename"
      if [ ! -f "$target" ]; then
        cp "$ref_file" "$target"
        REF_COUNT=$((REF_COUNT + 1))
      fi
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
TOTAL_NEW=$((HOOK_COUNT + SKILL_COUNT))
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}✅ セットアップ完了！${NC}"
echo ""
echo "  インストール内容:"
echo "    Hooks:   ${HOOK_COUNT}個 → ~/.claude/hooks/"
echo "    スキル:  ${SKILL_COUNT}個 → ~/.claude/commands/"
echo "    設定:    settings.json 更新済み"
if [ "$BACKED_UP_CLAUDE_MD" = true ]; then
  echo "    CLAUDE.md: toolkit-generated として保存（既存を保持）"
else
  echo "    CLAUDE.md: 生成済み"
fi
echo ""
echo -e "  ${BOLD}次のステップ:${NC}"
echo "    Claude Code を再起動してください（新しいセッションを開始）"
echo ""
if [ "$BACKED_UP_SETTINGS" = true ]; then
  echo -e "  ${YELLOW}💡${NC} 既存設定のバックアップ → ${SETTINGS_FILE}${BACKUP_SUFFIX}"
fi
if [ "$BACKED_UP_CLAUDE_MD" = true ]; then
  echo -e "  ${YELLOW}💡${NC} 既存CLAUDE.mdのバックアップ → ~/CLAUDE.md${BACKUP_SUFFIX}"
fi
echo ""
