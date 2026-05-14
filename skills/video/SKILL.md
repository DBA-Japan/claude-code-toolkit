---
name: video
description: 素材動画(mov/mp4)からプロ品質のYouTube動画+ショート動画を自動制作するスキル。無音/フィラーカット・per-word文字起こし・フレーズ単位字幕焼き込み・明るいウクレレBGM合成・効果音・1.25倍速9:16ショート切り出し・タイトル合成までワンショット。「video」「動画編集」「YouTube動画」「ショート動画」「字幕付き動画」「BGM追加」「動画パイプライン」「素材投げて」「YouTube仕上げ」で発動。
---

# YouTube 動画編集パイプライン

素材動画 1本 から **長尺版（字幕+BGM+SE）** + **ショート版（1.25倍速・9:16・タイトル+字幕）** を一発生成する。

過去の試行錯誤を全部踏まえた最短ルート。下の「絶対守る運用ルール」セクションは**毎回読む**。

---

## 絶対守る運用ルール（過去のつまずき記憶）

### 0. 環境セットアップ（毎回最初に）
```bash
export PATH="$HOME/Library/Python/3.14/bin:$PATH"
```
`auto-editor` `stable-ts` `whisper` がここに入っている。これ抜きで実行すると command not found になる。

未インストールなら:
```bash
pip3 install --user --break-system-packages auto-editor stable-ts
brew install sox mpv  # まだなら
```
※ `pip3` 単体は **PEP 668** で blocked。必ず `--break-system-packages` 必要。

### 1. BGM は外部URLからダウンロードしない
過去の失敗: Pixabay / freepd / Bensound / Incompetech ぜんぶ HTML/XML エラーページ返してきた。
**`scripts/make_bgm.sh` で sox 合成する**。ウクレレ風 C-G-Am-F・0.5秒/chord・3和音同時+ベース。これがユーザー検証済みの唯一OK BGM。

### 2. 字幕は mpv で焼き込む（ffmpeg ではダメ）
Homebrew ffmpeg は **libass / libfreetype 抜き**。`subtitles` `drawtext` フィルタが「Unknown filter」になる。
**ASS 焼き込みは `mpv --o=...` で**。タイトル overlay も drawtext じゃなく **ASS の Title style + Layer 1 で同時焼き込み**。

### 3. 字幕は per-word じゃなくフレーズ単位
stable-ts のデフォルト word_level は1単語ずつパッパッ表示で読めない。
**必ず `scripts/regroup_ass.py` でフレーズ化**（22文字/4秒/0.45秒ギャップ・カタカナ境界保護・助詞区切り・13文字超で\\N折り返し）。

### 4. ショートは「ジャンプカット禁止」+「1.25倍速」
- 過去: ジャンプカットしたら「切り抜くな」と却下
- 過去: 1.5倍速で「早すぎ」 → 1.25倍が正解
- **ショートは指定範囲を連続で 1.25x speed・9:16 縦型・上部タイトル**

### 5. ショートのタイトルは action-oriented 3行
- 動画の「ユニークな wow 体験」を一文で。
- 例: `AIに話すだけで` `Claude Codeを` `セットアップできた`
- フォント: Hiragino Sans W8 / 118pt / 黄金 (#FFD700) / 黒バー背景

### 6. 終了点は「文末」を探す
mid-thought で切ると不自然。`scripts/find_endings.py` で「ます」「できちゃいます」「思います」「お願いします」等で終わるフレーズ位置を抽出して、ユーザーに候補を提示する。

### 7. フィラー「えー」削除はユーザーに候補を提示してから
`scripts/find_filler.py` で標準的フィラー（えー・あー・うー >0.4秒）を全部列挙 → **ユーザーに「これ消す？」と聞く**。勝手に消さない。

### 8. BGM 音量は -16dB から
- 長尺: `-14dB` + sidechain ratio 14, threshold 0.03
- ショート: `-16dB` + sidechain ratio 14, threshold 0.03
- 声 boost: 1.7〜1.8x
- これより大きいと「BGMうるさい」と却下される

### 9. ffmpeg amix で `weights` 使わない
空白で parser 落ちる。各 stream の `volume` フィルタで音量調整する。

### 10. ASS パスに日本語/コロンあると ffmpeg subtitles 落ちる
（mpv に統一したので緩和されたが）ASS は **`/tmp/cap_*.ass`** にコピーしてから渡す。

### 11. Python source で生 `\\N` 禁止
unicode escape として解釈されて SyntaxError。`NL = chr(92) + "N"` を使う。

---

## 全体フロー

```
input.mov
  ↓ ① auto-editor: 無音カット → cut.mp4
  ↓ ② stable-ts: per-word ASS → captions.ass
  ↓ ③ regroup_ass.py: フレーズ化 → captions_phrase.ass
  ↓ ④ style_ass.py: 1920x1080 用スタイル → captions_long.ass
  ↓ ⑤ mpv: 字幕焼き込み → with_subs.mp4
  ↓ ⑥ make_bgm.sh: ウクレレBGM合成 → bgm.mp3
  ↓ ⑦ make_se.sh: pop/ding SE生成 → se_pop.wav, se_ding.wav
  ↓ ⑧ ffmpeg: BGM + SE ミックス → long_final.mp4 ✅
  ↓
  ↓ ⑨ find_filler.py: フィラー候補 → ユーザー確認
  ↓ ⑩ find_endings.py: 終了点候補 → ユーザー確認 + ユーザーに開始秒を聞く
  ↓ ⑪ build_short.py: shifted/sped ASS + Title style
  ↓ ⑫ ffmpeg: cut + 1.25x + 9:16 → short_base.mp4
  ↓ ⑬ mpv: 字幕焼き込み（タイトル含む）→ short_subbed.mp4
  ↓ ⑭ ffmpeg: BGM + SE ミックス → short_001.mp4 ✅
```

---

## 入力（ユーザーから受け取る情報）

| 必須 | 項目 | 例 |
|---|---|---|
| ✓ | 素材動画パス | `~/Movies/raw.mov` |
| 任意 | プロジェクト名 | `claude-code-setup`（出力フォルダ名に使う） |
| ✓ | ショート作る？ | yes / no |
| ショート時 | ハイライト範囲（cut.mp4基準・秒） | `555.6` 〜 `661.5` |
| ショート時 | ショートタイトル（3行） | `AIに話すだけで\nClaude Codeを\nセットアップできた` |
| 任意 | 削除したいフィラー時刻 | `find_filler.py` 結果から選んでもらう |
| 任意 | 速度 | デフォルト 1.25 |

未指定なら **デフォルト値 + ユーザーに聞く** で進める。

---

## ステップ詳細

### ① auto-editor: 無音カット
```bash
auto-editor INPUT --edit "audio:threshold=4%" --margin 0.2sec --output cut.mp4
```
進捗バーが大量に出るので **stdout を `tail -5` で抑制**するか、出力先を別ファイルに redirect。

### ② stable-ts: per-word 文字起こし
```bash
stable-ts cut.mp4 --language ja --model medium \
  --output_format ass --word_level true --segment_level false \
  --output captions.ass
```
12分動画で M1 Mac CPU 5〜10分。**バックグラウンド実行**でユーザーに進捗報告する。

### ③ フレーズ化
```bash
python3 scripts/regroup_ass.py captions.ass captions_phrase.ass
```

### ④ スタイリング
```bash
# 長尺用 (1920x1080, Hiragino Sans W6 72pt, 白+黒厚アウトライン)
python3 scripts/style_ass.py captions_phrase.ass captions_long.ass landscape
```

### ⑤ 字幕焼き込み（mpv）
```bash
cp captions_long.ass /tmp/cap.ass  # コロン回避

mpv cut.mp4 --sub-file=/tmp/cap.ass \
  --o=with_subs.mp4 --of=mp4 \
  --ovc=libx264 --ovcopts=preset=fast,crf=22,pix_fmt=yuv420p \
  --oac=aac --oacopts=b=192k --no-config
```

### ⑥ BGM 生成
```bash
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 cut.mp4)
bash scripts/make_bgm.sh "$DURATION" assets/bgm.mp3
```

### ⑦ SE 生成
```bash
bash scripts/make_se.sh assets/
```

### ⑧ 長尺最終ミックス
```bash
ffmpeg -y -i with_subs.mp4 -i assets/bgm.mp3 -i assets/se_pop.wav -i assets/se_ding.wav \
  -filter_complex "
    [1:a]volume=-14dB,aloop=loop=-1:size=2e+09[bgm_loud];
    [bgm_loud][0:a]sidechaincompress=threshold=0.03:ratio=14:attack=12:release=350:level_sc=1[bgm_d];
    [2:a]adelay=1500|1500,volume=1dB[se_intro];
    [3:a]adelay=$((CLIMAX_MS))|$((CLIMAX_MS)),volume=1dB[se_climax];
    [3:a]adelay=$((OUTRO_MS))|$((OUTRO_MS)),volume=1dB[se_outro];
    [0:a]volume=1.7[voice];
    [voice][bgm_d][se_intro][se_climax][se_outro]amix=inputs=5:duration=first:normalize=0[aout]
  " \
  -map "0:v" -map "[aout]" -c:v copy -c:a aac -b:a 192k -t "$DURATION" \
  output/long_final.mp4
```
※ `weights=` 使わない・各 volume で調整

### ⑨ フィラー候補抽出
```bash
python3 scripts/find_filler.py captions.ass --min-dur 0.4 --range $S $E
```
出力（JSON）をユーザーに見せて「これ削る？」と確認。

### ⑩ 終了点候補
```bash
python3 scripts/find_endings.py captions_phrase.ass $S $E_OPEN
```
ユーザーに「この中でどれ？」と聞く。スコア高い順（できちゃいます=10, できます=9, ...）。

### ⑪ ショート用 ASS 生成
```bash
python3 scripts/build_short.py \
  captions.ass /tmp/cap_short.ass \
  $START $END $SPEED \
  "AIに話すだけで\nClaude Codeを\nセットアップできた" \
  '[[588.74, 589.64]]'   # フィラーカット時刻 JSON
```

### ⑫ ショート ベース動画
```bash
ffmpeg -y -i cut.mp4 -filter_complex "
  [0:v]trim=$START:$FILLER_S,setpts=PTS-STARTPTS[v1];
  [0:a]atrim=$START:$FILLER_S,asetpts=PTS-STARTPTS[a1];
  [0:v]trim=$FILLER_E:$END,setpts=PTS-STARTPTS[v2];
  [0:a]atrim=$FILLER_E:$END,asetpts=PTS-STARTPTS[a2];
  [v1][a1][v2][a2]concat=n=2:v=1:a=1[vraw][araw];
  [vraw]setpts=PTS/1.25[vsped];
  [araw]atempo=1.25[asped];
  [vsped]split=2[bg][fg];
  [bg]scale=1920:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=20:5[bgblur];
  [fg]scale=1080:-2[fgsmall];
  [bgblur][fgsmall]overlay=(W-w)/2:(H-h)/2[v]
" -map "[v]" -map "[asped]" \
  -c:v libx264 -preset fast -crf 22 -pix_fmt yuv420p -c:a aac -b:a 192k \
  short_base.mp4
```

### ⑬ ショート 字幕焼き込み
```bash
cp captions_short.ass /tmp/cap_short.ass

mpv short_base.mp4 --sub-file=/tmp/cap_short.ass \
  --o=short_subbed.mp4 --of=mp4 \
  --ovc=libx264 --ovcopts=preset=fast,crf=22,pix_fmt=yuv420p \
  --oac=aac --oacopts=b=192k --no-config
```

### ⑭ ショート最終ミックス
```bash
ffmpeg -y -i short_subbed.mp4 \
  -i assets/se_pop.wav -i assets/se_ding.wav -i assets/bgm.mp3 \
  -filter_complex "
    [1:a]volume=4dB[se1];
    [2:a]adelay=$((DUR_MS-1500))|$((DUR_MS-1500)),volume=4dB[se2];
    [3:a]volume=-16dB,atrim=0:$DUR[bgm];
    [bgm][0:a]sidechaincompress=threshold=0.03:ratio=14:attack=12:release=300:level_sc=1[bgm_d];
    [0:a]volume=1.8[voice];
    [voice][bgm_d][se1][se2]amix=inputs=4:duration=first:normalize=0[aout]
  " \
  -map "0:v" -map "[aout]" -c:v copy -c:a aac -b:a 192k -t "$DUR" \
  output/short_001.mp4
```

---

## 出力構造

```
~/Desktop/youtube-pipeline/<project>/
├── work/
│   ├── input.mov              元動画コピー
│   ├── cut.mp4                無音カット後
│   ├── captions.ass           per-word
│   ├── captions_phrase.ass    フレーズ化
│   ├── captions_long.ass      長尺用スタイル
│   ├── captions_short.ass     ショート用スタイル + タイトル
│   ├── with_subs.mp4          長尺・字幕焼き込み済み
│   ├── short_base.mp4         ショート 9:16ベース
│   └── short_subbed.mp4       ショート 字幕焼き込み済み
├── assets/
│   ├── bgm.mp3                ウクレレBGM
│   ├── se_pop.wav             intro pop SE
│   └── se_ding.wav            climax/outro ding SE
└── output/
    ├── long_final.mp4         ★長尺最終
    └── short_001.mp4          ★ショート最終
```

---

## ユーザーとの対話プロトコル

スキル発動時、最低限**4つだけ聞く**:

1. **素材動画のパス**は？（必須）
2. **プロジェクト名**は？（出力フォルダ用、デフォルトは動画ファイル名）
3. **ショート作る？** (yes/no)
4. ショートを作るなら:
   - **ハイライト範囲**は？（cut.mp4 基準・秒。「実演シーン」を聞く）
   - **タイトル文言**（3行・action-oriented）は？

stable-ts 完了後（ハイライト範囲付近の transcript が見えてから）に:
- フィラー候補を `find_filler.py` で出して「これ消す？」
- 終了点候補を `find_endings.py` で出して「どこで切る？」

---

## 「素材投げて全部やって」モード

ユーザーが完全自動化を望む場合のデフォルト:

| 項目 | デフォルト値 |
|---|---|
| 出力先 | `~/Desktop/youtube-pipeline/<basename>/` |
| 速度 | 1.25 |
| BGM音量 | 長尺-14dB / ショート-16dB |
| ショートタイトル | （ユーザーに必ず聞く・デフォルト不可） |
| ショート範囲 | （ユーザーに必ず聞く・デフォルト不可） |
| フィラー削除 | デフォルトなし（候補提示してユーザー判断） |
| 終了点 | （find_endings の最高スコア候補を提示・確認） |

タイトルとショート範囲だけは**絶対にユーザーに確認する**。これを勝手に決めると過去の v1〜v4 のように「違う」と何度も差し戻される。

---

## チェックリスト（出力前に毎回確認）

- [ ] BGM音量で声が聞こえなくなっていないか（プレビュー再生で1秒確認）
- [ ] ASS字幕が word-level じゃなく phrase-level になっているか
- [ ] ショートのタイトルが3行で表示されているか（フォント崩れていないか）
- [ ] ショートが mid-thought で切れていないか（最後のフレーズが文末で終わるか）
- [ ] 9:16 縦型動画が 1080x1920 になっているか
- [ ] BGM が drone じゃなくウクレレ風になっているか

---

## トラブルシュート（過去発生したエラー集）

| エラー | 原因 | 対処 |
|---|---|---|
| `command not found: auto-editor` | PATH 通ってない | `export PATH="$HOME/Library/Python/3.14/bin:$PATH"` |
| `pip: error: externally-managed-environment` | PEP 668 | `--break-system-packages` 追加 |
| `Unknown filter 'subtitles'` | ffmpeg に libass なし | mpv 使え |
| `Unknown filter 'drawtext'` | ffmpeg に libfreetype なし | ASS の Title style 使え |
| `No option name near '/tmp/cap.ass'` | filter_complex weights= に空白 | weights 使わず volume で |
| `unicodeescape codec...` | Python source の `\N` | `chr(92) + "N"` 使う |
| BGMが空ファイル / HTML | 外部URL不安定 | 必ず `make_bgm.sh` で生成 |
| ショートが mid-thought で終わる | 終了点固定 | `find_endings.py` で文末候補から選ぶ |

---

## 関連スキル
- `/hyperframes` — HTML/GSAP起点の動画制作（こちらは素材→ポストプロ）
- `/veo3` — 写真→AI動画生成（前段の素材作り）

`/yt-edit` は素材動画が「既に撮れている」前提のポストプロパイプライン。
