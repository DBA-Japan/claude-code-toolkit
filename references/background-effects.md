# 背景エフェクトガイド

ドット以外の背景パターン、オーロラ、グラデーションメッシュ、マウス連動、背景二重構造の実装方法。

---

## 1. SVG ノイズ / グレイン（JS 不要）

SVG `feTurbulence` をデータ URL 化。`baseFrequency`（粗さ）と `numOctaves`（複雑さ 1-4）で調整。

```css
.noise-overlay {
  position: absolute; inset: 0; z-index: 1; pointer-events: none;
  opacity: 0.06;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
}
```

ツール: [heropatterns.com](https://heropatterns.com) / [ibelick.com](https://ibelick.com)

---

## 2. クロスハッチ / ライン / グリッド（CSS-only）

`repeating-linear-gradient` で直線を重ねる。

```css
.crosshatch {
  background:
    repeating-linear-gradient(45deg, rgba(0,0,0,0.03) 0px, rgba(0,0,0,0.03) 1px, transparent 1px, transparent 10px),
    repeating-linear-gradient(-45deg, rgba(0,0,0,0.03) 0px, rgba(0,0,0,0.03) 1px, transparent 1px, transparent 10px);
}
```

ツール: [10015.io](https://10015.io) / [cssgradient.io](https://cssgradient.io)

---

## 3. グラデーションメッシュ

CSS 標準未対応。複数 `radial-gradient` を重ねて擬似実装。

```css
.mesh-gradient {
  background:
    radial-gradient(circle at 25% 25%, #FF6B9D, transparent 50%),
    radial-gradient(circle at 75% 75%, #4ECDC4, transparent 50%),
    radial-gradient(circle at 50% 50%, #FFE66D, transparent 50%);
}
```

ツール: [csshero.org/mesher](https://csshero.org/mesher) / [hypercolor.dev](https://hypercolor.dev)

---

## 4. オーロラ / 虹エフェクト（CSS-only）

複数 ellipse グラデーション + `blur(100px)` + animation。

```css
.aurora {
  position: absolute; inset: -50%; z-index: 0;
  background:
    radial-gradient(ellipse at 20% 30%, rgba(0,200,255,0.4), transparent 40%),
    radial-gradient(ellipse at 80% 70%, rgba(100,50,255,0.3), transparent 40%),
    radial-gradient(ellipse at 50% 50%, rgba(0,255,150,0.2), transparent 50%);
  filter: blur(100px);
  animation: auroraFlow 8s ease-in-out infinite alternate;
}
@keyframes auroraFlow {
  to { transform: translate(5%, -5%) rotate(3deg); }
}
```

---

## 5. マウス連動背景（WebGL なし）

JS でマウス座標取得 → CSS 変数 → `radial-gradient` の位置変更。

```js
document.addEventListener('mousemove', (e) => {
  const x = (e.clientX / window.innerWidth) * 100;
  const y = (e.clientY / window.innerHeight) * 100;
  document.documentElement.style.setProperty('--mouse-x', x + '%');
  document.documentElement.style.setProperty('--mouse-y', y + '%');
});
```

```css
.interactive-bg {
  background: radial-gradient(
    600px circle at var(--mouse-x, 50%) var(--mouse-y, 50%),
    rgba(255, 100, 100, 0.15),
    transparent
  );
}
```

---

## 6. 背景二重構造（パララックス）

CSS `perspective` + `translateZ()` で奥行き。

```css
.parallax-container {
  perspective: 1px;
  height: 100vh;
  overflow-x: hidden;
  overflow-y: auto;
}
.layer-back {
  transform: translateZ(-500px) scale(3);
}
.layer-front {
  transform: translateZ(0);
}
```

---

## 7. Stripe 風メッシュグラデーション

WebGL miniGL (10KB) で Fractal Brownian Motion + Simplex ノイズ。

参考: [bram.us — Stripe gradient](https://bram.us/2021/10/13/how-to-create-the-stripe-website-gradient-effect)

---

## ツール / 生成器一覧

| ツール | URL | 用途 |
|--------|-----|------|
| Hero Patterns | heropatterns.com | SVG パターン |
| SVG Backgrounds | svgbackgrounds.com | カスタム背景 |
| Noise & Gradient | noiseandgradient.com | ノイズ+グラデーション |
| Grainy Gradients | grainy-gradients.vercel.app | グレインプレイグラウンド |
| Grainient | grainient.supply | 1000+ AI 生成グラデーション画像 |
| Mesh Gradient | csshero.org/mesher | メッシュグラデーション生成 |
