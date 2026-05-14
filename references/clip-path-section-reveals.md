---
name: Clip-Path Section Reveals (スクロール駆動)
description: clip-pathで次セクションを「出現」させる6つの手法。Circle expand, Vertical blinds, Diamond, Iris wipe, Horizontal wipe, Organic blob。完全コード例3本付き。パフォーマンス・iOS Safari・Canvas互換性・比較表
type: reference
---

# Clip-Path Based Section Reveals (2026-03 調査)

スクロールで次のセクションが形（円・多角形・ブロブ等）を広げながら出現する手法。

---

## 全手法共通: 構造パターン

```html
<!-- 現在のセクション -->
<section class="section current" style="background: #0a0a14;">
  <div class="content">Current Section</div>
</section>

<!-- 次のセクション（clip-pathで隠れている） -->
<section class="section reveal" style="background: #F5F3EF;">
  <div class="content">Revealed Section</div>
</section>
```

```css
.section {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
}
.reveal {
  /* 初期状態: 完全に隠す */
  -webkit-clip-path: circle(0% at 50% 50%);
  clip-path: circle(0% at 50% 50%);
  /* will-changeは必須 — clip-pathはデフォルトでGPU合成されない */
  will-change: clip-path;
}
```

**重要**: `-webkit-clip-path` は iOS Safari で必須。省略すると動かない。

---

## 1. Circle Expand from Center (円拡大)

**効果**: 画面中央から円が広がり次セクションを露出

```css
/* 初期 */  clip-path: circle(0% at 50% 50%);
/* 完了 */  clip-path: circle(150% at 50% 50%);
```

**なぜ150%?** — `100%`だと画面の角が切れる。`sqrt(50^2 + 50^2) = ~70.7%` が対角線なので、安全マージンで `150%` を使う。正確な最小値は `71%` だが、アスペクト比がvwベースなので横長画面で不足する。

```js
gsap.registerPlugin(ScrollTrigger);

gsap.to(".reveal", {
  clipPath: "circle(150% at 50% 50%)",
  ease: "none",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top bottom",    // セクションが画面下に来たら開始
    end: "top top",         // セクションが画面上端に来たら完了
    scrub: 1,               // 1秒の遅延でスムーズに
    // pin: true,           // 必要なら固定
  }
});
```

**iOS Safari**: 問題なし。circle()は最も軽い形状。
**Canvas背景**: 適用可能（セクションごとclipされるのでCanvas含め全て影響）。
**モバイル**: `150%`の値はvw基準なので縦長でも問題なし。

---

## 2. Vertical Blinds (ブラインド効果)

**効果**: 垂直のスリットが広がるベネチアンブラインド

```css
/* 5枚ブラインド — 初期（全閉） */
clip-path: polygon(
  0% 0%, 0% 0%,           /* strip 1 */
  20% 0%, 20% 0%,
  20% 0%, 20% 0%,         /* strip 2 */
  40% 0%, 40% 0%,
  40% 0%, 40% 0%,         /* strip 3 */
  60% 0%, 60% 0%,
  60% 0%, 60% 0%,         /* strip 4 */
  80% 0%, 80% 0%,
  80% 0%, 80% 0%,         /* strip 5 */
  100% 0%, 100% 0%
);

/* 5枚ブラインド — 完了（全開） */
clip-path: polygon(
  0% 0%, 0% 100%,
  20% 100%, 20% 0%,
  20% 0%, 20% 100%,
  40% 100%, 40% 0%,
  40% 0%, 40% 100%,
  60% 100%, 60% 0%,
  60% 0%, 60% 100%,
  80% 100%, 80% 0%,
  80% 0%, 80% 100%,
  100% 100%, 100% 0%
);
```

**注意**: polygon()のポイント数は開始と終了で一致させること（GSAPが補間できない）。

```js
gsap.to(".reveal", {
  clipPath: "polygon(0% 0%, 0% 100%, 20% 100%, 20% 0%, 20% 0%, 20% 100%, 40% 100%, 40% 0%, 40% 0%, 40% 100%, 60% 100%, 60% 0%, 60% 0%, 60% 100%, 80% 100%, 80% 0%, 80% 0%, 80% 100%, 100% 100%, 100% 0%)",
  ease: "power2.inOut",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top bottom",
    end: "top 20%",
    scrub: 1.5,
  }
});
```

**iOS Safari**: polygon()の頂点数が多いとパフォーマンス低下。5枚ブラインド(20頂点)は安全圏。10枚以上は避ける。
**Canvas背景**: 適用可能。
**モバイル**: 3枚ブラインドに減らすのが安全（画面幅が狭いのでスリットが細すぎると見えない）。

---

## 3. Diamond / Rhombus Reveal (ダイヤモンド拡大)

**効果**: 画面中央からひし形が拡大

```css
/* 初期 */
clip-path: polygon(50% 50%, 50% 50%, 50% 50%, 50% 50%);
/* 完了 — 画面全体を覆うダイヤ */
clip-path: polygon(50% -50%, 150% 50%, 50% 150%, -50% 50%);
```

```js
gsap.to(".reveal", {
  clipPath: "polygon(50% -50%, 150% 50%, 50% 150%, -50% 50%)",
  ease: "power1.inOut",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top 80%",
    end: "top 10%",
    scrub: 1,
  }
});
```

**iOS Safari**: polygon(4頂点)は非常に軽い。問題なし。
**Canvas背景**: 適用可能。
**モバイル**: 縦長画面ではダイヤが横に間延びする可能性。`polygon(50% -80%, 150% 50%, 50% 180%, -50% 50%)` で縦を伸ばすと自然。

---

## 4. Iris Wipe (映画カメラ虹彩風)

**効果**: 複数のポイントが同心円的に広がる（カメラの絞り羽根風）

circle()だけでは「羽根」感が出ない。SVG clipPathを使う。

```html
<svg width="0" height="0" style="position:absolute;">
  <defs>
    <clipPath id="iris" clipPathUnits="objectBoundingBox">
      <!-- 6枚羽根の虹彩。初期は閉じた状態 -->
      <polygon id="irisBlades" points="
        0.5,0.5  0.5,0.5  0.5,0.5
        0.5,0.5  0.5,0.5  0.5,0.5
        0.5,0.5  0.5,0.5  0.5,0.5
        0.5,0.5  0.5,0.5  0.5,0.5
      "/>
    </clipPath>
  </defs>
</svg>
```

```css
.reveal {
  -webkit-clip-path: url(#iris);
  clip-path: url(#iris);
}
```

```js
// 6枚羽根が開いた状態（完全に画面を覆う六角形）
gsap.to("#irisBlades", {
  attr: {
    points: `
      0.5,-0.5  1.37,0.0  1.37,0.0
      1.37,1.0  1.37,1.0  0.5,1.5
      0.5,1.5  -0.37,1.0  -0.37,1.0
      -0.37,0.0  -0.37,0.0  0.5,-0.5
    `
  },
  ease: "power2.inOut",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top 80%",
    end: "top top",
    scrub: 1,
  }
});
```

**iOS Safari**: `url()` 参照のSVG clipPathは `-webkit-` prefix でも動作が不安定な場合がある。インラインSVGを使い、同一DOM内に配置すること。外部ファイル参照は避ける。
**Canvas背景**: 適用可能（CSS clip-pathがセクション全体に効く）。
**モバイル**: SVG clipPathUnits="objectBoundingBox" は相対座標(0-1)なのでレスポンシブ対応済み。

---

## 5. Horizontal Wipe (左から右)

**効果**: 左端から右端へカーテンが開くように

```css
/* 初期 */  clip-path: inset(0 100% 0 0);
/* 完了 */  clip-path: inset(0 0% 0 0);
```

**inset()構文**: `inset(top right bottom left)` — right: 100%で右側全体をクリップ。

```js
gsap.to(".reveal", {
  clipPath: "inset(0 0% 0 0)",
  ease: "none",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top bottom",
    end: "top 30%",
    scrub: 1,
  }
});
```

**iOS Safari**: inset()は最も安定。パフォーマンス最良。
**Canvas背景**: 適用可能。
**モバイル**: 横幅が狭いので遷移が速く感じる。`end: "top top"` まで伸ばして遅くする。

**バリエーション**:
- 右から左: `inset(0 0 0 100%)` → `inset(0 0 0 0%)`
- 上から下: `inset(100% 0 0 0)` → `inset(0 0 0 0)`
- 中央から外へ: `inset(50% 50% 50% 50%)` → `inset(0 0 0 0)` (四方向に同時展開)

---

## 6. Irregular Organic Shape (インク/ブロブ拡大)

**効果**: 不規則な有機的形状がインクのように広がる

CSS clip-pathだけでは不規則形状は難しい。**SVG clipPath + MorphSVG** が最適解。

```html
<svg width="0" height="0" style="position:absolute;">
  <defs>
    <clipPath id="blobClip" clipPathUnits="objectBoundingBox">
      <path id="blobPath" d="M0.5,0.5 C0.5,0.5 0.5,0.5 0.5,0.5 C0.5,0.5 0.5,0.5 0.5,0.5 C0.5,0.5 0.5,0.5 0.5,0.5 C0.5,0.5 0.5,0.5 0.5,0.5Z"/>
    </clipPath>
  </defs>
</svg>
```

```css
.reveal {
  -webkit-clip-path: url(#blobClip);
  clip-path: url(#blobClip);
}
```

```js
// MorphSVGPlugin（GSAP無料化済み）で不規則形状にモーフィング
gsap.registerPlugin(MorphSVGPlugin, ScrollTrigger);

gsap.to("#blobPath", {
  morphSVG: "M-0.5,-0.5 C-0.2,-0.6 0.7,-0.8 1.5,-0.5 C1.8,0.1 1.6,0.6 1.5,1.5 C0.8,1.7 0.2,1.6 -0.5,1.5 C-0.8,0.9 -0.7,0.2 -0.5,-0.5Z",
  ease: "power1.inOut",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top 80%",
    end: "top top",
    scrub: 1.5,
  }
});
```

**MorphSVGなしの代替**: circle()のサイズを段階的に変えつつ、中心点もずらすことで擬似的な不規則感を出す:

```js
const tl = gsap.timeline({
  scrollTrigger: { trigger: ".reveal", start: "top bottom", end: "top top", scrub: 1 }
});
tl.to(".reveal", { clipPath: "circle(10% at 45% 55%)", duration: 1 })
  .to(".reveal", { clipPath: "circle(30% at 52% 48%)", duration: 1 })
  .to(".reveal", { clipPath: "circle(60% at 48% 52%)", duration: 1 })
  .to(".reveal", { clipPath: "circle(150% at 50% 50%)", duration: 1 });
```

**iOS Safari**: MorphSVGのSVG clipPath参照は要注意。フォールバックとしてcircle()版を用意すべき。
**Canvas背景**: 適用可能。
**モバイル**: blob形状は小画面で視認しにくい。モバイルではcircle expand(手法1)にフォールバック推奨。

---

## 比較: clip-path vs mask-image vs overflow:hidden vs Houdini

| 項目 | clip-path | mask-image | overflow:hidden + resize | Houdini Paint Worklet |
|------|-----------|------------|--------------------------|----------------------|
| **ブラウザ対応** | 全ブラウザ (-webkit-必須) | 全ブラウザ (-webkit-必須) | 全ブラウザ | Chromiumのみ (Safari/Firefox NG) |
| **GPU加速** | 将来的に自動合成化予定。現在はpaint層 | paint層（clip-pathと同等） | transform可能=compositor層 | compositor層（理論上最速） |
| **形状の自由度** | circle/ellipse/polygon/inset/path()/shape() | グラデーション/画像/SVG — 任意形状可能 | 矩形のみ | 完全自由（JS描画） |
| **iOS Safari** | 安定（-webkit-付き） | 安定（-webkit-付き） | 安定 | 非対応 |
| **GSAP連携** | 直接アニメ可能 | CSS変数経由で間接的 | transform/width/heightで制御 | CSS変数経由 |
| **Canvas背景** | セクション全体にかかる | セクション全体にかかる | コンテナサイズ変更で制御 | 背景描画として使用 |
| **推奨用途** | **第1候補。円・多角形・基本形状** | **ソフトエッジ・グラデーション境界・フェザリング** | **矩形のみで良い場合。最高パフォーマンス** | **Chromium限定で良ければ最高の自由度** |

### いつmask-imageを選ぶか

clip-pathは**ハードエッジ**（くっきりした境界）。mask-imageは**ソフトエッジ**が可能:

```css
/* グラデーションマスクで「ぼやけた円」の出現 */
.reveal {
  -webkit-mask-image: radial-gradient(circle at 50% 50%, black 0%, transparent 0%);
  mask-image: radial-gradient(circle at 50% 50%, black 0%, transparent 0%);
}

/* スクロールでグラデーション範囲を広げる */
/* → GSAP でCSS変数を動かしてmask-imageの値を更新 */
```

**問題**: GSAPは `mask-image` を直接補間できない。CSS `@property` で変数を定義し、その変数をアニメーションする必要がある:

```css
@property --mask-size {
  syntax: '<percentage>';
  initial-value: 0%;
  inherits: false;
}
.reveal {
  -webkit-mask-image: radial-gradient(circle, black var(--mask-size), transparent var(--mask-size));
  mask-image: radial-gradient(circle, black var(--mask-size), transparent var(--mask-size));
}
```

```js
gsap.to(".reveal", {
  "--mask-size": "150%",
  scrollTrigger: { trigger: ".reveal", start: "top bottom", end: "top top", scrub: 1 }
});
```

### overflow:hidden + transform アプローチ

矩形ワイプ限定だが、**最高パフォーマンス**（transform = compositor層）:

```css
.reveal-wrapper {
  position: relative;
  overflow: hidden;
  height: 100vh;
}
.reveal-inner {
  position: absolute;
  inset: 0;
  transform: translateX(-100%); /* 初期: 画面外 */
  will-change: transform;
}
```

```js
gsap.to(".reveal-inner", {
  x: "0%",
  scrollTrigger: { trigger: ".reveal-wrapper", start: "top bottom", end: "top top", scrub: 1 }
});
```

### SVG clipPath for Complex Shapes

CSS clip-pathの `polygon()` では表現できない曲線・複雑形状に:

```html
<svg width="0" height="0">
  <defs>
    <clipPath id="complexShape" clipPathUnits="objectBoundingBox">
      <path d="M0.5,0.5 C0.5,0.3 0.7,0.5 0.5,0.5Z"/>
    </clipPath>
  </defs>
</svg>
```

**注意点**:
- `clipPathUnits="objectBoundingBox"` → 座標は0-1の相対値（レスポンシブ対応）
- `clipPathUnits="userSpaceOnUse"` → ピクセル値（要リサイズ対応）
- SVGは**インラインで同一HTML内に置く**。外部ファイル参照 `url(file.svg#id)` はSafariで動かない
- MorphSVGPlugin でpath d属性をアニメすれば任意の形状変形が可能

### CSS Houdini Paint Worklet

**現実**: 2026年3月時点でSafari非対応、Firefox非対応。Chromiumのみ。ポリフィル(css-paint-polyfill)はあるが、スクロール同期のリアルタイムペイントには重すぎる。

**本番サイトでは非推奨**。実験やChromium限定プロジェクトでのみ。

---

## Pure CSS (JSゼロ) でのclip-path スクロールリビール

Safari 17+, Chrome 115+, Firefox 110+ 対応:

```css
@property --reveal-progress {
  syntax: '<percentage>';
  initial-value: 0%;
  inherits: false;
}

.reveal {
  animation: clipReveal linear;
  animation-timeline: view();
  animation-range: entry 0% cover 50%;
  -webkit-clip-path: circle(var(--reveal-progress) at 50% 50%);
  clip-path: circle(var(--reveal-progress) at 50% 50%);
}

@keyframes clipReveal {
  from { --reveal-progress: 0%; }
  to   { --reveal-progress: 150%; }
}
```

**制限**: `animation-timeline: view()` はSafari 26+で対応予定（2026年秋）。現時点ではSafari未対応。GSAPフォールバック必須。

---

## パフォーマンス最適化ルール

### clip-pathが重い理由
clip-pathの変更はブラウザの**paint**フェーズを毎フレーム発火する。`transform`/`opacity`のようにcompositor層だけで完結しない。

### 最適化チェックリスト

1. **`will-change: clip-path`** — 必ず付ける。ペイント用のレイヤーを事前作成
2. **`-webkit-clip-path` を常に併記** — iOSで必須
3. **`scrub: 1` 以上** — `scrub: true`(0)だとフレームごとに更新=重い。1-2秒の遅延で間引き
4. **同時に2つ以上のclip-pathアニメを走らせない** — 1セクション遷移に1つだけ
5. **polygon()の頂点は20以下** — 20超えるとモバイルでjank
6. **モバイルでは形状を簡素化** — ブラインド5枚→3枚、blob→circle
7. **IntersectionObserverでViewport外は無効化** — GSAPのtoggleActionsで自動対応
8. **Canvas背景がある場合**: Canvas自体のrAFループも考慮。clip-path + Canvas描画で二重負荷になる。モバイルではCanvas DPR 1.0xに下げる
9. **backface-visibility: hidden** — 一部ブラウザでレイヤー合成を助ける
10. **contain: paint** — 再ペイントの範囲をセクション内に限定

### iOS Safari 特有の問題と対策

| 問題 | 対策 |
|------|------|
| -webkit-prefix 未記述で動かない | **常に併記** |
| SVG url() clipPathが効かない | インラインSVGを使う。外部ファイル参照禁止 |
| スクロール中のflicker | `scrub: 1.5`以上で緩和。`-webkit-backface-visibility: hidden` 追加 |
| position:fixed + clip-path の組合せ | 不安定。fixedレイヤーにはclip-pathを使わない |
| 大きなcircle()値でクラッシュ | 200%以下に抑える。150%が安全ライン |
| 高DPRデバイス(3x)でのpaint負荷 | `@media (-webkit-min-device-pixel-ratio: 3)` でアニメ簡素化 |

---

## 完全コード例 Top 3

### Example A: Circle Expand (最も汎用的)

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Circle Reveal</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { overflow-x: hidden; }

  .section {
    position: relative;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
  }

  .section-dark {
    background: #0a0a14;
    color: #F5F3EF;
  }

  .section-light {
    background: #F5F3EF;
    color: #0a0a14;
    /* 初期: 完全に隠す */
    -webkit-clip-path: circle(0% at 50% 50%);
    clip-path: circle(0% at 50% 50%);
    will-change: clip-path;
    /* clip-pathで隠れている間もスクロール空間を確保 */
  }

  .section h2 {
    font-family: "Helvetica Neue", Arial, sans-serif;
    font-size: clamp(2rem, 5vw, 4rem);
    font-weight: 700;
  }

  /* Canvas背景の例 */
  .section-dark canvas {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    z-index: 0;
  }
  .section .content {
    position: relative;
    z-index: 1;
  }
</style>
</head>
<body>

<section class="section section-dark">
  <div class="content">
    <h2>Dark Section with Canvas</h2>
    <p>Scroll down to reveal the next section</p>
  </div>
</section>

<section class="section section-light" id="revealSection">
  <div class="content">
    <h2>Light Section Revealed</h2>
    <p>This appeared through a circle expand</p>
  </div>
</section>

<section class="section section-dark">
  <div class="content">
    <h2>Another Dark Section</h2>
  </div>
</section>

<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js"></script>
<script>
gsap.registerPlugin(ScrollTrigger);

// Circle Reveal
gsap.to("#revealSection", {
  clipPath: "circle(150% at 50% 50%)",
  webkitClipPath: "circle(150% at 50% 50%)",
  ease: "none",
  scrollTrigger: {
    trigger: "#revealSection",
    start: "top 80%",        // セクション上端が画面80%位置に来たら開始
    end: "top 20%",          // セクション上端が画面20%位置で完了
    scrub: 1.5,              // 1.5秒の遅延 — iOS Safari flicker防止
    // markers: true,         // デバッグ用
  }
});

// モバイル判定: 高DPRデバイスでアニメ簡素化
if (window.devicePixelRatio >= 3) {
  // 超高解像度ではスクラブを緩くしてフレーム間引き
  ScrollTrigger.getAll().forEach(st => {
    if (st.vars.scrub) st.vars.scrub = 2.5;
  });
}
</script>
</body>
</html>
```

### Example B: Horizontal Wipe + Pin (映画的ワイプ)

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Horizontal Wipe Reveal</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { overflow-x: hidden; }

  .panel {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
  }

  .panel h2 {
    font-family: "Helvetica Neue", Arial, sans-serif;
    font-size: clamp(2rem, 5vw, 4rem);
    font-weight: 700;
  }

  .panel-a {
    background: #1a1c2d;
    color: #F5F3EF;
    z-index: 1;
  }

  .panel-b {
    background: #F5F3EF;
    color: #1a1c2d;
    z-index: 2;
    /* 初期: 右側から完全にクリップ */
    -webkit-clip-path: inset(0 100% 0 0);
    clip-path: inset(0 100% 0 0);
    will-change: clip-path;
    /* pinするので上に重ねる */
    margin-top: -100vh;
  }

  /* ワイプ中に見える「エッジライン」装飾 */
  .panel-b::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 3px;
    height: 100%;
    background: linear-gradient(to bottom, transparent, #00C896, transparent);
    z-index: 10;
    opacity: 0;
    transition: opacity 0.3s;
  }
  .panel-b.wiping::before {
    opacity: 1;
  }

  /* Canvas背景対応 */
  .panel canvas {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
  }
  .panel .content { position: relative; z-index: 1; }
</style>
</head>
<body>

<section class="panel panel-a" id="panelA">
  <div class="content">
    <h2>Section One</h2>
    <p>A cinematic horizontal wipe reveals the next section</p>
  </div>
</section>

<section class="panel panel-b" id="panelB">
  <div class="content">
    <h2>Section Two</h2>
    <p>Wiped in from left to right</p>
  </div>
</section>

<!-- スクロール空間（Pinで消費される分） -->
<div style="height: 100vh;"></div>

<section class="panel panel-a">
  <div class="content">
    <h2>Section Three</h2>
  </div>
</section>

<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js"></script>
<script>
gsap.registerPlugin(ScrollTrigger);

const panelB = document.getElementById("panelB");

const wipeTl = gsap.timeline({
  scrollTrigger: {
    trigger: "#panelA",
    start: "top top",        // セクションAが画面上端に来たらpin開始
    end: "+=100%",           // 100vhのスクロール分
    pin: true,               // セクションAを固定
    scrub: 1,
    onUpdate: (self) => {
      // ワイプ中の装飾表示
      const progress = self.progress;
      if (progress > 0.05 && progress < 0.95) {
        panelB.classList.add("wiping");
      } else {
        panelB.classList.remove("wiping");
      }
    }
  }
});

wipeTl
  .to("#panelB", {
    clipPath: "inset(0 0% 0 0)",
    webkitClipPath: "inset(0 0% 0 0)",
    duration: 1,
    ease: "power2.inOut",
  });

// ワイプ方向をモバイルで変更（上から下の方が自然）
if (window.innerWidth < 768) {
  gsap.set("#panelB", {
    clipPath: "inset(100% 0 0 0)",
    webkitClipPath: "inset(100% 0 0 0)",
  });
  wipeTl.clear();
  wipeTl.to("#panelB", {
    clipPath: "inset(0 0 0 0)",
    webkitClipPath: "inset(0 0 0 0)",
    duration: 1,
    ease: "power2.inOut",
  });
}
</script>
</body>
</html>
```

### Example C: Diamond Reveal + Staggered Content (ダイヤ+コンテンツ登場)

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Diamond Reveal</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { overflow-x: hidden; font-family: "Helvetica Neue", Arial, sans-serif; }

  .section {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
  }

  .section h2 {
    font-size: clamp(2rem, 5vw, 4rem);
    font-weight: 700;
    margin-bottom: 1rem;
  }

  .section-origin {
    background: #0a0a14;
    color: #F5F3EF;
    z-index: 1;
  }

  .section-target {
    background: linear-gradient(135deg, #0D4F3C, #1a6b50);
    color: #F5F3EF;
    z-index: 2;
    /* 初期: 中央の点 */
    -webkit-clip-path: polygon(50% 50%, 50% 50%, 50% 50%, 50% 50%);
    clip-path: polygon(50% 50%, 50% 50%, 50% 50%, 50% 50%);
    will-change: clip-path;
    contain: paint;
  }

  .section-target .content {
    position: relative;
    z-index: 1;
    text-align: center;
    max-width: 800px;
    padding: 2rem;
  }

  .section-target .content > * {
    opacity: 0;
    transform: translateY(30px);
  }

  .section-target p {
    font-size: clamp(1rem, 2vw, 1.25rem);
    line-height: 1.8;
    opacity: 0.85;
  }

  /* SVGノイズテクスチャ（セクション背景の質感向上） */
  .section-target::after {
    content: '';
    position: absolute;
    inset: 0;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.06'/%3E%3C/svg%3E");
    background-size: 128px 128px;
    pointer-events: none;
    z-index: 0;
  }
</style>
</head>
<body>

<section class="section section-origin">
  <div class="content">
    <h2>Before the Diamond</h2>
    <p>Keep scrolling for the diamond reveal</p>
  </div>
</section>

<section class="section section-target" id="diamondSection">
  <div class="content" id="diamondContent">
    <h2>Revealed through Diamond</h2>
    <p>The content fades in after the diamond shape fully expands,<br>creating a two-phase reveal effect.</p>
  </div>
</section>

<section class="section section-origin">
  <div class="content">
    <h2>Continues...</h2>
  </div>
</section>

<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js"></script>
<script>
gsap.registerPlugin(ScrollTrigger);

// Phase 1: Diamond reveal (clip-path)
// モバイルでは縦に伸ばしたダイヤ
const isMobile = window.innerWidth < 768;
const finalClip = isMobile
  ? "polygon(50% -80%, 180% 50%, 50% 180%, -80% 50%)"  // 縦長画面用
  : "polygon(50% -50%, 150% 50%, 50% 150%, -50% 50%)";  // PC用

gsap.to("#diamondSection", {
  clipPath: finalClip,
  webkitClipPath: finalClip,
  ease: "power1.inOut",
  scrollTrigger: {
    trigger: "#diamondSection",
    start: "top 90%",
    end: "top 20%",
    scrub: 1.5,
    onEnter: () => {
      // Phase 2: ダイヤ出現完了後にコンテンツstagger表示
      gsap.to("#diamondContent > *", {
        opacity: 1,
        y: 0,
        duration: 0.8,
        stagger: 0.15,
        ease: "power2.out",
        delay: 0.2,
      });
    },
    onLeaveBack: () => {
      // スクロールバックでコンテンツを再度隠す
      gsap.to("#diamondContent > *", {
        opacity: 0,
        y: 30,
        duration: 0.3,
        stagger: 0.05,
      });
    }
  }
});

// iOS Safari flicker対策
document.getElementById("diamondSection").style.webkitBackfaceVisibility = "hidden";
</script>
</body>
</html>
```

---

## Canvas背景との併用まとめ

clip-pathはCSS propertyなので、セクション全体（子要素含む）をクリップする。つまり:

- Canvas要素がセクション内にある場合 → **自動的にclipされる** (追加作業なし)
- Canvas要素がfixed/absoluteで**セクション外にある場合** → clipされない。セクション内に移動するか、JSでCanvas自体にclip-pathを追加する必要がある

```css
/* Canvas背景がfixed layerの場合の対策 */
#fixedCanvas {
  position: fixed;
  inset: 0;
  z-index: 0;
  /* セクションのclip-pathとは別に、このCanvasにもclipを同期させる */
}
```

```js
// fixedなCanvas背景にもclip-pathを同期
ScrollTrigger.create({
  trigger: "#revealSection",
  start: "top 80%",
  end: "top 20%",
  scrub: 1.5,
  onUpdate: (self) => {
    const r = self.progress * 150;
    const cp = `circle(${r}% at 50% 50%)`;
    document.getElementById("fixedCanvas").style.clipPath = cp;
    document.getElementById("fixedCanvas").style.webkitClipPath = cp;
  }
});
```

---

## seamless-section-transition.md との使い分け

| シナリオ | 使う手法 |
|---------|---------|
| 同系色のグラデーション遷移（ライト→ダーク） | **Twilight Protocol** (seamless-section-transition.md) |
| ドラマチックな「登場」演出 | **clip-path reveal** (このドキュメント) |
| 対比色のセクション切り替え（緑→白等） | **clip-path reveal** (色の中間が不自然になるため) |
| 映画的・ストーリーテリング | **clip-path reveal** (iris wipe, horizontal wipe) |
| 控えめ・品のある遷移 | **Twilight Protocol** |
| 両方組み合わせ | Twilight Protocolで色を変えつつ、clip-pathで次セクションの「窓」を開ける |

---

## CDN (全て無料化済み)
```html
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js"></script>
<!-- MorphSVG (有機的形状用) -->
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/MorphSVGPlugin.min.js"></script>
```

## Sources
- [GSAP clip-path animation](https://codepen.io/GreenSock/pen/JyOVqp)
- [GSAP ScrollTrigger polygon demo](https://codepen.io/GreenSock/pen/dyVyqpq)
- [Horizontal Wipe (tutsplus)](https://codepen.io/tutsplus/pen/abgxGaE)
- [@property + clip-path scroll (utilitybend)](https://utilitybend.com/blog/animating-clip-paths-on-scroll-with-at-property-in-css/)
- [Organic Shape Animations with SVG clipPath (Codrops)](https://tympanus.net/codrops/2017/06/28/organic-shape-animations-with-svg-clippath/)
- [SVG Shapes on Scroll (Codrops)](https://tympanus.net/codrops/2022/06/08/how-to-animate-svg-shapes-on-scroll/)
- [Safari clip-path fixes (devbytoni)](https://devbytoni.com/proven-fixes-for-css-clip-path-svg-polygon-issues-in-safari-unlock-flawless-rendering-in-2025/)
- [clip-path browser support (Can I Use)](https://caniuse.com/css-clip-path)
- [GPU animation guide (Chrome DevRel)](https://developer.chrome.com/blog/hardware-accelerated-animations)
- [CSS Houdini (web.dev)](https://web.dev/articles/houdini-how)
- [clip-path (MDN)](https://developer.mozilla.org/en-US/docs/Web/CSS/clip-path)
- [Emil Kowalski - The Magic of Clip Path](https://emilkowal.ski/ui/the-magic-of-clip-path)
- [Understanding Clip Path (ishadeed)](https://ishadeed.com/article/clip-path/)
- [Sara Soueidan - CSS SVG Clipping](https://www.sarasoueidan.com/blog/css-svg-clipping/)
