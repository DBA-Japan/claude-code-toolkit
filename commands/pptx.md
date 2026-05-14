# PPTX（python-pptx 制作ハブ）

提案資料・プレゼン・スライドを **python-pptx** で生成する汎用コマンド。

## 起動

```
/pptx                # 対話形式（ユーザーに用途・スライド数・配色等をヒアリング）
/pptx new            # ゼロから新規
/pptx extend <path>  # 既存 PPTX に章追加
/pptx review <path>  # 既存 PPTX の品質チェック（フォント・コントラスト・余白）
```

引数: $ARGUMENTS

## 設計原則

`references/feedback_pptx_extension_recipe.md` を必読。

### 鉄則

1. **既存 PPTX の手動編集を尊重する**。「一から作り直す」は最終手段。python-pptx で既存ファイルを読み込んで部分追加するパッチ方式が基本
2. **スライドサイズは 16:9（13.333 × 7.5 inch）を既定**
3. **フォント**: 日本語は「游ゴシック」「Noto Sans JP」を第一候補。AI 臭を出さないため等幅・タイポラフィ階層を意識
4. **コントラスト**: WCAG AA（4.5:1 以上）を最低基準。`color: var(--surface)` の文字色流用は禁止
5. **数字の扱い**: `rules/factcheck.md` 遵守、未検証数字には「未検証」マーク
6. **ダッシュ使用禁止**: `rules/no-dashes.md` 遵守（PPTX 表示テキストも対象）

## 標準パイプライン

### 1. ヒアリング

Claude が以下を確認:
- 目的（営業提案／社内報告／教育資料／企画書）
- 対象（経営層／実務者／顧客／一般）
- スライド数（厳守）
- 配色テーマ（ブランドカラー / モダン / 落ち着き等）
- 出力先パス

### 2. アウトライン生成

章立てをユーザーに承認してもらってから本文に進む。

### 3. python-pptx 実装

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

# レイアウトはマスタースライドではなく、空白レイアウト + 手動配置を推奨
blank = prs.slide_layouts[6]

slide = prs.slides.add_slide(blank)
# テキストボックス / 図形 / 画像 を Inches 単位で精密配置
```

### 4. 検証

ユーザーに PowerPoint / Keynote で開いてもらい、フォント崩れ・はみ出し・コントラストを確認。

### 5. PDF 変換（任意）

`/doctor brew` で `libreoffice` を確認。あれば:

```bash
libreoffice --headless --convert-to pdf <input.pptx>
```

または、ユーザーが PowerPoint / Keynote で「PDF 書き出し」する。

## 依存

| 機能 | 要るもの |
|---|---|
| 基本生成 | `pip install --user python-pptx`（`/doctor python` で確認） |
| PDF 変換 | `brew install --cask libreoffice` または PowerPoint / Keynote |
| 画像処理 | `pip install --user Pillow`（透過処理等で必要時） |

## 関連

- `references/feedback_pptx_extension_recipe.md` — 大量スライド追加レシピ（必読）
- `references/feedback_pptx_layout_pitfalls.md` — レイアウトの落とし穴
- `references/feedback_slide_text_human_polish.md` — AI 生成スライドの人間推敲 13 パターン
- `rules/factcheck.md` — 統計の原典確認
- `rules/no-dashes.md` — ダッシュ使用禁止
- `rules/edit-policy.md` — 手動編集を壊さない
