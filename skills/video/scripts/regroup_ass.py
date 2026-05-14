#!/usr/bin/env python3
# ASS regrouping: word-level -> phrase-level (Japanese-aware)
import re
import sys
from pathlib import Path

INPUT = Path(sys.argv[1])
OUTPUT = Path(sys.argv[2])

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


src = INPUT.read_text(encoding="utf-8")
header_lines = []
events = []
in_events = False

for line in src.splitlines():
    if line.startswith("[Events]"):
        in_events = True
        header_lines.append(line)
        continue
    if in_events and line.startswith("Format:"):
        header_lines.append(line)
        continue
    if in_events and line.startswith("Dialogue:"):
        parts = line.split(",", 9)
        if len(parts) < 10:
            continue
        s = parse_t(parts[1])
        e = parse_t(parts[2])
        word = parts[9]
        events.append((s, e, word))
        continue
    if not in_events:
        header_lines.append(line)


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


phrases = []
buf = []
prev_end = None

for s, e, w in events:
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

out_lines = list(header_lines)
for idx, (s, e, t) in enumerate(final):
    out_lines.append(
        f"Dialogue: {idx},{fmt_t(s)},{fmt_t(e)},Default,,0,0,0,,{t}"
    )

OUTPUT.write_text("\n".join(out_lines), encoding="utf-8")
print(f"phrases: {len(final)} (from {len(events)} words)")
print(f"written: {OUTPUT}")
