# MCP セットアップ完全版

claude-code-toolkit が想定する MCP サーバを `claude mcp add` で登録するガイド。**すべて任意**、必要になった時だけ入れる。

## MCP の確認・追加・削除

```bash
claude mcp list                      # 登録済み一覧
claude mcp add <name> <command...>   # 追加
claude mcp remove <name>             # 削除
claude mcp doctor                    # 接続健全性
```

スコープ:
- なし: プロジェクト（その作業フォルダだけ）
- `--scope user`: ユーザー全体（どこからでも使える）

## 一覧表

| MCP | 用途 | API key | コマンド | 推奨スコープ |
|---|---|---|---|---|
| `context7` | ライブラリ docs（最新版） | 不要 | `claude mcp add context7 npx -y @upstash/context7-mcp` | user |
| `repomix` | リモートリポジトリ解析 | 不要 | `claude mcp add repomix npx -y repomix` | user |
| `exa` | Web 検索（質と被覆率） | 必要 | `claude mcp add --scope user exa npx -y exa-mcp` | user |
| `perplexity` | 鮮度命のリサーチ | 必要 | `claude mcp add --scope user perplexity npx -y perplexity-mcp` | user |
| `playwright` | ブラウザ操作・スクレイピング | 不要（chromium 自動DL） | `claude mcp add --scope user playwright npx -y @microsoft/playwright-mcp` | user |
| `claude-peers` | マルチインスタンス通信 | 不要（bun） | [`../mcp-servers/claude-peers-setup.md`](../mcp-servers/claude-peers-setup.md) | user |

## それぞれの詳細

### context7（ライブラリ docs）

Claude の学習データは古い。`context7` を入れると、ライブラリの **最新公式 docs** を引いてくれます。

```bash
claude mcp add --scope user context7 npx -y @upstash/context7-mcp
```

確認:
```
/mcp
# context7 が緑色 (connected) になっていれば OK
```

使い方:
```
React 19 の useTransition の最新仕様を context7 で引いて
```

→ Claude が `mcp__context7__query-docs` を呼んで取得。

### repomix（GitHub リポジトリ解析）

リモートリポジトリを丸ごと AI 最適化された XML に変換。コードレビュー・OSS 理解に強い。

```bash
claude mcp add --scope user repomix npx -y repomix
```

使い方:
```
https://github.com/vercel/swr のコードを解析して、useSWR の実装を要約して
```

→ `mcp__repomix__pack_remote_repository` でパック → `mcp__repomix__grep_repomix_output` で対象部分抽出。

### exa（汎用 Web 検索）

```bash
# 1. API key 取得
open https://exa.ai/

# 2. 環境変数設定
echo 'export EXA_API_KEY="..."' >> ~/.zshrc
source ~/.zshrc

# 3. MCP 登録
claude mcp add --scope user exa npx -y exa-mcp
```

特徴:
- Anthropic 標準の WebSearch より **クオリティ** と **被覆率** が高い
- 企業調査・人物プロファイル・OSS リポジトリ調査に強い

`/research` がデフォルトで Exa を選ぶよう振り分け済み。

### perplexity（鮮度重視のリサーチ）

最新ニュース・直近イベント・人物発信は perplexity 第一。

```bash
# 1. API key 取得
open https://perplexity.ai/

# 2. 環境変数設定
echo 'export PERPLEXITY_API_KEY="..."' >> ~/.zshrc

# 3. MCP 登録
claude mcp add --scope user perplexity npx -y perplexity-mcp
```

注意:
- 鮮度命の場合のみ使う（汎用リサーチは Exa を推奨）
- tool description が「鮮度命」と明示されてないと誤発動するので、`memory/feedback_perplexity_mcp_usage_policy.md` に運用ルールを書いておくと安全

### playwright（ブラウザ操作）

```bash
claude mcp add --scope user playwright npx -y @microsoft/playwright-mcp

# 初回起動時に chromium をDL（数百MB）
```

使い方:
- Web ページのテキスト全抽出
- スクリーンショット
- フォーム自動入力（テスト用）
- 動的ページの DOM スナップショット
- ログイン後の画面操作

`/web-build` の Day 0 プロトコル（既存サイトのテキスト全抽出）はこれを使います。

### claude-peers（マルチインスタンス通信）

別 CC インスタンス間でメッセージ通信。

詳細: [`../mcp-servers/claude-peers-setup.md`](../mcp-servers/claude-peers-setup.md)

依存: bun

## Claude.ai Connector（参考）

Web 版 claude.ai で有効化する以下のコネクタは MCP とは別の仕組みです（OAuth ベース）:
- Gmail / Google Calendar / Google Drive
- Notion
- Adobe Creative Cloud

これらは Web UI から有効化し、Claude Code CLI からも `mcp__claude_ai_<service>__*` として呼べます。

設定先: https://claude.ai/settings/connectors

## API key の保管方法（セキュリティ）

❌ **絶対やめろ**:
- `~/.claude/settings.json` に api_key を書く
- `~/.zshrc` を git に push する
- リポジトリに `.env` を含める

✅ **推奨**:
- `~/.zshrc` 内で `export EXA_API_KEY="..."` （ローカルだけ）
- macOS Keychain（複雑な場合）
- 1Password CLI（チーム共有が必要な場合）

漏洩した場合は **即時失効**:
- Exa: https://exa.ai/ の Settings から
- Perplexity: 同上
- Anthropic: console.anthropic.com から

## トラブルシュート

### `/mcp` で名前が赤い
- プロセスが落ちている
- `pkill -f <mcp名>` してから CC 再起動

### MCP 自体が認識されない
- `claude mcp list` で確認
- `~/.claude/settings.json` の `mcpServers` キーを目視

### 「Permission denied for tool ...」
- 設定で MCP ツールの許可リストに入ってない
- `/permissions` で確認・追加

## 関連

- [`doctor-explained.md`](./doctor-explained.md)
- [`playwright-mcp.md`](./playwright-mcp.md)
- [`exa-cinii-jstage.md`](./exa-cinii-jstage.md)
- [`../mcp-servers/`](../mcp-servers/)
