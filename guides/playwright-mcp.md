# Playwright MCP — ブラウザ自動操作

Playwright MCP は Web ページの **テキスト抽出 / スクリーンショット / フォーム入力 / DOM スナップショット / 動的レンダリング** を Claude Code から直接行えます。

`/web-build` の Day 0 プロトコル（既存サイトの全テキスト抽出）の標準武器。

## セットアップ

```bash
claude mcp add --scope user playwright npx -y @microsoft/playwright-mcp
```

初回起動時に chromium をダウンロード（数百 MB、5〜10 分）。

確認:
```
/mcp
# playwright が connected
```

## よく使うツール

| ツール | 用途 |
|---|---|
| `browser_navigate` | URL に移動 |
| `browser_snapshot` | DOM スナップショット（テキスト + 構造） |
| `browser_take_screenshot` | スクショ取得 |
| `browser_evaluate` | JS 実行 |
| `browser_fill_form` | フォーム自動入力 |
| `browser_click` | クリック |
| `browser_console_messages` | コンソールエラー取得 |
| `browser_network_requests` | ネットワークリクエスト記録 |

## ユースケース 1: 既存サイトのテキスト全抽出

新規 Web 案件 Day 0 の標準手順:

```
https://example.com を開いて、本文テキストとセクション構成を抽出して
```

→ Claude が `browser_navigate` → `browser_snapshot` を実行。結果が Markdown で整形される。

これを `<project>/text-audit.md` に保存して、リファクタの起点にする。

## ユースケース 2: 競合サイト調査

```
https://stripe.com のヒーローセクションの構造を Playwright で確認して、コピーと CTA の配置を抽出して
```

→ snapshot + screenshot で構造把握。

注意: 商用利用の場合は robots.txt と利用規約を必ず確認。

## ユースケース 3: Web 化石度実機検証

「このサイト本当に古い？」を客観的に検証:

- フォントが Web フォントか
- 動きが CSS transition / GSAP / Canvas / WebGL のどれか
- レスポンシブ対応の有無
- パフォーマンス（Lighthouse 連動）

`/web-build` での競合比較で標準ワークフロー。

## ユースケース 4: フォームテスト

開発中のフォームを Playwright で実機テスト:

```
http://localhost:3000/contact を開いて、お問い合わせフォームに以下を入力:
名前: テスト太郎
メール: test@example.com
本文: テスト送信
送信ボタンを押して、送信完了画面のURLとメッセージを返して
```

## ユースケース 5: ログイン後の画面確認

Web サイトの **要ログイン領域** を扱う:

```
https://app.example.com/dashboard を開いて、ログイン画面が出たら以下で認証:
email: ${EMAIL_ENV}
password: ${PASS_ENV}
ログイン後の dashboard の主要数値を読み取って
```

⚠️ パスワードは絶対に Claude に直接渡さない。環境変数経由で。

## アンチパターン

### ❌ ログ取得目的だけで Playwright を呼ぶ
重い MCP なので、curl + grep で済むものは curl を使う。

### ❌ 大量のページに連続アクセス
スクレイピングと見なされ IP ブロックされる可能性。`/research` の Exa を併用。

### ❌ 機密サイトを Claude に見せる
Claude は会話履歴を Anthropic に送る。**社内 wiki / 経理 / 顧客情報** を Playwright で開かない。

## トラブルシュート

### chromium が起動しない
- `~/Library/Caches/ms-playwright/` に chromium があるか確認
- `npx playwright install chromium` を手動実行

### `Permission denied`
- ファイルダウンロード時の権限
- スクショ保存先のディレクトリ権限

### 動的ページが空っぽ
- `browser_wait_for` で要素が表示されるまで待つ
- SPA は `networkidle` 待ちを挟む

## 関連

- [`mcp-setup-full.md`](./mcp-setup-full.md)
- [`../commands/web-build.md`](../commands/web-build.md)
- [`../references/world-class-sites.md`](../references/world-class-sites.md)
