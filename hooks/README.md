# Hooks ディレクトリ

Claude Codeの特定イベントで自動実行されるシェルスクリプト群です。インストーラーが `~/.claude/hooks/` にコピーし、`settings.json` に登録します。

詳しい仕組みの解説は [`guides/hooks-explained.md`](../guides/hooks-explained.md) を参照してください。

---

## Hook 一覧

| ファイル名 | イベント | matcher | 説明 |
|-----------|---------|---------|------|
| `load-session-summary.sh` | SessionStart | 全て | 前回セッションの要約を読み込み、文脈を復元する |
| `health-check.sh` | SessionStart | 全て | ディスク・メモリ・プロセス数を起動時にチェックし、問題があれば警告を表示する |
| `save-session-summary.sh` | Stop | 全て | セッション終了時にトランスクリプトを解析し、要約を保存する |
| `parse-transcript.py` | Stop（間接） | - | `save-session-summary.sh` から呼ばれるPythonスクリプト。トランスクリプトの解析担当 |
| `cleanup.sh` | Stop | 全て | 一時ファイルとゾンビプロセスを掃除する |
| `learning-observer.sh` | PreToolUse + PostToolUse | 全て | ツール使用パターンを `~/.claude/instincts/observations.jsonl` に記録する |
| `block-no-verify.sh` | PreToolUse | Bash | `--no-verify` フラグを含むコマンドをブロック（exit 2）する |
| `governance-capture.sh` | PreToolUse | Bash | 危険なコマンド（シークレット漏洩・破壊的操作・権限昇格）を検出して警告・記録する |
| `doc-file-warning.sh` | PreToolUse | Write | 非標準の場所への `.md`/`.txt` 作成時に警告を表示する |
| `suggest-compact.sh` | PostToolUse | 全て | 約40回のツール使用ごとに `/compact` を提案する |
| `pre-compact.sh` | PreCompact | 全て | 圧縮前の作業状態を `~/.claude/pre-compact-state.md` に保存する |

---

## settings.json での Hook 登録方法

インストーラーが自動設定しますが、手動で確認・追加する場合は `settings/settings.json.template` を参照してください。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/load-session-summary.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

---

## exit code の意味

| exit code | 意味 |
|-----------|------|
| `0` | 正常終了。Claude Codeの処理を続行する |
| `1` | エラー。ログに記録されるが処理は続行する |
| `2` | ブロック（PreToolUse のみ有効）。ツール実行を中断する |
