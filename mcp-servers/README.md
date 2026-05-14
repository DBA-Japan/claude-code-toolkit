# mcp-servers/

カスタム MCP サーバ + 公式 MCP の登録ガイドへのリンク。

## 含まれるもの

### claude-peers-mcp/

[louislva/claude-peers-mcp](https://github.com/louislva/claude-peers-mcp) のラッパー。マルチインスタンスの Claude Code 間でメッセージ通信できます。

依存: bun

```bash
# 取得
git clone https://github.com/louislva/claude-peers-mcp.git ~/claude-peers-mcp
cd ~/claude-peers-mcp && bun install

# 登録
claude mcp add claude-peers bun ~/claude-peers-mcp/server.ts
```

## 公式 MCP の登録

別ガイドを参照: [`../guides/mcp-setup-full.md`](../guides/mcp-setup-full.md)

カバーする MCP:
- **Exa** — Web 検索（要 API key、`EXA_API_KEY`）
- **Playwright** — ブラウザ操作・スクレイピング（要 chromium）
- **Perplexity** — 鮮度命のリサーチ（要 API key、`PERPLEXITY_API_KEY`）
- **context7** — ライブラリ docs 取得（無料）
- **repomix** — リモートリポジトリ解析（無料）
- **NotebookLM** — Google NotebookLM API（OAuth）

## 設定の確認

`/doctor` を打つと、各 MCP の登録状況と必要な依存（API key 等）の有無を表示します。
