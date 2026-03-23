# Claude Code Toolkit

Claude Code を「別物」にするセットアップキット。

Hooks（自動化）、スキル（カスタムコマンド）、メモリシステム、リファレンス集を1コマンドでインストール。

## 何が入っているか

| カテゴリ | 内容 | 数 |
|---------|------|----|
| **Hooks** | セッション自動保存/復元、ヘルスチェック、セキュリティ、学習観察 | 11個 |
| **スキル** | コンテキスト管理、品質監査、セッション保存、学習評価 等 | 11個 |
| **メモリシステム** | MEMORY.md + 個別ファイルのインデックス設計 | テンプレート |
| **リファレンス** | Web制作ライブラリ50+、デザインパターン、CCエコシステム | 4ファイル |
| **ガイド** | 初心者ガイド、スキル設計、メモリ設計、Hooks解説 等 | 6ファイル |

## インストール

### 方法1: Claude Code に頼む（最速）

Claude Code を起動して、こう打つだけ：

```
https://github.com/DBA-Japan/claude-code-toolkit をインストールして
```

Claude が自動で clone → インストール → 設定完了まで行います。許可を求められたら承認するだけ。

### 方法2: 対話モード（自分でカスタマイズ）

```bash
git clone https://github.com/DBA-Japan/claude-code-toolkit.git
cd claude-code-toolkit
bash install.sh
```

### 方法3: ワンライナー（クイック）

```bash
git clone https://github.com/DBA-Japan/claude-code-toolkit.git && cd claude-code-toolkit && bash install.sh --quick --name "あなたの名前" --role "あなたの役割"
```

### オプション

```bash
bash install.sh --quick                    # デフォルト設定で即インストール
bash install.sh --all                      # 全コンポーネント入り
bash install.sh --quick --name "太郎"      # 名前だけ指定
bash install.sh --help                     # ヘルプ表示
```

**既にClaude Codeを使っている人も安心**: 既存の settings.json・CLAUDE.md・MEMORY.md は自動バックアップされ、上書きされません。新しいHooksとスキルだけが追加されます。

## 含まれるスキル一覧

| コマンド | 用途 |
|---------|------|
| `/context` | コンテキストウィンドウの診断・最適化 |
| `/audit` | CC環境の品質・セキュリティ監査 |
| `/aside` | 作業中に別タスクを処理して復帰 |
| `/blueprint` | 大きなプロジェクトの設計図作成 |
| `/learn-eval` | セッション中の学びをメモリに保存 |
| `/save-session` | セッション状態の詳細保存 |
| `/resume-session` | 保存したセッションから復元 |
| `/de-sloppify` | 実装完了後の品質クリーンアップ |
| `/instinct` | 使い方パターンの可視化・進化 |
| `/context-switch` | DEV/RESEARCH/REVIEWモード切替 |
| `/chief-of-staff` | メッセージの仕分け・緊急度判定 |

## 含まれるHooks一覧

| Hook | タイミング | 機能 |
|------|-----------|------|
| `load-session-summary.sh` | SessionStart | 前回セッションの要約を自動読み込み |
| `health-check.sh` | SessionStart | ディスク・メモリ・プロセス数チェック |
| `save-session-summary.sh` | Stop | セッション要約を自動保存 |
| `cleanup.sh` | Stop | ゾンビプロセス掃除・一時ファイル削除 |
| `block-no-verify.sh` | PreToolUse(Bash) | `--no-verify` をブロック |
| `governance-capture.sh` | PreToolUse(Bash) | 危険コマンド・シークレット漏洩を検出 |
| `learning-observer.sh` | PreToolUse/PostToolUse | 全ツール使用を自動記録 |
| `doc-file-warning.sh` | PreToolUse(Write) | 不要なドキュメント増殖を警告 |
| `suggest-compact.sh` | PostToolUse | 定期的にcompactを提案 |
| `pre-compact.sh` | PreCompact | 圧縮前にセッション状態を保存 |
| `parse-transcript.py` | (内部) | トランスクリプト解析 |

## ディレクトリ構成

```
claude-code-toolkit/
├── install.sh               # インタラクティブインストーラー
├── CLAUDE.md.template        # CLAUDE.md テンプレート
├── commands/                 # カスタムスキル
├── hooks/                    # 自動化フック
├── memory/                   # メモリシステムテンプレート
├── settings/                 # 設定テンプレート
├── references/               # Web制作・CCリファレンス
└── guides/                   # 使い方ガイド
```

## claude-peers（マルチインスタンス連携）

複数のClaude Codeインスタンスが互いに通信できるMCPサーバー。インストーラーでオプション選択可。

- 元リポジトリ: [louislva/claude-peers-mcp](https://github.com/louislva/claude-peers-mcp)

## 参考

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — CC運用の包括的ガイド（本ツールキットの一部はここから着想）
- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)

## ライセンス

MIT
