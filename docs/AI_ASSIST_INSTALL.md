# Claude へ — 「インストールして」と頼まれた時の手順書

このドキュメントは **Claude Code（Claude）が読む手順書** です。ユーザーが README の 1 行インストールフロー（`https://github.com/DBA-Japan/claude-code-toolkit をインストールして`）を実行した時、Claude はこのファイルを読みながらインタラクティブにインストールを進めてください。

---

## 全体方針

「ワンクリック全自動」ではなく、**ユーザー承認を都度取る段階制** で進めます。理由は信頼境界（API キー / brew install / MCP 登録 / `~/.zshrc` 編集 は元に戻しにくい）。

## ステップ 0: 前提確認（自動）

Claude は以下を Bash で確認してから次に進む:

```bash
command -v git curl python3 bash
```

不足があれば、ユーザーに「Mac なら `brew install ...` で取得してください」と案内。

## ステップ 1: clone（ユーザー承認）

```
これからやることを 1 行で説明します:

  ~/Desktop/claude-code-toolkit/ に GitHub から clone します。
  既に存在する場合はその場所を使います。

実行してよろしいですか？ [y/n]
```

承認後:

```bash
mkdir -p ~/Desktop
cd ~/Desktop
[ ! -d claude-code-toolkit ] && \
  git clone https://github.com/DBA-Japan/claude-code-toolkit.git
cd claude-code-toolkit
```

## ステップ 2: ユーザー情報ヒアリング（対話）

```
CLAUDE.md（あなたのプロファイル）を作るために、簡単に教えてください:

1. 名前（ニックネーム可）: ?
2. 役割（例: エンジニア / 経営者 / 学生 / 副業）: ?
3. CC で主にやりたいこと:
   [a] Web 制作
   [b] 動画制作
   [c] リサーチ
   [d] 全部入り
```

回答を `--name` / `--role` / `--profile` 引数として保持。

## ステップ 3: plan（必ず通す）

```bash
bash install.sh --plan --profile <web|media|research|core|full>
```

**実行ではなくプレビュー**。出力をユーザーに見せて:

```
このプロファイルでは以下が ~/.claude/ に入ります:
  commands: XX files
  agents:   15 files
  skills:   XX dirs
  ...

CLAUDE.md は <存在しない → 新規作成 / 存在する → .toolkit-generated に保存> されます。

進めてよろしいですか？ [y/n]
```

## ステップ 4: install（承認後）

```bash
bash install.sh --quick --profile <selected> --name "<name>" --role "<role>"
```

出力を全部ユーザーに見せる。失敗があれば即時報告。

## ステップ 5: doctor

```bash
bash install.sh --doctor
```

出力に「不足」が出たら、それぞれ **ユーザー承認を取って** から実行案内:

### 不足: brew パッケージ

```
診断によると、whisper-cpp / ffmpeg / yt-dlp が未インストールです。

これは /video コマンドに必要です。インストールしますか？
（容量約 200MB、ダウンロード時間 5-10 分）

実行コマンド:
  brew install whisper-cpp ffmpeg yt-dlp

[y/n] →
```

承認後、Bash で実行。

### 不足: Python パッケージ

```
診断によると、python-pptx / google-genai が未インストールです。

これは /pptx と /ocr に必要です。

実行コマンド:
  pip install --user python-pptx google-genai

[y/n] →
```

### 不足: API キー

```
診断によると、以下の API キーが未設定です:
  - GEMINI_API_KEY  (Gemini OCR / VEO3 で必要)
  - EXA_API_KEY     (Exa リサーチで必要)

これらは **私（Claude）が自動設定しません**。あなたが手で設定する必要があります:

1. https://aistudio.google.com/apikey で Gemini API キーを取得
2. ~/.zshrc に追記:
     export GEMINI_API_KEY="..."
3. 新しい shell を開く

URL を開きますか？ [y/n] →
```

### 不足: MCP

```
診断によると、Exa MCP が未登録です。

登録には以下のコマンドが必要です:
  claude mcp add --scope user exa npx -y exa-mcp

実行してよろしいですか？ [y/n] →
```

## ステップ 6: 確認

```bash
claude mcp list
ls ~/.claude/commands/
```

「設定が反映されたか」をユーザーに見せる。

## ステップ 7: 再起動を促す

```
✅ セットアップ完了

次のステップ:
  1. 現在の CC セッションを閉じる
  2. 新しいターミナルで `claude` を起動
  3. /doctor で再診断
  4. /web-build などの入口コマンドを試す

何か質問はありますか？
```

---

## 絶対に守ること

### ✅ やれ
- 各ステップで **ユーザーの「yes」を取る**
- 失敗時は即時報告
- 何を変更したか具体的に提示
- バックアップの場所を明示
- rollback の方法を伝える

### ❌ やめろ
- 「全部やります」と言って黙って進める
- API キーをユーザーに代わって入力 / 環境変数設定する
- `~/.zshrc` を勝手に編集する
- 既存の `~/.claude/settings.json` を上書きする（マージは OK）
- 既存の `~/CLAUDE.md` を上書きする（`.toolkit-generated` として並置）
- 既存のメモリ / skill を上書きする
- `brew install` / `pip install` を承認なしで叩く
- 「丸投げ」モードで sleep を多用しない

### 失敗時のリカバリ

```bash
bash install.sh --rollback
```

これで直近のバックアップ（`~/.claude.backup-<timestamp>/`）から復元される。

ユーザーが「やめたい」と言ったら、必ず rollback を提案。

---

## 参考

- [`../README.md`](../README.md)
- [`../SECURITY.md`](../SECURITY.md)
- [`../install.sh`](../install.sh)
- [`../guides/doctor-explained.md`](../guides/doctor-explained.md)
- [`../guides/mcp-setup-full.md`](../guides/mcp-setup-full.md)
- [`../guides/auto-learning-system.md`](../guides/auto-learning-system.md)
