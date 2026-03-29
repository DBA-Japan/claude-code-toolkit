# Apple 級デザインガイド

Apple / Stripe / Linear レベルの Web サイトを作るためのツールキットと設計原則。

---

## ツール一覧

### Spline（3D デザイン — ノーコード）
- **URL**: [spline.design](https://spline.design)
- **用途**: ヒーローの 3D オブジェクト、フローティングカード、製品回転
- **埋め込み**: `<spline-viewer>` Web Component（CDN 1 行）
- **料金**: 無料（ロゴ付き）/ $12/月でロゴなし

```html
<script type="module" src="https://unpkg.com/@splinetool/viewer/build/spline-viewer.js"></script>
<spline-viewer url="https://prod.spline.design/YOUR_SCENE/scene.splinecode"></spline-viewer>
```

### Rive（インタラクティブアニメーション）
- **URL**: [rive.app](https://rive.app)
- **用途**: アニメアイコン、ローダー、ホバーで変化する UI、ステートマシン
- **Lottie 比**: 3.5 倍高速、90% 軽量
- **料金**: 無料（3 ファイル）/ $9/月で無制限

```html
<script src="https://unpkg.com/@rive-app/canvas"></script>
<canvas id="rive-canvas" width="500" height="500"></canvas>
<script>
  new rive.Rive({
    src: 'animation.riv',
    canvas: document.getElementById('rive-canvas'),
    autoplay: true,
  });
</script>
```

### Google Stitch 2.0（デザイン → コード）
- **MCP**: `claude mcp add stitch`（月 350 回無料）
- **用途**: モックアップ生成 → DESIGN.md 自動生成 → Claude Code がデザイン一貫性を保持

### Apple 式画像シーケンス
- **用途**: スクロール = フレーム再生。製品の回転・変形・ズーム
- **仕組み**: 動画 → FFmpeg → WebP フレーム → Canvas → GSAP scrub

```bash
ffmpeg -i video.mp4 -vf "fps=30,scale=1920:-1" -c:v libwebp -q:v 80 frame_%04d.webp
```

---

## Apple.com の 6 つのテクニック

1. **画像シーケンス・スクロール** — scrub = フレーム再生
2. **「隠して発見させる」** — 段階的情報開示
3. **テキスト+製品のシンクロ** — 読む+見るが同期
4. **極限タイポグラフィ** — 72-120px 見出し、情報量を半分に
5. **カラー制限** — 白黒+製品色の 3 色以内
6. **パフォーマンスへの執着** — AVIF/WebP、IntersectionObserver

---

## デザインルール（AI っぽくならない）

### 絶対禁止
- 均一カード（同サイズ 3 カード横並び）
- 丸/ドットのカーソルフォロワー
- 紫→青グラデーション背景
- グラデーション文字
- Inter / Roboto / Arial フォント
- ✕/✓ マーク（取り消し線で代替）

### 必須事項
- 背景に動き（ブロブ・テクスチャ・オーロラ）
- テクスチャ（SVG ノイズ、ドットパターン、グレイン）
- 非対称グリッド（`2fr 1fr` や `0.9fr 1.1fr 0.9fr`）
- 写真の形バラバラ（SmartHR 型）
- 改行制御（PC/SP 両方で `<br>` 制御）

### AI っぽさ回避チェック
- [ ] フォントは Inter/Roboto ではない
- [ ] グラデーション文字を使っていない
- [ ] カードのパディング/角丸が均一ではない
- [ ] 紫→青グラデーション背景がない
- [ ] レイアウトに意図的なズレ・非対称性がある
- [ ] テクスチャ・ノイズ背景を含む

---

## カード代替レイアウト

1. **Bento Grid**（Apple/Figma 風、不均等サイズ）
2. **テキスト+余白だけ**（Linear/Vercel 風）
3. **タイムライン**（縦線+ジグザグ）
4. **展開型アコーディオン**
5. **横スクロール**（ScrollTrigger pin）
6. **Before/After 分割**
7. **数字ドン**（画面いっぱいに 1 個）

---

## 推奨ワークフロー

```
Phase 0: 参考サイト検索（Awwwards, Dribbble, Behance）
Phase 1: Stitch でモックアップ + DESIGN.md 生成
Phase 2: Spline で 3D 素材 / Rive でアニメ素材
Phase 3: Claude Code + GSAP + Lenis で実装
Phase 4: 品質チェック + iOS Safari テスト
```
