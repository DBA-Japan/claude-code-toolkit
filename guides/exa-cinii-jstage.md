# Exa / CiNii / J-Stage 統合リサーチ

`/research` が裏で使う 3 つのリサーチ手段を、用途別に使い分けるガイド。

## 優先順位

| 調査内容 | 第一選択 | 理由 |
|---|---|---|
| 最新ニュース・人物発信 | **Perplexity** | 鮮度命 |
| 汎用 Web 検索（企業・サービス・OSS） | **Exa** | 質と被覆率 |
| 日本語学術論文（心理学・経済学・教育・医療等） | **CiNii** | 国内学術第一 |
| 査読付き学術論文（理工系含む） | **J-Stage** | 全文 PDF 多数 |
| 海外学術 | Exa academic | 英文論文 |
| 法律・公文書 | e-Gov + WebSearch | 一次資料 |

---

## 1. Exa MCP

### 何が強いか
- 汎用 Web 検索の **品質** と **被覆率** が公式 Anthropic WebSearch より高い
- 企業調査・人物プロファイル・OSS リポジトリ調査に強い
- 検索結果に **本文サマリー** が付く（再 fetch 不要）

### セットアップ
```bash
# API key
open https://exa.ai/

# 環境変数
echo 'export EXA_API_KEY="..."' >> ~/.zshrc
source ~/.zshrc

# MCP 登録
claude mcp add --scope user exa npx -y exa-mcp
```

### 使用例

```
Exa で「2026 年 Web 制作 トレンド」を検索して、上位 5 件の本文を要約して

Exa で「Anthropic CEO Dario Amodei」をリサーチ、最近の発言を抽出
```

### コスト
従量課金（2026-05 時点）。1 検索あたり数セント。**月固定** ではない点に注意。

---

## 2. Perplexity MCP

### 何が強いか
- **鮮度**: 数時間〜数日前のイベントに強い
- Sonar Pro モデル: 検索 + 推論を統合

### セットアップ
```bash
open https://perplexity.ai/
echo 'export PERPLEXITY_API_KEY="..."' >> ~/.zshrc
claude mcp add --scope user perplexity npx -y perplexity-mcp
```

### 使用例

```
Perplexity で「今週起きた Apple の発表」をリサーチ

Perplexity で「最近 AI 業界で話題のスタートアップ」を取得
```

### 注意

⚠️ tool description が広範すぎて誤発動する場合がある。`memory/feedback_perplexity_mcp_usage_policy.md` のような明示ガードルールを作ると安全。

---

## 3. CiNii Articles（日本語学術第一）

### 何が強いか
- **国内大学・学会の論文** をほぼ網羅
- API key 不要、無料、登録不要
- XML / JSON で返ってくる
- 心理学・教育学・社会学・看護・福祉 で特に強い

### API 仕様

検索エンドポイント:
```
https://ci.nii.ac.jp/opensearch/all?q=<query>&format=json&count=20
```

主要パラメータ:
| パラメータ | 用途 |
|---|---|
| `q` | キーワード |
| `format` | `json` or `atom`（XML） |
| `count` | 件数（max 200） |
| `start` | 開始位置（ページング） |
| `lang` | `ja` or `en` |
| `from` | 開始年 |
| `until` | 終了年 |

### 使用例（Claude が叩く）

```
CiNii で「AI 教育 効果」の論文を検索して、上位 10 件のタイトルと著者を抽出
```

Claude が:
```bash
curl -s "https://ci.nii.ac.jp/opensearch/all?q=AI%20教育%20効果&format=json&count=10" | jq '.items'
```

### 全文取得
CiNii は metadata しか返さない。**全文 PDF が必要なら** 各論文の `link` URL を辿る。多くは大学リポジトリに飛ぶ。

### CiNii Books
書籍情報なら別エンドポイント:
```
https://ci.nii.ac.jp/books/opensearch/search?q=<query>&format=json
```

---

## 4. J-Stage（査読付き学術第一）

### 何が強いか
- 日本の **査読付き学術論文** の集約
- 全文 PDF を多数公開
- 理工系・医学系も豊富

### API 仕様

```
https://api.jstage.jst.go.jp/searchapi/do?service=3&text=<query>
```

サービス番号:
- `service=1`: 雑誌
- `service=2`: 巻
- `service=3`: 記事（論文）
- `service=4`: 全文

### 使用例

```
J-Stage で「機械学習 自然言語処理」の論文を 20 件取得して、抄録を比較
```

Claude が:
```bash
curl -s "https://api.jstage.jst.go.jp/searchapi/do?service=3&text=機械学習%20自然言語処理&count=20" | xmllint --format -
```

JSON 形式は無く XML 返却。`xmllint` か Python の `xml.etree.ElementTree` でパース。

---

## 統合ワークフロー（実例）

### A. 「介護分野の AI 活用について研究してる教授を探したい」

1. **CiNii** で「介護 AI」検索 → 著者を抽出
2. 著者ごとに **Exa** で経歴調査 → 所属大学 + 専門
3. **Perplexity** で「最近の発表」確認

### B. 「Web デザイントレンド 2026 の根拠を 5 つ」

1. **Exa** で「Web design trends 2026」検索（英語）
2. **WebSearch** で日本語ブログ補強
3. 信頼度の高い 5 個を抽出 + 出典 URL 並記
4. `rules/factcheck.md` 遵守、未検証なら明記

### C. 「論文を 5 本投げて、ポッドキャストで通勤中に聞きたい」

1. **CiNii** + **J-Stage** で論文 PDF 取得
2. NotebookLM に投げる（[`notebooklm-pipeline.md`](./notebooklm-pipeline.md)）
3. Audio Overview 生成 → mp3 取得 → スマホで再生

---

## アンチパターン

### ❌ 検索 = LLM 出力で済ます
LLM の出力は学習時点の古い情報。最新が必要なら **必ず** 検索 MCP を経由。

### ❌ 1 ソースで結論を出す
3 ソース照合が最低限。`rules/factcheck.md` 遵守。

### ❌ Perplexity を「汎用検索」として使う
Perplexity は鮮度命の場合だけ。汎用は Exa。

### ❌ CiNii の metadata だけで論文を引用する
抄録だけ読んで本文を読まないと誤読する。全文 PDF を確認。

---

## 関連

- [`../commands/research.md`](../commands/research.md)
- [`mcp-setup-full.md`](./mcp-setup-full.md)
- [`../rules/factcheck.md`](../rules/factcheck.md)
- CiNii: https://ci.nii.ac.jp/
- J-Stage: https://www.jstage.jst.go.jp/
