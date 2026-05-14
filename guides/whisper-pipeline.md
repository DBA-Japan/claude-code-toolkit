# Whisper パイプライン — 動画 → 自動字幕

`whisper-cpp` で音声を文字起こしし、`ffmpeg` で動画に焼き込む標準パイプライン。

## セットアップ

```bash
brew install whisper-cpp ffmpeg yt-dlp
```

モデルは初回利用時に whisper.cpp が自動DL。手動DLは:

```bash
# Whisper モデル取得（small.ja で日本語に最適化）
mkdir -p ~/.whisper-models
cd ~/.whisper-models
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin -o ggml-small.bin
# 日本語特化（精度↑、サイズ↑）
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin -o ggml-medium.bin
```

モデル比較:
| Model | サイズ | 日本語精度 | 速度 |
|---|---|---|---|
| tiny | 75 MB | 低 | 5x rt |
| base | 142 MB | 中 | 2x rt |
| small | 466 MB | 高 | 1x rt |
| medium | 1.5 GB | 最高 | 0.5x rt |
| large | 3 GB | 最高 | 0.2x rt |

実用は **small** か **medium**。

## 標準パイプライン

### Step 1: 音声抽出
```bash
ffmpeg -i input.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav
```

### Step 2: 文字起こし（SRT 出力）
```bash
whisper-cpp -m ~/.whisper-models/ggml-small.bin -l ja -osrt audio.wav
# → audio.wav.srt が生成される
```

### Step 3: 字幕焼き込み（hard-sub）
```bash
ffmpeg -i input.mp4 -vf "subtitles=audio.wav.srt:force_style='FontName=Noto Sans JP,FontSize=24,PrimaryColour=&HFFFFFF,BackColour=&H80000000,BorderStyle=3'" \
       -c:a copy output.mp4
```

### Step 4: 字幕ソフトサブ（YouTube 用）
```bash
# SRT を VTT に変換
ffmpeg -i audio.wav.srt audio.wav.vtt

# YouTube に動画 + VTT 字幕を別ファイルでアップ → CC で表示可能
```

## per-word 字幕（フレーズ単位ハイライト）

`video` skill が採用する高度版。whisper の `--max-len` と `--word-thold` を駆使:

```bash
whisper-cpp -m ggml-small.bin -l ja \
  --max-len 20 --word-thold 0.01 \
  --output-srt --print-progress audio.wav
```

→ フレーズが短く区切られ、視認性 ↑。

## YouTube ショート対応（9:16 + 字幕大きく）

```bash
ffmpeg -i input.mp4 \
  -vf "crop=ih*9/16:ih,scale=1080:1920,subtitles=audio.wav.srt:force_style='FontName=Noto Sans JP,FontSize=48,Bold=1,Outline=3'" \
  -c:a copy short.mp4
```

字幕サイズは横長動画の **2 倍** が目安。

## yt-dlp との連携

```bash
# YouTube から動画 + 字幕取得
yt-dlp --write-auto-subs --sub-lang ja --convert-subs srt <URL>

# 字幕が既にあるなら whisper をスキップ可能
```

## 精度を上げるコツ

1. **音質**: ノイズ除去 → `ffmpeg -af "afftdn=nf=-25"`
2. **モデル**: medium 以上を試す
3. **言語明示**: `-l ja` を必ず付ける（自動判定だと混ざる）
4. **専門用語**: 初期プロンプト `--prompt "AI 研修 / Claude / etc"` で語彙ヒントを与える

## アンチパターン

### ❌ tiny で日本語精度を期待する
人名・固有名詞が壊滅的。small 以上。

### ❌ 字幕を **全部翻訳** で済ます
LLM で再生成した字幕は AI 臭が出る。**whisper 出力をベース** に最小限の手直しが鉄則。

### ❌ 字幕の色を派手にする
読みづらい。白文字 + 黒半透明背景（`BorderStyle=3`）が無難。

## 関連

- [`../commands/video.md`](../commands/video.md)
- [`../skills/video/SKILL.md`](../skills/video/SKILL.md) — フル動画パイプライン
- [`doctor-explained.md`](./doctor-explained.md)
