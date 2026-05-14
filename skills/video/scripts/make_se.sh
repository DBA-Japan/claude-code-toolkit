#!/usr/bin/env bash
# Generate basic SE pop and ding via ffmpeg sine.
# Usage: make_se.sh <output_dir>
set -e

DIR="${1:-/tmp}"

# Pop: short 880Hz burst (80ms)
ffmpeg -y -f lavfi -i "sine=frequency=880:duration=0.08,volume=0.5,afade=t=out:st=0.04:d=0.04" -ar 44100 -ac 2 "$DIR/se_pop.wav" 2>&1 | tail -1

# Ding: 1320Hz, 400ms, soft fade
ffmpeg -y -f lavfi -i "sine=frequency=1320:duration=0.4,volume=0.4,afade=t=out:st=0.05:d=0.35" -ar 44100 -ac 2 "$DIR/se_ding.wav" 2>&1 | tail -1

ls -la "$DIR/se_pop.wav" "$DIR/se_ding.wav"
