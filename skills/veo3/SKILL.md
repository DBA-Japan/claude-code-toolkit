---
name: veo3
description: VEO3（Google AI Studio）で写真を動画に変換し、Webサイトに組み込むスキル。写真フォルダを指定するだけで、プロンプト設計→API生成→品質分析→編集→Web最適化→デプロイまで一気通貫で行う。「VEO3」「veo3」「写真を動画に」「動画生成」「LP用の動画」「ヒーロー動画」「写真から動画」「image to video」と言われたら発動。VEO3でもveo3でもVeo3でも発動する。
---

# VEO3 写真→動画パイプライン

写真フォルダからLP/Webサイト用の動画素材を自動生成するスキル。

## 全体フロー

```
写真フォルダ指定 → 写真分析・分類 → プロンプト設計 → VEO3 API生成
→ フレーム品質分析 → ベスト区間トリミング → コンパイル → Web最適化 → デプロイ
```

## Phase 1: 写真の分析と分類

ユーザーが指定したフォルダ内のファイルを調査する。

1. `ls -la` でファイル一覧取得
2. `sips -g pixelWidth -g pixelHeight -g format` で各写真のサイズ・フォーマット確認
3. **動画ファイル（.mp4等）は除外**（写真のみ対象）
4. 各写真をReadで読み込み、内容を把握
5. VEO3向き度を★1-3で評価:
   - ★★★: 人物なし or シルエット、有機的テクスチャ、光線あり → VEO3が得意
   - ★★: 人物の顔が大きく映る、正方形に近い → リスクあるが可能
   - ★: 解像度低い（720p未満）、テキスト入り → 非推奨

ユーザーに一覧を提示し、どれを生成するか確認。

## Phase 2: プロンプト設計

VEO3 image-to-videoプロンプトの5原則:

1. **動きだけ指示する** — VEO3は画像を見ているので、シーンの説明は不要
2. **カメラは固定** — `Stationary camera.` を必ず末尾に入れる
3. **水中シーンはパーティクル＋光線** — `floating particles`, `light rays`, `caustics`
4. **人物の表情は動かさない** — 顔が大きい写真は環境の動き（泡、パーティクル）に頼る
5. **英語で書く** — VEO3は英語プロンプトが最も安定

### プロンプトテンプレート構造
```
[動きの指示] + [環境エフェクト] + [雰囲気] + Stationary camera.
```

### カテゴリ別プロンプトパターン

**水中風景（海藻・サンゴ）:**
```
Gentle ocean current slowly swaying the [subject]. [Light effect] through the water. 
Tiny particles drifting. Very slow, dreamy movement. Stationary camera.
```

**水中生物（魚群）:**
```
[Fish description] swimming [speed] in [formation]. Sunlight [effect] through the water surface.
Subtle underwater particle drift. [Mood]. Stationary camera.
```

**大型魚（コブダイ等、顔が大きい）:**
```
Very subtle [minimal movement] on the large fish. Small bubbles rising from [source].
Tiny particles floating. Minimal, calm movement. Stationary camera.
```
→ 顔が画面の30%以上なら口・目の動きは指示しない。崩壊リスク大。

**ダイバー:**
```
[Diver action]. Bubbles rising slowly. [Light/environment]. 
[Mood]. Stationary camera.
```
→ ダイバーがシルエットならより攻めたプロンプトが使える。

**陸上・夜景（星空等）:**
```
Very slow [celestial movement]. [Ground-level movement].
[Subject] remains still. Extremely slow movement. Stationary camera.
```
→ 星空は超スロー必須。速いとノイズ化。

ユーザーにプロンプト一覧を提示し、確認を取ってから生成に進む。

## Phase 3: VEO3 API バッチ生成

### 必要な環境
- `pip install google-genai requests`（`--break-system-packages` が必要な場合あり）
- `GOOGLE_API_KEY` 環境変数、またはAPI keyを直接指定

### APIキーの確認
```python
from google import genai
client = genai.Client(api_key="YOUR_KEY")
# テスト
response = client.models.generate_content(model='gemini-2.5-flash', contents='Say OK')
```

### 生成コード（1枚ずつ）
```python
from google.genai import types
import time, requests

operation = client.models.generate_videos(
    model="veo-3.0-fast-generate-001",
    prompt="YOUR_PROMPT",
    image=types.Image(image_bytes=image_bytes, mime_type="image/jpeg"),
    config=types.GenerateVideosConfig(
        aspect_ratio="16:9",  # or "9:16" for vertical photos
        duration_seconds=4,   # minimum (options: 4, 6, 8)
        number_of_videos=1,
        person_generation="allow_adult",
    ),
)

# ポーリング（非同期）
while not operation.done:
    time.sleep(10)
    operation = client.operations.get(operation)

# ダウンロード
video = operation.result.generated_videos[0]
uri = video.video.uri
resp = requests.get(f"{uri}&key={API_KEY}")
with open("output.mp4", "wb") as f:
    f.write(resp.content)
```

### アスペクト比の決め方
- 元写真が横長 → `16:9`
- 元写真が縦長 → `9:16`
- 正方形に近い → `16:9`（LP用途なら横優先）

### レート制限への対処

VEO3 Pay-as-you-go Tier 1の制限:
- **RPM**: 2リクエスト/分
- **RPD**: 10リクエスト/日

10本を超える場合:
1. バッチスクリプトで一気に送る（最初の10本は通る）
2. 残りは**リトライスクリプト**をバックグラウンドで実行（`nohup python retry.py &`）
3. 10分おきにリトライ、成功したらmacOS通知を飛ばす

```python
# macOS通知
import subprocess
subprocess.run(["osascript", "-e", 
    f'display notification "生成完了!" with title "VEO3"'])
```

クォータ増加が必要な場合:
- https://forms.gle/ETzX94k8jf7iSotH9 からTier 2へのアップグレード申請
- Billing Account ID: Google AI Studio → 課金ページ
- Project NUMBER: Google AI Studio → プロジェクト → プロジェクト名クリック

### コスト目安（Veo 3 Fast）
- $0.15/秒 × 4秒 = **$0.60/本**（約90円）
- 10本 = $6、20本 = $12

## Phase 4: 動画の品質分析

生成された動画を1本ずつフレーム抽出して品質チェックする。

### フレーム抽出
```bash
ffmpeg -i input.mp4 -vf "fps=2" -frames:v 8 frames/f%d.jpg
```
→ 4秒動画から0.5秒間隔で8フレーム抽出

### 分析観点（各フレームをReadで確認）
1. **構図の安定性**: カメラが動きすぎてないか
2. **VEO3アーティファクト**: 手指の崩壊、顔の変形、テクスチャの溶け
3. **アスペクト比の崩壊**: 後半で黒帯が出る（VEO3の既知バグ）
4. **動きの自然さ**: 生物の動きが物理的に正しいか

### ベスト区間の決定基準
- 崩壊がないフレーム区間を選ぶ
- VEO3は**冒頭1-2秒が最も安定**する傾向がある
- 後半（3-4秒）は崩壊しやすい
- 2.5秒を切り出す場合、多くの場合 **0.0-2.5秒** か **0.5-3.0秒** がベスト

エージェントを並列で使って10本同時分析するのが効率的。

## Phase 5: 編集とコンパイル

### トリミング
```bash
ffmpeg -y -ss [開始秒] -i input.mp4 -t 2.5 \
  -c:v libx264 -preset fast -crf 18 -an output.mp4
```

### 縦動画を横に変換（必要な場合）
```bash
# 9:16 → 16:9（中央クロップ）
ffmpeg -y -ss [開始秒] -i input.mp4 -t 2.5 \
  -vf "crop=720:405:0:437,scale=1280:720" \
  -c:v libx264 -preset fast -crf 18 -an output.mp4
```

### ストーリー順序の設計原則
LP用ヒーロー動画の構成:
1. **導入**: 風景・自然（海藻、光線）→ 第一印象「きれい」
2. **展開**: 生き物登場（魚群）→ 「すごい」
3. **クライマックス**: 体験（ダイバー、大型魚）→ 「潜りたい」
4. **締め**: 最もインパクトのあるショット

### クロスフェード付きコンパイル
```bash
ffmpeg -y \
  -i clip1.mp4 -i clip2.mp4 -i clip3.mp4 \
  -filter_complex "
    [0:v]setpts=PTS-STARTPTS,format=yuva420p[v0];
    [1:v]setpts=PTS-STARTPTS,format=yuva420p[v1];
    [2:v]setpts=PTS-STARTPTS,format=yuva420p[v2];
    [v0][v1]xfade=transition=fade:duration=0.4:offset=2.1[x01];
    [x01][v2]xfade=transition=fade:duration=0.4:offset=4.2,format=yuv420p[outv]
  " \
  -map "[outv]" -c:v libx264 -preset slow -crf 18 -an output.mp4
```

offset計算式: `前のクリップの終了時間 - フェード時間/2`
N本のクリップの場合、N番目のoffset = `(N-1) * (clip_duration - fade_duration/2)`

## Phase 6: Web最適化

### LP背景動画の最適化
```bash
ffmpeg -y -i compiled.mp4 \
  -c:v libx264 -preset slow -crf 26 \
  -movflags +faststart \
  -an \
  output_web.mp4
```

- **CRF 26**: 背景動画はテキストの後ろなので画質を少し落としてOK
- **faststart**: ストリーミング再生対応（Web必須）
- **-an**: 音声不要（LP背景はミュート）
- 目標サイズ: **5MB以下**（20秒の場合）

### 既存動画との結合
既存のヒーロー動画の一部を残して新クリップを追加する場合:

1. 既存動画の残したい部分を抽出（`-t`で秒数指定）
2. 解像度を合わせる（`scale=1280:720:flags=lanczos`）
3. xfadeで結合
4. Web最適化して出力

### LP組み込み
HTMLの`<video>`タグのsrcを差し替えるだけ:
```html
<video autoplay muted loop playsinline>
  <source src="videos/hero-combined.mp4" type="video/mp4">
</video>
```

CSSでスマホ対応:
```css
.hero-video {
  object-fit: cover;  /* 16:9動画もスマホで画面いっぱいに */
  width: 100%;
  height: 100%;
}
```

## Phase 7: ユーザーとの反復

動画をプレビューで見せて、ユーザーのフィードバックを反映する:
- 「これ削って」→ 該当クリップを除外して再コンパイル
- 「順番変えて」→ 順序入れ替えて再コンパイル
- 「もっと短く」→ 各クリップを2秒にトリミングし直し

再コンパイルは高速（数十秒）なので何回でも回せる。

## 注意事項

- **`generate_audio`パラメータは使わない** — Gemini APIでは非対応でエラーになる
- APIキーはスクリプトに直書きしない。環境変数または安全なシークレット管理を使う
- VEO3は人物の顔（特に手指）の動画生成が苦手。崩壊しやすいフレームは必ずカット
- 生成された動画は**サーバーに2日間保存**される。URIでダウンロードする場合は早めに
