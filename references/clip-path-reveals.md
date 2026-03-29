# Clip-Path Section Reveals（スクロール駆動）

`clip-path` で次セクションを「出現」させる 6 つの手法。GSAP ScrollTrigger + scrub で実装。

---

## 共通構造

```html
<section class="section current" style="background: #0a0a14;">
  <div class="content">Current</div>
</section>
<section class="section reveal" style="background: #F5F3EF;">
  <div class="content">Revealed</div>
</section>
```

```css
.reveal {
  -webkit-clip-path: circle(0% at 50% 50%); /* iOS Safari 必須 */
  clip-path: circle(0% at 50% 50%);
  will-change: clip-path; /* GPU 合成を強制 */
}
```

**重要**: `-webkit-clip-path` は iOS Safari で必須。省略すると動かない。

---

## 1. Circle Expand（円拡大）

画面中央から円が広がり次セクションを露出。

```css
/* 初期 */ clip-path: circle(0% at 50% 50%);
/* 完了 */ clip-path: circle(150% at 50% 50%);
```

```js
gsap.to(".reveal", {
  clipPath: "circle(150% at 50% 50%)",
  ease: "none",
  scrollTrigger: {
    trigger: ".reveal",
    start: "top bottom",
    end: "top top",
    scrub: 1,
  }
});
```

**なぜ 150%?** — `100%` だと画面の角が切れる。対角線が ~71% なので余裕を持って 150%。

---

## 2. Vertical Blinds（ブラインド効果）

5 枚のスリットが広がるベネチアンブラインド。

```js
gsap.to(".reveal", {
  clipPath: "polygon(0% 0%, 0% 100%, 20% 100%, 20% 0%, 20% 0%, 20% 100%, 40% 100%, 40% 0%, 40% 0%, 40% 100%, 60% 100%, 60% 0%, 60% 0%, 60% 100%, 80% 100%, 80% 0%, 80% 0%, 80% 100%, 100% 100%, 100% 0%)",
  scrollTrigger: { trigger: ".reveal", start: "top bottom", end: "top 20%", scrub: 1.5 }
});
```

**注意**: polygon の頂点数は開始と終了で一致させること（GSAP が補間できない）。
モバイルでは 3 枚に減らす（画面幅が狭いとスリットが見えない）。

---

## 3. Diamond Reveal（ダイヤモンド拡大）

```css
/* 初期 */ clip-path: polygon(50% 50%, 50% 50%, 50% 50%, 50% 50%);
/* 完了 */ clip-path: polygon(50% -50%, 150% 50%, 50% 150%, -50% 50%);
```

4 頂点なので iOS Safari でも非常に軽い。

---

## 4. Iris Wipe（映画カメラ虹彩風）

SVG `clipPath` で 6 枚羽根の虹彩。

```html
<svg width="0" height="0" style="position:absolute;">
  <defs>
    <clipPath id="iris" clipPathUnits="objectBoundingBox">
      <polygon id="irisBlades" points="0.5,0.5 0.5,0.5 ..."/>
    </clipPath>
  </defs>
</svg>
```

```js
gsap.to("#irisBlades", {
  attr: { points: "0.5,-0.5 1.37,0.0 ..." },
  scrollTrigger: { trigger: ".reveal", start: "top 80%", end: "top top", scrub: 1 }
});
```

**iOS Safari**: `url()` 参照は不安定。**インライン SVG を同一 DOM 内に配置**。

---

## 5. Horizontal Wipe（左→右）

最もシンプルで安定。

```css
/* 初期 */ clip-path: inset(0 100% 0 0);
/* 完了 */ clip-path: inset(0 0% 0 0);
```

**バリエーション**:
- 右→左: `inset(0 0 0 100%)` → `inset(0)`
- 上→下: `inset(100% 0 0 0)` → `inset(0)`
- 中央→外: `inset(50% 50% 50% 50%)` → `inset(0)`

`inset()` は iOS Safari で**最も安定**。

---

## 6. Organic Blob（インク拡大）

CSS `clip-path` だけでは不規則形状は難しい。**MorphSVGPlugin** が最適解。

```js
gsap.registerPlugin(MorphSVGPlugin, ScrollTrigger);

gsap.to("#blobPath", {
  morphSVG: "M-0.5,-0.5 C-0.2,-0.6 ... -0.5,-0.5Z",
  scrollTrigger: { trigger: ".reveal", start: "top 80%", end: "top top", scrub: 1.5 }
});
```

MorphSVG なしの代替: `circle()` のサイズと中心点を同時に変える。

---

## 比較表

| 手法 | 難易度 | iOS Safari | GPU 負荷 | 見た目 |
|------|--------|-----------|----------|--------|
| Circle Expand | 低 | 安定 | 低 | 定番 |
| Vertical Blinds | 中 | 安定（5枚以下） | 中 | ユニーク |
| Diamond | 低 | 安定 | 低 | シャープ |
| Iris Wipe | 高 | 要注意 | 中 | 映画的 |
| Horizontal Wipe | 低 | 最安定 | 最低 | クリーン |
| Organic Blob | 高 | 要 MorphSVG | 高 | 有機的 |

---

## パフォーマンス注意

- `will-change: clip-path` は必須（GPU 合成強制）
- `polygon()` の頂点は 20 個以下に（iOS でカクつく）
- Canvas 背景と併用可能（セクションごと clip される）
