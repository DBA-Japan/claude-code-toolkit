# agents/

汎用 sub-agent（`.md` 形式）。Claude Code の `Agent` ツールから `subagent_type` で呼び出します。

## 含まれるもの

| Agent | 役割 | モデル傾向 |
|---|---|---|
| `analyst` | 要件分析・事前コンサル（Opus） | Opus |
| `architect` | 戦略アーキテクチャ・デバッグ助言（Opus、READ-ONLY） | Opus |
| `code-reviewer` | コードレビュー（severity 評価込み） | Sonnet/Opus |
| `code-simplifier` | コードの簡素化・整理 | Sonnet |
| `critic` | 計画・コードの多角レビュー（Opus） | Opus |
| `debugger` | 根本原因解析・回帰分離 | Sonnet |
| `designer` | UI/UX 設計（Sonnet） | Sonnet |
| `document-specialist` | 外部資料 / リファレンス調査 | Sonnet |
| `executor` | 実装担当（Sonnet） | Sonnet |
| `explore` | コードベース探索（read-only） | Haiku/Sonnet |
| `git-master` | git の atomic commit, rebase, 履歴管理 | Sonnet |
| `planner` | 戦略計画（Opus） | Opus |
| `tracer` | 因果追跡・仮説検証 | Sonnet |
| `verifier` | 検証戦略・完成度チェック | Sonnet |
| `writer` | 技術文書執筆（Haiku） | Haiku |

## 配置方法

`install.sh` が `~/.claude/agents/` にコピーします。

## 使い方

```
Agent({
  subagent_type: "explore",
  description: "Search auth module",
  prompt: "Find all files that handle JWT verification."
})
```
