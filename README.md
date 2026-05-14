# Claude Code Toolkit

Claude Code を「別物」にする、ファイルコピー型のセットアップキット。

**インストール後にあなたが手にするもの**:

- 入口 5 コマンド: `/web-build` `/research` `/pptx` `/video` `/ocr` + `/doctor`
- **勝手に育つ環境**: auto memory + instinct 観察 + 月次棚卸しサイクル
- 11 個の skill / 15 個の汎用 sub-agent / 6 個の絶対ルール
- Web 制作・動画・PPTX・OCR・リサーチの全パイプライン

## インストール

### 推奨: Claude Code に「インストールして」と頼む

```
https://github.com/DBA-Japan/claude-code-toolkit をインストールして
```

Claude が `git clone` → `bash install.sh --plan` → 確認 → 実行 → 環境診断まで段階的にやります。失敗箇所はバックアップから rollback 可能。

### 手動

```bash
git clone https://github.com/DBA-Japan/claude-code-toolkit.git
cd claude-code-toolkit
bash install.sh                       # 対話モード
# または
bash install.sh --profile web         # 推奨 profile を指定
bash install.sh --plan --profile web  # 実行せずプレビューだけ
bash install.sh --doctor              # 診断のみ
```

### Profile（用途別）

| Profile | 入るもの | 推奨ユーザー |
|---|---|---|
| `core` (default) | 入口 5 + 汎用裏方 + agents 15 + rules 6 + 最小 references | 全員 |
| `web` | + Web 用 skills（design-extract, gsap, hyperframes 等）+ Web references | Web 制作 |
| `media` | + 動画/音声 skills（veo3, video, notebooklm）+ media guides | 動画制作 |
| `research` | + research guides（Exa/CiNii/J-Stage）+ claude-peers ガイド | リサーチャー |
| `full` | 全部入り（上級者向け、明示警告付き） | 既に CC に慣れている人 |

Profile は **後から追加可能**:
```bash
bash install.sh --add web        # 既存に web profile を追加
bash install.sh --rollback       # 直近バックアップから復元
```

## 5 つの入口コマンド

| コマンド | 用途 | 内部で呼ぶもの |
|---|---|---|
| `/web-build` | Web 制作・デザイン実装 | designer/code-reviewer agents, design-extract/seo-audit skills |
| `/research` | リサーチ（Web/学術/競合/ライブラリ） | Exa/Perplexity/context7 MCP, CiNii/J-Stage |
| `/pptx` | 提案資料・スライド作成 | python-pptx, designer/writer agents |
| `/video` | 動画制作（写真/素材動画/HTML/URL） | veo3/video/hyperframes skills, whisper |
| `/ocr` | 画像・PDF の日本語 OCR | gemini-ocr.py（Gemini Vision） |
| `/doctor` | 環境診断・依存確認 | manifests + brew/pip/MCP/API key 状況 |

## 勝手に育つ環境

Claude Code は使うほどあなた仕様に育ちます。このキットはその自動育成を 4 層で配線:

```
① auto memory（CC 本体機能）
   └ 会話から好み・事実・参照先を自動的にメモリに保存

② instinct システム（hook + command）
   └ ツール使用ログから利用パターンを可視化・進化

③ self-improving-agent（skill）
   └ メモリの棚卸し・パターン昇格・スキル抽出

④ governance / health（hook）
   └ 危険コマンド検出 + 環境健全性の自動レポート
```

詳細: [`guides/auto-learning-system.md`](./guides/auto-learning-system.md) / [`guides/instinct-and-evolution.md`](./guides/instinct-and-evolution.md)

## ディレクトリ構成

```
claude-code-toolkit/
├── install.sh                # doctor 段階制インストーラー
├── README.md                 # この文書
├── SECURITY.md               # セキュリティ宣言
├── CONTRIBUTING.md           # 貢献ガイド（公開 allowlist 思考）
├── CLAUDE.md.template        # ~/CLAUDE.md の雛形
│
├── commands/                 # 入口 5 + 汎用裏方 17（合計 22）
├── agents/                   # 汎用 sub-agent 15
├── skills/                   # plugin-style skill 14
├── rules/                    # 絶対ルール 6
├── tools/                    # gemini-ocr.py + cdp-scripts
├── mcp-servers/              # claude-peers セットアップ + MCP 案内
├── manifests/                # skill-requirements.json（/doctor が読む）
├── hooks/                    # 11 個（最小 3 + 自動学習 8）
├── settings/                 # settings.json テンプレート
├── memory/                   # MEMORY.md テンプレート
├── references/               # Web 制作・CC 内部 リファレンス 23 個
├── guides/                   # 使い方ガイド 19 個
├── profiles/                 # profile 定義（将来拡張用）
└── docs/                     # 設計ドキュメント
    ├── AI_ASSIST_INSTALL.md  # Claude が「インストールして」と頼まれた時の手順書
    └── MIGRATION_PHASE_2.md  # Phase 2 で plugin marketplace 化する計画
```

## 設計原則

### 1. 段階制セットアップ（Codex 反証反映）
`doctor → plan → confirm → backup → install → verify → rollback hint`

「インストールして」一発で全部入る設計は **わざと採用していません**。`brew install` / `pip install` / `claude mcp add` / API key 設定は **doctor が案内するだけ** で、自動実行しない。

### 2. オプトイン徹底
デフォルト ON にしてよいのは「API キー不要・認証不要・壊れても CC 本体を巻き込まない」ものだけ:

| デフォルト ON | デフォルト OFF（オプトイン） |
|---|---|
| auto memory | Exa / Perplexity MCP |
| learning-observer hook | Playwright MCP |
| governance-capture hook | whisper-cpp / ffmpeg |
| Anthropic 公式 WebSearch | Gemini API |
| context7 / repomix MCP（無料） | NotebookLM（OAuth） |

### 3. 機密混入ゼロ
公開リポなので `gitleaks` + `detect-secrets` + 禁止語辞書 + 正規表現で CI チェック。詳細: [`SECURITY.md`](./SECURITY.md)

### 4. 公開 allowlist 思考
内部素材を移植するのではなく、**公開用に再記述** する。詳細: [`CONTRIBUTING.md`](./CONTRIBUTING.md)

## 何が入っていないか

明示しておく:

- ❌ ホテル運営 / 旅館固有のコマンド（汎用 CC に集約）
- ❌ 営業 / 商談 / 研修ヒアリング系の専門コマンド
- ❌ 特定企業・クライアント名を含む事例
- ❌ 売上数字・個別案件メモリ
- ❌ 自動で API key を環境変数に書き込む処理（信頼境界）

## トラブルシュート

| 症状 | 対処 |
|---|---|
| `/doctor` が動かない | `~/.claude/commands/doctor.md` を確認、CC 再起動 |
| MCP が登録できない | `guides/mcp-setup-full.md` |
| Skill が認識されない | `/audit skills` |
| メモリが膨らんだ | `/self-improving-agent health` |
| Hook がエラーを出す | `~/.claude/hooks/` のファイル + 実行権限を確認 |
| install.sh 失敗 | `bash install.sh --rollback` |

## 関連 / 参考

- [Claude Code 公式 docs](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)（Phase 2 で対応予定）
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — CC 運用の包括的ガイド

## ライセンス

MIT
