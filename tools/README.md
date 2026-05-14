# tools/

ヘルパースクリプト集。`install.sh` が `~/.claude/tools/` にコピーします。

## 含まれるもの

| Tool | 用途 | 依存 |
|---|---|---|
| `gemini-ocr.py` | 日本語 OCR（Gemini Vision API） | `pip install --user google-genai` + `GEMINI_API_KEY` |
| `cdp-scripts/` | Chrome DevTools Protocol 操作スクリプト集 | `pip install --user websockets requests` |

## 使い方

```bash
# OCR
python3 ~/.claude/tools/gemini-ocr.py path/to/image.png

# 依存セットアップ
pip install --user google-genai websockets requests
export GEMINI_API_KEY="..."   # ~/.zshrc に追記推奨
```

API キーは絶対にこのフォルダに置かないでください。`~/.zshrc` か `~/.claude/.env` の環境変数経由で渡します。
