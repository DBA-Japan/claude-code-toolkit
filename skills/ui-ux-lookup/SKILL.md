---
name: ui-ux-lookup
description: UI UX Pro Max DB (161パレット/99UX規則/67スタイル/34 LPパターン) からの参照引き当て専用。「業種別の色」「UX規則の根拠」「LP構造パターン」を取りに行く時に使う。デザイン提案・レビュー・実装は対象外（それらは /web-build /ウェブデザイン /apple-design-review）
---

# UI UX Lookup — 参照引き当て専用スキル

**役割**: データベース問い合わせ。デザインの判断や実装はしない。

## 発火シーン

| 要求 | 引く場所 |
|---|---|
| 「ヘルスケア系の色」「SaaS の色」等 業種別パレット | `index/by-industry.json` |
| 「この UX 規則の根拠」「High severity の規則トップ」 | `index/high-severity-ux.json` |
| 「LP の鉄板構造」「ヒーロー→CTA の並び」 | `index/lp-patterns.json` |
| 全件精査（161 パレット全部見たい等） | `raw/*.csv` を直接 Read / grep |

## 引き方のフロー

1. **索引優先** (`index/*.json`) — 軽量・蒸留済・ほぼ即答
2. **生データ** (`raw/*.csv`) — 索引で見つからない時のみ grep で横断検索
3. **結果提示** — 引いたパレット/規則/パターンをユーザーに返す。**「これを使え」と推さない**（判断は /ウェブデザイン や /web-build）

## データセットアップ

データ本体は別リポ（MIT）に置かれている。ローカルに取得してから使う:

```bash
# 取得先（推奨）: ~/.claude/tools/ui-ux-db/
git clone https://github.com/nextlevelbuilder/ui-ux-pro-max-skill ~/.claude/tools/ui-ux-pro-max
mkdir -p ~/.claude/tools/ui-ux-db
cp -r ~/.claude/tools/ui-ux-pro-max/raw   ~/.claude/tools/ui-ux-db/
cp -r ~/.claude/tools/ui-ux-pro-max/index ~/.claude/tools/ui-ux-db/
```

`/doctor` を打つと、データの有無を診断し、未取得なら上記の取得コマンドを案内します。

## データパス

```
~/.claude/tools/ui-ux-db/
├── raw/           # 生 CSV（6 ファイル・260 KB）
│   ├── ux-guidelines.csv      99 規則
│   ├── colors.csv             161 パレット
│   ├── typography.csv         タイポ
│   ├── styles.csv             67 スタイル
│   ├── landing.csv            34 LP パターン
│   └── charts.csv             チャート種類
└── index/         # 蒸留 JSON（3 ファイル・71 KB）
    ├── by-industry.json       業種→代表色 即引き
    ├── high-severity-ux.json  High Severity 32 規則
    └── lp-patterns.json       34 LP 構造パターン
```

## 実例

ユーザー「ヘルスケア業界の Web サイト、どの色系統がいい？」
→ このスキル:
```bash
jq '.palettes[] | select(.industry | test("Healthcare|Senior|Care"; "i"))' \
  ~/.claude/tools/ui-ux-db/index/by-industry.json
```
→ 結果をそのまま提示。判断は `/ウェブデザイン` またはユーザー本人。

## 境界（混同回避）

- このスキルは **生成しない**
- このスキルは **レビューしない**
- このスキルは **判断しない**
- 参照するだけ

## 出典・更新

- 元リポジトリ: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill (MIT)
- 取得日: 2026-04-22
- 更新追従: 生 CSV は `raw/` に原型保存。アップデート時は `raw/` を差し替え → 索引を Python 再生成
