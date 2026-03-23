# Settings ディレクトリ

Claude Codeの設定ファイルのテンプレートを管理するディレクトリです。

---

## ファイル一覧

| ファイル名 | 説明 |
|-----------|------|
| `settings.json.template` | インストール時に `~/.claude/settings.json` にマージされる設定テンプレート |

---

## settings.json.template の内容

このテンプレートには以下の設定が含まれています。

### hooks セクション

全Hookの登録設定です。インストーラーがこの定義を読み取り、既存の `~/.claude/settings.json` にマージします。

```json
"hooks": {
  "SessionStart": [...],   // セッション開始時のHook
  "Stop": [...],           // セッション終了時のHook
  "PreToolUse": [...],     // ツール実行前のHook
  "PostToolUse": [...],    // ツール実行後のHook
  "PreCompact": [...]      // /compact 実行前のHook
}
```

各Hookの詳細は [`hooks/README.md`](../hooks/README.md) および [`guides/hooks-explained.md`](../guides/hooks-explained.md) を参照してください。

### language

```json
"language": "Japanese"
```

Claude Codeの応答言語を日本語に設定します。既存の `settings.json` に `language` が設定されていない場合のみ書き込まれます。

### effortLevel

```json
"effortLevel": "high"
```

Claude Codeの作業品質レベルを最高に設定します。既存の設定がある場合は上書きされません。

---

## インストーラーのマージロジック

`install.sh` は Python スクリプトを使って既存の設定を破壊せずにテンプレートをマージします。

**マージの原則:**
1. 既存の `~/.claude/settings.json` が存在する場合、バックアップを作成する
2. テンプレートの hooks を読み込み、既存に登録されていないコマンドだけを追加する（重複追加しない）
3. `language`・`effortLevel` は既存設定がない場合のみ設定する
4. 既存の設定（カスタムMCPサーバー等）はすべて保持する

このため、インストーラーを再実行しても既存の設定が失われることはありません。

---

## 手動で settings.json を編集したい場合

`~/.claude/settings.json` を直接編集できます。Claude Codeを再起動すると変更が反映されます。

設定のリファレンス: https://docs.anthropic.com/claude-code

**注意:** `hooks` セクションを誤って削除すると自動化が無効になります。編集前に必ずバックアップを取ってください。

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup
```
