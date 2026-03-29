# Claude Code Toolkit

Claude Code を「別物」にするセットアップキット。

Hooks（自動化）、スキル（カスタムコマンド）、メモリシステム、リファレンス集を 1 コマンドでインストール。

## 何が入っているか

| カテゴリ | 内容 | 数 |
|---------|------|----|
| **Hooks** | セッション自動保存/復元、ヘルスチェック、セキュリティ、学習観察 | 11 個 |
| **スキル** | コンテキスト管理、品質監査、セッション保存、ホテル運営 等 | 18 個 |
| **メモリシステム** | MEMORY.md + 個別ファイルのインデックス設計 | テンプレート |
| **リファレンス** | Web 制作ライブラリ 50+、デザインパターン、ホテル運営、CC エコシステム | 16 ファイル |
| **ガイド** | 初心者ガイド、ホテル経営者向け入門、Apple 級デザイン 等 | 9 ファイル |

## インストール

### 方法 1: Claude Code に頼む（最速）

Claude Code を起動して、こう打つだけ：

```
https://github.com/DBA-Japan/claude-code-toolkit をインストールして
```

Claude が自動で clone → インストール → 設定完了まで行います。許可を求められたら承認するだけ。

### 方法 2: 対話モード（自分でカスタマイズ）

```bash
git clone https://github.com/DBA-Japan/claude-code-toolkit.git
cd claude-code-toolkit
bash install.sh
```

### 方法 3: ワンライナー（クイック）

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

**既に Claude Code を使っている人も安心**: 既存の settings.json・CLAUDE.md・MEMORY.md は自動バックアップされ、上書きされません。新しい Hooks とスキルだけが追加されます。

## 含まれるスキル一覧

| コマンド | 用途 |
|---------|------|
| `/context` | コンテキストウィンドウの診断・最適化 |
| `/audit` | CC 環境の品質・セキュリティ監査 |
| `/aside` | 作業中に別タスクを処理して復帰 |
| `/blueprint` | 大きなプロジェクトの設計図作成 |
| `/learn-eval` | セッション中の学びをメモリに保存 |
| `/save-session` | セッション状態の詳細保存 |
| `/resume-session` | 保存したセッションから復元 |
| `/de-sloppify` | 実装完了後の品質クリーンアップ |
| `/instinct` | 使い方パターンの可視化・進化 |
| `/context-switch` | DEV/RESEARCH/REVIEW モード切替 |
| `/chief-of-staff` | メッセージの仕分け・緊急度判定 |
| `/guest-reply` | ゲストメッセージ返信（多言語対応） |
| `/ota-listing` | OTA 物件説明文の最適化 |
| `/review-reply` | レビュー返信の生成 |
| `/operation-manual` | 運営マニュアル・チェックリスト作成 |
| `/business-report` | 月次レポート・事業分析 |
| `/sns-post` | SNS 投稿文の生成 |
| `/admin-docs` | 行政書類・申請書の下書き |
| `/translate-hotel` | 宿泊業特化の多言語翻訳（5 言語 + 文化説明） |

## 含まれる Hooks 一覧

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
| `suggest-compact.sh` | PostToolUse | 定期的に compact を提案 |
| `pre-compact.sh` | PreCompact | 圧縮前にセッション状態を保存 |
| `parse-transcript.py` | (内部) | トランスクリプト解析 |

## リファレンス（16 ファイル）

| ファイル | 内容 |
|---------|------|
| `web-libraries.md` | 50+ ライブラリの「やりたいこと → 使うもの」辞典 |
| `design-patterns.md` | 日本 IT 企業 20 社から抽出した 8 パターン（コード例付き） |
| `design-resources.md` | X(Twitter) フォローすべきアカウント + CSS Tips コード集 |
| `design-rules.md` | AI っぽくならないデザインの禁止/必須/チェックリスト |
| `cc-ecosystem.md` | スキル発見プラットフォーム、Task Master AI、Remotion、NotebookLM MCP |
| `canvas-optimization.md` | Canvas 2D 軽量化の鉄則、表示されない 4 原因、iOS トラップ |
| `ios-safari-fixes.md` | マーキー・backdrop-filter・GPU 合成レイヤーの iOS Safari 修正パターン |
| `background-effects.md` | オーロラ、グラデーションメッシュ、マウス連動、SVG ノイズ |
| `micro-interactions.md` | 磁気ボタン、リップル、光るボーダー、カーソルフォロワー |
| `scroll-storytelling.md` | Pin / Scrub / 横スクロール / CSS scroll-driven animations |
| `typography.md` | 日本語フォント CSS 設定、混植、テキストアニメーション |
| `color-palettes.md` | 2026 年カラートレンド + 業種別パレット 5 案 |
| `clip-path-reveals.md` | セクション出現アニメ 6 手法（円拡大、ブラインド、ダイヤモンド等） |
| `section-transitions.md` | seam のないセクション色遷移 + Twilight Protocol 10 段階パレット |
| `world-class-sites.md` | Stripe / Linear / Vercel / 日本企業 TOP10 の分析 |
| `hotel-operations.md` | 宿泊施設運営リファレンス（OTA 運用、料金設定、多言語対応） |

## ガイド一覧（9 ファイル）

| ファイル | 内容 |
|---------|------|
| `getting-started.md` | Claude Code 初心者ガイド |
| `hooks-explained.md` | Hooks の仕組みと設計思想 |
| `memory-system.md` | メモリシステムの使い方 |
| `context-management.md` | コンテキストウィンドウ管理 |
| `skill-design.md` | スキルの自作方法 |
| `claude-peers.md` | マルチインスタンス連携 |
| `web-build-lessons.md` | Web 制作の致命的ミス集 & 解決パターン |
| `apple-quality-design.md` | Apple / Stripe / Linear 級デザインガイド |
| `hotel-getting-started.md` | ホテル経営者向け Claude Code 入門ガイド |

## ディレクトリ構成

```
claude-code-toolkit/
├── install.sh               # インタラクティブインストーラー
├── CLAUDE.md.template        # CLAUDE.md テンプレート
├── commands/                 # カスタムスキル (18個)
├── hooks/                    # 自動化フック (11個)
├── memory/                   # メモリシステムテンプレート
├── settings/                 # 設定テンプレート
├── references/               # Web 制作・ホテル運営リファレンス (16個)
└── guides/                   # 使い方ガイド (9個)
```

## claude-peers（マルチインスタンス連携）

複数の Claude Code インスタンスが互いに通信できる MCP サーバー。インストーラーでオプション選択可。

- 元リポジトリ: [louislva/claude-peers-mcp](https://github.com/louislva/claude-peers-mcp)

## 参考

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — CC 運用の包括的ガイド
- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)

## ライセンス

MIT
