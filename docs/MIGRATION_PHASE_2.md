# Phase 2 — Anthropic Plugin Marketplace への移行計画

このドキュメントは **次のフェーズの設計図** です。Phase 1（現状: ファイルコピー型）が安定したら Phase 2 として実施。

## なぜ Plugin marketplace に移行するか

Codex 反証で指摘されたとおり、Anthropic 公式の plugin エコシステムは:

- `commands/` / `agents/` / `skills/` / `hooks/` / MCP 設定を **plugin として配布可能**
- バージョン管理 / 更新通知 / 依存解決が公式仕様で組み込まれている
- standalone `.claude/` は **個人・プロジェクト用**、plugins は **チーム・コミュニティ配布向け**

出典:
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Discover Plugins](https://code.claude.com/docs/en/discover-plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## 想定される構造

Phase 2 では現在の単一リポを **複数 plugin に分割**:

```
cct-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    ├── cct-core/
    │   ├── plugin.json
    │   ├── commands/         # 入口 5 + 汎用裏方
    │   ├── agents/
    │   ├── rules/
    │   └── hooks/
    ├── cct-web/
    │   ├── plugin.json
    │   ├── skills/           # design-extract, gsap, hyperframes...
    │   └── references/
    ├── cct-media/
    │   ├── plugin.json
    │   └── skills/           # veo3, video, notebooklm
    ├── cct-research/
    │   ├── plugin.json
    │   └── skills/           # exa-cinii-jstage 系
    └── cct-office/
        ├── plugin.json
        └── skills/           # pptx
```

Plugin 単位で:

```bash
claude plugin install cct-core
claude plugin install cct-web
claude plugin install cct-media
```

## marketplace.json の例

```json
{
  "name": "claude-code-toolkit",
  "version": "2.0.0",
  "description": "Claude Code を別物にするセットアップキット",
  "repository": "https://github.com/DBA-Japan/claude-code-toolkit",
  "plugins": [
    {
      "name": "cct-core",
      "path": "./plugins/cct-core",
      "description": "入口 5 コマンド + 汎用裏方"
    },
    {
      "name": "cct-web",
      "path": "./plugins/cct-web",
      "description": "Web 制作 skills + references",
      "requires": ["cct-core"]
    },
    {
      "name": "cct-media",
      "path": "./plugins/cct-media",
      "description": "動画/音声 skills",
      "requires": ["cct-core"]
    },
    {
      "name": "cct-research",
      "path": "./plugins/cct-research",
      "description": "リサーチ guides",
      "requires": ["cct-core"]
    }
  ]
}
```

## 移行ステップ

### Step 1: Phase 1 安定化（現在進行中）
- ファイルコピー型で 1 ヶ月運用
- バグ報告・改善 PR を受け付ける
- references の汎用化再記述（Phase 1.5）

### Step 2: plugin 分割
- 上記構造で `plugins/` 配下に再配置
- 各 `plugin.json` を作成
- `marketplace.json` を root に配置

### Step 3: install.sh の役割縮小
- Phase 2 では `install.sh` の役割は:
  - 公式 plugin marketplace 未対応の CC バージョン向け fallback
  - Phase 1 → Phase 2 の移行補助
  - doctor + MCP 対話セットアップ

### Step 4: README 書き換え
```
推奨インストール:
  claude plugin add https://github.com/DBA-Japan/claude-code-toolkit

旧方式（Phase 1 互換）:
  bash install.sh --profile web
```

### Step 5: 旧方式の deprecate
- 6 ヶ月の併用期間
- その後、`install.sh` をアーカイブ

## 互換性のコミットメント

Phase 1 → Phase 2 の移行で、ユーザーの:
- メモリ（`~/.claude/projects/*/memory/`）
- 既存 settings.json の hooks
- カスタマイズした CLAUDE.md

**は壊れません**。plugin 化はあくまで配布方式の変更で、ファイル配置は同じ。

## タイムライン（暫定）

| 時期 | フェーズ |
|---|---|
| 2026 Q2 | Phase 1 リリース（このリポ） |
| 2026 Q2-Q3 | Phase 1.5: references 汎用化、PR フィードバック吸収 |
| 2026 Q3 | Phase 2 設計開始、plugin 分割実験 |
| 2026 Q4 | Phase 2 リリース |
| 2027 Q1-Q2 | 旧方式 deprecation 期間 |
| 2027 Q3 | install.sh アーカイブ |

## 未解決事項

- Plugin marketplace の認証・配布フローの公式仕様確定待ち
- 依存解決の sequencing（cct-core が先、その後 cct-web）
- バージョン互換性（CC 本体側のバージョン跨ぎ）

これらは Phase 2 着手時に再評価。
