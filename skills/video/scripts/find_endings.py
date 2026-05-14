#!/usr/bin/env python3
"""
Suggest natural ending points (in cut.mp4 timestamps) by scanning phrase ASS
for sentence-ending verb forms.

A "natural ending" is a phrase whose text ends with one of:
- できます / できました / できちゃいます / できちゃいました
- 成功です / 完了です / 終わりです
- ます / でした
- います / いました
- 思います / と思います
- ありがとうございました / よろしくお願いします

Usage: find_endings.py <phrase.ass> <range_start> <range_end>
Outputs JSON list of {time, text, score} sorted by score desc.
"""
import re
import sys
import json
from pathlib import Path

if len(sys.argv) < 4:
    print("usage: find_endings.py <phrase.ass> <start> <end>")
    sys.exit(1)

PHRASE_ASS = Path(sys.argv[1])
RS = float(sys.argv[2])
RE = float(sys.argv[3])

# Pattern → score (higher = stronger natural ending)
PATTERNS = [
    (re.compile(r"できちゃいます$"), 10),
    (re.compile(r"できちゃいました$"), 10),
    (re.compile(r"できます$"), 9),
    (re.compile(r"できました$"), 9),
    (re.compile(r"成功です$"), 9),
    (re.compile(r"完了です$"), 9),
    (re.compile(r"ありがとうございました$"), 8),
    (re.compile(r"よろしくお願いします$"), 8),
    (re.compile(r"と思います$"), 7),
    (re.compile(r"思います$"), 6),
    (re.compile(r"います$"), 5),
    (re.compile(r"でした$"), 5),
    (re.compile(r"ました$"), 5),
    (re.compile(r"ます$"), 4),
]

NL = chr(92) + "N"


def parse_t(s):
    m = re.match(r"(\d+):(\d+):(\d+\.?\d*)", s)
    if not m:
        return 0.0
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


src = PHRASE_ASS.read_text(encoding="utf-8")
candidates = []
for line in src.splitlines():
    if not line.startswith("Dialogue:"):
        continue
    parts = line.split(",", 9)
    if len(parts) < 10:
        continue
    s = parse_t(parts[1])
    e = parse_t(parts[2])
    txt = parts[9].replace(NL, "").strip()
    if e < RS or s > RE:
        continue
    for pat, score in PATTERNS:
        if pat.search(txt):
            candidates.append({"end_time": round(e, 2), "text": txt, "score": score, "pattern": pat.pattern})
            break

# Sort by time then score
candidates.sort(key=lambda c: (-c["score"], c["end_time"]))
print(json.dumps(candidates[:20], ensure_ascii=False, indent=2))
