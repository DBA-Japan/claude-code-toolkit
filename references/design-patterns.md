---
name: 実証済みデザインパターン集
description: 日本IT企業20社レビューで確認した8つの再現可能なデザインパターン。各パターンにコード例付き
type: reference
---

# 実証済みデザインパターン（日本IT企業20社レビューで確認）

以下は実在する超一流サイトから抽出したパターン。各パターンに再現方法を明記。

---

## Pattern 1: クリーン+モーション（LayerX型）
**見た目**: 動きはあるがごちゃごちゃしない。情報密度が低くクリーン

**再現**: GSAP ScrollTrigger（`toggleActions: "play none none none"`, `once: true`）+ Lenis。1セクション1アニメーション。3箇所以上同時に動かさない

**参考**: layerx.co.jp

---

## Pattern 2: 写真の形バリエーション（SmartHR型）
**見た目**: 人物写真が丸・楕円・正方形・長方形とバラバラの形で横に流れる

**再現**: CSS `clip-path` で各写真に異なる形を適用 + GSAP横スクロール or CSS marquee

```css
.photo-circle  { clip-path: circle(50%); }
.photo-ellipse { clip-path: ellipse(40% 50%); }
.photo-square  { clip-path: inset(0); border-radius: 0; }
.photo-rect    { clip-path: inset(5% 0); }
.photo-rounded { clip-path: inset(0 round 24px); }
```

**参考**: smarthr.co.jp

---

## Pattern 3: 背景二重構造/覗き込み（PLAID型）
**見た目**: ヒーローの背景が二重レイヤー。スクロールで裏の画像が「覗き込む」ように見える

**再現**: 前景に `clip-path` or `mask-image` 付きのレイヤー、背景に別画像。スクロールで前景をずらす（GSAP ScrollTrigger `scrub: true`）

```css
.foreground { position: relative; z-index: 2; }
.background { position: fixed; z-index: 1; /* 背景固定でパララックス効果 */ }
.peek-window { clip-path: circle(30% at 70% 50%); /* 覗き窓 */ }
```

**参考**: plaid.co.jp

---

## Pattern 4: カーソルフォロワー（Goodpatch型）
**見た目**: マウスに円のイメージがついてくる

**再現**: mouse-follower (Cuberto) — CDN + 初期化3行。PC専用（`@media (hover: hover)`）

**参考**: goodpatch.com

---

## Pattern 5: ズームイン/アウト写真スライド（CyberAgent型）
**見た目**: 写真がズームアウト→右から左にスライド→新写真が小さく登場→ズームイン

**再現**: GSAP timeline

```js
const tl = gsap.timeline({ repeat: -1 });
tl.to('.photo-current', { scale: 0.8, duration: 0.6, ease: 'power2.inOut' })
  .to('.photo-current', { x: '-100%', duration: 0.8, ease: 'power2.inOut' }, '-=0.2')
  .fromTo('.photo-next', { scale: 0.6, x: '100%' }, { scale: 1, x: '0%', duration: 1, ease: 'power2.out' }, '-=0.4');
```

**参考**: cyberagent.co.jp

---

## Pattern 6: 余白+画像配置+背景薄文字（Wantedly型）
**見た目**: 画像の周囲に余白があって「置いている」感じ。背景にうっすらテキスト

**再現**: CSS Grid で画像に余白確保 + `::before` で巨大な薄いテキストを背景に

```css
.section-bg-text::before {
  content: 'APPROACH'; /* 装飾テキスト */
  position: absolute;
  font-size: clamp(5rem, 15vw, 12rem);
  font-weight: 900;
  color: rgba(0,0,0,0.03); /* ほぼ見えない */
  z-index: 0;
}
```

**参考**: wantedlyinc.com

---

## Pattern 7: アニメーションシンボル+テクスチャ背景（SpiralAI型）
**見た目**: 小さなシンボル（ハート）がアニメで動く。背景にドットテクスチャ。一部グレーウォール。背景が常に微動

**再現**:
- シンボル: SVG + GSAP MotionPath（スクロールでロゴまで移動→消える）
- ドットテクスチャ: `radial-gradient(circle, rgba(0,0,0,0.08) 1px, transparent 1px); background-size: 16px 16px;`
- グレーウォール: セクション背景色の切り替え（Intersection Observer + CSS transition）
- 微動する背景: CSS `@keyframes` で `background-position` を微妙にずらし続ける

**参考**: go-spiral.ai

---

## Pattern 8: ドット背景+スクロール色変化（10X型）
**見た目**: グレーのつぶつぶ背景。下にスクロールすると緑のつぶつぶに変わる

**再現**: ドットは `radial-gradient` で生成。色変化は CSS変数 + Intersection Observer

```css
:root { --dot-color: rgba(0,0,0,0.08); }
.section-green { --dot-color: rgba(46,125,50,0.12); }
.dot-bg {
  background-image: radial-gradient(circle, var(--dot-color) 1px, transparent 1px);
  background-size: 20px 20px;
  transition: --dot-color 0.6s ease; /* @property必要 */
}
```

**参考**: 10x.co.jp

---

## パターン選定のコンビネーション例

| 会社タイプ | 推奨パターン組み合わせ |
|-----------|----------------------|
| AI/コンサル（信頼重視） | Pattern 1 + Pattern 7 + Pattern 8 |
| スタートアップ（攻め） | Pattern 4 + Pattern 5 + Pattern 7 |
| 旅行/観光（写真主役） | Pattern 3 + Pattern 5 |
| HR/人材（人物中心） | Pattern 2 + Pattern 6 |
| クリエイティブ | Pattern 3 + Pattern 4 + 自由組み合わせ |
