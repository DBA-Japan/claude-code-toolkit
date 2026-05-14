# 自動学習システム — Claude Code が「勝手に育つ」配線

Claude Code は使えば使うほど **あなたのユーザー** に最適化されます。このキットは、その自動育成を 4 つの仕組みで動かしています。

```
┌──────────────────────────────────────────────────────┐
│  ① auto memory（Claude Code 本体機能）                  │
│    └ 会話から好み・事実・参照先を自動的にメモリに保存       │
│                                                       │
│  ② instinct システム（hook + command）                  │
│    └ ツール使用ログから利用パターンを可視化・進化           │
│                                                       │
│  ③ self-improving-agent（skill）                       │
│    └ メモリの棚卸し・パターン昇格・スキル抽出              │
│                                                       │
│  ④ governance / health（hook）                         │
│    └ 危険コマンド検出 + 環境健全性の自動レポート           │
└──────────────────────────────────────────────────────┘
```

各層は独立して動きますが、`/audit` / `/instinct` / `/learn-eval` で **手動 trigger** も可能です。

---

## ① auto memory（Claude Code 本体機能）

Claude Code には永続メモリ機能が組み込まれています。会話中に発見した「あなたの好み」「プロジェクトの事実」「外部リソースのリンク先」「行動ルール」を `~/.claude/projects/-Users-<user>/memory/` に Markdown として保存し、**次のセッションでも自動ロード** されます。

### 4 つのメモリタイプ

| Type | 何を保存するか | 例 |
|---|---|---|
| **user** | あなたの役割・前提・知識・好み | 「React 5 年。日本語 UI 案件中心」 |
| **feedback** | 「これはやって／やめて」と指示したガイダンス | 「テストでモックは禁止、実 DB を使う」 |
| **project** | プロジェクトの状況・締切・関係者 | 「来週水曜にローンチ、レビュー担当は田中さん」 |
| **reference** | 外部システムへのポインタ | 「バグは Linear `INGEST` プロジェクトで管理」 |

### 保存される時とフォーマット

Claude は以下のタイミングで memory ファイルを書きます:

- ユーザーが「覚えておいて」「これからこうして」と明示
- 修正を 2 回以上受けた行動パターン（暗黙学習）
- 新しい役割・プロジェクト・外部リソースに言及された時

各メモリは独立した `.md` で:

```markdown
---
name: feedback-no-mocks
description: テストでモックは使わない、実 DB を使う
metadata:
  type: feedback
---

テストでモックは使わない、実 DB を使う。

**Why:** 前回モックが通って本番 migration が壊れた。
**How to apply:** 統合テスト・E2E テストすべてで適用。
```

そして `MEMORY.md` に 1 行 index として追加:

```markdown
- [feedback-no-mocks](feedback-no-mocks.md) — モック禁止、実 DB のみ
```

### MEMORY.md の上限

- **200 行 / 25 KB**。超えるとサイレント切り捨て（Claude Code 本体仕様）
- index 形式に徹する。詳細は個別 `.md` に。
- 古いものは `archive/` に退避

### 保存先パス

```
~/.claude/projects/-Users-<your-name>/memory/
├── MEMORY.md                # 索引（必ずここに 1 行追加）
├── user-role.md             # type: user
├── feedback-no-mocks.md     # type: feedback
├── project-q3-launch.md     # type: project
├── reference-linear-ingest.md  # type: reference
└── archive/                 # 古くなったもの
```

`install.sh` がディレクトリ作成と `MEMORY.md.template` の初期配置を行います。

---

## ② instinct システム

Claude Code が **どのツールをいつ何回呼んだか** を全部ログに取り、パターンを可視化・進化させる仕組み。

### 構成要素

| Layer | 役割 | ファイル |
|---|---|---|
| **観察** | 全 tool 呼び出しを記録 | `hooks/learning-observer.sh` (Pre/PostToolUse) |
| **保管** | 観察ログを蓄積 | `~/.claude/instincts/observations.jsonl` |
| **可視化** | パターン抽出・統計表示 | `/instinct`（command） |
| **昇格** | 観察 → 永続メモリ | `/learn-eval`（command） |
| **進化** | パターンからスキル抽出 | `skills/self-improving-agent` |

### 自動ループ

```
PreToolUse(全ツール)
   ↓ learning-observer.sh が観察を ~/.claude/instincts/ に書く
PostToolUse(全ツール)
   ↓ learning-observer.sh が完了状態を追記
   …（積もる）
ユーザー: /instinct
   ↓ 観察を集計してダッシュボード表示
   ↓ 「観察数 50 以上、これは昇格すべきパターン」と提案
ユーザー: /learn-eval
   ↓ 提案されたパターンを memory に昇格
   ↓ MEMORY.md に index 追記
（次のセッションで Claude が自然に発揮）
```

### 何を観察しているか

`hooks/learning-observer.sh` は以下を JSONL で `~/.claude/instincts/` に書きます:

- ツール名（`Read`, `Bash`, `WebFetch`, MCP 名等）
- 呼ばれた頻度
- セッション中の前後関係（連鎖パターン）
- 成功/失敗（PostToolUse でステータス）
- timestamp

### `/instinct` の出力例

```
📊 観察期間: 2026-04-01 〜 2026-05-13 (43 日)
─────────────────────────────────────
TOP 連鎖パターン:
  1. Read → Edit → Bash         (87 回)  ← 実装ループ
  2. Grep → Read → Edit          (62 回)  ← 調査→修正
  3. WebFetch → Write            (38 回)  ← リサーチ蓄積

頻出 MCP:
  1. mcp__exa__web_search_exa    (29)
  2. mcp__notion__notion-search  (18)

未使用エージェント:
  - tracer (0 回, 30日)
  - verifier (1 回, 30日)
  → 廃止候補？

昇格候補（高頻度・未メモリ化）:
  ✱ 「WebFetch → Write」パターン → リサーチ自動蓄積を memory 化？
```

### `/learn-eval`

`/instinct` が提案したパターンを **永続メモリ** に昇格する coupling コマンド。型 (feedback / user / project / reference) を選んで `~/.claude/projects/...memory/` に書き込みます。

詳細: [`instinct-and-evolution.md`](./instinct-and-evolution.md)

---

## ③ self-improving-agent（skill）

[`skills/self-improving-agent`](../skills/self-improving-agent/SKILL.md) は **メモリ自体** を整える skill。

### 何ができるか

1. **MEMORY.md 棚卸し** — 重複・古い・参照されてないメモリを検出
2. **パターン昇格** — 何度も指示されているけどメモリ化されてない行動を抽出
3. **スキル抽出** — 似たような command を何度も書いていたら skill 化を提案
4. **健康診断** — MEMORY.md の行数・サイズ・frontmatter 完整性チェック

### 起動

```
/self-improving-agent          # フル棚卸し
/self-improving-agent health   # 健康診断だけ
/self-improving-agent promote  # 昇格候補を抽出
```

または **キーワード自動発動**: 「メモリ整理」「メモリ健康診断」「パターン昇格」「MEMORY 棚卸し」

### いつ走らせるか

- 月 1 回（カレンダー登録推奨）
- MEMORY.md が 150 行を超えたら
- セッション直後に「これメモリにしたい」と思った時
- `/audit` のスコアが下がった時

---

## ④ governance / health（hook）

セキュリティと環境健全性の自動チェック。`/audit` でレポート化される。

### 構成

| Hook | タイミング | 役割 |
|---|---|---|
| `governance-capture.sh` | PreToolUse(Bash) | 危険コマンド・シークレット漏洩を検出、`~/.claude/governance.log` に記録 |
| `block-no-verify.sh` | PreToolUse(Bash) | `git commit --no-verify` 等をブロック |
| `health-check.sh` | SessionStart | ディスク・メモリ・プロセス数チェック |
| `doc-file-warning.sh` | PreToolUse(Write) | 不要なドキュメント増殖を警告 |

### 何を見ているか

`governance-capture.sh` は:
- `rm -rf` / `git push --force` / `curl -d` 等のリスク高コマンド
- `.env*` / `*.pem` / `*.key` への参照
- ハードコードされた API key / token 形式（`sk-...`, `AKIA...` 等）
- 外部送信を含む怪しいワンライナー

検出時はログに残し、`/audit security` で集計します。

### `/audit` の連動

```
/audit            # フル監査（Harness + Security + Skills）
/audit harness    # 環境スコアリングだけ
/audit security   # governance ログ集計だけ
/audit skills     # skill 棚卸しだけ
```

詳細: [`doctor-explained.md`](./doctor-explained.md)（環境診断側）+ [`hooks-explained.md`](./hooks-explained.md)（hook の仕組み）

---

## 4 層の連動シナリオ

リアルな育成サイクルは以下のように回ります:

### 1 ヶ月目（観察フェーズ）
- 何も意識せず CC を使い続ける
- hook が裏でログを溜める
- ユーザーが「テストでモック禁止」と一度言う → Claude が `feedback-no-mocks.md` 保存

### 1 ヶ月の節目
- `/audit` を実行。スコアが B+
- security レポートで `rm -rf` 警告が 3 回 → 改善ポイント
- `/instinct` で観察を可視化 → 「WebFetch → Write が 38 回」発見

### 2 ヶ月目（昇格フェーズ）
- `/learn-eval` で「リサーチ → メモリ蓄積」のパターンを user memory に昇格
- `/self-improving-agent` でメモリ棚卸し、5 件アーカイブ
- 古い tracer agent を削除候補としてマーク

### 3 ヶ月目（進化フェーズ）
- メモリが厚くなり、Claude の判断が「あなた基準」になる
- 「リサーチして」と一言で 既定の出力フォーマット で返ってくる
- セッション開始時に前回の続きを正しく理解する

これが「育つ環境」の正体です。

---

## 設定の確認

`/doctor` で auto-learning システムの **配線状況** を確認できます:

```
✓ hooks/learning-observer.sh        active (PreToolUse, PostToolUse)
✓ hooks/governance-capture.sh       active (PreToolUse[Bash])
✓ hooks/health-check.sh             active (SessionStart)
✓ ~/.claude/instincts/              exists (1.2 MB, 43 days)
✓ ~/.claude/governance.log          exists (45 entries)
✓ MEMORY.md                          92 / 200 lines (46%)
- skills/self-improving-agent       installed (not run this month)
```

---

## 関連

- [`instinct-and-evolution.md`](./instinct-and-evolution.md) — /instinct / /learn-eval の詳細
- [`hooks-explained.md`](./hooks-explained.md) — hook の仕組み
- [`memory-system.md`](./memory-system.md) — メモリの基本
- [`doctor-explained.md`](./doctor-explained.md) — /doctor の使い方
- [`../skills/self-improving-agent/SKILL.md`](../skills/self-improving-agent/SKILL.md) — メモリ整理 skill
