# Doctor（環境診断ハブ）

Claude Code Toolkit が要求する依存（API キー / MCP / brew パッケージ / Python / Node 等）の有無を診断し、不足があれば取得手順を案内します。

## 起動

```
/doctor              # フル診断
/doctor mcp          # MCP のみ
/doctor api          # API キーのみ
/doctor brew         # brew 系（ffmpeg, whisper-cpp, yt-dlp, libreoffice）のみ
/doctor python       # Python deps のみ
/doctor profile web  # 特定 profile が要求する依存だけ確認
```

引数: $ARGUMENTS

## 動作仕様

Claude が以下を順に実行して結果を表に出す。**API キーの取得や brew install を自動実行しない**。常に「取得 URL / 取得コマンド」を提示するだけで、ユーザーが手で実行する。

### 1. ベース環境

| 依存 | 確認方法 | 不足時の案内 |
|---|---|---|
| `python3` | `command -v python3` | https://www.python.org/downloads/ |
| `node` | `command -v node` | https://nodejs.org/ |
| `bun` | `command -v bun` | `curl -fsSL https://bun.sh/install \| bash` |
| `brew` | `command -v brew` | https://brew.sh/ |
| `gh` | `command -v gh` | https://cli.github.com/ |
| `git` | `command -v git` | 必須 |
| `curl` | `command -v curl` | 必須 |

### 2. brew パッケージ（オプトイン依存）

| パッケージ | 用途 | コマンド |
|---|---|---|
| `ffmpeg` | `/video` の動画処理 | `brew install ffmpeg` |
| `whisper-cpp` | `/video` の文字起こし | `brew install whisper-cpp` |
| `yt-dlp` | `/video` の動画取得 | `brew install yt-dlp` |
| `libreoffice` | PPTX → PDF 変換（任意） | `brew install --cask libreoffice` |

### 3. Python パッケージ

| パッケージ | 用途 | コマンド |
|---|---|---|
| `google-genai` | `/ocr`, `/video` の veo3 | `pip install --user google-genai` |
| `python-pptx` | `/pptx` の生成 | `pip install --user python-pptx` |
| `websockets`, `requests` | `tools/cdp-scripts/` | `pip install --user websockets requests` |

### 4. MCP サーバ

`claude mcp list` を実行して登録状態を確認。未登録のものは登録コマンドを表示するだけ。

| MCP | 用途 | 登録コマンド |
|---|---|---|
| `exa` | `/research` Web 検索 | `claude mcp add exa npx -y exa-mcp` |
| `perplexity` | `/research` 鮮度命リサーチ | `claude mcp add perplexity npx -y perplexity-mcp` |
| `playwright` | Web 抽出・スクレイピング | `claude mcp add playwright npx -y @microsoft/playwright-mcp` |
| `context7` | ライブラリ docs | `claude mcp add context7 npx -y @upstash/context7-mcp` |
| `repomix` | リポジトリ解析 | `claude mcp add repomix npx -y repomix` |
| `claude-peers` | マルチインスタンス通信 | `mcp-servers/claude-peers-setup.md` を参照 |

### 5. API キー（環境変数）

`~/.zshrc` または `~/.bash_profile` に以下が設定されているか確認。

| 環境変数 | 用途 | 取得 |
|---|---|---|
| `GEMINI_API_KEY` | `/ocr`, `/video` veo3 | https://aistudio.google.com/apikey |
| `EXA_API_KEY` | `/research` Exa | https://exa.ai/ |
| `PERPLEXITY_API_KEY` | `/research` Perplexity | https://perplexity.ai/ |
| `OPENAI_API_KEY` | `/codex` セカンドオピニオン（任意） | https://platform.openai.com/api-keys |

### 6. 出力フォーマット

```
✓ python3            (Python 3.13.0)
✓ node               (v22.5.0)
✗ bun                → 取得: curl -fsSL https://bun.sh/install | bash
✓ brew               (Homebrew 4.3.10)
- ffmpeg             ✓ /opt/homebrew/bin/ffmpeg
- whisper-cpp        ✗ → brew install whisper-cpp
✓ GEMINI_API_KEY     (環境変数で設定済み)
✗ EXA_API_KEY        → https://exa.ai/ で取得後、~/.zshrc に追記
```

## 安全境界

1. **diagnostic-only**。`/doctor` は**インストール・登録・API キー設定を自動実行しない**
2. 確認用に Bash で `command -v` / `claude mcp list` を読み取り限定で叩く
3. 不足するものは「取得 URL / 取得コマンド」だけ提示し、ユーザーが手で実行
4. すべての MCP 登録 / brew install / pip install は **ユーザー承認** で実行

## 関連

- `references/cc-environment-map.md` — CC 環境の全体像
- `manifests/skill-requirements.json` — skill ごとの依存マニフェスト
- `mcp-servers/claude-peers-setup.md` — claude-peers セットアップ
- `guides/mcp-setup-full.md` — MCP 登録の全パターン
