---
name: Claude Code Hooksシステム内部動作 完全調査レポート
description: 2026-03-31ソースコードリークから判明した全26フックイベント・内部実行アーキテクチャ・未公開機能・実践的自動化パターン集
type: reference
---

# Claude Code Hooksシステム 内部動作 完全調査レポート

> 調査日: 2026-04-04
> ソース: 公式ドキュメント + 2026-03-31ソースコードリーク（v2.1.88）+ コミュニティ分析

---

## 1. 全フックイベント一覧（26イベント）

公式ドキュメントに記載されている全イベントと、リークで判明した追加情報を統合。

### セッションライフサイクル（4イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **SessionStart** | セッション開始・再開・クリア・コンパクト時 | いいえ（exit 2はユーザーに表示のみ） | コンテキスト注入、環境変数設定 |
| **SessionEnd** | セッション終了時 | いいえ | クリーンアップ、ログ保存 |
| **InstructionsLoaded** | CLAUDE.mdやrules/*.mdが読み込まれた時 | いいえ（監視専用） | 命令ファイルの変更追跡 |
| **ConfigChange** | 設定ファイルが変更された時 | はい | 設定変更の監査・ブロック |

### ユーザー入力（1イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **UserPromptSubmit** | ユーザーがプロンプトを送信した時（処理前） | はい（exit 2でプロンプト消去） | 入力バリデーション、コンテキスト追加 |

### ツール実行（5イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **PreToolUse** | ツール実行前 | はい | セキュリティゲート、自動承認、入力書き換え |
| **PostToolUse** | ツール実行成功後 | いいえ（Claudeへフィードバック可） | フォーマット、リント、ログ |
| **PostToolUseFailure** | ツール実行失敗後 | いいえ | エラーハンドリング |
| **PermissionRequest** | 許可ダイアログ表示時 | はい | 自動承認・拒否 |
| **PermissionDenied** | autoモードで拒否された時 | いいえ（retry可） | リトライ指示 |

### エージェント（4イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **SubagentStart** | サブエージェント起動時 | いいえ | サブエージェント初期化 |
| **SubagentStop** | サブエージェント完了時 | はい（exit 2で停止阻止） | サブエージェント品質検証 |
| **TaskCreated** | TaskCreateでタスク作成時 | はい（exit 2でロールバック） | タスクバリデーション |
| **TaskCompleted** | タスク完了マーク時 | はい（exit 2で完了阻止） | 品質ゲート |

### 停止制御（3イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **Stop** | Claudeが応答を終えた時 | はい（exit 2で継続強制） | タスク完了検証、自動要約 |
| **StopFailure** | APIエラーでターン終了時 | いいえ（出力無視） | エラー監視 |
| **TeammateIdle** | チームメイトがアイドルになる時 | はい（exit 2でアイドル阻止） | チーム品質ゲート |

### 通知（1イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **Notification** | 通知送信時 | いいえ | デスクトップ通知、Slack連携 |

### コンパクション（2イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **PreCompact** | コンテキスト圧縮前 | いいえ | トランスクリプトバックアップ |
| **PostCompact** | コンテキスト圧縮後 | いいえ | 圧縮後のコンテキスト再注入 |

### ファイル・ディレクトリ監視（2イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **CwdChanged** | 作業ディレクトリ変更時 | いいえ | 環境変数リロード（direnv連携） |
| **FileChanged** | 監視ファイル変更時 | いいえ | .env変更検知、自動リロード |

### ワークツリー（2イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **WorktreeCreate** | ワークツリー作成時 | はい | カスタムgit操作 |
| **WorktreeRemove** | ワークツリー削除時 | いいえ | クリーンアップ |

### MCP連携（2イベント）

| イベント | 発火タイミング | ブロック可能 | 主な用途 |
|---------|-------------|-----------|---------|
| **Elicitation** | MCPサーバーがユーザー入力を要求した時 | はい | 自動応答 |
| **ElicitationResult** | ユーザーがMCPフォームに回答した後 | はい | 応答の上書き・拒否 |

---

## 2. フックの実行タイミングと同期性

### 同期実行（デフォルト）
- フックはデフォルトで**同期的**に実行される
- Claudeはフックの完了を待ってから次のステップに進む
- バリデーション・承認判断・コンテキスト注入に適切

### 非同期実行（`async: true`）
```json
{
  "type": "command",
  "command": "node backup.js",
  "async": true,
  "timeout": 300
}
```
- `"async": true`を設定するとバックグラウンド実行
- Claudeは待たずに次のステップへ進む
- ログ、バックアップ、通知送信に適切
- タイムアウトのデフォルトは同期と同じ10分

### 未公開フィールド: `asyncRewake`
```json
{
  "type": "command",
  "command": "node validate.js",
  "asyncRewake": true
}
```
- 通常は非同期だが、exit code 2の場合はブロッキングに変わる
- 「普段は邪魔しないが、問題があったら止める」パターン

### 並列実行
- **同じイベントの複数フックは並列実行**される
- 同一コマンドは自動的に重複排除される
- 決定が競合した場合は**最も制限的な結果が優先**される
  - PreToolUse: `deny` > `defer` > `ask` > `allow`

---

## 3. フックからのフィードバック仕組み

### 方法1: Exit Code
| Exit Code | 意味 | JSON処理 |
|-----------|------|---------|
| **0** | 成功 | stdoutからJSON解析 |
| **2** | ブロッキングエラー | stdoutは無視、stderrがClaudeへフィードバック |
| **その他** | 非ブロッキングエラー | stdoutは無視、stderrはverboseモードで表示 |

### 方法2: JSON出力（stdout）

#### PreToolUse の場合（`hookSpecificOutput`を使用）
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "grepの代わりにrgを使ってください",
    "updatedInput": { "command": "rg 'pattern' ." },
    "additionalContext": "このプロジェクトではripgrepを使います"
  }
}
```

#### PostToolUse / Stop の場合（トップレベルフィールド）
```json
{
  "decision": "block",
  "reason": "テストが失敗しています。修正してください。"
}
```

#### PermissionRequest の場合
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "updatedPermissions": [
        { "type": "setMode", "mode": "acceptEdits", "destination": "session" }
      ]
    }
  }
}
```

### フィードバックの伝達先
- `additionalContext` → **system-reminderとして**Claudeのコンテキストに注入
- `reason` / `permissionDecisionReason` → Claudeが読んで行動を修正
- stderrテキスト（exit 2時） → Claudeへのエラーメッセージとして直接伝達
- SessionStart のstdout → Claudeのコンテキストに追加

---

## 4. settings.json のフック設定パターン

### 基本構造（3層ネスト）
```json
{
  "hooks": {
    "イベント名": [           // 第1層: イベント選択
      {
        "matcher": "正規表現",  // 第2層: フィルタ条件
        "hooks": [              // 第3層: 実行するハンドラ
          {
            "type": "command",
            "command": "スクリプトのパス",
            "timeout": 60,
            "async": false,
            "statusMessage": "実行中..."
          }
        ]
      }
    ]
  }
}
```

### 設定ファイルの場所と優先度
| 場所 | スコープ | 共有可能 |
|------|---------|---------|
| `~/.claude/settings.json` | 全プロジェクト共通 | いいえ |
| `.claude/settings.json` | プロジェクト固有 | はい（gitコミット可） |
| `.claude/settings.local.json` | プロジェクト固有 | いいえ（gitignore） |
| マネージドポリシー設定 | 組織全体 | はい（管理者制御） |
| プラグインの `hooks/hooks.json` | プラグイン有効時 | はい |
| スキル/エージェントのfrontmatter | スキル/エージェント実行中 | はい |

### Matcherパターンマッチの仕組み
- **正規表現**で評価される（大文字小文字区別あり）
- パイプ `|` でOR条件: `"Edit|Write|MultiEdit"`
- `mcp__.*` でMCPツール全般にマッチ
- `mcp__github__.*` で特定MCPサーバーのツールにマッチ
- 空文字列 `""` または省略 → 全てにマッチ

### `if` フィールド（v2.1.85以降）
matcher以上に細かいフィルタリング:
```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "if": "Bash(git *)",
    "command": "check-git-policy.sh"
  }]
}
```
- permissionルールと同じ構文: `"Bash(git *)"`, `"Edit(*.ts)"`
- ツールイベントのみ対応（PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied）

---

## 5. フックの制約

### タイムアウト
| ハンドラタイプ | デフォルト | 設定可能 |
|-------------|----------|---------|
| command | 600秒（10分） | はい（`timeout`フィールド） |
| prompt | 30秒 | はい |
| agent | 60秒 | はい |
| http | 30秒 | はい |

### 失敗時の挙動
- **コマンドフック**: exit code 0以外 → 非ブロッキングエラー（verboseモードで表示）
- **HTTPフック**: 接続失敗・タイムアウト・非2xx → 非ブロッキングエラー（実行継続）
- **Exit 2のみ**がブロッキング動作を引き起こす
- フックがクラッシュしてもClaude Code本体は止まらない

### フック内でツールは使えるか？
- **commandフック**: 使えない。stdout/stderr/exit codeのみで通信
- **agentフック**: 使える。サブエージェントが生成され、Read/Grep/Glob等のツールを使って検証可能（最大50ツール使用ターン）
- **promptフック**: 使えない。単一LLMコールのみ
- **httpフック**: 使えない。HTTPレスポンスのみ

### その他の制約
- フック内から `/` コマンドやツールコールを直接トリガーできない
- `additionalContext`はsystem-reminderとしてプレーンテキスト注入のみ
- PostToolUseは実行済みのアクションを取り消せない
- PermissionRequestフックは非対話モード（`-p`）では発火しない
- Stopフックはユーザーの割り込み時には発火しない（APIエラー時はStopFailureが発火）
- 複数のPreToolUseフックが`updatedInput`を返した場合、最後に完了したものが勝つ（非決定的）
- **2.5時間以上の長時間セッションでフックが停止するバグ**が報告されている（Issue #16047）

---

## 6. Stop hookの仕組み

### 基本動作
1. Claudeが応答を完了しようとする
2. Stopフックが発火
3. exit 0 + JSON `{"decision": "block", "reason": "..."}` → Claudeが継続を強制される
4. exit 2 → stderrがClaudeに伝達され、継続強制
5. exit 0（JSONなし） → Claudeは正常に停止

### 無限ループ防止（最重要）
```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # 2回目以降は停止を許可
fi
# 1回目の検証ロジック
```
- `stop_hook_active` フィールドが `true` → 既に1回継続強制済み
- これをチェックしないと**無限ループ**になる

### `continue: false` による強制停止
```json
{
  "continue": false,
  "stopReason": "セッション終了時の自動保存が完了しました"
}
```
- `continue: false` → Claudeの全処理を停止
- `stopReason` → ユーザーに表示（Claudeには見えない）
- `decision: "block"` より優先される

### 自動要約保存の実装パターン
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "bash ~/.claude/hooks/save-summary.sh"
      }]
    }]
  }
}
```

save-summary.sh:
```bash
#!/bin/bash
INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

RESPONSE=$(echo "$INPUT" | jq -r '.final_response // empty')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# 要約をファイルに保存
echo "=== Session $SESSION_ID ($TIMESTAMP) ===" >> ~/.claude/session-summaries.md
echo "$RESPONSE" | head -50 >> ~/.claude/session-summaries.md
echo "" >> ~/.claude/session-summaries.md

exit 0
```

---

## 7. PreToolUse / PostToolUse 詳細

### PreToolUse

**発火対象ツール:**
Bash, Edit, Write, Read, Glob, Grep, Agent, WebFetch, WebSearch, AskUserQuestion, ExitPlanMode, 全MCPツール（`mcp__サーバー名__ツール名`）

**入力JSON（stdin）:**
```json
{
  "session_id": "abc123",
  "cwd": "~/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test",
    "description": "テスト実行",
    "timeout": 120000
  },
  "tool_use_id": "toolu_xxx"
}
```

**ツール別の入力スキーマ:**
- **Bash**: `command`, `description`, `timeout`, `run_in_background`
- **Write**: `file_path`, `content`
- **Edit**: `file_path`, `old_string`, `new_string`, `replace_all`
- **Read**: `file_path`, `offset`, `limit`
- **Glob**: `pattern`, `path`
- **Grep**: `pattern`, `path`, `glob`, `output_mode`, `-i`, `multiline`
- **WebFetch**: `url`, `prompt`
- **WebSearch**: `query`, `allowed_domains`, `blocked_domains`
- **Agent**: `prompt`, `description`, `subagent_type`, `model`

**出力制御（permissionDecision）:**
- `"allow"` → 許可プロンプトをスキップ（ただしdenyルールは上書きしない）
- `"deny"` → ツールコールをキャンセル、reasonをClaudeに伝達
- `"ask"` → 通常の許可プロンプトを表示
- `"defer"` → 非対話モード（-p）専用、外部ラッパーに判断を委譲

**重要な発見（リーク由来）:**
- PreToolUseフックは内蔵の**23段階Bash検証**の後に実行される
- つまりフックは「セキュリティの第2層」であり、唯一の防御ではない
- `permissionDecision: "allow"` を返しても、settings.jsonのdenyルールは上書きできない
- denyルール > フックの判断 という優先度

### PostToolUse

**入力JSON（stdin）:**
```json
{
  "session_id": "abc123",
  "cwd": "~/project",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.html",
    "old_string": "...",
    "new_string": "..."
  },
  "tool_response": "編集が成功しました...",
  "tool_use_id": "toolu_xxx"
}
```

**出力制御:**
- `decision: "block"` + `reason` → Claudeに「やり直し」指示
- `additionalContext` → 追加情報をClaudeに注入
- `updatedMCPToolOutput` → MCPツールの出力を書き換え（MCP専用）
- ただし**ツールは既に実行済み**なので、アクションの取り消しは不可能

---

## 8. リークで判明した未公開・高度な機能

### 未公開フックフィールド
1. **`once: true`** → 1セッションで1回だけ発火し、自動的に無効化
2. **`async: true`** → バックグラウンド実行（ドキュメントには簡潔にしか記載なし）
3. **`asyncRewake: true`** → 通常非同期だがexit 2ならブロッキング

### 未公開エージェントfrontmatterフィールド
- `color` → UIで色分け表示（red, orange, yellow, green, blue, purple, pink, gray）
- `memory` → エージェント固有の永続メモリ（user/project/local スコープ）
- `effort` → 推論深度制御（low, medium, high, max）
- `criticalSystemReminder_EXPERIMENTAL` → 毎ターン再注入されるリマインダー
- `omitClaudeMd: true` → CLAUDE.md階層を読み込まない
- `requiredMcpServers` → MCP依存関係の強制

### SessionStartの未公開出力フィールド
- `watchPaths` → FileChangedイベントの自動監視パスを設定
- `initialUserMessage` → 最初のユーザーメッセージにコンテンツを先頭追加

### autoモードの隠し設定
- `autoMode.environment` → 自然言語でAI分類器に環境情報を伝達
  ```json
  { "autoMode": { "environment": ["本番サーバーではなくローカル開発環境"] } }
  ```

### 学習システム（未公開）
- `autoMemoryEnabled: true` → セッションから自動的に永続メモリを抽出
- `autoDreamEnabled: true` → 24時間ごと、5セッション以上でメモリ整理を自動実行

### KAIROS（未リリース機能）
- `PROACTIVE` と `KAIROS` フラグで制御
- 24/7バックグラウンドで動作する自律デーモンモード
- ハートビートプロンプト（「今やるべきことはあるか？」）
- プッシュ通知、ファイル配信、GitHub PR監視
- `autoDream`プロセスでアイドル時にメモリ統合
- 追記専用ログ（履歴の消去不可）

### Anti-Distillation防御（内部機能）
- `ANTI_DISTILLATION_CC`フラグ有効時、偽のツール定義を会話に注入
- 訓練データ抽出を汚染する目的
- `CONNECTOR_TEXT`層で暗号署名付き要約を生成

### Undercover Mode（内部機能）
- 90行のメカニズム
- 外部ビルドから内部コードネーム・Slackチャンネル名・製品名を除去
- 不可逆（一方通行）

---

## 9. 実践的な自動化パターン集

### パターン1: デスクトップ通知（macOS）
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"Claude Codeが入力を待っています\" with title \"Claude Code\"'"
      }]
    }]
  }
}
```
**効果:** ターミナルを見ていなくても、Claudeが入力待ちの時にmacOS通知が出る。

### パターン2: ファイル編集後の自動フォーマット
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
      }]
    }]
  }
}
```
**効果:** ClaudeがEdit/Writeでファイルを変更するたびにPrettierが自動実行。

### パターン3: 保護ファイルへの編集ブロック
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'INPUT=$(cat); FILE=$(echo \"$INPUT\" | jq -r \".tool_input.file_path // empty\"); case \"$FILE\" in *.env*|*package-lock*|*.git/*) echo \"保護ファイル: $FILE\" >&2; exit 2;; esac; exit 0'"
      }]
    }]
  }
}
```
**効果:** .envやpackage-lock.jsonへの編集を自動ブロック。

### パターン4: git pushの自動ブロック（決済禁止ルール対応）
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "if": "Bash(git push*)",
        "command": "echo '自動git pushはブロックされました。ユーザーの明示的な承認が必要です。' >&2; exit 2"
      }]
    }]
  }
}
```
**効果:** CLAUDE.mdの「決済禁止」ルールをコードレベルで強制。

### パターン5: コンパクション時のコンテキスト再注入
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "compact",
      "hooks": [{
        "type": "command",
        "command": "echo 'リマインダー: Bunを使用。npmは使わない。コミット前にbun test実行。'"
      }]
    }]
  }
}
```
**効果:** コンテキスト圧縮後に失われがちなルールを自動再注入。

### パターン6: 全Bashコマンドのログ記録
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.command' >> ~/.claude/command-log.txt",
        "async": true
      }]
    }]
  }
}
```
**効果:** Claudeが実行した全コマンドを非同期でログファイルに記録。

### パターン7: Stopフックでタスク完了検証（promptタイプ）
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "ユーザーの依頼が全て完了したか確認してください。未完了のタスクがある場合は {\"ok\": false, \"reason\": \"残りのタスク: ...\"} で応答してください。"
      }]
    }]
  }
}
```
**効果:** Claudeが中途半端に終了するのを防止。LLMが完了度を判定。

### パターン8: Stopフックでタスク完了検証（agentタイプ）
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "agent",
        "prompt": "ユニットテストが全て通るか確認してください。テストスイートを実行し、結果を検証してください。 $ARGUMENTS",
        "timeout": 120
      }]
    }]
  }
}
```
**効果:** サブエージェントが実際にテストを実行し、失敗があれば継続を強制。

### パターン9: PermissionRequestの自動承認（ExitPlanMode）
```json
{
  "hooks": {
    "PermissionRequest": [{
      "matcher": "ExitPlanMode",
      "hooks": [{
        "type": "command",
        "command": "echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PermissionRequest\", \"decision\": {\"behavior\": \"allow\"}}}'"
      }]
    }]
  }
}
```
**効果:** プランモード終了時の許可ダイアログを自動スキップ。

### パターン10: セッション終了時のクリーンアップ
```json
{
  "hooks": {
    "SessionEnd": [{
      "matcher": "clear",
      "hooks": [{
        "type": "command",
        "command": "rm -f /tmp/claude-scratch-*.txt"
      }]
    }]
  }
}
```
**効果:** /clear実行時に一時ファイルを自動削除。

### パターン11: PreCompactでトランスクリプトバックアップ
```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'INPUT=$(cat); TRANSCRIPT=$(echo \"$INPUT\" | jq -r \".transcript_path\"); cp \"$TRANSCRIPT\" ~/.claude/backups/$(date +%Y%m%d_%H%M%S)_transcript.json'",
        "async": true
      }]
    }]
  }
}
```
**効果:** 自動コンパクション前にトランスクリプトをバックアップ。

### パターン12: 設定変更の監査ログ
```json
{
  "hooks": {
    "ConfigChange": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
      }]
    }]
  }
}
```
**効果:** 設定ファイルの変更を全て監査ログに記録。

---

## 10. ニケツバサへの推奨: 今すぐ追加すべきフック

現在の `~/.claude/settings.json` にはhooksが未設定。以下を追加推奨:

### 最優先（即効果あり）
1. **Notification → デスクトップ通知** — Claudeの入力待ちを見逃さない
2. **PreToolUse(Bash) → git push/deploy自動ブロック** — CLAUDE.mdの決済禁止ルールをコード強制
3. **SessionStart(compact) → コンテキスト再注入** — コンパクション後のルール消失を防止

### 次のステップ
4. **PostToolUse(Edit|Write) → 自動フォーマット** — コード品質の自動維持
5. **PreCompact → トランスクリプトバックアップ** — 圧縮前のセッション保存
6. **Stop → promptタイプでタスク完了検証** — 中途半端な終了を防止

---

## Sources
- [Hooks reference - Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [Automate workflows with hooks - Claude Code Docs](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code power user customization: How to configure hooks](https://claude.com/blog/how-to-configure-hooks)
- [The Claude Code Source Leak - Alex Kim's blog](https://alex000kim.com/posts/2026-03-31-claude-code-source-leak/)
- [What the Claude Code Source Leak Reveals - Blake Crosley](https://blakecrosley.com/blog/claude-code-source-leak)
- [Claude Code Hooks: Why Each of My 95 Hooks Exists - Blake Crosley](https://blakecrosley.com/blog/claude-code-hooks)
- [I Read the Claude Code Source Code - BuildingBetter.tech](https://buildingbetter.tech/p/i-read-the-claude-code-source-code)
- [Claude Code Source Code Leaked - Superframeworks](https://superframeworks.com/articles/claude-code-source-code-leak)
- [Diving into Claude Code's Source Code - Engineer's Codex](https://read.engineerscodex.com/p/diving-into-claude-codes-source-code)
- [Claude Code Hooks: Complete Guide to All 12 Lifecycle Events - claudefa.st](https://claudefa.st/blog/tools/hooks/hooks-guide)
- [Claude Code's source code appears to have leaked - VentureBeat](https://venturebeat.com/technology/claude-codes-source-code-appears-to-have-leaked-heres-what-we-know)
