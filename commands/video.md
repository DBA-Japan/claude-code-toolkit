# Video（動画制作ハブ）

動画制作のすべての入口。素材の種類に応じて適切な skill / ツールに振り分ける。

## 起動

```
/video                       # 対話形式
/video photo <folder>        # 写真フォルダ → 動画（VEO3）
/video footage <files>       # 素材動画 → YouTube + ショート（video スキル）
/video html <url|file>       # HTML / GSAP → 動画（hyperframes）
/video website <url>         # Web サイト → プロモ動画（website-to-hyperframes）
/video subtitle <video>      # 動画に字幕を焼き込む（whisper + ffmpeg）
```

引数: $ARGUMENTS

## 振り分けロジック

| 素材 | 推奨 skill | 依存 |
|---|---|---|
| 写真（jpg/png）→ 動画化 | `veo3` | `GEMINI_API_KEY` |
| 素材動画（mov/mp4）→ 仕上げ | `video` | `ffmpeg`, `whisper-cpp`, `yt-dlp` |
| HTML / GSAP / Canvas 起点 | `hyperframes` + `hyperframes-cli` | `npx hyperframes-cli` |
| Web サイト URL → 動画 | `website-to-hyperframes` | Playwright MCP, hyperframes-cli |
| 既存動画 + 自動字幕 | `whisper-cpp` + `ffmpeg` | brew |

## ワークフロー

### 1. 素材ヒアリング

- 何を素材にするか（写真 / 動画 / HTML / URL）
- 完成形（YouTube 横長 / ショート 9:16 / 広告 / SNS）
- 長さ（秒数）
- BGM / 字幕 / ナレーション必要か

### 2. skill 振り分け

該当 skill の SKILL.md を読み込み、そのフローに従う。

### 3. 出力

`<project>/video-output/` 配下に書き出し。サイズが大きいので `.gitignore` 推奨。

## よくあるパイプライン

### A. 素材動画 → YouTube + ショート（一気通貫）

```
/video footage input/*.mov
```

1. 無音 / フィラーカット（whisper-cpp + ffmpeg）
2. per-word 文字起こし
3. フレーズ単位字幕焼き込み
4. BGM + 効果音
5. 1.25 倍速 9:16 ショート切り出し
6. タイトル合成

詳細: `skills/video/SKILL.md`

### B. 写真フォルダ → ヒーロー動画

```
/video photo assets/photos/
```

1. プロンプト設計
2. VEO3 API で各写真を 4-8 秒の動画化
3. 品質分析（ぶれ・色飛び）
4. 編集（つなぎ・トランジション）
5. Web 最適化（H.264 + ポスター画像）

詳細: `skills/veo3/SKILL.md`

### C. URL → 30 秒プロモ

```
/video website https://example.com
```

1. Playwright で画面録画
2. テキスト抽出 → ハイライト箇所判定
3. hyperframes コンポジション自動生成
4. レンダリング

詳細: `skills/website-to-hyperframes/SKILL.md`

## 依存

| 機能 | 要るもの | デフォルト |
|---|---|---|
| `veo3` | `GEMINI_API_KEY` + `pip install --user google-genai` | OFF |
| `video` | `brew install ffmpeg whisper-cpp yt-dlp` | OFF |
| `hyperframes` | `npm install -g hyperframes-cli` または `npx -y hyperframes-cli` | OFF |
| `website-to-hyperframes` | Playwright MCP + 上記 | OFF |
| 字幕焼き込み | `brew install ffmpeg whisper-cpp` | OFF |

`/doctor brew` / `/doctor python` で依存の有無を確認。

## 関連

- `skills/veo3/SKILL.md` — 写真 → 動画
- `skills/video/SKILL.md` — 素材動画 → YouTube
- `skills/hyperframes/SKILL.md` — HTML 起点
- `skills/website-to-hyperframes/SKILL.md` — URL 起点
- `guides/whisper-pipeline.md` — 字幕パイプライン
