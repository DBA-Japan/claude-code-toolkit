# タイポグラフィガイド（日本語 Web + テキストアニメーション）

日本語フォントの CSS 最適設定、混植、テキストアニメーション、装飾テキストの実装方法。

---

## 日本語フォント CSS 最適設定

| プロパティ | 推奨値 | 理由 |
|-----------|--------|------|
| `line-height` | 1.7em 以上 | CJK は情報密度が高い。英文 1.5 の +20% |
| `letter-spacing` | 0.05-0.15em | SP では縮小（改行崩れ防止） |
| `font-size` | 英文の約 10% 大きく | 日本語は視覚的に小さく見える |
| `font-style` | `italic` 禁止 | 日本語に斜体は存在しない → `font-weight` で代替 |

---

## フォントスタック

```css
/* 日本語（ゴシック） */
font-family: "Noto Sans JP", "Hiragino Kaku Gothic ProN", "Yu Gothic", "Meiryo", sans-serif;

/* 日本語（明朝） */
font-family: "Noto Serif JP", "Hiragino Mincho ProN", "Yu Mincho", serif;

/* 英語見出し用 */
font-family: "Geist", "SF Pro Display", -apple-system, sans-serif;
```

**WOFF2 + font-display: swap + preload**（フォントは 1-2 個まで）:
```html
<link rel="preload" href="font.woff2" as="font" type="font/woff2" crossorigin>
```

---

## 混植（日英）ルール

- 英数字は日本語の約 10% 小さく表示すると視覚的に揃う
- 行長: 日本語混植は **30 文字がベスト**（英文 50-75 文字より短い）
- セリフ日本語 + サンセリフ英数字は OK

---

## テキストアニメーション

| ライブラリ | サイズ | 用途 | CDN |
|-----------|--------|------|-----|
| **GSAP SplitText** | — | 文字/単語/行で分割。日本語 OK | `cdn.jsdelivr.net/npm/gsap@3/dist/SplitText.min.js` |
| **Splitting.js** | 1.5KB | CSS 変数自動生成。SplitText の軽量代替 | `unpkg.com/splitting/dist/splitting.min.js` |
| **Typed.js** | 5KB | タイピングエフェクト | `unpkg.com/typed.js@3.0.0/dist/typed.umd.js` |
| **CountUp.js** | 8KB | 数字カウントアップ | `cdn.jsdelivr.net/npm/countup.js@2.10.0/dist/countUp.umd.js` |
| **baffle.js** | 1.8KB | テキストスクランブル | `cdn.jsdelivr.net/npm/baffle@0.3.6/dist/baffle.min.js` |

### GSAP SplitText 例

```js
const split = SplitText.create('.title', { type: 'chars' });
gsap.from(split.chars, {
  opacity: 0, y: 50,
  stagger: 0.03,
  duration: 0.8,
  ease: 'power3.out'
});
```

---

## 装飾テキスト（背景ウォーターマーク）

### ::before 方式

```css
.section {
  position: relative;
}
.section::before {
  content: "PROCESS";
  position: absolute;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  font-size: clamp(5rem, 15vw, 12rem);
  font-weight: 900;
  color: rgba(0, 0, 0, 0.03);
  z-index: 0;
  pointer-events: none;
  white-space: nowrap;
}
```

---

## グラデーションテキスト

```css
.gradient-text {
  background: linear-gradient(90deg, #ff0080, #40e0d0);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
```

---

## テキストマスク（端フェード）

```css
.faded-text {
  -webkit-mask-image: linear-gradient(90deg, transparent 0%, black 20%, black 80%, transparent 100%);
  mask-image: linear-gradient(90deg, transparent 0%, black 20%, black 80%, transparent 100%);
}
```
