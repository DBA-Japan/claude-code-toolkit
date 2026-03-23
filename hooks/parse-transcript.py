#!/usr/bin/env python3
# =============================================================================
# トランスクリプト解析スクリプト
# =============================================================================
# セッションのトランスクリプト（JSONL）を読み込み、
# Markdown形式の要約を stdout に出力する。
#
# 使い方:
#   python3 parse-transcript.py /path/to/transcript.jsonl
# =============================================================================

import sys
import json
import os
from datetime import datetime


def main():
    if len(sys.argv) < 2:
        sys.exit(0)

    transcript_path = sys.argv[1]
    if not transcript_path or not os.path.exists(transcript_path):
        sys.exit(0)

    user_messages = []
    tools_used = set()
    files_modified = set()
    assistant_snippets = []

    try:
        with open(transcript_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                # ユーザーメッセージを収集
                if entry.get("type") == "user" or entry.get("role") == "user":
                    raw = entry.get("message", {}).get("content") or entry.get("content", "")
                    if isinstance(raw, list):
                        text = " ".join(
                            c.get("text", "") for c in raw if isinstance(c, dict)
                        )
                    else:
                        text = str(raw)
                    text = text.strip()
                    if text and len(text) > 3:
                        user_messages.append(text[:200])

                # アシスタントの応答からツール使用を収集
                if entry.get("type") == "assistant":
                    content_blocks = []
                    msg = entry.get("message", {})
                    if isinstance(msg, dict) and isinstance(msg.get("content"), list):
                        content_blocks = msg["content"]

                    for block in content_blocks:
                        if not isinstance(block, dict):
                            continue
                        if block.get("type") == "tool_use":
                            tool_name = block.get("name", "")
                            if tool_name:
                                tools_used.add(tool_name)
                            inp = block.get("input", {})
                            if isinstance(inp, dict):
                                fp = inp.get("file_path", "")
                                if fp and tool_name in ("Edit", "Write", "MultiEdit"):
                                    files_modified.add(fp)
                                cmd = inp.get("command", "")
                                if cmd and tool_name == "Bash":
                                    if any(kw in cmd for kw in [
                                        "git commit", "git push", "npm", "deploy",
                                        "netlify", "curl", "mkdir"
                                    ]):
                                        files_modified.add("[cmd] " + cmd[:100])
                        elif block.get("type") == "text":
                            text = block.get("text", "")
                            if text and len(text) > 20:
                                assistant_snippets.append(text[:500])
    except Exception:
        sys.exit(0)

    # ユーザーメッセージがない場合はスキップ
    if not user_messages:
        sys.exit(0)

    # --- 要約をMarkdown形式で組み立て ---
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M:%S")

    lines = []
    lines.append("# セッション要約: {} {}".format(date_str, time_str))
    lines.append("")
    lines.append("**日時**: {} {}".format(date_str, time_str))
    lines.append("**メッセージ数**: ユーザー {} 件".format(len(user_messages)))
    lines.append("**トランスクリプト**: {}".format(transcript_path))
    lines.append("")

    # やったこと（ユーザーの依頼から抽出）
    lines.append("## やったこと（ユーザーの依頼）")
    for msg in user_messages[-10:]:
        clean = msg.replace("\n", " ").replace("\r", "")
        lines.append("- {}".format(clean))
    lines.append("")

    # 編集したファイル
    if files_modified:
        lines.append("## 編集・操作したファイル")
        for f_path in sorted(files_modified):
            lines.append("- {}".format(f_path))
        lines.append("")

    # 使ったツール
    if tools_used:
        lines.append("## 使ったツール")
        lines.append(", ".join(sorted(tools_used)))
        lines.append("")

    # アシスタントの最後の応答（次回セッションへの引き継ぎ用）
    if assistant_snippets:
        lines.append("## 最後の作業内容（次回への引き継ぎ）")
        last_snippet = assistant_snippets[-1]
        lines.append(last_snippet[:500])
        lines.append("")

    print("\n".join(lines))


if __name__ == "__main__":
    main()
