# Claude Code Commands

このディレクトリには、Claude Code のカスタムスキル（スラッシュコマンド）が含まれています。
`~/.claude/commands/` にコピーまたはシンボリックリンクすることで使用できます。

## コマンド一覧

| コマンド | ファイル | 説明 |
|---------|---------|------|
| `/context` | context.md | コンテキストウィンドウの診断・コンパクト判断・トークン最適化を統合したハブ。Budget（残量確認）/ Compact（タイミング判定）/ Optimize（削減アクション）の3モードを自動判定 |
| `/audit` | audit.md | Claude Code環境の品質・セキュリティ・スキルを一括監査。Harness（70点スコアリング）/ Security（A-F評価）/ Skills（棚卸し）の3パートで構成 |
| `/aside` | aside.md | 作業中に別の小タスクを処理して元の作業に復帰するコマンド。メイン作業のコンテキストを保持したまま、サイドタスクを素早く完了させる |
| `/blueprint` | blueprint.md | 1行の目標をマルチセッションの実行計画に変換。Research → Design → Draft → Review → Register の5フェーズで大きなプロジェクトを構造化する |
| `/learn-eval` | learn-eval.md | セッション中に発見したTips・解決パターンを振り返り、品質評価（Save/Improve/Absorb/Drop）してからメモリに保存するコマンド |
| `/save-session` | save-session.md | 作業の中断時にセッション状態を構造化して保存する手動保存コマンド。失敗したアプローチを含む詳細な記録を残す |
| `/resume-session` | resume-session.md | `/save-session` で保存したセッション状態を読み込み、中断した作業を再開するコマンド。前回の失敗を繰り返さないよう警告する |
| `/de-sloppify` | de-sloppify.md | 実装完了後の「仕上げパス」スキル。HTML/CSS/JSの品質チェックリストを実行し、機能を変えずに品質を一段引き上げる |
| `/instinct` | instinct.md | ツール使用ログを分析し、ワークフローパターンを自動抽出する継続学習システム。Status（ダッシュボード）/ Evolve（パターン進化）の2モード |
| `/context-switch` | context-switch.md | 新しいClaudeセッションの思考モードを切り替える。DEV（実装）/ RESEARCH（調査）/ REVIEW（評価）の3モードを起動時に指定 |
| `/chief-of-staff` | chief-of-staff.md | メール・LINE・メッセージを仕分けし、緊急度判定（4段階）・返信ドラフト生成・対応方針を提案する参謀コマンド。関係者DBをカスタマイズして使う |

## セットアップ

```bash
# 方法1: シンボリックリンク（推奨 — ファイルを同期し続ける）
ln -s /path/to/claude-code-toolkit/commands ~/.claude/commands

# 方法2: コピー（独立して使う場合）
cp /path/to/claude-code-toolkit/commands/*.md ~/.claude/commands/
```

## カスタマイズが必要なコマンド

### `/chief-of-staff`
関係者DB（クライアント・パートナー・その他の連絡先）をあなたのビジネスに合わせて記入してください。
テンプレート形式になっているので、実際の名前・会社・関係性を埋めることで最大限機能します。

### `/context` (Optimize モード)
Step 1のbashコマンド内のメモリパスを、あなたの環境に合わせて変更してください。

### `/instinct`
`~/.claude/projects/memory/user-patterns.md` のパスを、あなたのメモリファイルの場所に合わせてください。

## スキルチェーン

完了したスキルの後に自然な次のステップを提案する:

| 完了したスキル | 次に提案 |
|--------------|---------|
| `/blueprint` | Session 1 の開始 |
| `/save-session` | 次のセッションで `/resume-session` |
| Web制作完了 | `/de-sloppify` |
| `/audit` (スコアA-以下) | 改善推奨TOP3の実行 |
| `/context` (健康度黄/赤) | `/context optimize` |
| `/instinct status` (50件以上) | `/instinct evolve` |
