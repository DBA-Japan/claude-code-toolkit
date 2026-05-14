#!/usr/bin/env bash
# Pre-flight check for yt-edit skill.
# Usage: doctor.sh
set +e

export PATH="$HOME/Library/Python/3.14/bin:$PATH"

echo "=== yt-edit doctor ==="
echo ""

PASS=0
FAIL=0
check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "✓ $label"
    PASS=$((PASS+1))
  else
    echo "✗ $label  ($cmd)"
    FAIL=$((FAIL+1))
  fi
}

check "ffmpeg"                "command -v ffmpeg"
check "ffprobe"               "command -v ffprobe"
check "mpv (字幕焼き込み用)"   "command -v mpv"
check "sox (BGM合成用)"        "command -v sox"
check "auto-editor"            "command -v auto-editor"
check "stable-ts"              "command -v stable-ts"
check "Python 3"               "command -v python3"
check "Hiragino W6 font"       "test -f '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc'"
check "Hiragino W7 font"       "test -f '/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc'"
check "Hiragino W8 font"       "test -f '/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc'"

echo ""
echo "PASS: $PASS / FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "=== 修復コマンド ==="
  echo "brew install ffmpeg mpv sox"
  echo "pip3 install --user --break-system-packages auto-editor stable-ts"
  echo "export PATH=\"\$HOME/Library/Python/3.14/bin:\$PATH\""
  exit 1
fi

# Copy fonts to /tmp for ffmpeg (libfreetypeなしでも動くようキャッシュ)
cp -n "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" /tmp/HiraginoW6.ttc 2>/dev/null
cp -n "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc" /tmp/HiraginoW7.ttc 2>/dev/null
cp -n "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc" /tmp/HiraginoW8.ttc 2>/dev/null

echo ""
echo "全部OK。yt-edit 起動できます。"
