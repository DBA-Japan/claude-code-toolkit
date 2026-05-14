# /instinct と進化サイクル — Claude Code を「自分仕様」に育てる

`/instinct` と `/learn-eval` は、**観察したパターンを永続知見に昇格** するための双子コマンドです。観察だけでは Claude は育ちません。**昇格** という人間のレビューを挟むことで、ノイズではなく価値のあるパターンだけが残ります。

## なぜこの 2 段構えか

| 仕組み | 良い点 | 悪い点 |
|---|---|---|
| **観察だけ** | コスト 0 で全部記録 | ノイズが混じる、重要度が分からない |
| **観察 → 自動昇格** | 完全自動 | 偶然のパターンを「あなたの好み」と誤認するリスク |
| **観察 → 人間レビュー → 昇格**（採用） | ノイズ排除、根拠付きメモリ | 月 1 で手間がかかる |

採用したのは 3 番目。Codex 反証「自動学習は誤学習を生む。人間の gating を入れろ」を取り入れた設計です。

---

## サイクル全体図

```
[Day 1〜30: 観察]
   PreToolUse / PostToolUse hooks (learning-observer.sh)
        ↓
   ~/.claude/instincts/observations.jsonl
   ~/.claude/instincts/sessions.jsonl
        ↓
[月 1: 可視化]
   /instinct
        ↓
   ダッシュボード表示（連鎖パターン / 頻出ツール / 未使用エージェント）
        ↓
[人間レビュー]
   どれを昇格するか選ぶ
        ↓
[昇格]
   /learn-eval
        ↓
   ~/.claude/projects/.../memory/<name>.md
   MEMORY.md にも index 追記
        ↓
[次のセッション]
   SessionStart で MEMORY.md が読み込まれる
   関連メモリが必要に応じて参照される
   → Claude の判断が「あなた基準」に近づく
```

---

## `/instinct` — パターン可視化

### モード

```
/instinct             # フルダッシュボード
/instinct status      # サマリー 1 画面
/instinct evolve      # 昇格候補を抽出 → /learn-eval に渡せる形に
/instinct chains      # 連鎖パターン特化（A → B → C）
/instinct dormant     # 一度も呼ばれてないツール・エージェント
/instinct mcp         # MCP 呼び出しの頻度
```

### 出力例（実機）

```
📊 INSTINCT DASHBOARD                    観察期間: 43 days
═══════════════════════════════════════════════════════
セッション数        : 87
ツール呼び出し総数  : 4,231
平均 / セッション    : 48.6

🔗 TOP 連鎖パターン（A → B → C で頻度高）
  1. Read → Edit → Bash               87 回 ← 実装ループ
  2. Grep → Read → Edit                62 回 ← 調査→修正
  3. WebFetch → Write                  38 回 ← リサーチ蓄積
  4. Bash(git status) → Bash(git diff) 31 回 ← コミット前確認
  5. Agent(Explore) → Read → Edit     24 回 ← 並列調査→実装

🛠️  TOP ツール
  1. Read                              892
  2. Bash                              663
  3. Edit                              548
  4. Grep                              321
  5. Write                             198

🌐 TOP MCP
  1. mcp__exa__web_search_exa          29
  2. mcp__notion__notion-search        18
  3. mcp__playwright__browser_navigate  8

⚠️  Dormant（30 日間 0 回）
  - agents/tracer
  - agents/verifier
  - skills/seo-audit

✱ 昇格候補
  - 「WebFetch → Write」(38 回): user memory にリサーチ自動蓄積を書く？
  - 「git status → git diff」(31 回): コミット前自動表示の hook 化？
  - Bash `pip install --user google-genai` (7 回): 環境セットアップを doctor 化？

→ /learn-eval で昇格 / 廃止判断
```

---

## `/learn-eval` — 観察を永続メモリに昇格

`/instinct evolve` で抽出された昇格候補を、メモリ型 (feedback / user / project / reference) に分類して保存します。

### 起動

```
/learn-eval                              # フルレビュー
/learn-eval "<昇格したいパターン>"        # 直接指定
/learn-eval evolve                       # /instinct evolve の結果を消費
```

### 対話の流れ

```
You: /learn-eval

Claude: 昇格候補 3 件があります:
  1. WebFetch → Write (38 回)
  2. git status → git diff (31 回)
  3. pip install --user google-genai (7 回)

  どれを昇格しますか？
  > 1 を昇格、type は？
  > "feedback"（行動ルール）/ "user"（あなたの好み）/
  > "project"（プロジェクト固有）/ "reference"（外部リソース）

You: 1, feedback

Claude: 「リサーチ後は memory に蓄積する」を feedback として保存します。
        Why（理由）と How to apply（適用範囲）を教えてください。

You: Why は「過去のリサーチを使い回せて時短になる」
     How to apply は「3 回以上同じ調べ物をしそうな時」

Claude: 保存しました:
        ~/.claude/projects/-Users-you/memory/feedback-research-to-memory.md
        MEMORY.md に index 追加:
        - [リサーチ後は memory に蓄積](feedback-research-to-memory.md)
```

### 保存される .md

```markdown
---
name: feedback-research-to-memory
description: リサーチ後は memory に蓄積する
metadata:
  type: feedback
---

リサーチ後は memory に蓄積する。

**Why:** 過去のリサーチを使い回せて時短になる。
**How to apply:** 3 回以上同じ調べ物をしそうな時。
```

---

## 月次運用テンプレ

カレンダーに登録推奨:

```
🗓️  毎月 1 日 11:00 — Claude Code 環境棚卸し（15 分）

1. /audit                  → スコア確認 (目標: A-以上)
2. /instinct               → 観察ダッシュボード確認
3. /instinct evolve        → 昇格候補抽出
4. /learn-eval evolve      → 良いものだけ昇格
5. /self-improving-agent   → メモリ棚卸し（重複・古いものをarchive）
6. /audit skills           → 未使用 skill を retire 候補化
7. 棚卸しメモを project memory に保存
```

---

## アンチパターン

### ❌ 全部昇格する

観察 100 件あったら 100 件全部 memory にしない。**月 1〜3 件** が健全。MEMORY.md は索引なので、200 行・25 KB を超えると Claude Code 本体がサイレント切り捨てします。

### ❌ feedback と user を混ぜる

- **feedback** = 行動ルール（「これはやって／やめて」）
- **user** = あなたの背景・好み（「React 5 年」「日本語 UI 中心」）

混ぜると Claude の参照効率が落ちます。

### ❌ Why を書かない

未来の自分が「これなんで書いた？」となって死蔵します。**Why と How to apply** は最低限。

### ❌ project メモリを使い回す

project は「今のプロジェクトだけ」のもの。次のクライアントには無関係。プロジェクト終了時に `archive/` に移すか、削除する。

---

## 進化の停滞シグナル

以下が出たら、サイクルが回ってない:

- `/instinct` のセッション数が 1 ヶ月で 0 増加 → CC を使ってない（OK）
- `/instinct` 観察 100+ なのに `/learn-eval` 0 → 昇格していない、月次棚卸しを動かす
- MEMORY.md が 180 行超 → アーカイブ作業を `/self-improving-agent` で
- `/audit` スコアが 3 ヶ月連続で下降 → hook が壊れてる可能性、`/doctor` で確認

---

## 関連

- [`auto-learning-system.md`](./auto-learning-system.md) — 4 層の全体像
- [`memory-system.md`](./memory-system.md) — メモリの基本
- [`doctor-explained.md`](./doctor-explained.md) — 環境診断
- [`hooks-explained.md`](./hooks-explained.md) — hook の仕組み
- [`../skills/self-improving-agent/SKILL.md`](../skills/self-improving-agent/SKILL.md)
