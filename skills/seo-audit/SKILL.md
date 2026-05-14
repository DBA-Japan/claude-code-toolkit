---
name: seo-audit
description: 既存WebページのSEO監査専用。技術SEO（クローラビリティ/インデックス/CWV/モバイル）・構造化・見出し・メタ・内部リンクを診断し、優先度付きの改善提案を返す。「SEOチェック」「SEO監査」「検索順位下がった」で発火。デザイン改善や実装品質レビューは対象外（それは /de-sloppify）
---

# SEO Audit — 日本語ラッパー版

原本（Antigravity community / 2026-02-27）の日本語ラッパー。詳細ワークフローは `SKILL-en.md` と `reference/audit-framework.md`。

## 原本の思想（3段階）

1. **Scope Gate** — 監査前に必ず確認: サイト種別/SEO目的/対象市場/データアクセス有無
2. **Audit Framework** — 優先順位付き5段階
   1. Crawlability & Indexation
   2. Technical Foundations
   3. On-Page Optimization
   4. Content Quality & E-E-A-T
   5. Authority & Signals
3. **Scoring Layer** — 0-100 SEO Health Index（詳細は reference/）

## このラッパーで追加した観点

このラッパーで原本に追加・修正している点:

- **多言語サイトでは `hreflang` 検査を必須化**
  - 中規模（数十ページ）の 2-3 言語サイトを想定
  - 各言語のファイル間で言語リンクが整合しているか確認

- **Vanilla HTML+CSS 前提（任意）**
  - フレームワーク非依存の Web プロジェクト向け監査を主眼に置く
  - フレームワーク固有のSEO施策（Next.js metadata API等）は対象外。Next.js 等で運用する場合は原本（`SKILL-en.md`）の英語版を直接参照

- **Netlify 前提**
  - `_redirects` ファイル、Netlify Forms、Edge Functions の文脈で提案

- **対象外（他スキルに委譲）**
  - デザイン改善 → `/de-sloppify` or `/web-design-review`
  - UI品質 → `/apple-design-review`
  - コピー改善 → `/humanizer`
  - 実装 → `/web-build`

## 使い方

1. ユーザーが「SEOチェック」「検索順位下がった」「SEO監査」等で発火
2. **Scope Gate** を先に聞く（サイトURL・目的・Search Console アクセス有無）
3. **Audit Framework** の5段階を順に診断
4. 優先度High/Medium/Lowで改善項目を並べて返す
5. Scoring Layer は任意（ユーザーが数値化を希望した時のみ）

## 境界（混同回避）

- **対象**: 既存ページの診断・問題特定・優先順位付け
- **非対象**: 新規ページ作成、デザイン、コピー、実装
- **迷ったら**: Scope Gate を追加質問する。推測で進めない

## 出典・同期

- 元ファイル: `SKILL-en.md`
- 詳細: `reference/audit-framework.md`
- メタ: `.meta.yml`
