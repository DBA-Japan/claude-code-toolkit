# iOS Safari 修正パターン集

iOS Safari 固有のバグと、実戦で検証済みの解決策。マーキー、backdrop-filter、overflow、GPU 合成レイヤーの問題を網羅。

---

## マーキー / 無限スクロールでカードが消える

### 根本原因（3 つが重なって発生）

#### 原因 1: `overflow: hidden` が `backdrop-filter` を殺す
CSS 仕様レベルの問題。`overflow: hidden` は新しいスタッキングコンテキストを作り、子要素の `backdrop-filter` が効かなくなる。

**解決**: `mask-image` に置換
```css
.marquee-container {
  overflow: hidden; /* レイアウト制御用に残す */
  -webkit-mask-image: linear-gradient(90deg, transparent 0%, #000 3%, #000 97%, transparent 100%);
  mask-image: linear-gradient(90deg, transparent 0%, #000 3%, #000 97%, transparent 100%);
}
```
BONUS: 端がフェードアウトする美しい見た目になる。

#### 原因 2: `translateX()` で GPU レイヤーが不安定
`translateX` は 2D トランスフォーム → ブラウザが GPU レイヤーを任意に破棄。

**解決**: `translate3d(x, 0, 0)` を使う
```css
@keyframes marqueeScroll {
  0%   { transform: translate3d(0, 0, 0); }
  100% { transform: translate3d(-XXXpx, 0, 0); }
}
```
esbuild も `translate3d → translateX` 変換で Safari が壊れるバグを修正済み（#2057）。

#### 原因 3: `backdrop-filter` の GPU レイヤーがスクロール時に破棄
iOS Safari 固有。画面外に出た要素の GPU レイヤーをメモリ節約のため積極破棄。

**解決**: モバイルでは `backdrop-filter` を削除、不透明背景で代替
```css
@media (max-width: 768px) {
  .glass-card {
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    background: rgba(27, 54, 93, 0.92);
    box-shadow: inset 0 1px 2px rgba(255,255,255,0.1), 0 8px 24px rgba(0,0,0,0.12);
  }
}
```

---

## マーキー実装チェックリスト

### 必須
- [ ] `overflow: hidden` + `mask-image` 併用（レイアウト + 視覚フェード）
- [ ] `translateX` ではなく `translate3d(x, 0, 0)`
- [ ] `-webkit-backface-visibility: hidden` をトラック要素に
- [ ] モバイルでは `backdrop-filter` なし
- [ ] scroll-driven animation (`fade-in` 等) をマーキーカードに付けない

### 推奨
- [ ] スクロール距離はピクセル正確値で計算（`-50%` ではなく `n * (cardWidth + gap)` px）
- [ ] `prefers-reduced-motion: reduce` 時は静的グリッドにフォールバック
- [ ] `window.resize` でスタイル再計算（デバウンス付き）

---

## CSS テンプレート（コピペ用）

```css
/* マーキーコンテナ */
.marquee-container {
  display: block;
  overflow: hidden;
  -webkit-mask-image: linear-gradient(90deg, transparent 0%, #000 3%, #000 97%, transparent 100%);
  mask-image: linear-gradient(90deg, transparent 0%, #000 3%, #000 97%, transparent 100%);
  cursor: grab;
}

/* マーキートラック */
.marquee-track {
  display: flex;
  gap: 20px;
  width: max-content;
  animation: marqueeScroll 40s linear infinite;
  -webkit-backface-visibility: hidden;
  backface-visibility: hidden;
}

/* カード — animation を無効化 */
.marquee-track .card {
  flex: 0 0 340px;
  opacity: 1 !important;
  animation: none !important;
}

/* キーフレーム */
@keyframes marqueeScroll {
  0%   { transform: translate3d(0, 0, 0); }
  100% { transform: translate3d(-XXXpx, 0, 0); } /* JS で正確値計算 */
}

/* モバイル — backdrop-filter 除去 */
@media (max-width: 768px) {
  .glass-card {
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    background: rgba(27, 54, 93, 0.92);
  }
}

/* アクセシビリティ */
@media (prefers-reduced-motion: reduce) {
  .marquee-track {
    animation: none !important;
    flex-wrap: wrap;
    width: auto !important;
    justify-content: center;
  }
  .marquee-track [aria-hidden="true"] { display: none !important; }
  .marquee-container { mask-image: none; }
}
```

---

## やってはいけないこと

| NG | 理由 |
|----|------|
| `overflow: hidden` + `backdrop-filter` の子要素 | backdrop-filter が死ぬ（CSS 仕様） |
| `translateX()` でマーキーアニメーション | iOS Safari が GPU レイヤー破棄 |
| `translateX(-50%)` でループ | gap 計算のズレで継ぎ目がカクつく |
| `will-change: transform` と `translate3d` 同時使用 | メモリ二重消費 |
| `passive: true` の touchmove で `preventDefault()` | 呼べない。横スワイプ時にページが動く |

---

## 参考リンク
- [Josh Comeau — backdrop-filter](https://www.joshwcomeau.com/css/backdrop-filter/)
- [Ryan Mulligan — The Infinite Marquee](https://ryanmulligan.dev/blog/css-marquee/)
- [Smashing Magazine — GPU Animation](https://www.smashingmagazine.com/2016/12/gpu-animation-doing-it-right/)
- [esbuild #2057 — translate3d Safari bug](https://github.com/evanw/esbuild/issues/2057)
