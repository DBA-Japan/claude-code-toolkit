---
name: Web制作ライブラリカタログ
description: 36エージェント調査に基づく完全なWebライブラリ・技法カタログ。サイト制作時に最適なツールを即座に引き出すためのリファレンス
type: reference
---

# Web制作ツールキット（2026-03 調査、36エージェント統合）

## クイックリファレンス: 何をやりたい → 何を使う

| やりたいこと | 第1候補 | CDN | 備考 |
|-------------|---------|-----|------|
| スムーススクロール | **Lenis** (13.4k★) | `unpkg.com/lenis@1.3.4/dist/lenis.min.js` | 3行で導入。GTA VI, Shopify採用 |
| スクロール連動アニメ | **GSAP ScrollTrigger** (24k★) | `cdn.jsdelivr.net/npm/gsap@3/dist/ScrollTrigger.min.js` | 2025年完全無料化 |
| テキスト分割アニメ | **GSAP SplitText** | `cdn.jsdelivr.net/npm/gsap@3/dist/SplitText.min.js` | 文字/単語/行で分割。日本語OK |
| テキストスクランブル | **baffle.js** (1.8k★) | `cdn.jsdelivr.net/npm/baffle@0.3.6/dist/baffle.min.js` | 1.8KB。日本語characters指定可 |
| 3D背景 | **Vanta.js** (6.4k★) | Three.js + `cdn.jsdelivr.net/npm/vanta@latest/dist/vanta.halo.min.js` | 13種プリセット。5行で動く |
| 流体背景 | **webgl-fluid** | `cdn.jsdelivr.net/npm/webgl-fluid@0.3` | CDN1行で流体シミュレーション |
| グラデーション | **Granim.js** (5.3k★) | `cdnjs.cloudflare.com/ajax/libs/granim/2.0.0/granim.min.js` | 17KB |
| パーティクル | **tsParticles** (8.7k★) | `cdn.jsdelivr.net/npm/@tsparticles/preset-firefly@3/tsparticles.preset.firefly.bundle.min.js` | Fireflyが蛍風 |
| カスタムカーソル | **mouse-follower** (Cuberto) | `unpkg.com/mouse-follower@latest/dist/mouse-follower.min.js` | GSAP依存。PC専用 |
| カード3D傾き | **vanilla-tilt.js** (4k★) | `cdnjs.cloudflare.com/ajax/libs/vanilla-tilt/1.8.1/vanilla-tilt.min.js` | 4KB。Glare内蔵 |
| 磁気ボタン | **magnet-mouse** | npm | CTAボタンに |
| ホバーエフェクト | **Hover.css** (29.2k★) | `cdnjs.cloudflare.com/ajax/libs/hover.css/2.3.1/css/hover-min.css` | クラス名だけ |
| 画像液体歪み | **hover-effect** (1.8k★) | `cdn.jsdelivr.net/npm/hover-effect` | ディスプレイスメントマップ |
| テキスト歪み | **VFX-JS** | `cdn.jsdelivr.net/npm/@vfx-js/core` | HTML要素にWebGLシェーダー |
| テキスト→パーティクル | **particlesGL** | CDN | DOM要素をパーティクルに変換 |
| SVGストローク描画 | **Vivus.js** (15.3k★) | `cdn.jsdelivr.net/npm/vivus/dist/vivus.min.js` | 8KB。3行で動く |
| SVGモーフィング | **GSAP MorphSVG** | `cdn.jsdelivr.net/npm/gsap@3/dist/MorphSVGPlugin.min.js` | 無料化済み |
| レイアウトアニメ | **GSAP Flip** | `cdn.jsdelivr.net/npm/gsap@3/dist/Flip.min.js` | 無料化済み |
| 自動レイアウトアニメ | **auto-animate** (12k★) | `cdn.jsdelivr.net/npm/@formkit/auto-animate` | 1行で完了。1.9KB |
| ローディングバー | **Pace.js** (15.6k★) | `cdn.jsdelivr.net/npm/pace-js@latest/pace.min.js` | scriptタグ2行 |
| 紙吹雪 | **canvas-confetti** (12.5k★) | `cdn.jsdelivr.net/npm/canvas-confetti@1.9.3/dist/confetti.browser.min.js` | 1行で紙吹雪 |
| エラー揺れ | **CSShake** (4.8k★) | `cdnjs.cloudflare.com/ajax/libs/csshake/1.5.3/csshake.min.css` | クラス追加 |
| サウンド | **Howler.js** (25.2k★) | `cdnjs.cloudflare.com/ajax/libs/howler/2.2.3/howler.min.js` | 7KB。初期OFF必須 |
| ノイズテクスチャ | **SVG feTurbulence** | CSS-only (data URI) | JSゼロ。opacity 0.06-0.10 |
| ダーク背景素材 | **Grainient** | grainient.supply | 3Dガラス風グラデ画像。フラット黒の代わりに。Canvasの下に敷く |
| 写真切り抜き | **remove.bg** | remove.bg | 人物写真の背景除去。Team写真等 |
| レイアウト参考 | **Bento Grids** | bentogrids.com | Apple/Vercel/Linear等のBento Grid実例集 |
| ブロブアニメ | **CSS border-radius** | CSS-only | 6行CSS |
| 粘液融合 | **SVG Goo Filter** | CSS-only | filter定義1つ |
| Lottieアニメ | **lottie-web** (31.7k★) | `cdn.jsdelivr.net/npm/lottie-web/build/player/lottie.min.js` | LottieFilesで無料素材 |
| Stripe風グラデ | **whatamesh** | npm `whatamesh` | 10KB |
| オーロラ背景 | CSS変数+radial-gradient | 不要 | JS5行+CSS20行 |
| シェーダーアート | **Radiant** (340★) | コピペ | 130+エフェクト。依存なし |
| GSAPの軽量代替 | **Motion** (31.3k★) | `cdn.jsdelivr.net/npm/motion@11.11.13/dist/motion.js` | mini 2.3KB/hybrid 17KB。WAAPI。GSAP比2.5x高速 |
| スクロール(軽量) | **Trig.js** (160★) | `cdn.jsdelivr.net/npm/trig-js/src/trig.min.js` | 4KB。CSS変数ベース。依存なし |
| スクロール(最軽量) | **Sal.js** (3.7k★) | `cdn.jsdelivr.net/npm/sal.js/dist/sal.js` | 2.8KB。IO基盤。data属性だけ |
| タイピング | **Typed.js** (16.3k★) | `unpkg.com/typed.js@3.0.0/dist/typed.umd.js` | ~5KB。ヒーロー文字タイプ |
| テキスト分割(軽量) | **Splitting.js** (1.8k★) | `unpkg.com/splitting/dist/splitting.min.js` | **1.5KB**。SplitTextの軽量代替 |
| 数値カウント | **CountUp.js** (8.2k★) | `cdn.jsdelivr.net/npm/countup.js@2.10.0/dist/countUp.umd.js` | ~8KB。実績数字に |
| マイクロインタラクション | **Micron.js** (2.3k★) | `unpkg.com/webkul-micron@1.1.6/dist/script/micron.min.js` | ~2KB。data属性で12種 |
| カーソル(GSAP不要) | **MagicMouse.js** (422★) | Cloudinary CDN | 軽量。mouse-followerの非GSAP版 |
| 波アニメーション | **nice-waves** (117★) | `unpkg.com/nice-waves@latest` | SVG波生成。セクション区切りに |
| CSSアニメ(ユニーク) | **Magic.css** (8.6k★) | `cdn.jsdelivr.net/npm/magic.css@latest/dist/magic.min.css` | 3.1KB(gz)。Animate.cssより個性的 |
| ローダー集 | **LDRS** (2.2k★) | HTML+CSSコピペ(uiball.com/ldrs) | 44種。Web Components |
| 3Dパララックスカード | **Atropos.js** (2.8k★) | `cdn.jsdelivr.net/npm/atropos` | タッチ対応。vanilla-tiltの上位互換 |
| 物理バースト | **mo.js** (18.7k★) | `cdn.jsdelivr.net/npm/@mojs/core/dist/mo.umd.js` | クリック時バーストエフェクト |
| スクロールテリング | **Scrollama** (5.7k★) | `cdnjs.cloudflare.com/ajax/libs/scrollama/3.2.0/scrollama.min.js` | IntersectionObserver基盤。ストーリー展開向け |
| 軽量カルーセル | **Embla Carousel** (11.9k★) | `cdn.jsdelivr.net/npm/embla-carousel/embla-carousel.umd.js` | 7KB。Swiperの軽量代替 |
| ノイズテクスチャ(JS) | **Grained.js** (310★) | 小さいのでコピペ | フィルムグレイン風 |
| フルスクリーン切替 | **fullPage.js** (35k★) | `cdnjs.cloudflare.com/ajax/libs/fullPage.js/4.0.25/fullpage.min.js` | スナップスクロール |
| 軽量パララックス | **Rellax.js** (7.2k★) | `cdn.jsdelivr.net/npm/rellax/rellax.min.js` | data属性で速度制御 |
| Bentoグリッド参考 | **Magic UI** (20.5k★) | コピペ方式 | 150+コンポーネント。Bento Grid, Border Beam等 |
| ランプ/ビーム参考 | **Aceternity UI** | ui.aceternity.com | Lamp Effect, Tracing Beam, Infinite Moving Cards |

---

## デザイン自動選定ガイド: 会社の特徴 → 最適なデザイン

サイト制作時、クライアントの以下の情報から最適なデザインパターンを自動選定する。

### Step 1: 業種で大枠を決める

| 業種 | トーン | 背景 | 動き | 写真 |
|------|--------|------|------|------|
| **AI/テック** | ダーク70%+光30% | ドットテクスチャ+グロー | 多め（シンボルアニメ、パーティクル） | テック感ある構図 |
| **SaaS/B2B** | ライト or ダーク | クリーン、余白重視 | 中程度（スクロールフェードイン） | プロダクトUI、人物 |
| **コンサル/研修** | ダーク+アクセント1色 | ノイズテクスチャ | 控えめ（信頼重視） | 人物写真重要 |
| **旅行/ホテル/飲食** | ライト、写真主役 | 写真フルブリード | 写真遷移（ズーム、パララックス） | 大型写真が命 |
| **クリエイティブ/デザイン** | 自由（個性重視） | 実験的OK | 多め（カーソル、WebGL） | ポートフォリオ作品 |
| **地方/中小企業** | ライト、温かみ | シンプル | 最小限（読みやすさ優先） | 人物+現場写真 |
| **EC/D2C** | 商品に合わせる | 商品が映える背景 | 商品ズーム、カート演出 | 商品写真が全て |

### Step 2: 会社の「人格」で細部を決める

| 会社が大事にしていること | デザインへの反映 |
|------------------------|-----------------|
| **革新・先進性** | ダーク背景、パーティクル、WebGLエフェクト、カスタムカーソル |
| **信頼・堅実** | 余白多め、ミニマル、実績数値、ロゴバー、人物写真 |
| **親しみやすさ** | 丸い形、暖色、イラスト、写真形バリエーション(SmartHR型) |
| **高級感・プレミアム** | 黒+金/白、余白極大、letter-spacing広め、アニメ控えめ |
| **遊び心・ユニーク** | アニメシンボル(SpiralAI型)、カーソルエフェクト、予想外の動き |
| **透明性・オープン** | プロセス可視化、チーム写真全員、数字で語る |
| **スピード・成長** | 動きのテンポ速め、実績カウンター、ダイナミックなレイアウト |

### Step 3: ターゲット顧客で調整

| ターゲット | 調整ポイント |
|-----------|-------------|
| **大企業の担当者** | 派手すぎない。信頼シグナル最重要。「怪しくない」ライン |
| **スタートアップ/テック系** | 攻めたデザインOK。WebGL、インタラクション多め |
| **一般消費者** | 分かりやすさ最優先。専門用語排除。モバイルファースト |
| **地方/高齢層** | フォント大きめ、動き最小限、コントラスト高め |
| **海外** | 英語フォント重視、文化的に中立なデザイン |

---

## 実証済みデザインパターン（日本IT企業20社レビューで確認）

→ 詳細なコード例付きの独立ファイルは `design-patterns.md` を参照

以下は実在する超一流サイトから抽出したパターン一覧:

- **Pattern 1**: クリーン+モーション（LayerX型）— layerx.co.jp
- **Pattern 2**: 写真の形バリエーション（SmartHR型）— smarthr.co.jp
- **Pattern 3**: 背景二重構造/覗き込み（PLAID型）— plaid.co.jp
- **Pattern 4**: カーソルフォロワー（Goodpatch型）— goodpatch.com
- **Pattern 5**: ズームイン/アウト写真スライド（CyberAgent型）— cyberagent.co.jp
- **Pattern 6**: 余白+画像配置+背景薄文字（Wantedly型）— wantedlyinc.com
- **Pattern 7**: アニメーションシンボル+テクスチャ背景（SpiralAI型）— go-spiral.ai
- **Pattern 8**: ドット背景+スクロール色変化（10X型）— 10x.co.jp

---

## パフォーマンス必須ルール

1. **anime.jsとGSAPは併用しない** → GSAPで全て代替（Motionも同様、1プロジェクト1エンジン）
2. **Lenis + GSAPのrAFループ統合**: `lenis.on('scroll', ScrollTrigger.update)` + `gsap.ticker.add()`
3. **Vanta/Granimはload後に動的import** → TBT改善
4. **モバイルでWebGL無効**: `window.innerWidth > 768 && navigator.hardwareConcurrency > 3` でPC判定
5. **IntersectionObserverで画面外停止** → GPU節約
6. **画像: WebP/AVIF + loading="lazy"** (ヒーローだけ `fetchpriority="high"`)
7. **フォント: WOFF2 + font-display: swap + preload** (1-2個まで)
8. **deferで読み込み順序保証**: GSAP → Lenis → main.js
9. **CSS scroll-driven animations活用**: AOS.js等のJS不要。Chrome115+/Edge115+/Safari26+対応
10. **Anime.js v4情報**: v4.3.6（2026-02）。モジュラー、~10KB gzip。CDN: `cdn.jsdelivr.net/npm/animejs/dist/bundles/anime.umd.min.js`

## CSS-only新機能（JSライブラリ不要）

| 機能 | 置き換えるJS | ブラウザ |
|------|-------------|---------|
| scroll-driven animations | AOS.js | 全対応 |
| @property | グラデーションアニメJS | 全対応 |
| :has() | 条件分岐JS | 全対応 |
| Popover API | モーダルJS | 全対応 |
| View Transitions | Barba.js (SPA) | ほぼ全対応 |

---

## AI動画生成（LP埋め込み用）

### Higgsfield AI (higgsfield.ai)
- **用途**: LP/Webサイトのヒーロー背景動画、セクション間の動画、プロモクリップ
- **特徴**: 15+モデル（Sora 2, Veo 3.1, Kling 3.0等）のアグリゲーター。テキスト→動画、画像→動画
- **料金**: 無料枠あり / Basic $9/月 / Pro $29/月
- **LP埋め込み方法**: MP4/WebM生成 → `<video autoplay muted loop playsinline>` で背景設置
- **注意**: モバイルでは重い。`prefers-reduced-motion` で静止画フォールバック必須
- **MCP**: あり（コミュニティ製 `geopopos/higgsfield_ai_mcp`、Python）。APIキー必要（cloud.higgsfield.ai）
- **向いてる場面**: 抽象的AI背景（ニューラルネット風、データフロー風）、雰囲気映像
- **向かない場面**: リアルな人物、実写に近い映像（AIっぽさが出る）
- **セットアップ**: APIキー取得 → `pip install higgsfield-mcp` → .mcp.json に追加

### LP動画背景のベストプラクティス
```html
<div class="hero">
  <video autoplay muted loop playsinline poster="fallback.webp">
    <source src="hero.webm" type="video/webm">
    <source src="hero.mp4" type="video/mp4">
  </video>
  <div class="hero-content">...</div>
</div>
```
```css
.hero video {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover; z-index: -1;
}
@media (prefers-reduced-motion: reduce) {
  .hero video { display: none; }
}
@media (max-width: 768px) {
  .hero video { display: none; } /* モバイルはposter画像で代替 */
}
```

---

## 無料デザインリソース

| リソース | URL | 何ができるか | いつ使う |
|---------|-----|-------------|---------|
| **Grainient** | grainient.supply | 1000+ AI生成グラデーション/3Dガラス背景画像 | **ダークセクション背景**。フラット黒の代わりにリッチな下地を敷く。Moon/Phantom/Nova等。Canvasの下に重ねると奥行きが出る |
| **Bento Grids** | bentogrids.com | Bento Gridインスピレーション集。Apple/Vercel/Linear/Stripe等の実例 | **レイアウト参考**。Servicesやfeature紹介で均一カードの代わりに |
| **remove.bg** | remove.bg | 画像背景除去AI | **人物写真の切り抜き**。Team写真をレイアウト自由に配置したい時 |
| **Fontshare** | fontshare.com | 無料高品質フォント（英語） | 英語見出し用のディスプレイフォント探し |
| **Kling AI** | klingai.com | 動画生成AI | LP背景動画の生成（Higgsfield AIの代替/併用） |
| **Curated Design** | craftwork.design/curated/websites/ | デザインインスピレーションギャラリー + UI素材マーケット | 参考ギャラリー。有料素材もあり |
| **Figmify** | figmify.ai | 画像→Figma変換 | デザインカンプからの変換 |

### Grainient活用ガイド
1. grainient.supply で好みの背景を選ぶ（Moon/Phantom/Novaあたりが◎）
2. 画像をダウンロード（WebP/PNG）
3. セクションの `background-image` に設定:
```css
.dark-section {
  background: #0D1117; /* フォールバック */
  background-image: url('grainient-phantom.webp');
  background-size: cover;
  background-position: center;
}
```
4. その上にCanvasオーバーレイを重ねる → 奥行き段違い
5. SVGノイズテクスチャを最上層に → 統一感

---

## インスピレーション源

- **Codrops** (github.com/codrops) — 343リポ。エフェクトデモ+ソースの宝庫
- **dark.design** — ダークテーマ専門ギャラリー
- **ICS MEDIA** (ics.media) — Three.js日本語チュートリアル最高峰
- **Shift Brain** — 洗練+温かみの日本エージェンシー
- **Awwwardsトップ**: Linear, Vercel, Stripe, Vapi.ai, teamLab
- **bentogrids.com** — Bento Gridレイアウト専門。UI/グラフィック/テンプレート
- **UIVerse.io** — 1,100+カードデザイン、ボタン、フォーム等のCSSコピペ
- **Magic UI** (magicui.design) — 150+コンポーネント。Bento Grid, Border Beam等
- **Aceternity UI** (ui.aceternity.com) — Lamp Effect, Tracing Beam, Infinite Cards
