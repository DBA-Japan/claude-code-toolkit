# PPTX 制作 — python-pptx で大量スライド生成

`/pptx` が裏で使う python-pptx の実装パターン集。

## なぜ python-pptx か

| 候補 | メリット | デメリット |
|---|---|---|
| PowerPoint / Keynote 手作業 | 細かい調整 | 50 枚以上は地獄 |
| Google スライド + API | ブラウザ共有 | 日本語フォント弱い |
| Reveal.js / Slidev | HTML で柔軟 | クライアントが PPTX 求めることが多い |
| **python-pptx** | 既存 PPTX 編集可、業界標準、無料 | コード量多い |

クライアント納品 + 大量生成 + 自動化なら **python-pptx 一択**。

## セットアップ

```bash
pip install --user python-pptx Pillow
```

オプション（PDF 変換）:
```bash
brew install --cask libreoffice
```

## 基本: 新規 PPTX

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN

prs = Presentation()
# 16:9 ワイド
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

# 空白レイアウト（マスタ無視で自由配置）
blank = prs.slide_layouts[6]

slide = prs.slides.add_slide(blank)

# テキストボックス追加
tb = slide.shapes.add_textbox(Inches(0.6), Inches(0.6), Inches(12), Inches(1))
tf = tb.text_frame
tf.text = "Hello"
p = tf.paragraphs[0]
p.font.name = "Noto Sans JP"
p.font.size = Pt(48)
p.font.bold = True
p.font.color.rgb = RGBColor(0x1A, 0x1A, 0x1A)

prs.save("out.pptx")
```

## 既存 PPTX に章追加（パッチ方式・推奨）

`rules/edit-policy.md` 遵守: 手動編集を尊重して、既存ファイルに `add_slide` するだけ。

```python
prs = Presentation("client-deck.pptx")
blank = prs.slide_layouts[6]

# 新規スライドを末尾に追加
new = prs.slides.add_slide(blank)
# ...本文・図形を配置
prs.save("client-deck-v2.pptx")
```

## レイアウト鉄則

| 要素 | 単位 | 推奨値 |
|---|---|---|
| スライドサイズ | inch | 16:9 = 13.333 × 7.5 |
| 余白（safe area） | inch | 左右 0.6、上下 0.5 |
| タイトル | Pt | 36〜48、Bold、Noto Sans JP |
| 本文 | Pt | 18〜24、Regular |
| キャプション | Pt | 12〜14、light gray |
| 行間 | line_spacing | 1.2〜1.4 |

## コントラスト（WCAG AA = 4.5:1 以上）

文字色と背景色のコントラスト比を保つ。**`color: var(--surface)` の文字色流用は禁止**（背景と文字が同色になる事故が起きる）。

検証:
```python
def contrast_ratio(fg_rgb, bg_rgb):
    def relative_lum(rgb):
        r, g, b = [c / 255 for c in rgb]
        r = r / 12.92 if r <= 0.03928 else ((r + 0.055) / 1.055) ** 2.4
        g = g / 12.92 if g <= 0.03928 else ((g + 0.055) / 1.055) ** 2.4
        b = b / 12.92 if b <= 0.03928 else ((b + 0.055) / 1.055) ** 2.4
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    l1 = relative_lum(fg_rgb) + 0.05
    l2 = relative_lum(bg_rgb) + 0.05
    return max(l1, l2) / min(l1, l2)
```

## 表組み

```python
table_data = [
    ["項目", "数値", "備考"],
    ["売上", "1,000", ""],
    ["原価", "600", ""],
]

rows = len(table_data)
cols = len(table_data[0])
table = slide.shapes.add_table(rows, cols,
    Inches(1), Inches(2.5), Inches(11), Inches(3)).table

for r, row_data in enumerate(table_data):
    for c, val in enumerate(row_data):
        cell = table.cell(r, c)
        cell.text = val
        for p in cell.text_frame.paragraphs:
            p.font.name = "Noto Sans JP"
            p.font.size = Pt(16 if r > 0 else 18)
            if r == 0:
                p.font.bold = True
```

## 画像配置

```python
slide.shapes.add_picture(
    "assets/hero.jpg",
    Inches(0), Inches(0),
    width=Inches(13.333), height=Inches(7.5)
)
```

**Pillow で事前リサイズ** が画質・ファイルサイズで有利:
```python
from PIL import Image
img = Image.open("orig.jpg")
img.thumbnail((1920, 1080))
img.save("compressed.jpg", quality=85)
```

## 図形（矢印 / カード / バッジ）

```python
from pptx.enum.shapes import MSO_SHAPE

# 角丸長方形（カード）
card = slide.shapes.add_shape(
    MSO_SHAPE.ROUNDED_RECTANGLE,
    Inches(1), Inches(3), Inches(4), Inches(2)
)
card.fill.solid()
card.fill.fore_color.rgb = RGBColor(0xF5, 0xF5, 0xF5)
card.line.color.rgb = RGBColor(0xE0, 0xE0, 0xE0)
card.line.width = Pt(0.5)

# 矢印
arrow = slide.shapes.add_shape(
    MSO_SHAPE.RIGHT_ARROW,
    Inches(5.2), Inches(3.5), Inches(0.8), Inches(0.6)
)
```

## PDF 変換

```bash
libreoffice --headless --convert-to pdf out.pptx
```

または PowerPoint / Keynote で「PDF 書き出し」。

## P × L マトリクス（特殊パターン）

2 軸スコアで候補をプロットする「P × L マトリクス」は提案・営業判断スライドで頻出。

```python
# 散布図 + 4 象限色分け
# 詳細は specific implementation を skill 側に書く
```

## アンチパターン

### ❌ ダッシュ使用
`rules/no-dashes.md` 遵守。スライドの表示テキストでもダッシュ禁止。

### ❌ 未検証数字を太字で配置
`rules/factcheck.md` 遵守。原典確認できない数字には「未検証」マーク、もしくは入れない。

### ❌ AI 生成文をそのまま配置
`rules/no-truncation.md` + AI 臭消し対策。Tweet サイズ化、対比、固有名詞、リアル感を意識。

### ❌ マスタースライドの設定を信用
古い PPTX を編集すると、マスタ側の設定が悪さする。**空白レイアウト + 手動配置** が安全。

## 関連

- [`../commands/pptx.md`](../commands/pptx.md)
- [`../rules/no-dashes.md`](../rules/no-dashes.md)
- [`../rules/factcheck.md`](../rules/factcheck.md)
- [`../rules/edit-policy.md`](../rules/edit-policy.md)
- python-pptx docs: https://python-pptx.readthedocs.io/
