# 各Hookの仕組み解説

## Hooks とは

Hook（フック）は、Claude Codeの特定イベントが発生したときに**自動実行されるシェルスクリプト**です。設定は `~/.claude/settings.json` の `hooks` セクションに記述します。

ユーザーが何も意識しなくても、セッション開始・終了・コマンド実行のたびにバックグラウンドで動き、安全性・利便性・品質を維持します。

---

## Hook イベントの種類

| イベント | いつ発火するか |
|---------|--------------|
| `SessionStart` | Claude Codeのセッションが始まった直後 |
| `Stop` | セッションが終了するとき（応答完了後） |
| `PreToolUse` | Claudeがツール（Bash/Edit/Read等）を使う直前 |
| `PostToolUse` | ツール使用が完了した直後 |
| `PreCompact` | `/compact` で会話圧縮が始まる直前 |

### matcher（フィルタリング）

`matcher` を指定すると、特定のツールだけに反応させられます。

```json
{
  "matcher": "Bash",
  "hooks": [...]
}
```

`matcher: ""` は全ツールに反応します。

---

## 各Hookの詳細解説

### load-session-summary.sh
**イベント:** SessionStart

**何をするか:** `~/.claude/session-summaries/latest.md`（前回セッションの要約）を読み込み、内容を標準出力に書き出します。Claude Codeはこの出力をコンテキストとして取り込むため、前回の会話の要点が自動的に引き継がれます。

**なぜ必要か:** セッションをまたぐたびに「先日の続きなんですが...」と説明し直す手間がなくなります。常に「前回はここまで進んでいた」という文脈から再開できます。

---

### save-session-summary.sh + parse-transcript.py
**イベント:** Stop

**何をするか:** セッション終了時にトランスクリプト（会話ログ）を解析し、要点をMarkdown形式の要約ファイルとして `~/.claude/session-summaries/YYYY-MM-DD_HHMMSS.md` に保存します。`latest.md` というシンボリックリンクも更新されるため、次のセッションで `load-session-summary.sh` がすぐに読み込めます。50件を超えた古い要約は自動削除されます。

**なぜ必要か:** 「あのセッションで何をやったか」が後から確認できます。また、翌日のセッション開始時の文脈復元に使われます。

---

### health-check.sh
**イベント:** SessionStart

**何をするか:** セッション開始時に環境の健康状態を自動チェックします。問題があれば警告を表示します。

チェック項目:
- ディスク空き容量が10GB未満でないか
- 利用可能メモリが4GB未満でないか（macOSのみ）
- Claude Codeプロセスが4つ以上起動していないか（多すぎる場合）
- `/tmp` にClaude関連ファイルが100MB以上溜まっていないか（自動クリーンアップ）

**なぜ必要か:** リソース不足に気づかずに重い作業を始めると、応答が遅くなったりクラッシュしたりします。事前に警告することで問題を予防できます。

---

### block-no-verify.sh
**イベント:** PreToolUse（Bash限定）

**何をするか:** 実行しようとしているBashコマンドに `--no-verify` フラグが含まれていた場合、実行をブロック（exit 2）します。

**なぜ必要か:** `git commit --no-verify` はコミット前のフック（コード品質チェック、型チェック等）をスキップします。これを許可すると、品質チェックが無効化されたまま変更がコミットされる危険があります。常にフックを通過させることでコード品質を守ります。

---

### governance-capture.sh
**イベント:** PreToolUse（Bash限定）

**何をするか:** 実行しようとしているBashコマンドを解析し、危険なパターンを検出した場合に警告を表示して `~/.claude/governance.log` に記録します。ブロックはしません（警告のみ）。

検出するパターン:
- AWSアクセスキー（`AKIA...`）の平文
- 秘密鍵ファイル（`id_rsa`、`.pem` 等）へのアクセス
- APIキー・パスワードの平文書き込み
- `.env` ファイルの読み取り・外部送信
- `rm -rf` などの破壊的削除
- SQL の DROP/TRUNCATE/DELETE
- `git push --force`
- `sudo` による権限昇格
- `curl ... | bash` など外部コードの直接実行

**なぜ必要か:** AIが自律的に作業するとき、意図しない破壊的操作や情報漏洩が起こるリスクがあります。ログを残すことで「何が起きたか」を後から追跡できます。

---

### learning-observer.sh
**イベント:** PreToolUse + PostToolUse（全ツール）

**何をするか:** Claudeがどのツールをどの頻度で使っているかを `~/.claude/instincts/observations.jsonl` に自動記録します。

**なぜ必要か:** ツール使用パターンを蓄積することで `/instinct` スキルがユーザーの行動傾向を学習できます。「いつも同じ手順を踏んでいる」パターンを発見し、スキル化の提案ができるようになります。

---

### suggest-compact.sh
**イベント:** PostToolUse

**何をするか:** ツール使用回数を追跡し、約40回のツール使用ごとにコンパクトを提案するメッセージを出力します。

**なぜ必要か:** コンテキストウィンドウは徐々に埋まっていきますが、ユーザーはその状況に気づきにくいです。定期的なリマインダーで「そろそろ /compact すべきタイミング」を教えてくれます。

---

### pre-compact.sh
**イベント:** PreCompact

**何をするか:** `/compact` が実行される直前に、現在のセッション状態（作業中のファイル・現在の目標・重要な決定）を `~/.claude/pre-compact-state.md` に保存します。

**なぜ必要か:** コンパクト後に「圧縮前に何をやっていたか」が分からなくなることがあります。pre-compact.sh が保存したファイルを参照することで、圧縮後もスムーズに作業を再開できます。

---

### doc-file-warning.sh
**イベント:** PreToolUse（Write限定）

**何をするか:** Claudeが新しい `.md` または `.txt` ファイルを作成しようとしたとき、そのファイルパスが標準的な場所（`memory/`、`guides/`、`docs/`）以外であれば警告を表示します。

**なぜ必要か:** Claudeは「メモとして」ドキュメントファイルを作りがちです。気づかないうちにプロジェクトに不要な `.md` ファイルが増殖するのを防ぎます。

---

### cleanup.sh
**イベント:** Stop

**何をするか:** セッション終了時に以下を掃除します:
- 24時間以上前に作成された `/tmp/claude-*` ファイル
- ゾンビ化したClaude関連プロセスの終了

**なぜ必要か:** 長期間使い続けると一時ファイルが蓄積してディスクを圧迫します。自動で掃除することで環境を清潔に保ちます。

---

## 自分でHookを作る方法

### 基本パターン

```bash
#!/bin/bash
# =============================================================================
# my-hook.sh — イベント名 Hook
# 何をするかの説明
# =============================================================================

# stdin から Claude Code のJSON入力を読み取る（必須）
INPUT=$(cat)

# 処理を書く
# ...

# exit 0: 処理を通過させる（通常はこれ）
# exit 2: 処理をブロックする（PreToolUseのみ有効）
exit 0
```

### stdin の読み取り

Claude Codeは Hook にJSON形式の情報を stdin で渡します。Python で解析できます。

```bash
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
")
```

### settings.json への登録

作成したHookは `~/.claude/settings.json` に登録します。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/my-hook.sh",
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

| exit code | 意味 | どこで使えるか |
|-----------|------|--------------|
| `0` | 正常終了、処理を続行 | 全イベント |
| `1` | エラー（ログに記録されるが処理は続行） | 全イベント |
| `2` | ブロック（処理を中断） | PreToolUse のみ |

`exit 2` は強力です。PreToolUse でブロックすると、Claudeはそのツール実行を止めます。乱用するとClaude自体が動けなくなるので、確実に危険なケースだけに使ってください。

---

## Tips: Hookのデバッグ方法

Hookが動いているか確認したい場合、スクリプトの中にログを出力します。

```bash
# デバッグ用ログ（ターミナルに表示）
echo "[DEBUG] hook が呼ばれました" >&2

# ファイルに記録
echo "[$(date)] hook 実行" >> ~/.claude/hook-debug.log
```

stdout への出力はClaude Codeがコンテキストとして取り込みます（SessionStart の `load-session-summary.sh` がその仕組みを使っています）。stderr への出力はターミナルに表示されます。

### タイムアウト設定

settings.json の `timeout` はミリ秒単位です（デフォルトは5000ms = 5秒）。重い処理をするHookは適切にタイムアウトを設定してください。

```json
{
  "type": "command",
  "command": "bash ~/.claude/hooks/my-hook.sh",
  "timeout": 10000
}
```

タイムアウトを超えると Hook は強制終了されますが、Claude Codeの処理は続行されます。
