# /doctor — 環境診断の使い方

`/doctor` は claude-code-toolkit の **核** です。何かが動かないとき、新機能を使い始めるとき、必ず最初に叩くコマンド。

## 段階制設計（なぜそうしてあるか）

「インストールして」一発で全部入る設計を **わざと採用していません**。Codex 反証を取り入れた段階制:

```
doctor → plan → confirm → backup → install → verify → rollback hint
```

各段階でユーザーが「yes」と言わないと次に進みません。理由は:
- API key、brew install、MCP 登録、外部リポクローン は **信頼境界を越える操作**
- 半分失敗して何が壊れたか分からない事態を避ける
- 「Claude Code に丸投げ」しても、何を変更するか先に提示してから動く

## モード一覧

```bash
/doctor              # フル診断
/doctor mcp          # MCP の登録状況だけ
/doctor api          # API キーの設定状況だけ
/doctor brew         # brew パッケージだけ（ffmpeg, whisper-cpp 等）
/doctor python       # Python deps だけ
/doctor node         # Node / npm deps だけ
/doctor profile web  # 特定 profile が要求する依存
/doctor learning     # 自動学習システムの配線確認
/doctor security     # シークレット漏れ・hook 健全性
```

## フル診断の出力（実機）

```
🩺 CLAUDE CODE TOOLKIT — DOCTOR REPORT
════════════════════════════════════════
Profile: core + web
OS: Darwin 25.4.0 (arm64)
Shell: zsh 5.9
CC: claude-code 1.x.x
========================================

[1/6] ベース環境
  ✓ python3              Python 3.13.0
  ✓ node                 v22.5.0
  ✗ bun                  → curl -fsSL https://bun.sh/install | bash
  ✓ brew                 Homebrew 4.3.10
  ✓ git                  2.43.0
  ✓ gh                   2.62.0
  ✓ curl                 8.7.1

[2/6] brew パッケージ（profile web に必要）
  ✓ ffmpeg               /opt/homebrew/bin/ffmpeg
  ✗ whisper-cpp          → brew install whisper-cpp
  ✓ yt-dlp               /opt/homebrew/bin/yt-dlp
  - libreoffice          (任意) → brew install --cask libreoffice

[3/6] Python パッケージ
  ✓ google-genai         (Gemini OCR / VEO3)
  ✗ python-pptx          → pip install --user python-pptx
  ✓ websockets           (cdp-scripts)
  ✓ requests             (cdp-scripts)

[4/6] MCP 登録
  ✓ context7             connected
  ✓ repomix              connected
  ✗ exa                  → claude mcp add exa npx -y exa-mcp
  ✗ playwright           → claude mcp add playwright npx -y @microsoft/playwright-mcp
  - perplexity           (任意, profile research)
  - claude-peers         (任意, multi-instance)

[5/6] API キー (環境変数)
  ✓ GEMINI_API_KEY       (set)
  ✗ EXA_API_KEY          → https://exa.ai/ で取得後 ~/.zshrc に追記
  - PERPLEXITY_API_KEY   (任意)
  - OPENAI_API_KEY       (任意, /codex 用)

[6/6] 自動学習システム
  ✓ hooks/learning-observer.sh    active (Pre/PostToolUse)
  ✓ hooks/governance-capture.sh   active (PreToolUse[Bash])
  ✓ ~/.claude/instincts/          exists (1.2 MB, 43 days)
  ✓ ~/.claude/governance.log      exists (45 entries)
  ✓ MEMORY.md                      92 / 200 lines (46%)

────────────────────────────────────────
🟢 致命的問題: 0
🟡 警告: 4 件（whisper-cpp / python-pptx / exa MCP / EXA_API_KEY）
🟢 推奨アクション:
  1. brew install whisper-cpp           (動画字幕)
  2. pip install --user python-pptx     (/pptx)
  3. https://exa.ai/ で API key 取得 → ~/.zshrc 追記
  4. claude mcp add exa npx -y exa-mcp

→ 全部やるなら次のコマンドをコピペ:
   brew install whisper-cpp && \
   pip install --user python-pptx
   (Exa は手動)
```

## 自動修正は **しない** 設計

`/doctor` は診断結果に基づいて何かを **実行しません**。代わりに「次にこれをやってください」というコマンドを表示するだけ。理由:

1. **信頼境界**: brew install / pip install / claude mcp add は権限・ネットワーク・課金が絡む
2. **冪等性の確認**: ユーザー自身が pre/post で何が変わるか把握する余地を残す
3. **rollback の単純化**: 自動実行しなければ rollback も「実行しない」だけで済む

「全部入れて」と言いたい時は: `/doctor` の出力をユーザー自身がコピペして実行する。

## オプトイン哲学

| 機能 | デフォルト | 理由 |
|---|---|---|
| auto memory（本体機能） | ON | Claude Code 自動、コスト 0 |
| learning-observer hook | ON | 軽量、ログ取りのみ |
| governance-capture hook | ON | 軽量、安全強化 |
| Anthropic 公式 WebSearch | ON | 標準同梱 |
| context7 / repomix MCP | OFF | claude mcp add 必要 |
| Exa / Perplexity MCP | OFF | API key 必要 |
| Playwright MCP | OFF | chromium 必要、重い |
| whisper-cpp / ffmpeg / libreoffice | OFF | brew install 必要、容量大 |
| python-pptx / google-genai | OFF | pip 必要 |
| claude-peers | OFF | bun + 別 repo |

「全部使える」と謳いつつ実際は半分動かない事態を避けるため、**必要になった機能だけ** 個別にオプトインする方針です。

## トラブルシュート

### `/doctor` が「⊘ コマンドが認識されません」と返す
- `~/.claude/commands/doctor.md` が存在するか確認
- CC を再起動

### MCP の確認が `error` を返す
- `claude mcp list` を直接 Bash で実行
- MCP server プロセスが死んでないか `ps aux | grep mcp`

### API key が「設定済み」と出るのに動かない
- `echo $EXA_API_KEY` で値を確認
- `~/.zshrc` の追記後、新しい shell を起動したか確認
- CC を再起動

### `~/.claude/instincts/` が見つからない
- `install.sh` の Phase が古い可能性
- `mkdir -p ~/.claude/instincts ~/.claude/session-summaries ~/.claude/session-saves`

## ロールバック

`install.sh` を再実行する前に、何が変わるか必ず:

```bash
bash install.sh --plan --profile web
# ← 「これから何が入るか」が表示される、実行はしない
```

実行後の rollback:

```bash
bash install.sh --rollback
# ← 最後のバックアップ（settings.json と CLAUDE.md）から復元
```

## 関連

- [`auto-learning-system.md`](./auto-learning-system.md)
- [`mcp-setup-full.md`](./mcp-setup-full.md)
- [`../commands/doctor.md`](../commands/doctor.md)
- [`../manifests/skill-requirements.json`](../manifests/skill-requirements.json)
