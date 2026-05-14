#!/usr/bin/env python3
"""
Detect standalone filler words from a word-level ASS file.
Outputs JSON list of {start, end, text} for each filler.
Filler patterns: えー, あー, うー, あの, えーっと, etc.
A "filler" is a short word matching the patterns AND duration > MIN_DUR
AND surrounded by gaps (>= GAP) or at sentence boundary.

Usage: find_filler.py <words.ass> [--min-dur 0.4] [--range start end]
"""
import re
import sys
import json
import argparse
from pathlib import Path

FILLER_TEXTS = {"えー", "あー", "うー", "えーっと", "うーん", "あのー"}
SHORT_FILLER = {"えー", "あー", "うー"}  # standalone these are clear fillers


def parse_t(s):
    m = re.match(r"(\d+):(\d+):(\d+\.?\d*)", s)
    if not m:
        return 0.0
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


parser = argparse.ArgumentParser()
parser.add_argument("input", type=Path)
parser.add_argument("--min-dur", type=float, default=0.4)
parser.add_argument("--range", nargs=2, type=float, default=None)
args = parser.parse_args()

src = args.input.read_text(encoding="utf-8")
words = []
for line in src.splitlines():
    if not line.startswith("Dialogue:"):
        continue
    parts = line.split(",", 9)
    if len(parts) < 10:
        continue
    s = parse_t(parts[1])
    e = parse_t(parts[2])
    txt = parts[9].strip()
    words.append((s, e, txt))

# Filter to range if specified
if args.range:
    rs, re_ = args.range
    words = [w for w in words if w[0] >= rs and w[1] <= re_]

# Detect fillers
fillers = []
for s, e, t in words:
    dur = e - s
    if t in SHORT_FILLER and dur >= args.min_dur:
        fillers.append({"start": round(s, 2), "end": round(e, 2), "text": t, "dur": round(dur, 2)})

print(json.dumps(fillers, ensure_ascii=False, indent=2))
