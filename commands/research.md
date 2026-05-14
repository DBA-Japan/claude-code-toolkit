# Research（リサーチ全部入り）

Web リサーチ・学術リサーチ・最新情報・競合分析を、用途に応じて最適な MCP / ツールに振り分けるハブコマンド。

## 起動

```
/research <調査内容>            # 自動振り分け
/research --web <query>         # Exa MCP（汎用 Web 検索）
/research --news <query>        # Perplexity MCP（鮮度命）
/research --library <name>      # context7 MCP（ライブラリ docs）
/research --scholar <topic>     # CiNii / J-Stage（学術論文）
/research --repo <url>          # repomix MCP（GitHub リポジトリ解析）
/research --deep <topic>        # 複数ツール並列で深掘り
```

引数: $ARGUMENTS

## 振り分けロジック

Claude は以下の優先順で適切な手段を選ぶ:

| 調査タイプ | 第一選択 | 第二選択 | 備考 |
|---|---|---|---|
| 最新ニュース・人物発信・直近イベント | Perplexity MCP | Exa MCP | 鮮度命なら Perplexity |
| 競合企業・サービス調査 | Exa MCP | WebSearch | 質と被覆率 |
| 学術論文（心理学・経済学・教育・医療） | CiNii / J-Stage | Exa academic | 日本語学術は CiNii 第一 |
| ライブラリ・SDK・API 仕様 | context7 MCP | 公式 docs | 学習データのバージョン古い対策 |
| OSS リポジトリ解析 | repomix MCP | gh CLI | コード理解の時短 |
| 人物・経営者プロファイル | Exa MCP | LinkedIn 公式 + Web | 複数ソース照合 |
| 統計・数字の原典確認 | 公式統計庁 + WebSearch | Exa | `rules/factcheck.md` 遵守 |

## 学術リサーチ（CiNii / J-Stage）

CiNii と J-Stage は API キー不要、無料、登録不要で叩ける。Claude は以下を直接 fetch する:

```
# CiNii Articles 検索（XML）
https://ci.nii.ac.jp/opensearch/all?q=<query>&format=json

# J-Stage 記事検索
https://api.jstage.jst.go.jp/searchapi/do?service=3&text=<query>
```

詳細手順: `guides/exa-cinii-jstage.md`

## ファクトチェック必須

`rules/factcheck.md` 遵守。統計・数字を引用する場合は:
1. 提示前に WebSearch / Exa で原典確認
2. 裏付けが取れない数字には「未検証」マークを付ける
3. 出典は URL または正式レポート名で特定（曖昧表記不可）

## 依存

| 機能 | 要るもの | デフォルト |
|---|---|---|
| Exa MCP | `EXA_API_KEY` | OFF |
| Perplexity MCP | `PERPLEXITY_API_KEY` | OFF |
| context7 MCP | なし（無料） | OFF |
| repomix MCP | なし（無料） | OFF |
| CiNii / J-Stage | なし（API キー不要） | ON |
| Anthropic 公式 WebSearch | CC 本体に同梱 | ON |

`/doctor api` で API キーの設定状況を確認できる。

## 出力フォーマット

```
[結論を 1-2 段落で]

## 根拠
- 出典 1: <URL> — <抜粋>
- 出典 2: <URL> — <抜粋>

## 信頼度
- 一次情報: ○ / 二次情報: × / 推測: ×
```

## 関連

- `rules/factcheck.md` — ファクトチェック絶対ルール
- `guides/exa-cinii-jstage.md` — Exa / CiNii / J-Stage 統合ガイド
- `guides/mcp-setup-full.md` — MCP セットアップ全パターン
- `references/why-claude-code-cli.md` — 公式 WebSearch との使い分け
