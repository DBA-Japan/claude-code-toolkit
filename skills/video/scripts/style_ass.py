#!/usr/bin/env python3
# Apply landscape-1080p or portrait-9:16 styling to a phrase ASS file.
# Usage: style_ass.py <input.ass> <output.ass> [landscape|portrait]
import sys
import re
from pathlib import Path

INPUT = Path(sys.argv[1])
OUTPUT = Path(sys.argv[2])
MODE = sys.argv[3] if len(sys.argv) > 3 else "landscape"

src = INPUT.read_text(encoding="utf-8")

if MODE == "portrait":
    play_x, play_y = 1080, 1920
    style = (
        "Style: Default,Hiragino Sans W7,90,"
        "&H00FFFFFF,&H00FFFFFF,&H00000000,&HE0000000,"
        "1,0,0,0,100,100,0,0,1,7,3,2,60,60,180,1"
    )
else:
    play_x, play_y = 1920, 1080
    style = (
        "Style: Default,Hiragino Sans W6,72,"
        "&H00FFFFFF,&H00FFFFFF,&H00000000,&HC0000000,"
        "1,0,0,0,100,100,0,0,1,4,2,2,80,80,60,1"
    )

src = re.sub(r"PlayResX: \d+", f"PlayResX: {play_x}", src)
src = re.sub(r"PlayResY: \d+", f"PlayResY: {play_y}", src)
src = re.sub(r"^Style: Default,.*$", style, src, count=1, flags=re.M)

OUTPUT.write_text(src, encoding="utf-8")
print(f"styled ({MODE}): {OUTPUT}")
