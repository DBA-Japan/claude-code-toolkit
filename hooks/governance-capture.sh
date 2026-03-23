#!/bin/bash
# =============================================================================
# governance-capture.sh — PreToolUse Hook (Bash)
# 危険な操作（シークレット漏洩・破壊的コマンド・権限昇格・外部送信）を検出
# ブロックはしない（exit 0）が、警告を表示し governance.log に記録
# =============================================================================

LOG_FILE="$HOME/.claude/governance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# stdin から Claude Code の PreToolUse JSON を読み取る
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

# 検出フラグ
DETECTED=0

# ログに書き込む関数
log_detection() {
    local detection_type="$1"
    local detail="$2"
    echo "🔒 ガバナンス検出: ${detection_type} — ${detail}"
    echo "[${TIMESTAMP}] ${detection_type}: ${detail}" >> "$LOG_FILE"
    echo "   コマンド: ${COMMAND}" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    DETECTED=1
}

# =============================================================================
# 1. シークレット検出
# =============================================================================

# AWS アクセスキー (AKIA で始まる20文字)
if echo "$COMMAND" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    log_detection "シークレット漏洩" "AWSアクセスキー（AKIA...）がコマンドに含まれています"
fi

# プライベートキーファイルの操作
if echo "$COMMAND" | grep -qE '(id_rsa|id_ed25519|id_ecdsa|\.pem|\.key)([ \t]|$)|BEGIN.*(PRIVATE|RSA|EC) KEY'; then
    log_detection "シークレット漏洩" "秘密鍵ファイルへのアクセスが検出されました"
fi

# トークン・パスワードの直書き
if echo "$COMMAND" | grep -qiE '(api_key|api_secret|secret_key|access_token|auth_token|password)\s*=\s*["\x27][^\s]+'; then
    log_detection "シークレット漏洩" "トークン/パスワードの平文がコマンドに含まれています"
fi

# .env ファイルの読み取り・送信
if echo "$COMMAND" | grep -qE '(cat|less|more|head|tail|curl.*-d.*@|wget).*\.env(\s|$|/)'; then
    log_detection "シークレット漏洩" ".envファイルへのアクセスが検出されました"
fi

# =============================================================================
# 2. 破壊的コマンド
# =============================================================================

# rm -rf（ルートや広範囲の削除）
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s'; then
    log_detection "破壊的コマンド" "rm -rf が検出されました。重要なファイルの削除に注意してください"
fi

# SQL破壊操作
if echo "$COMMAND" | grep -qiE '(DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;)'; then
    log_detection "破壊的コマンド" "SQL破壊操作（DROP/TRUNCATE/DELETE）が検出されました"
fi

# git force push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)(\s|$)'; then
    log_detection "破壊的コマンド" "git push --force が検出されました。リモート履歴が上書きされます"
fi

# =============================================================================
# 3. 権限昇格
# =============================================================================

# sudo
if echo "$COMMAND" | grep -qE '(^|\s|;|&&|\|)sudo\s'; then
    log_detection "権限昇格" "sudo が検出されました。管理者権限でのコマンド実行です"
fi

# chmod 777
if echo "$COMMAND" | grep -qE 'chmod\s+777'; then
    log_detection "権限昇格" "chmod 777 が検出されました。全ユーザーにフル権限が付与されます"
fi

# =============================================================================
# 4. ネットワーク外部送信（exfiltration）
# =============================================================================

# curl/wget をパイプで bash に渡す
if echo "$COMMAND" | grep -qE '(curl|wget)\s.*\|\s*(ba)?sh'; then
    log_detection "外部コード実行" "curl/wget の出力をシェルにパイプしています。信頼できないコードが実行される可能性があります"
fi

# curl で外部にファイルを送信
if echo "$COMMAND" | grep -qE 'curl\s.*(-F|--data-binary|--upload-file)\s.*@'; then
    log_detection "データ外部送信" "curl でローカルファイルを外部に送信しています"
fi

# 問題なし — 通過（検出があっても警告のみでブロックしない）
exit 0
