#!/usr/bin/env bash
# =============================================================================
# Claude Code Toolkit — インストーラー v2（doctor 段階制）
# =============================================================================
# 使い方:
#   bash install.sh                  対話モード
#   bash install.sh --quick          デフォルト profile (core) で即インストール
#   bash install.sh --profile web    特定 profile を指定
#   bash install.sh --add media      既存に media を追加
#   bash install.sh --plan           実行内容のプレビューだけ表示
#   bash install.sh --doctor         診断のみ
#   bash install.sh --rollback       直近バックアップに復元
#   bash install.sh --help           ヘルプ
#
# 設計原則:
#   1. doctor → plan → confirm → backup → install → verify → rollback hint
#   2. API key / brew install / claude mcp add は **doctor が案内するだけ**
#      で、install.sh では絶対に自動実行しない（信頼境界）
#   3. 既存ファイルは上書きしない（newer のものは保持）
#   4. backup は ~/.claude.backup-<timestamp>/ に丸ごと
# =============================================================================
set -eo pipefail
# set -u は使わない: bash 3.2 (macOS デフォルト) で空配列の [@] が
# unbound variable 扱いになるため。空配列は手動で if [ ${#arr[@]} -gt 0 ] で防御。

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_BASE="$HOME/.claude.backup-$(date +%Y%m%d_%H%M%S)"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# --- カラー ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
err()  { echo -e "  ${RED}✗${NC} $*"; }
info() { echo -e "  ${CYAN}→${NC} $*"; }

# =============================================================================
# 引数パース
# =============================================================================
PROFILE="core"
MODE="install"             # install / plan / doctor / rollback / add
ADD_PROFILE=""
QUICK=false
USER_NAME=""
USER_ROLE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)  PROFILE="$2"; shift 2 ;;
    --add)      MODE="add"; ADD_PROFILE="$2"; shift 2 ;;
    --plan)     MODE="plan"; shift ;;
    --doctor)   MODE="doctor"; shift ;;
    --rollback) MODE="rollback"; shift ;;
    --quick|-q) QUICK=true; shift ;;
    --name)     USER_NAME="$2"; shift 2 ;;
    --role)     USER_ROLE="$2"; shift 2 ;;
    --help|-h)
      sed -n '4,15p' "$0"
      exit 0 ;;
    *) err "不明なオプション: $1（--help で使い方）"; exit 1 ;;
  esac
done

# Profile 妥当性チェック
case "$PROFILE" in
  core|web|media|research|full) ;;
  *) err "不明な profile: $PROFILE（core/web/media/research/full）"; exit 1 ;;
esac

# =============================================================================
# Phase 1: preflight check
# =============================================================================
echo ""
echo -e "${BOLD}${CYAN}🔧 Claude Code Toolkit セットアップ${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Profile: ${BOLD}${PROFILE}${NC}"
echo -e "  Mode:    ${BOLD}${MODE}${NC}"
echo ""

echo -e "${BOLD}[1/7] Preflight check${NC}"

missing_critical=()
command -v git     >/dev/null 2>&1 && ok "git" || missing_critical+=("git")
command -v curl    >/dev/null 2>&1 && ok "curl" || missing_critical+=("curl")
command -v python3 >/dev/null 2>&1 && ok "python3" || missing_critical+=("python3")
command -v bash    >/dev/null 2>&1 && ok "bash"

if [ ${#missing_critical[@]} -gt 0 ]; then
  err "致命的不足: ${missing_critical[*]}"
  echo "    Mac: brew install ${missing_critical[*]}"
  echo "    Linux: 各 distro のパッケージマネージャから"
  exit 1
fi

# =============================================================================
# Phase 2: doctor — 環境診断
# =============================================================================
echo ""
echo -e "${BOLD}[2/7] Doctor（環境診断）${NC}"

# brew パッケージ
if command -v brew >/dev/null 2>&1; then
  ok "brew $(brew --version | head -1 | awk '{print $2}')"

  for pkg in ffmpeg whisper-cpp yt-dlp; do
    if brew list --formula 2>/dev/null | grep -q "^${pkg}$"; then
      ok "brew/$pkg"
    else
      warn "brew/$pkg 未インストール → brew install $pkg"
    fi
  done
else
  warn "brew が未インストール（macOS 推奨）"
fi

# Node / bun
command -v node >/dev/null 2>&1 && ok "node $(node --version)" || warn "node 未（一部 MCP 不可）"
command -v bun  >/dev/null 2>&1 && ok "bun $(bun --version)" || warn "bun 未（claude-peers 不可）"

# Python パッケージ
for pkg in google-genai python-pptx; do
  if python3 -c "import ${pkg//-/_}" 2>/dev/null; then
    ok "python/$pkg"
  else
    warn "python/$pkg 未 → pip install --user $pkg"
  fi
done

# API キー
for env in GEMINI_API_KEY EXA_API_KEY PERPLEXITY_API_KEY OPENAI_API_KEY; do
  if [ -n "${!env:-}" ]; then
    ok "$env (set)"
  else
    warn "$env 未設定（必要な時に doctor が案内）"
  fi
done

# Claude Code 本体
if command -v claude >/dev/null 2>&1; then
  ok "claude $(claude --version 2>/dev/null | head -1 || echo '?')"
else
  err "claude CLI が見つかりません。https://docs.anthropic.com/en/docs/claude-code から取得"
  exit 1
fi

# MCP 登録状況
if command -v claude >/dev/null 2>&1; then
  registered_mcp=$(claude mcp list 2>/dev/null | grep -c "^[a-z]" || echo 0)
  info "MCP 登録済み: $registered_mcp 件"
fi

if [ "$MODE" = "doctor" ]; then
  echo ""
  echo -e "${GREEN}診断のみで終了します。インストールは別途 'bash install.sh' で。${NC}"
  exit 0
fi

# =============================================================================
# Phase 3: plan — 何をインストールするかを表示
# =============================================================================
echo ""
echo -e "${BOLD}[3/7] Plan（実行内容のプレビュー）${NC}"

# 各 profile に対応するファイル群（空配列で初期化、set -u 対策）
INSTALL_COMMANDS=()
INSTALL_SKILLS=()
INSTALL_AGENTS=()
INSTALL_RULES=()
INSTALL_REFERENCES=()
INSTALL_GUIDES=()
INSTALL_TOOLS=()

# core: 入口 + 汎用裏方
INSTALL_COMMANDS=(doctor.md research.md pptx.md video.md ocr.md
                  audit.md context.md aside.md blueprint.md
                  save-session.md resume-session.md de-sloppify.md
                  humanizer.md chief-of-staff.md instinct.md
                  learn-eval.md context-switch.md)
INSTALL_AGENTS=(analyst.md architect.md code-reviewer.md code-simplifier.md
                critic.md debugger.md designer.md document-specialist.md
                executor.md explore.md git-master.md planner.md
                tracer.md verifier.md writer.md)
INSTALL_RULES=(safety.md factcheck.md no-dashes.md no-truncation.md
               edit-policy.md security-discipline.md)
INSTALL_REFERENCES=(canvas-lessons.md cc-skill-system-internals.md
                    cc-tool-selection-and-toolsearch.md hooks-system-internals.md
                    pwa-pitfalls-and-best-practices.md)
INSTALL_GUIDES=(getting-started.md hooks-explained.md memory-system.md
                context-management.md skill-design.md
                auto-learning-system.md instinct-and-evolution.md
                doctor-explained.md mcp-setup-full.md)
INSTALL_TOOLS=(gemini-ocr.py)

case "$PROFILE" in
  web|full)
    INSTALL_SKILLS+=(humanizer notebooklm design-extract seo-audit
                     skill-creator self-improving-agent ui-ux-lookup latent-demand
                     gsap hyperframes hyperframes-cli website-to-hyperframes)
    INSTALL_GUIDES+=(playwright-mcp.md)
    INSTALL_REFERENCES+=(typography.md design-patterns.md design-rules.md
                         color-palettes.md css-tips.md web-libraries.md
                         world-class-sites.md design-resources.md
                         canvas-optimization.md ios-safari-fixes.md
                         clip-path-section-reveals.md seamless-section-transition.md)
    ;;
esac
case "$PROFILE" in
  media|full)
    INSTALL_SKILLS+=(veo3 video)
    INSTALL_GUIDES+=(whisper-pipeline.md notebooklm-pipeline.md
                     pptx-with-python-pptx.md gemini-ocr-jp.md)
    ;;
esac
case "$PROFILE" in
  research|full)
    INSTALL_GUIDES+=(exa-cinii-jstage.md claude-peers.md)
    ;;
esac

# unique 化（重複を排除、空配列対応）
if [ ${#INSTALL_SKILLS[@]} -gt 0 ]; then
  INSTALL_SKILLS=($(printf '%s\n' "${INSTALL_SKILLS[@]}" | sort -u))
fi
if [ ${#INSTALL_GUIDES[@]} -gt 0 ]; then
  INSTALL_GUIDES=($(printf '%s\n' "${INSTALL_GUIDES[@]}" | sort -u))
fi
if [ ${#INSTALL_REFERENCES[@]} -gt 0 ]; then
  INSTALL_REFERENCES=($(printf '%s\n' "${INSTALL_REFERENCES[@]}" | sort -u))
fi

# 表示
echo "  $CLAUDE_DIR/ にインストールするもの:"
echo "    commands    : ${#INSTALL_COMMANDS[@]} files"
echo "    agents      : ${#INSTALL_AGENTS[@]} files"
echo "    skills      : ${#INSTALL_SKILLS[@]} dirs"
echo "    rules       : ${#INSTALL_RULES[@]} files"
echo "    references  : ${#INSTALL_REFERENCES[@]} files"
echo "    guides      : ${#INSTALL_GUIDES[@]} files"
echo "    tools       : ${#INSTALL_TOOLS[@]} files"
echo "    hooks       : 3 files（最小: load/save-session-summary, health-check）"
echo "    + auto-learning hooks（learning-observer, governance-capture 等 8 file）"
echo ""
echo "  変更されるファイル:"
echo "    ~/.claude/settings.json  （hooks 設定マージ）"
echo "    ~/CLAUDE.md              （存在しなければ作成、あれば .toolkit-generated）"
echo "    ~/.claude/projects/-Users-\$USER/memory/MEMORY.md  （初期化）"
echo ""
echo "  変更されない / 自動実行しないもの:"
echo "    × brew install （doctor 案内のみ）"
echo "    × pip install （doctor 案内のみ）"
echo "    × API key 設定（doctor 案内のみ）"
echo "    × claude mcp add （doctor 案内のみ）"
echo "    × ~/.zshrc 編集（doctor 案内のみ）"
echo ""

if [ "$MODE" = "plan" ]; then
  echo -e "${GREEN}プレビュー終了。実行するには 'bash install.sh --profile $PROFILE' で。${NC}"
  exit 0
fi

# =============================================================================
# Phase 4: confirm — ユーザー承認
# =============================================================================
if [ "$QUICK" = false ]; then
  echo -e "${BOLD}[4/7] Confirm${NC}"
  read -p "  この内容でインストールしますか？ [Y/n]: " CONFIRM
  CONFIRM="${CONFIRM:-y}"
  if [[ ! "$CONFIRM" =~ ^[yY] ]]; then
    echo "  キャンセルしました。"
    exit 0
  fi
fi

# =============================================================================
# Phase 5: backup
# =============================================================================
echo ""
echo -e "${BOLD}[5/7] Backup${NC}"

if [ -d "$CLAUDE_DIR" ]; then
  mkdir -p "$BACKUP_BASE"
  for f in settings.json CLAUDE.md; do
    [ -f "$CLAUDE_DIR/$f" ] && cp "$CLAUDE_DIR/$f" "$BACKUP_BASE/$f"
  done
  [ -f "$HOME/CLAUDE.md" ] && cp "$HOME/CLAUDE.md" "$BACKUP_BASE/CLAUDE.md.home"
  ok "Backup: $BACKUP_BASE"
else
  info "新規セットアップ（既存 ~/.claude/ 無し）"
fi

# =============================================================================
# Phase 6: install
# =============================================================================
echo ""
echo -e "${BOLD}[6/7] Install${NC}"

mkdir -p "$CLAUDE_DIR"/{commands,agents,skills,rules,hooks,tools}
mkdir -p "$CLAUDE_DIR"/{instincts,session-summaries,session-saves}

PROJ_MEM="$CLAUDE_DIR/projects/-Users-$(whoami)/memory"
mkdir -p "$PROJ_MEM"

# 既存をスキップしながらコピー
copy_if_new() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ]; then
    return 1  # 既存
  fi
  cp -R "$src" "$dst"
  return 0
}

# commands
n_new=0; n_skip=0
for f in "${INSTALL_COMMANDS[@]}"; do
  if [ -f "$TOOLKIT_DIR/commands/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/commands/$f" "$CLAUDE_DIR/commands/$f" \
      && n_new=$((n_new + 1)) || n_skip=$((n_skip + 1))
  fi
done
ok "commands: 新規 $n_new / 既存スキップ $n_skip"

# agents
n_new=0; n_skip=0
for f in "${INSTALL_AGENTS[@]}"; do
  if [ -f "$TOOLKIT_DIR/agents/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/agents/$f" "$CLAUDE_DIR/agents/$f" \
      && n_new=$((n_new + 1)) || n_skip=$((n_skip + 1))
  fi
done
ok "agents: 新規 $n_new / 既存スキップ $n_skip"

# skills（ディレクトリ単位）
n_new=0; n_skip=0
for d in "${INSTALL_SKILLS[@]}"; do
  if [ -d "$TOOLKIT_DIR/skills/$d" ]; then
    copy_if_new "$TOOLKIT_DIR/skills/$d" "$CLAUDE_DIR/skills/$d" \
      && n_new=$((n_new + 1)) || n_skip=$((n_skip + 1))
  fi
done
ok "skills: 新規 $n_new / 既存スキップ $n_skip"

# rules
n_new=0; n_skip=0
for f in "${INSTALL_RULES[@]}"; do
  if [ -f "$TOOLKIT_DIR/rules/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/rules/$f" "$CLAUDE_DIR/rules/$f" \
      && n_new=$((n_new + 1)) || n_skip=$((n_skip + 1))
  fi
done
ok "rules: 新規 $n_new / 既存スキップ $n_skip"

# references（プロジェクトメモリに配置）
n_new=0
for f in "${INSTALL_REFERENCES[@]}"; do
  if [ -f "$TOOLKIT_DIR/references/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/references/$f" "$PROJ_MEM/$f" \
      && n_new=$((n_new + 1)) || true
  fi
done
ok "references: 新規 $n_new"

# guides
n_new=0
for f in "${INSTALL_GUIDES[@]}"; do
  if [ -f "$TOOLKIT_DIR/guides/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/guides/$f" "$PROJ_MEM/$f" \
      && n_new=$((n_new + 1)) || true
  fi
done
ok "guides: 新規 $n_new"

# tools
n_new=0
for f in "${INSTALL_TOOLS[@]}"; do
  if [ -f "$TOOLKIT_DIR/tools/$f" ]; then
    copy_if_new "$TOOLKIT_DIR/tools/$f" "$CLAUDE_DIR/tools/$f" \
      && n_new=$((n_new + 1)) || true
  fi
done
if [ -d "$TOOLKIT_DIR/tools/cdp-scripts" ]; then
  copy_if_new "$TOOLKIT_DIR/tools/cdp-scripts" "$CLAUDE_DIR/tools/cdp-scripts" \
    && n_new=$((n_new + 1)) || true
fi
ok "tools: 新規 $n_new"

# hooks（最小3 + 自動学習5）
n_new=0; n_skip=0
HOOK_LIST=(load-session-summary.sh save-session-summary.sh health-check.sh
           learning-observer.sh governance-capture.sh block-no-verify.sh
           doc-file-warning.sh cleanup.sh suggest-compact.sh pre-compact.sh
           parse-transcript.py)
for f in "${HOOK_LIST[@]}"; do
  if [ -f "$TOOLKIT_DIR/hooks/$f" ]; then
    if copy_if_new "$TOOLKIT_DIR/hooks/$f" "$CLAUDE_DIR/hooks/$f"; then
      [[ "$f" == *.sh ]] && chmod +x "$CLAUDE_DIR/hooks/$f"
      n_new=$((n_new + 1))
    else
      n_skip=$((n_skip + 1))
    fi
  fi
done
ok "hooks: 新規 $n_new / 既存スキップ $n_skip"

# settings.json マージ
if [ -f "$TOOLKIT_DIR/settings/settings.json.template" ]; then
  python3 - "$CLAUDE_DIR/settings.json" "$TOOLKIT_DIR/settings/settings.json.template" << 'PYEOF'
import sys, json, os

target_path, template_path = sys.argv[1], sys.argv[2]
existing = {}
if os.path.exists(target_path):
    try:
        with open(target_path) as f: existing = json.load(f)
    except: existing = {}
with open(template_path) as f: template = json.load(f)

# hooks をマージ（重複コマンドは追加しない）
existing.setdefault("hooks", {})
for event, event_hooks in template.get("hooks", {}).items():
    if event not in existing["hooks"]:
        existing["hooks"][event] = event_hooks
    else:
        existing_cmds = {h.get("command", "")
                        for grp in existing["hooks"][event]
                        for h in grp.get("hooks", [])}
        for grp in event_hooks:
            new_hooks = [h for h in grp.get("hooks", [])
                         if h.get("command", "") not in existing_cmds]
            if new_hooks:
                existing["hooks"][event].append({
                    "matcher": grp.get("matcher", ""),
                    "hooks": new_hooks
                })

existing.setdefault("language", template.get("language", "Japanese"))
existing.setdefault("effortLevel", template.get("effortLevel", "high"))

with open(target_path, "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
print("OK")
PYEOF
  ok "settings.json マージ済み"
fi

# CLAUDE.md（既存があれば .toolkit-generated）
if [ -f "$TOOLKIT_DIR/CLAUDE.md.template" ]; then
  content=$(cat "$TOOLKIT_DIR/CLAUDE.md.template")
  content="${content//\{\{USER_NAME\}\}/${USER_NAME:-User}}"
  content="${content//\{\{USER_ROLE\}\}/${USER_ROLE:-Claude Code ユーザー}}"
  content="${content//\{\{USE_CASE\}\}/汎用}"

  if [ -f "$HOME/CLAUDE.md" ]; then
    echo "$content" > "$HOME/CLAUDE.md.toolkit-generated"
    warn "既存 ~/CLAUDE.md があるため CLAUDE.md.toolkit-generated として保存"
  else
    echo "$content" > "$HOME/CLAUDE.md"
    ok "~/CLAUDE.md 生成"
  fi
fi

# MEMORY.md（プロジェクトメモリ）
if [ ! -f "$PROJ_MEM/MEMORY.md" ] && [ -f "$TOOLKIT_DIR/memory/MEMORY.md.template" ]; then
  cp "$TOOLKIT_DIR/memory/MEMORY.md.template" "$PROJ_MEM/MEMORY.md"
  ok "MEMORY.md 初期化"
fi

# =============================================================================
# Phase 7: verify
# =============================================================================
echo ""
echo -e "${BOLD}[7/7] Verify${NC}"

count_dir() { find "$1" -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' '; }

ok "commands  : $(count_dir $CLAUDE_DIR/commands) files"
ok "agents    : $(count_dir $CLAUDE_DIR/agents) files"
ok "skills    : $(find $CLAUDE_DIR/skills -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ') dirs"
ok "rules     : $(count_dir $CLAUDE_DIR/rules) files"
ok "hooks     : $(count_dir $CLAUDE_DIR/hooks) files"
ok "tools     : $(count_dir $CLAUDE_DIR/tools) files"
ok "MEMORY.md : $([ -f $PROJ_MEM/MEMORY.md ] && echo exists || echo missing)"

# =============================================================================
# 完了 + 次のステップ
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}✅ セットアップ完了${NC}"
echo ""
echo -e "${BOLD}次のステップ:${NC}"
echo ""
echo "  1. CC を再起動（claude を新しいセッションで起動）"
echo "  2. 環境診断: ${CYAN}/doctor${NC}"
echo "  3. 5 つの入口コマンドを試す:"
echo "       /web-build  /research  /pptx  /video  /ocr"
echo ""
echo "  自動学習システムの確認: ${CYAN}/instinct${NC}"
echo "  全コマンド一覧:         ${CYAN}/audit skills${NC}"
echo ""
if [ -d "$BACKUP_BASE" ]; then
  echo -e "${YELLOW}💡 既存設定のバックアップ: $BACKUP_BASE${NC}"
  echo "   ロールバック: bash install.sh --rollback"
fi
echo ""
