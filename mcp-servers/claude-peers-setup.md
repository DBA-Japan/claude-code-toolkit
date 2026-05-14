# claude-peers セットアップ

[louislva/claude-peers-mcp](https://github.com/louislva/claude-peers-mcp) — 同じマシン上で複数 Claude Code インスタンスがメッセージ通信できる MCP サーバ。

## 依存

- `bun`（https://bun.sh/）
- `git`

## セットアップ手順

### 1. リポジトリを取得

```bash
git clone https://github.com/louislva/claude-peers-mcp.git ~/claude-peers-mcp
cd ~/claude-peers-mcp
bun install
```

### 2. MCP に登録

```bash
claude mcp add claude-peers bun ~/claude-peers-mcp/server.ts
```

ユーザースコープに入れたい場合:

```bash
claude mcp add --scope user claude-peers bun ~/claude-peers-mcp/server.ts
```

### 3. 動作確認

CC を再起動して、別のターミナルで CC を 2 つ立ち上げる。それぞれで:

```
/mcp
```

`claude-peers` が緑色 (connected) で表示されればOK。

## 使い方

別の CC インスタンスに話しかける:

```
mcp__claude-peers__list_peers
mcp__claude-peers__send_message を使って他の CC に質問する
```

## トラブルシュート

- `bun: command not found` → `curl -fsSL https://bun.sh/install | bash`
- 接続できない → bash プロセスが残ってないか `lsof -i :PORT` で確認、`pkill -f claude-peers-mcp` でリセット
- 詳細: 元リポジトリ Issues を参照

## 安全性

claude-peers は同マシン内の IPC のみ。外部ネットワークには出ない（v0.x 時点）。
