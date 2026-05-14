#!/usr/bin/env bash
# Generate ukulele-strum style BGM (the validated good one).
# Usage: make_bgm.sh <duration_sec> <output_path>
set -e

DURATION="${1:-720}"
OUT="${2:-/tmp/bgm.mp3}"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
cd "$TMPDIR"

# C major chord (C E G simultaneously, 0.5s) + bass C3
sox -n -r 44100 -c 2 c_mid.wav synth 0.5 pluck C4 pluck E4 pluck G4 fade 0.005 0.5 0.1 2>/dev/null
sox -n -r 44100 -c 2 c_bass.wav synth 0.5 pluck C3 fade 0.005 0.5 0.1 vol 0.5 2>/dev/null
sox -m c_mid.wav c_bass.wav chord_C.wav 2>/dev/null

# G major (B D G) + bass G2
sox -n -r 44100 -c 2 g_mid.wav synth 0.5 pluck B3 pluck D4 pluck G4 fade 0.005 0.5 0.1 2>/dev/null
sox -n -r 44100 -c 2 g_bass.wav synth 0.5 pluck G2 fade 0.005 0.5 0.1 vol 0.5 2>/dev/null
sox -m g_mid.wav g_bass.wav chord_G.wav 2>/dev/null

# Am (A C E) + bass A2
sox -n -r 44100 -c 2 a_mid.wav synth 0.5 pluck A3 pluck C4 pluck E4 fade 0.005 0.5 0.1 2>/dev/null
sox -n -r 44100 -c 2 a_bass.wav synth 0.5 pluck A2 fade 0.005 0.5 0.1 vol 0.5 2>/dev/null
sox -m a_mid.wav a_bass.wav chord_A.wav 2>/dev/null

# F (F A C) + bass F2
sox -n -r 44100 -c 2 f_mid.wav synth 0.5 pluck F3 pluck A3 pluck C4 fade 0.005 0.5 0.1 2>/dev/null
sox -n -r 44100 -c 2 f_bass.wav synth 0.5 pluck F2 fade 0.005 0.5 0.1 vol 0.5 2>/dev/null
sox -m f_mid.wav f_bass.wav chord_F.wav 2>/dev/null

# Phrase: C-G-Am-F = 2sec
sox chord_C.wav chord_G.wav chord_A.wav chord_F.wav phrase.wav 2>/dev/null

# Loop to target duration (each phrase = 2s)
LOOPS=$(python3 -c "import math; print(math.ceil($DURATION / 2.0) - 1)")
sox phrase.wav -r 44100 bgm_uke.wav repeat "$LOOPS" lowpass 6000 reverb 30 50 60 100 0 0 gain -2 2>/dev/null

# To MP3
ffmpeg -y -i bgm_uke.wav -codec:a libmp3lame -b:a 192k "$OUT" 2>&1 | tail -2
echo "BGM generated: $OUT ($(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")s)"
