---
name: Claude Code エコシステム参照
description: スキル発見プラットフォーム、Task Master AI、Remotion、NotebookLM MCP、その他の外部ツール参照情報
type: reference
---

# Claude Code エコシステム参照

## おすすめリソース

### everything-claude-code
- **GitHub**: https://github.com/affaan-m/everything-claude-code
- Claude Code のスキル・フック・設定・ベストプラクティスをまとめたコミュニティリポジトリ。スキル体系の設計思想（ハブ化・CLAUDE.md昇格・スキルチェーン）の元ネタ

### claude-peers-mcp
- **GitHub**: https://github.com/louislva/claude-peers-mcp
- 同一マシン上の複数の Claude Code インスタンスがメッセージを送り合えるMCP。並列エージェントのコーディネーションに使える

---

## 1. スキル発見プラットフォーム（全て無料）

スキル = Claude Code の能力を拡張する SKILL.md ファイル。`~/.claude/skills/` に置くだけで使える。

### SkillsMP（skillsmp.com）
- **何**: GitHub上のスキルを自動収集した最大規模のディレクトリ（96,000+件）
- **対応**: Claude Code / Codex CLI / ChatGPT
- **品質管理**: GitHub Star 2以上のみ収録。ただし玉石混交なので Star 数とREADMEで判断
- **使い方**: サイトで検索 → GitHub URL をコピー → `npx skills add <author/repo>` でインストール
- **探し方のコツ**: カテゴリフィルター（Development, Marketing, Writing等）+ キーワード検索
- **注意**: 量は最多だが、品質のばらつきが大きい。Star数順にソートして上位から見るのが効率的

### aitmpl.com（Claude Code Templates）
- **何**: スキルだけでなく Agent / Command / Hook / MCP / Settings もまとめて管理できるプラットフォーム
- **規模**: 1,000+コンポーネント
- **最大の特徴**: 「カート」機能で複数コンポーネントを一括インストールできる
- **使い方**: `npx claude-code-templates@latest --skill <category/name>`
- **探し方のコツ**: タブで種類を切り替え（Agents / Commands / Skills / Hooks / MCPs）。「Development Team」「Business Marketing」等のプリセットカテゴリが便利
- **おすすめ**: 初めてスキルを探すならここが一番整理されている

### SkillHub（skillhub.club）
- **何**: AI が5軸（実用性・明瞭性・自動化・品質・影響度）で評価済みのスキルマーケット
- **規模**: 7,000+件（S/A/B/Cランク付き）
- **最大の特徴**: 品質ランクが付いている（S=9.0+, A=8.0+）。ハズレを引きにくい
- **使い方**: 「Copy SKILL.md」ボタン → `~/.claude/skills/` に貼り付け → Claude 再起動。またはデスクトップアプリでワンクリック
- **探し方のコツ**: S/Aランクだけフィルターすれば高品質なものに絞れる

### agentskills.io
- **何**: Agent Skills 仕様のオープン標準を定義する公式サイト（Anthropic関連）
- **用途**: スキルの「仕様書」。スキルを探す場所ではなく、スキルの作り方・構造を理解する場所
- **実用的な価値**: 自分でスキルを作りたい時の設計ガイド。既存スキルを探すなら上の3サイトを使う

### まとめ: どれを使うべきか

| 目的 | 使うサイト |
|------|-----------|
| とにかく大量から探したい | SkillsMP |
| 整理されたカタログで選びたい | aitmpl.com |
| 品質が保証されたものだけ欲しい | SkillHub |
| スキルの仕組みを理解したい | agentskills.io |

### 共通インストール方法
```bash
# 方法1: npx skills（最も簡単）
npx skills add <author/repo>

# 方法2: 手動コピー
# SKILL.md をダウンロード → ~/.claude/skills/<skill-name>/SKILL.md に配置
```

---

## 2. Task Master AI（タスク管理MCP）

### 概要
PRD（製品要件書）を書くと、AIが依存関係付きのタスクリスト（tasks.json）に自動変換してくれるツール。元々Cursor用だが Claude Code でも使える。

### npmパッケージ
- **名前**: `task-master-ai`（npm）
- **GitHub**: `eyaltoledano/claude-task-master`（25,000+ Stars）

### どう動くか
1. PRD（やりたいことを文章で書く）を用意
2. Task Master が解析 → tasks.json を生成（依存関係も自動マッピング）
3. タスクを1つずつ実行・完了管理

### APIキー
- **Claude Code で使う場合: APIキー不要**（Claude Code の OAuth 経由で動く）
- 単体で使う場合は ANTHROPIC_API_KEY 等が1つ必要

### インストール（Claude Code）
```bash
claude mcp add taskmaster-ai -- npx -y task-master-ai
```

### ツールモード
- **Core**（7ツール）: トークン消費 70%削減。軽量
- **Standard**（15ツール）: バランス型
- **All**（36ツール）: 全機能

### 向いている用途
- 複数人が関わるプログラミングプロジェクトの依存関係管理
- 大規模アプリ開発（バックエンド/フロントエンド連携）
- 長期プロジェクトのタスク追跡

---

## 3. Remotion（プログラマティック動画生成）

### 概要
React で動画をプログラム的に作るフレームワーク。Claude Code 用のスキルが公式から出ている。

### Claude Code スキル（公式）
```bash
npx skills add remotion-dev/skills
```
これ1行で Claude Code に動画制作能力が追加される。

### 使い方（スキルインストール後）
1. Claude Code で「〇〇な動画を作って」と自然言語で指示
2. Claude が React/Remotion コードを自動生成
3. Remotion Studio でプレビュー → MP4にレンダリング

### 向いている用途
- データビジュアライゼーション動画
- SNS投稿用の定型動画の量産
- プロモーション・説明動画

### 注意点
- Node.js + React の環境セットアップが必要
- 動画レンダリングにマシンパワーが必要
- 複雑な動画はプロンプトだけでは難しい場面がある

### LP背景動画との比較
LP背景用途なら CSS/JS アニメーション（GSAP, Lottie 等）の方が軽量で実用的。Remotion は定型動画を大量生成するユースケースで真価を発揮する。

---

## 4. NotebookLM MCP

### 概要
Google NotebookLM を Claude Code から直接操作できる MCP サーバー。NotebookLM にアップロードした資料を Claude が検索・引用できる。

### MCPサーバー
- **GitHub**: `PleasePrompto/notebooklm-mcp`
- **npm**: `notebooklm-mcp`
- **スキル版もあり**: `PleasePrompto/notebooklm-skill`

### インストール（Claude Code）
```bash
claude mcp add notebooklm npx notebooklm-mcp@latest
```

### 認証
- **Googleアカウント必須**（NotebookLM自体がGoogleサービス）
- **APIキー不要**（ブラウザの Cookie 経由で認証。Chrome等のCookieを自動取得）
- オプションで GEMINI_API_KEY を追加すると deep_research 等の追加機能が使える

### 何ができるか
- Claude Code から NotebookLM のノートブックを検索・クエリ
- アップロードした資料（PDF、Webページ等）から引用付きの回答を取得
- 複数ノートブックを横断検索
- ライブラリ管理（ノートブック一覧取得等）

### 注意点
- ブラウザ Cookie ベースの認証なので、Google が内部APIを変更すると壊れる可能性あり
- 普段から NotebookLM を使っていないと導入メリットが薄い。まず NotebookLM 自体を試してから判断

---

## クイックリファレンス

| ツール | インストールコマンド | APIキー | 難易度 |
|--------|---------------------|---------|--------|
| スキル（汎用） | `npx skills add <author/repo>` | 不要 | 簡単 |
| Task Master AI | `claude mcp add taskmaster-ai -- npx -y task-master-ai` | CC経由なら不要 | 簡単 |
| Remotion | `npx skills add remotion-dev/skills` | 不要 | 中（環境構築必要） |
| NotebookLM MCP | `claude mcp add notebooklm npx notebooklm-mcp@latest` | Google垢のみ | 中 |
