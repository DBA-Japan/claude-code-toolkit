# シームレスセクション色遷移テクニック

セクション間の背景色遷移で seam（境界線）を完全に消す手法。

---

## 核心原則: 色を持つ面を 1 つにする

**根本原因**: 複数の HTML 要素がそれぞれ背景色を持つ → 境界線が必ず見える。

**解決**: 1 つの固定レイヤーだけが色を持ち、セクションは全て透明にする。

これ以外の方法（ブリッジ div、負マージン、z-index 重ね、手動 RGB lerp）は全て seam が残る。

---

## 実装パターン

### 1. HTML — 固定背景レイヤー

```html
<div id="colorTransitionBg" aria-hidden="true"></div>
```

### 2. CSS — 固定 + セクション透明化

```css
#colorTransitionBg {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background-color: #F5F3EF; /* 開始色 */
}

/* 遷移元セクションの下部をフェード */
.section-before-transition {
  background: linear-gradient(to bottom,
    #F5F3EF 0%, #F5F3EF 75%, transparent 100%);
  margin-bottom: -1px; /* サブピクセルギャップ防止 */
}

/* 遷移先セクションは透明 → 固定レイヤーが見える */
.section-after-transition {
  background: transparent;
}

/* ブリッジ（スクロールトリガー用の空スペース） */
.transition-bridge {
  height: 150vh;
  pointer-events: none;
}
```

### 3. JS — GSAP ScrollTrigger

```js
gsap.registerPlugin(ScrollTrigger);

const tl = gsap.timeline({
  scrollTrigger: {
    trigger: "#colorBridge",
    start: "top 70%",
    end: "bottom top",
    scrub: 1.5,
  }
});

tl.to("#colorTransitionBg", { backgroundColor: "#E8E4DE", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#D6D0C7", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#BDB5AD", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#9E958F", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#737C82", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#515A67", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#323749", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#1A1C2D", duration: 1, ease: "none" })
  .to("#colorTransitionBg", { backgroundColor: "#0A0A14", duration: 1, ease: "none" });
```

---

## Twilight Protocol — 知覚的に自然な色遷移パレット

ライト → ダークの遷移で、人間の目に自然に見える 10 段階。

| # | 名前 | HEX | 彩度 | 役割 |
|---|------|-----|------|------|
| 1 | Cloud Dancer | `#F5F3EF` | 23% | 開始（暖ベージュ） |
| 2 | Warm Parchment | `#E8E4DE` | 19% | |
| 3 | Linen | `#D6D0C7` | 15% | |
| 4 | Desert Stone | `#BDB5AD` | 11% | |
| **5** | **Warm Ash** | `#9E958F` | **7%** | **クロスオーバー（暖→寒）** |
| **6** | **Cool Ash** | `#737C82` | **6%** | **寒色側** |
| 7 | Slate Blue | `#515A67` | 12% | |
| 8 | Indigo Slate | `#323749` | 19% | |
| 9 | Indigo Dusk | `#1A1C2D` | 27% | |
| 10 | Dark Indigo | `#0A0A14` | 33% | 終了 |

**原理**: 彩度が 7%→6% のとき暖色→寒色の hue ジャンプが起きるが、人間の目には「ただのグレー」にしか見えない。だから自然。

---

## 失敗パターン（やってはいけない）

| NG | 理由 |
|----|------|
| ブリッジ div に背景色を変える | セクション間に必ず seam |
| negative margin でセクション重ね | z-index 崩壊 |
| 手動 RGB lerp | 中間色がガリガリ（GSAP の color interpolation を使う） |
| body の background-color を変える | iOS Safari で問題。fixed div が安全 |
| オレンジ→パープル直接遷移 | マゼンタ/ピンクを通って不自然 |
