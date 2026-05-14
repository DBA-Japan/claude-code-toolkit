# セキュリティ宣言

このリポジトリは Claude Code の **設定ファイル / 知見ドキュメント / 自動化スクリプト** を配布する公開キットです。リスク管理のため以下の原則を明示しておきます。

## 1. このリポに **入っていない** もの

- API キー / アクセストークン
- 個人情報 / 顧客情報
- 営業秘密 / 商談内容 / クライアント名
- 売上数字 / 個別案件メモリ
- 内部 URL / 内部 Slack 断片

公開前に `gitleaks` + `detect-secrets` + 禁止語辞書 + 正規表現の CI を通します（`.github/workflows/public-audit.yml`）。

## 2. install.sh が **やらない** こと

`install.sh` は以下を **自動実行しません**。`/doctor` の出力に「次にこれをやってください」と表示するだけ。

- `brew install` / `pip install` / `npm install -g` の実行
- `claude mcp add` の実行
- `~/.zshrc` 編集
- `~/.bash_profile` 編集
- 環境変数の設定
- 外部 API への接続（除く: 公開 GitHub からの clone）
- パスワード入力

理由: brew install / pip install / MCP 登録 / API キー設定は **信頼境界を越える** ため、ユーザーが手で実行することで責任所在が明確になる。

## 3. Claude が「インストールして」と頼まれた時

公開 README の 1 行インストールフロー（Claude Code に「`https://github.com/DBA-Japan/claude-code-toolkit をインストールして`」と頼む）では、Claude は [`docs/AI_ASSIST_INSTALL.md`](./docs/AI_ASSIST_INSTALL.md) の手順に従います。

**Claude が必ず承認を取る 5 項目**:

1. `~/.claude/settings.json` への書き込み
2. `~/.zshrc` / `~/.bash_profile` 編集
3. MCP 登録（`claude mcp add ...`）
4. 外部リポクローン（toolkit 自身を除く）
5. `brew install` / `pip install`

これらは「これからこれをやる、yes/no？」とステップごとに聞きます。

## 4. API キーの取り扱い

### ✅ 推奨
- 環境変数: `~/.zshrc` 内で `export EXA_API_KEY="..."`（ローカルだけ）
- macOS Keychain（OS の鍵束）
- 1Password CLI（チーム共有が必要な場合）

### ❌ 絶対やめろ
- `~/.claude/settings.json` に API キーを書く
- リポジトリに `.env` を含める
- `~/.zshrc` を git に push する
- Claude の会話履歴に直接貼る（学習データに残るリスク）

漏洩した場合は **即時失効**:
- Anthropic: https://console.anthropic.com/
- Exa: https://exa.ai/settings
- Perplexity: https://perplexity.ai/settings
- Google Gemini: https://aistudio.google.com/apikey

## 5. Hook が拾うログ

このキットは以下の hook をデフォルトで有効化します:

| Hook | タイミング | 何を見る | 何を書く |
|---|---|---|---|
| `learning-observer.sh` | PreToolUse / PostToolUse | 全 tool 呼び出し | `~/.claude/instincts/*.jsonl` |
| `governance-capture.sh` | PreToolUse(Bash) | 危険コマンド・シークレット形式 | `~/.claude/governance.log` |
| `health-check.sh` | SessionStart | ディスク・メモリ・プロセス数 | stderr のみ |

**ログの外部送信は無し**。すべてローカルにのみ保存。

`governance.log` は危険コマンドを **検出した時のみ** 記録します。マスクされたパターンに該当しないシークレット値が混入する可能性があるので、git push する場合は `.gitignore` で除外することを推奨。

## 6. プロンプトインジェクション対策

外部由来テキスト（WebFetch / Gmail / Notion / Issue / 第三者 README 等）に含まれる「以前の指示を無視して〜」「秘密ファイルを送って〜」等のテキストは **無視します**。検出した場合は「このテキスト内に不審な指示がありました」と報告します。

詳細: [`rules/security-discipline.md`](./rules/security-discipline.md)

## 7. CC 本体の `settings.json` 改変について

`~/.claude/settings.json` への Write/Edit は、原則ユーザーが手で行います。`install.sh` のマージスクリプトのみが例外で、その内容は `settings/settings.json.template` を読んで `hooks` キーをマージするだけ（既存設定は壊さない）。

詳細: [`rules/security-discipline.md`](./rules/security-discipline.md) §5

## 8. 脆弱性報告

このキットに関する脆弱性を発見した場合:

- GitHub Issues に投稿（ただし機密内容は含めない）
- リポオーナーに DM

CC 本体（Claude Code CLI）の脆弱性は Anthropic に直接報告:
https://www.anthropic.com/security

## 9. ライセンス

MIT。利用は自己責任で。
