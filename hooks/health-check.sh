#!/bin/bash
# =============================================================================
# セッション開始時ヘルスチェック
# =============================================================================
# SessionStart hook から呼ばれる。問題があれば警告を stdout に出力。
# Claude Code がこの出力をコンテキストとして取り込む。
# =============================================================================

WARNINGS=""
add_warning() { WARNINGS="${WARNINGS}  - $1\n"; }

# --- stdin読み捨て ---
cat > /dev/null

# --- 1. ディスク空き容量（10GB未満で警告） ---
DISK_FREE_KB=$(df -k / | tail -1 | awk '{print $4}')
DISK_FREE_GB=$((DISK_FREE_KB / 1024 / 1024))
if [ "$DISK_FREE_GB" -lt 10 ]; then
  add_warning "ディスク残り ${DISK_FREE_GB}GB（10GB未満）"
fi

# --- 2. メモリ（空き+非アクティブが4GB未満で警告） ---
if [ "$(uname)" = "Darwin" ]; then
  MEM_INFO=$(vm_stat 2>/dev/null)
  if [ -n "$MEM_INFO" ]; then
    PAGE_SIZE=$(sysctl -n vm.pagesize 2>/dev/null || echo 16384)
    FREE_PAGES=$(echo "$MEM_INFO" | awk '/Pages free/{gsub(/[^0-9]/,"",$3); print $3}')
    INACTIVE_PAGES=$(echo "$MEM_INFO" | awk '/Pages inactive/{gsub(/[^0-9]/,"",$3); print $3}')
    AVAIL_GB=$(( (FREE_PAGES + INACTIVE_PAGES) * PAGE_SIZE / 1024 / 1024 / 1024 ))
    if [ "$AVAIL_GB" -lt 4 ]; then
      add_warning "利用可能メモリ ${AVAIL_GB}GB（4GB未満）— 不要なアプリを閉じて"
    fi
  fi
fi

# --- 3. CCプロセス数（4つ以上で警告） ---
CC_PROCS=$(ps aux | grep "[c]laude.*node" 2>/dev/null | wc -l | tr -d ' ')
if [ "${CC_PROCS:-0}" -gt 4 ]; then
  add_warning "Claude Codeが ${CC_PROCS} プロセス起動中（多すぎ）"
fi

# --- 5. /tmp のデバッグログ肥大化（100MB超で警告） ---
TMP_SIZE=$(du -sm /tmp/claude-* 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
if [ "$TMP_SIZE" -gt 100 ]; then
  add_warning "/tmp にClaude関連ファイル ${TMP_SIZE}MB（自動削除で掃除します）"
  # 自動で掃除
  find /tmp -name "claude-*" -type f -mtime +1 -delete 2>/dev/null
fi

# --- 結果出力 ---
if [ -n "$WARNINGS" ]; then
  echo ""
  echo "=== ヘルスチェック警告 ==="
  printf "$WARNINGS"
  echo "==========================="
  echo ""
fi

exit 0
