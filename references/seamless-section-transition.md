---
name: シームレスセクション色遷移テクニック
description: セクション間の背景色遷移でseam（境界線）を完全に消す手法。固定レイヤー+GSAP ScrollTrigger+Twilight Protocol。全Web制作で必須
type: feedback
---

## 核心原則: 色を持つ面を1つにする

セクション間の色遷移でseamが出る根本原因: **複数のHTML要素がそれぞれ背景色を持つ**こと。
解決: **1つの固定レイヤーだけが色を持ち、セクションは全て透明にする**。

**Why:** 10回以上の試行で、ブリッジdiv・負マージン・z-index重ね・手動JS補間を全て試したが、全てseamが残った。唯一seamが消えたのは「色を持つ面が物理的に1つしかない」構造。

**How to apply:** ライト→ダーク、ダーク→ライト、どんなセクション遷移でもこの原則を最初に適用する。

---

## 実装パターン（検証済み・本番適用済み）

### 1. HTML — 固定背景レイヤー（bodyの最初の子要素）
```html
<div id="colorTransitionBg" aria-hidden="true"></div>
```

### 2. CSS — 固定レイヤー + セクション透明化
```css
#colorTransitionBg {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background-color: #F5F3EF; /* 開始色 */
}

/* 遷移元セクションの下部をフェード（重要！） */
.section-before-transition {
  background: linear-gradient(to bottom,
    #F5F3EF 0%, #F5F3EF 75%, transparent 100%);
  margin-bottom: -1px; /* サブピクセルギャップ防止 */
}

/* 遷移先セクションは透明 */
.section-after-transition {
  background: transparent; /* 固定レイヤーが見える */
}

/* ブリッジ（空のスクロールトリガー） */
.transition-bridge {
  height: 150vh;
  pointer-events: none;
}
```

### 3. JS — GSAP ScrollTrigger + Twilight Protocol
```html
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/ScrollTrigger.min.js"></script>
```

```js
gsap.registerPlugin(ScrollTrigger);

// タイムラインで10段階のTwilight Protocol色を順番に通す
var tl = gsap.timeline({
  scrollTrigger: {
    trigger: "#colorBridge",
    start: "top 70%",     // セクションがほぼ画面外になってから開始
    end: "bottom top",
    scrub: 1.5,           // 1.5秒の抵抗感
  }
});
tl.to("#colorTransitionBg", { backgroundColor:"#E8E4DE", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#D6D0C7", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#BDB5AD", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#9E958F", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#737C82", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#515A67", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#323749", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#1A1C2D", duration:1, ease:"none" })
  .to("#colorTransitionBg", { backgroundColor:"#0A0A14", duration:1, ease:"none" });
```

---

## Twilight Protocol — 知覚的に自然な色遷移パレット

| # | 名前 | HEX | 彩度 | 役割 |
|---|------|-----|------|------|
| 1 | Cloud Dancer | #F5F3EF | 23% | 開始（暖ベージュ） |
| 2 | Warm Parchment | #E8E4DE | 19% | |
| 3 | Linen | #D6D0C7 | 15% | |
| 4 | Desert Stone | #BDB5AD | 11% | |
| **5** | **Warm Ash** | **#9E958F** | **7%** | **クロスオーバー（暖→寒）** |
| **6** | **Cool Ash** | **#737C82** | **6%** | **寒色側（気づかない）** |
| 7 | Slate Blue | #515A67 | 12% | |
| 8 | Indigo Slate | #323749 | 19% | |
| 9 | Indigo Dusk | #1A1C2D | 27% | |
| 10 | Dark Indigo | #0A0A14 | 33% | 終了（ダークインディゴ） |

**原理**: 彩度が7%→6%のとき暖色→寒色のhueジャンプが起きるが、人間の目には「ただのグレー」にしか見えない。だから自然。

---

## 失敗パターン（二度とやらない）

1. **ブリッジdivに背景色を変える** → セクション間に必ずseam
2. **negative marginでセクションを重ねる** → z-indexが崩壊
3. **手動RGB lerp** → 中間色がガリガリになる（GSAPのcolor interpolationを使う）
4. **bodyのbackground-colorを変える** → iOS Safariで問題。fixed divの方が安全
5. **オレンジ→パープルの直接遷移** → マゼンタ/ピンクを通って不自然
