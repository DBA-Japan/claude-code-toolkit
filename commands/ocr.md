# OCR（日本語特化 OCR）

画像 / PDF から日本語テキストを抽出する。`tools/gemini-ocr.py` を呼び出して Gemini Vision API で OCR を実行。

## 起動

```
/ocr <image_path>           # 単一画像
/ocr <folder>               # フォルダ内の画像をすべて
/ocr <pdf_path>             # PDF（ページごとに画像化してから OCR）
```

引数: $ARGUMENTS

## なぜ Gemini か

日本語 OCR では Gemini が現時点（2026 年）で最高クラスの精度。Tesseract や AWS Textract と比較しても、縦書き・ルビ・手書き・複雑レイアウトで圧倒的に強い。

詳細: `guides/gemini-ocr-jp.md`

## 依存

- `pip install --user google-genai`
- 環境変数 `GEMINI_API_KEY` または `GOOGLE_API_KEY`

API キー取得: https://aistudio.google.com/apikey

設定確認:
```bash
/doctor api
```

## 標準呼び出し

```bash
python3 ~/.claude/tools/gemini-ocr.py <image_path>
```

出力は標準出力に Markdown で。`-o <file>` でファイル保存も可能。

## ユースケース

| 用途 | 例 |
|---|---|
| スクショから本文抽出 | LINE / Slack 履歴のスクショ |
| 紙資料のデジタル化 | 手書きメモ・FAX / 古い PDF |
| OCR ベンチマーク | Tesseract と精度比較 |
| 翻訳前処理 | 多言語 OCR → 翻訳パイプライン |

## 制約

- API 料金が発生する（Gemini 2.0 / 2.5 Flash 系は安価）
- ネット接続必須
- 機密文書は社内ポリシー要確認

## 関連

- `tools/gemini-ocr.py` — 実装本体（79 行）
- `guides/gemini-ocr-jp.md` — Gemini 日本語 OCR 完全ガイド
- `rules/security-discipline.md` — 機密ファイルの取り扱い
