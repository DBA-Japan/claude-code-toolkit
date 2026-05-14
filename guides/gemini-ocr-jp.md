# Gemini OCR — 日本語特化 OCR の完全ガイド

`tools/gemini-ocr.py` の使い方と、なぜ日本語 OCR で Gemini が圧倒的に強いかの解説。

## なぜ Gemini か

日本語 OCR は英語 OCR より遥かに難しい:
- ひらがな・カタカナ・漢字の混在
- 縦書き
- ルビ（振り仮名）
- 手書きの個性
- 縦横が混在するレイアウト

2026 年現在、以下の選択肢を比較すると:

| ツール | 日本語精度 | 速度 | コスト | 縦書き | 手書き |
|---|---|---|---|---|---|
| Tesseract | △ | ◎ | 無料 | × | × |
| AWS Textract | ○ | ○ | $1.5/1000枚 | △ | △ |
| Google Vision | ◎ | ◎ | $1.5/1000枚 | ◎ | △ |
| Azure OCR | ○ | ○ | $1/1000枚 | △ | △ |
| **Gemini 2.5 Flash** | **◎+** | ○ | $0.1〜0.3/1000枚 | **◎** | **◎** |

Gemini が安く・速く・縦書きと手書きで他を圧倒。**日本語 OCR は Gemini 一択**（2026-05 時点）。

## セットアップ

```bash
# Python パッケージ
pip install --user google-genai

# API key 取得
open https://aistudio.google.com/apikey

# 環境変数設定
echo 'export GEMINI_API_KEY="..."' >> ~/.zshrc
source ~/.zshrc
```

確認:
```
/doctor api
# ✓ GEMINI_API_KEY (set)
```

## 基本の使い方

```bash
python3 ~/.claude/tools/gemini-ocr.py path/to/image.png
```

出力: 標準出力に Markdown 形式で。レイアウト保持。

```bash
# ファイル保存
python3 ~/.claude/tools/gemini-ocr.py image.png -o output.md

# フォルダ一括
for f in folder/*.png; do
  python3 ~/.claude/tools/gemini-ocr.py "$f" -o "${f%.png}.md"
done
```

## PDF 対応

PDF はページごとに画像化してから OCR:

```bash
# brew install poppler
pdftoppm -png -r 300 input.pdf page

# 全ページ OCR
for p in page-*.png; do
  python3 ~/.claude/tools/gemini-ocr.py "$p" -o "${p%.png}.md"
done

# 結合
cat page-*.md > full.md
```

## モデル選択

`gemini-ocr.py` は内部で **Gemini 2.5 Flash** を使用（デフォルト）。

| モデル | 精度 | 速度 | コスト |
|---|---|---|---|
| `gemini-2.5-flash-lite` | 高 | 最速 | 最安 |
| `gemini-2.5-flash` | 最高 | 速 | 安 |
| `gemini-2.5-pro` | 最高 | 遅 | やや高 |

ほとんどのケースで `flash` で十分。複雑なレイアウトの古文書だけ `pro`。

## ユースケース

### A. スクショからテキスト抽出

会議資料・LINE 履歴・Slack 履歴のスクショを文字化:

```bash
python3 ~/.claude/tools/gemini-ocr.py screenshot.png
```

### B. 紙資料デジタル化

手書きメモ・FAX を OCR:

```bash
# iPhone 等で撮影 → AirDrop or 共有
python3 ~/.claude/tools/gemini-ocr.py memo.jpg -o memo.md
```

### C. PDF レポート（縦書き混在）

```bash
pdftoppm -png report.pdf p -r 300
for f in p-*.png; do python3 ~/.claude/tools/gemini-ocr.py "$f" -o "${f%.png}.md"; done
cat p-*.md > report.md
```

### D. 翻訳前処理

```bash
# 1. OCR
python3 ~/.claude/tools/gemini-ocr.py jp-document.png -o jp.md

# 2. Claude に翻訳依頼
# → AI 臭が出ないよう /humanizer で仕上げ
```

## プロンプト調整

`tools/gemini-ocr.py` はデフォルトで「忠実に文字起こし、レイアウトは Markdown で再現」というプロンプト。

カスタマイズしたい場合:

```python
# tools/gemini-ocr.py を編集
PROMPT = """
以下の画像から文字を抽出してください。
- 元の改行と段落を保持
- 表は Markdown 表として再現
- 縦書きは横書きに変換
- ルビは [漢字]{ふりがな} 形式
"""
```

## アンチパターン

### ❌ 機密文書を投げる
Gemini API に送信される。**社内機密 / 顧客データ** は Tesseract（オンプレ）。

### ❌ コスト無視で大量実行
Gemini Flash は安いが、1000 ファイル投げれば数百円。**バッチ前に料金見積もり**。

### ❌ 出力を盲信
OCR は誤読する。**重要な数字・固有名詞は目視確認** が原則。

## トラブルシュート

### `ImportError: No module named 'google.genai'`
```bash
pip install --user google-genai
```

### `API key not valid`
```bash
echo $GEMINI_API_KEY   # 設定されてるか
# 新しい shell で実行しているか
```

### `Image is too large`
```bash
# Pillow でリサイズ
python3 -c "from PIL import Image; Image.open('big.png').thumbnail((2048, 2048)); Image.open('big.png').save('small.png')"
```

### 精度が低い
1. 画像の解像度を上げる（300 DPI 以上）
2. ノイズ除去（コントラスト調整）
3. `pro` モデルに切り替え

## 関連

- [`../commands/ocr.md`](../commands/ocr.md)
- [`../tools/gemini-ocr.py`](../tools/gemini-ocr.py) — 79 行の実装本体
- [`../rules/security-discipline.md`](../rules/security-discipline.md) — 機密文書取り扱い
- Gemini API docs: https://ai.google.dev/api
