---
name: CCスキルシステム内部動作
description: スキル発見・マッチング・ロード・description250文字上限・バジェット16K文字・paths条件付きロード・context:fork・model指定。リーク分析から抽出
type: reference
---

# Claude Code スキルシステム内部動作（2026-03-31リークから抽出）

## スキルの発見・マッチング
- マッチングはClaude自身のtransformer推論で行われる（キーワードマッチではない）
- 全スキルのname+descriptionが`<available_skills>`リストとしてSkillToolプロンプト内に生成
- `/xxx`直接入力 → ファイル名マッチ
- 自然言語入力 → descriptionベースでClaude自身が判断

## 2段階ロード
- **第1段階（常時）**: メタデータ（name+description）のみ。約100トークン/スキル
- **第2段階（呼び出し時）**: SKILL.md全文ロード。最大5,000トークン/スキル
- `paths:`フロントマター付きスキルは第1段階すらスキップ → コンテキスト節約

## description予算
- 総バジェット: 約15,500〜16,000文字
- 各descriptionの上限: 250文字（超過分は切り捨て）
- 各スキルのオーバーヘッド: 約109文字
- 平均descriptionで最大約42スキル表示
- 130文字以下に圧縮すれば最大約65スキル
- 環境変数 `SLASH_COMMAND_TOOL_CHAR_BUDGET=32000` でバジェット拡張可能

## 優先順位
- 明示的な優先順位ロジックはない。Claudeモデルが判断
- descriptionの具体性が高いほどマッチ精度UP
- descriptionの先頭250文字が切り捨て後も残る → トリガーキーワードは先頭に

## フロントマター全フィールド
- `name`: スキル名
- `description`: 250文字上限。マッチングの生命線
- `disable-model-invocation`: trueでClaude自動発動禁止（/入力のみ）
- `user-invocable`: falseで/入力禁止（Claude専用背景知識向き）
- `allowed-tools`: 使えるツールを制限
- `context`: `fork`でサブエージェント実行（会話履歴なし）
- `agent`: サブエージェント種類（Explore/Plan/general-purpose）
- `model`: 実行モデル指定（Sonnet/Haikuでコスト最適化）
- `paths`: globパターン。マッチするファイルに触れた時だけアクティブ
- `argument-hint`: 引数のヒント表示

## コスト最適化Tips
- 単純な検索・確認作業は `context: fork` + `model: haiku` でコスト削減
- `paths:` で条件付きロードするとメタデータのコンテキスト消費もゼロに
- 42スキル超えそうなら `SLASH_COMMAND_TOOL_CHAR_BUDGET=32000` を.zshrcに追加
