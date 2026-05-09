# Claude Code でマウスクリック → カーソル位置移動を有効化する

Claude Code のターミナル入力欄、デフォルトでは **マウスクリックでカーソル位置を動かせない**。長いプロンプトの真ん中を直したいのに、矢印キーでちまちま移動するしかない。

これを **マウスクリック一発で「ここに飛んでこい」** に変える方法は 2 つある。

---

## 方法 1: CC 公式 Fullscreen rendering(推奨・無料・5 秒で完了)

Anthropic が 2026 年に追加した公式機能。環境変数 1 つ設定するだけ。

### 手順

```bash
# zsh の場合(macOS デフォルト)
echo 'export CLAUDE_CODE_NO_FLICKER=1' >> ~/.zshrc
source ~/.zshrc

# bash の場合
echo 'export CLAUDE_CODE_NO_FLICKER=1' >> ~/.bashrc
source ~/.bashrc
```

### iTerm2 を使ってる場合の追加設定(必須)

iTerm2 の設定で **マウスレポート** を有効化:

1. iTerm2 → Settings → Profiles → Terminal
2. **"Enable mouse reporting"** にチェック

これがオフだとクリックが CC に届かない。

### 他のターミナルの場合

- **Warp / Ghostty / Kitty / WezTerm**: デフォルトでマウスレポート有効。追加設定不要
- **Windows Terminal**: 同様にデフォルト有効
- **macOS Terminal.app**: デフォルト有効

### 何ができるようになるか

- **入力欄の任意位置をクリック → カーソルジャンプ**
- ツール出力結果をクリックで展開 / 折りたたみ
- URL / ファイルパスをクリックで開く
- ドラッグでテキスト選択(ダブルクリックで単語選択)
- マウスホイールで会話履歴スクロール

### トラブルシューティング

#### 「設定したのに動かない」

- CC のバージョンを確認: `claude --version`(2026 年 3 月以降のバージョンが必要)
- アップデート: `claude update`
- iTerm2 の "Enable mouse reporting" を再確認
- 一度 CC を完全終了 → 再起動

#### 「mouse 操作で native の選択コピーが効かなくなった」

CC がマウスイベントを横取りするので、ターミナルの「ドラッグ→自動コピー」が効かなくなる。これが嫌なら:

```bash
export CLAUDE_CODE_DISABLE_MOUSE=1
```

ただしこれを設定すると **クリック→カーソル移動も無効化** されるトレードオフ。

公式ドキュメント: https://code.claude.com/docs/en/fullscreen

---

## 方法 2: Cidan/ask(GUI 風 TUI ラッパー・上級者向け)

CC を Bubble Tea(Go 製 TUI ライブラリ)でラップする外部ツール。フル GUI 風の体験が手に入る。

### 何ができるか

- **スクロールバーをマウスクリックでジャンプ**
- マウスホイール対応
- リッチな UI(タブ式モーダル、approval prompt 改良版)
- セッション再開 / モデル切替 / 設定 GUI
- 自前の `AskUserQuestion` MCP 実装で対話品質向上

### インストール

```bash
# Go 1.21+ が必要
go install github.com/Cidan/ask@latest

# または GitHub Release からバイナリダウンロード
# https://github.com/Cidan/ask/releases
```

### 起動

```bash
ask                # CC を ask TUI でラップして起動
```

### キーバインド主要分

| キー | 動作 |
|---|---|
| `Enter` | 送信 / 確定 |
| `Shift+Enter` / `Ctrl+J` | 入力欄で改行 |
| `Ctrl+V` | クリップボード画像貼り付け |
| `Ctrl+C` 1 回 | 実行中の turn を停止 |
| `Ctrl+C` 2 回(idle 時) | 終了 |
| `↑` / `↓`(空入力時) | 過去のメッセージを呼び出し |
| `Mouse wheel` | スクロール |
| `Mouse click on │` | スクロールバーの位置にジャンプ |

### 方法 1 と方法 2 のどっちを選ぶか

| 軸 | 方法 1 (NO_FLICKER) | 方法 2 (Cidan/ask) |
|---|---|---|
| インストール | 環境変数 1 行 | Go バイナリ |
| 公式サポート | あり(Anthropic 公式) | なし(個人開発) |
| 入力欄クリック移動 | ◎ | ◎ |
| GUI リッチさ | △(機能限定) | ◎ |
| 安定性 | ◎ | ○(2026-04 時点で活発開発) |
| 追加機能 | 公式機能のみ | tab modal, custom MCP 等 |

**おすすめ**: まず方法 1 を試す。それで満足なら終わり。「もっと GUI っぽくしたい」なら方法 2 を追加。

GitHub: https://github.com/Cidan/ask

---

## 補足: Anthropic 公式が「クリックで過去メッセージ編集」をまだ実装していない

念のため明記。**現時点(2026-04)で「過去のプロンプトをマウスクリック → 編集 → 再送」は CC 公式・Cidan/ask 双方で未実装**。これを実現したいなら:

- `Esc` 2 回連打 → 過去プロンプト一覧 → 矢印で選んで編集(キーボード操作)
- `Ctrl+G` → 外部エディタ(VS Code 等)を起動 → 編集して保存

詳細: https://github.com/anthropics/claude-code/issues/27561

---

## 関連

- CC 公式 Fullscreen docs: https://code.claude.com/docs/en/fullscreen
- Cidan/ask: https://github.com/Cidan/ask
- 関連 Issue(click-to-position-cursor 履歴): #27561, #36546, #41166
