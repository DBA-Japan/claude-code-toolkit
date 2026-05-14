#!/usr/bin/env python3
"""
Build a portrait short ASS from word-level captions.
- Filter to source range [start, end] in cut.mp4 timestamps
- Optionally remove specific filler word cuts (list of "えー" timestamps)
- Apply speed-up
- Add 3-line title overlay (Title style)
- Output portrait 1080x1920 ASS

Usage:
  build_short.py <words.ass> <out.ass> <start_sec> <end_sec> <speed> <title> [<filler_t1>...]
"""
import re
import sys
import json
from pathlib import Path

WORDS_ASS = Path(sys.argv[1])
OUTPUT = Path(sys.argv[2])
SRC_START = float(sys.argv[3])
SRC_END = float(sys.argv[4])
SPEED = float(sys.argv[5])
TITLE = sys.argv[6]
FILLER_CUTS_JSON = sys.argv[7] if len(sys.argv) > 7 else "[]"
FILLER_CUTS = json.loads(FILLER_CUTS_JSON)  # [[s,e], [s,e], ...]

NL = chr(92) + "N"

MAX_CHARS = 22
SOFT_MAX = 16
MIN_CHARS = 4
MAX_DUR = 4.0
MIN_DUR = 0.7
GAP_SEC = 0.45
WRAP_AT = 13

HARD_BREAK = set("、。！？!?…")
SOFT_BREAK_PARTICLE = set("はがをにでとのもへやよねな")
KATAKANA_RE = re.compile(r"[゠-ヿー]")


def parse_t(s):
    m = re.match(r"(\d+):(\d+):(\d+\.?\d*)", s)
    if not m:
        return 0.0
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


def fmt_t(t):
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = t - h * 3600 - m * 60
    return f"{h}:{m:02d}:{s:05.2f}"


def is_katakana(ch):
    return bool(KATAKANA_RE.match(ch)) if ch else False


def wrap_two_lines(text):
    if len(text) <= WRAP_AT:
        return text
    n = len(text)
    mid = n // 2
    for offset in range(0, 4):
        for sign in (1, -1):
            i = mid + offset * sign
            if 0 < i < n and text[i] in HARD_BREAK:
                return text[:i + 1] + NL + text[i + 1:]
    for offset in range(0, 6):
        for sign in (1, -1):
            i = mid + offset * sign
            if 0 < i < n and text[i] in SOFT_BREAK_PARTICLE:
                if i > 0 and is_katakana(text[i - 1]) and is_katakana(text[i]):
                    continue
                return text[:i + 1] + NL + text[i + 1:]
    for offset in range(0, 6):
        for sign in (1, -1):
            i = mid + offset * sign
            if 0 < i < n and is_katakana(text[i - 1]) and not is_katakana(text[i]):
                return text[:i] + NL + text[i:]
    return text[:mid] + NL + text[mid:]


# Read words
src = WORDS_ASS.read_text(encoding="utf-8")
words = []
for line in src.splitlines():
    if not line.startswith("Dialogue:"):
        continue
    parts = line.split(",", 9)
    if len(parts) < 10:
        continue
    s = parse_t(parts[1])
    e = parse_t(parts[2])
    txt = parts[9]
    words.append((s, e, txt))

# Filter to source range
filtered = [(s, e, t) for s, e, t in words if s >= SRC_START and e <= SRC_END]


# Apply filler cuts: remove words within each cut, shift later words earlier
def apply_filler_cuts(words, cuts):
    cuts_sorted = sorted(cuts, key=lambda c: c[0])
    out = []
    cumulative_shift = 0.0
    cut_idx = 0
    for s, e, t in words:
        # Apply any cuts that ended before this word
        while cut_idx < len(cuts_sorted) and cuts_sorted[cut_idx][1] <= s:
            cumulative_shift += cuts_sorted[cut_idx][1] - cuts_sorted[cut_idx][0]
            cut_idx += 1
        # Skip words that fall within active cuts
        in_cut = False
        for cs, ce in cuts_sorted:
            if s >= cs and e <= ce:
                in_cut = True
                break
        if in_cut:
            continue
        out.append((s - cumulative_shift, e - cumulative_shift, t))
    return out


adjusted = apply_filler_cuts(filtered, FILLER_CUTS)
total_cut_dur = sum(ce - cs for cs, ce in FILLER_CUTS)

# Shift to 0
shifted = [(s - SRC_START, e - SRC_START, t) for s, e, t in adjusted]

# Apply speed
sped = [(s / SPEED, e / SPEED, t) for s, e, t in shifted]

# Regroup
phrases = []
buf = []
prev_end = None


def flush_phrase(buf, out):
    if not buf:
        return
    s = buf[0][0]
    e = buf[-1][1]
    text = "".join(w[2] for w in buf).strip()
    if not text:
        return
    if e - s < MIN_DUR:
        e = s + MIN_DUR
    out.append((s, e, text))


for s, e, w in sped:
    if prev_end is not None and s - prev_end > GAP_SEC and buf:
        flush_phrase(buf, phrases)
        buf = []
    buf.append((s, e, w))
    cur_text = "".join(x[2] for x in buf)
    cur_dur = buf[-1][1] - buf[0][0]
    last_char = w.strip()[-1] if w.strip() else ""

    if last_char in HARD_BREAK:
        flush_phrase(buf, phrases)
        buf = []
        prev_end = e
        continue

    if len(cur_text) >= SOFT_MAX:
        if last_char and is_katakana(last_char):
            pass
        elif last_char in SOFT_BREAK_PARTICLE:
            flush_phrase(buf, phrases)
            buf = []
        elif len(cur_text) >= MAX_CHARS or cur_dur >= MAX_DUR:
            flush_phrase(buf, phrases)
            buf = []
    prev_end = e

flush_phrase(buf, phrases)

merged = []
i = 0
while i < len(phrases):
    s, e, t = phrases[i]
    if len(t) < MIN_CHARS and i + 1 < len(phrases):
        ns, ne, nt = phrases[i + 1]
        if ns - e < 0.3 and len(t + nt) <= MAX_CHARS + 4:
            merged.append((s, ne, t + nt))
            i += 2
            continue
    merged.append((s, e, t))
    i += 1

final = [(s, e, wrap_two_lines(t)) for s, e, t in merged]

total_dur = (SRC_END - SRC_START - total_cut_dur) / SPEED

# Title: split into 3 lines if not already with NL
title_text = TITLE.replace("\n", NL)

# Compose ASS
title_style = (
    "Style: Title,Hiragino Sans W8,118,"
    "&H0000D7FF,&H0000D7FF,&H00000000,&HE6000000,"
    "1,0,0,0,100,100,0,0,3,16,5,8,30,30,120,1"
)
default_style = (
    "Style: Default,Hiragino Sans W7,86,"
    "&H00FFFFFF,&H00FFFFFF,&H00000000,&HE0000000,"
    "1,0,0,0,100,100,0,0,1,7,3,2,60,60,160,1"
)

ass = []
ass.append("[Script Info]")
ass.append("ScriptType: v4.00+")
ass.append("PlayResX: 1080")
ass.append("PlayResY: 1920")
ass.append("ScaledBorderAndShadow: yes")
ass.append("")
ass.append("[V4+ Styles]")
ass.append(
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, "
    "OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, "
    "ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, "
    "Alignment, MarginL, MarginR, MarginV, Encoding"
)
ass.append(default_style)
ass.append(title_style)
ass.append("")
ass.append("[Events]")
ass.append(
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, "
    "MarginV, Effect, Text"
)
ass.append(
    f"Dialogue: 1,0:00:00.00,{fmt_t(total_dur)},Title,,0,0,0,,{title_text}"
)
for idx, (s, e, t) in enumerate(final):
    ass.append(
        f"Dialogue: 0,{fmt_t(s)},{fmt_t(e)},Default,,0,0,0,,{t}"
    )

OUTPUT.write_text("\n".join(ass), encoding="utf-8")
print(f"phrases: {len(final)}")
print(f"target duration: {total_dur:.2f}s")
print(f"written: {OUTPUT}")

# Output JSON metadata for ffmpeg orchestration
meta = {
    "source_start": SRC_START,
    "source_end": SRC_END,
    "filler_cuts": FILLER_CUTS,
    "speed": SPEED,
    "expected_duration": total_dur,
    "phrase_count": len(final),
}
meta_path = OUTPUT.with_suffix(".meta.json")
meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
print(f"meta: {meta_path}")
