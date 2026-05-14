---
name: design-extract
description: 外部参考サイトのデザイン要素（色・タイポ・動き・間合い）を現在の案件に取り入れる手順を提示。Chrome拡張「DESIGN.md Style Extractor」でlive抽出→3分法フィルタ→日本語換算→独自アレンジのフロー。「このサイトのXいい」「この動き使いたい」「〇〇みたいにして」「この雰囲気取り入れて」で発火。新規制作全体（/web-build）や崩れ修正（/web-design-review）とは別
---

# Design Extract — 外部参考サイトからのデザイン引用ワークフロー

**役割**: ユーザーが外部サイトの具体要素を「使いたい」と言った時、Chrome拡張経由でDESIGN.mdを取得→案件適用の手順を組む。

## 発火トリガー（ユーザー発言例）

- 「〇〇のLPのXが良い」「このサイトの動きいい」
- 「これ使えるようにして」「〇〇みたいにして」
- 「この雰囲気取り入れて」「この色感いい」
- 「〇〇のアニメ参考にしたい」

## 手順（6ステップ）

### Step 1. Chrome拡張の実行を促す

ユーザーに以下を指示:
```
そのページを Chrome で開いて、ツールバーの "DESIGN.md Style Extractor" をクリック。
DESIGN.md をダウンロードしたら、プロジェクトの参考素材フォルダ
（例: <project>/design-refs/[案件名]/[サイト名].md）に保存して、パスを教えて。
```

### Step 2. 抽出ファイルを Read

受け取ったら精読:
- CSS 変数（色・余白・影・角丸）
- `font-family` / `font-weight` / `letter-spacing` / `line-height`
- アニメーション定義（`transition` / `transform` / `@keyframes`）

### Step 3. 3分法でフィルタ（必須・`getdesign-md-workflow.md` §3分法 参照）

| 層 | 採用可否 | 具体例 |
|---|---|---|
| **ユニバーサル層** | ✅ | 余白リズム・タイポ階層・動きの timing/easing |
| **業界パターン層** | ⚠️ 業界一致案件なら原理のみ | B2B SaaS 信頼感の色温度原理 |
| **企業固有ブランド層** | ❌ 禁止 | 特定社の色・ロゴ風・Visual Theme |

### Step 4. 気に入った要素だけ抽出

ユーザー発言に忠実に:
- 「動きが良い」→ transition curve と duration **だけ**
- 「LPの構造が良い」→ section順と spacing **だけ**
- 「この雰囲気」→ 色温度とフォント重み、letter-spacing **だけ**

**全部持ってこない**。気に入った部分の根拠だけ抜く。

### Step 5. 日本語換算（英語サイトからの場合）

`getdesign-md-workflow.md` §日本語変換ルール:
| 項目 | 欧文値 | 日本語換算 |
|---|---|---|
| letter-spacing | -1.4px (56px時) | -0.15〜-0.3px |
| line-height | 1.03〜1.15 | 1.2〜1.4 |
| font-weight | 300 | 350〜400 |

### Step 6. 実装（コピペ禁止・独自アレンジ必須）

「参考 → 解釈 → 独自アレンジ」の3段を経由。採用要素を案件ファイルに反映し、`extracted/[案件名]/notes.md` に**採用判断の理由**を記録。

## 保存先の推奨レイアウト

プロジェクトルートに `design-refs/` を作る運用がおすすめ:

```
<project>/design-refs/
└── [案件名]/              # 例: example-1 / example-2 / example-3
    ├── [サイト名1].md     # 抽出 DESIGN.md 原本
    ├── [サイト名2].md
    └── notes.md           # どの要素を採用したか + 根拠
```

## やってはいけない（明示）

1. **SKILL.md 出力を使う** — Chrome拡張は SKILL.md も出力できるが**絶対使わない**。既存スキル体系を汚染するリスク大
2. **丸コピー** — 3分法の「企業固有ブランド層コピー禁止」厳守
3. **業界層を自社サイトへそのまま適用** — 「オーダーメイド哲学」と矛盾。引用は原理だけ
4. **英語値そのまま適用** — letter-spacing/line-height/font-weight は必ず日本語換算

## 境界（混同回避）

| スキル/コマンド | 役割 |
|---|---|
| **design-extract**（本スキル） | **外部参考サイトからの引用ワークフロー** |
| /web-build | 新規制作全体 |
| /web-design-review | UI崩れ・不具合修正 |
| /ウェブデザイン | 方向性設計・9人議論 |
| /apple-design-review | Apple品質レビュー |
| /de-sloppify | 仕上げパス |

## 関連ドキュメント

- **AI 臭消し原則**: `references/ai-antidote.md`
- **Web 制作武器ランキング**: `references/web-weapons-ranking.md`
- **タイポグラフィ原則**: `references/typography-principles.md`

## 出典

- Chrome拡張: DESIGN.md Style Extractor - TypeUI (typeui.sh) / 2026-04-22 導入
- 既存運用: `getdesign-md-workflow.md` (2026-04-14 確立)
