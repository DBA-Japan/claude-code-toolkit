# NotebookLM パイプライン — ノートブック・ポッドキャスト自動生成

Google NotebookLM の **完全 API** を Claude Code から叩くガイド。`skills/notebooklm` が中身を担当。

## NotebookLM とは

Google が出した「**ソース付き AI ノート**」。論文・Web ページ・PDF・動画を投げ込むと:
- ソースを引用しながら回答する
- 自動でノートブックを構築
- **AI 二人会話のポッドキャスト** を生成（質の高さで話題）
- ガイド・FAQ・タイムライン等のアーティファクト生成

Web 版: https://notebooklm.google.com/

## 認証

NotebookLM は **公式 API が公開されていない** ため、`skills/notebooklm` は **OAuth + 内部 API** を経由します。

セットアップ:

```bash
# skills/notebooklm/SKILL.md の指示に従う
# Google アカウント OAuth (Web ブラウザ経由)
```

`/doctor` で認証状態確認:
```
/doctor mcp
# notebooklm: connected (OAuth, expires 2026-XX-XX)
```

## ユースケース

### A. 学術リサーチをポッドキャスト化

```
NotebookLM で以下の論文 5 本を投げ込んで、20 分のポッドキャスト生成して:
- arxiv 2304.xxxxx
- arxiv 2305.xxxxx
- ...
```

→ skills/notebooklm が:
1. ノートブック作成
2. ソース URL を投げ込む
3. 「Generate Audio Overview」を実行
4. 完成した mp3 を取得

通勤中に最新研究を耳で聞く運用に強い。

### B. 案件資料の音声化

クライアント向け資料を BGM 付きで音声化して送る:

```
このフォルダの PDF を全部 NotebookLM に投げて、10 分のサマリーポッドキャスト作って
```

### C. 長尺動画の要約

YouTube 動画の URL を投げてサマリー:

```
https://www.youtube.com/watch?v=XXXX のトランスクリプトをノートブックに入れて、
要点を 5 個に整理した文書を生成して
```

## 構成（skills/notebooklm の内部）

```
skills/notebooklm/
├── SKILL.md
├── scripts/
│   ├── create-notebook.py     # ノートブック作成
│   ├── add-source.py          # ソース追加
│   ├── generate-podcast.py    # Audio Overview 生成
│   └── download-artifact.py   # 完成物 DL
└── references/
    └── api-quirks.md          # 非公式 API の癖まとめ
```

## アンチパターン

### ❌ 機密文書を投げる
Google サーバに送られる。NDA 案件 / クライアント機密は NG。

### ❌ ポッドキャストを「丸ごとマーケに使う」
NotebookLM の音声は「AI 二人会話」と気付かれやすい（質が高すぎて逆にバレる）。冒頭 30 秒の人間ナレーション + メイン本体 NotebookLM の **ハイブリッド** が安全。

### ❌ 無限に投げ続ける
NotebookLM は無料枠あり、超えると制限。Plus 課金（$20/月）で本格運用。

## 制限事項（2026-05 時点）

- ノートブック数: 無料 100、Plus 上限なし
- ソース/ノートブック: 50（無料）、300（Plus）
- ポッドキャスト生成: 無料は 月数本、Plus は無制限相当
- 音声の長さ: 自動調整、通常 15〜30 分

## 関連

- [`../commands/video.md`](../commands/video.md) — 動画パイプラインで連携
- [`../skills/notebooklm/SKILL.md`](../skills/notebooklm/SKILL.md)
- 公式: https://notebooklm.google.com/
- API 状況: 非公式（変更リスクあり）
