# スクロールストーリーテリングガイド

Apple / Stripe / Linear 風のスクロール駆動ストーリーテリング。Pin、Scrub、横スクロール、CSS scroll-driven の実装パターン。

---

## 基本テクニック

### Pin（固定）

ScrollTrigger の `pin: true` でセクションを画面に固定し、内部をアニメーション。

```js
gsap.registerPlugin(ScrollTrigger);

gsap.to('.hero-content', {
  opacity: 0, y: -50,
  scrollTrigger: {
    trigger: '.hero',
    start: 'top top',
    end: '+=100%',
    pin: true,
    scrub: 1,
  }
});
```

**注意**: pin された要素自体をアニメしない。**子要素だけ**動かす。

### Scrub（同期）

`scrub: 1` でスクロール位置とアニメーション進度を 1:1 対応。数値が大きいほど追従が遅い。

### Parallax（視差）

`perspective` + `translateZ()` で多層の速度差。

```css
.parallax-container { perspective: 1px; overflow-y: auto; }
.layer-slow  { transform: translateZ(-2px) scale(3); }
.layer-fast  { transform: translateZ(0); }
```

---

## 「ピンが長すぎてうざい」を避ける

- duration を **100vh 程度**に抑える（200vh は長すぎ）
- 複数 pin なら間に**スペーサー**を入れる
- ユーザーに「進行中」感を与える**プログレスバー**を追加

---

## 横スクロール実装

```js
const sections = gsap.utils.toArray('.panel');

gsap.to(sections, {
  xPercent: -100 * (sections.length - 1),
  ease: 'none',
  scrollTrigger: {
    trigger: '.horizontal-wrapper',
    pin: true,
    scrub: 1,
    end: () => '+=' + document.querySelector('.horizontal-wrapper').scrollWidth,
  }
});
```

モバイルでは**縦レイアウトにフォールバック**する。

---

## CSS Scroll-Driven Animations（JS ゼロ）

AOS.js の完全代替。Chrome 115+ / Edge 115+ / Safari 26+ 対応。

```css
.element {
  animation: slide-in linear both;
  animation-timeline: view();
  animation-range: entry 0% cover 40%;
}

@keyframes slide-in {
  from { opacity: 0; transform: translateY(50px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

### scroll() vs view()
- `scroll()` — ページ全体のスクロール位置に連動
- `view()` — 要素がビューポートに入る/出るタイミングに連動

---

## Codrops 参考デモ（GitHub）

| リポ名 | ★ | テクニック |
|--------|---|-----------|
| ScrollBasedLayoutAnimations | 325 | GSAP Flip + ScrollTrigger |
| ColumnScroll | 208 | カラム逆方向スクロール |
| StickySections | 130 | スティッキーセクション |
| ScrollBlurTypography | 135 | ぼやけ→クリア |
| OnScrollTypographyAnimations | 335 | テキスト変形 |

---

## 超一流サイトの手法

| サイト | テクニック |
|--------|-----------|
| **Apple** | Pin + Scrub + 画像シーケンス。シネマティック |
| **Stripe** | WebGL miniGL (10KB) でメッシュグラデーション |
| **Linear** | Lenis カスタムで「意図的に遅い」スクロール |
| **Vercel** | `overscroll-behavior: contain` でモーダル制御 |

---

## パフォーマンス鉄則

1. `transform` と `opacity` のみアニメーション
2. `will-change: transform` で事前宣言（乱用禁止）
3. 60fps 維持（DevTools Performance タブで確認）
4. 画面外のアニメーションは IntersectionObserver で停止
5. モバイルでは重い pin + scrub を省略（フェードインだけで十分）
