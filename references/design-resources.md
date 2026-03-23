---
name: X(Twitter)デザインリソース
description: フォローすべきWebデザイナー/開発者アカウントとCSS Tipsのコード集。最新トレンドのキャッチアップに
type: reference
---

# X(Twitter) Webデザインリソース（2026-03 調査）

## 最重要アカウント（CSS/アニメーション）
- @jh3yy (jhey): CSS Tips最重要。scroll-driven, offset-path, @property
- @ChallengesCss (T. Afif): Pure CSSチャレンジ、3Dカード
- @argyleink (Adam Argyle): Chrome DevRel、CSS新機能
- @anatudor (Ana Tudor): CSS数学的アート、グラデーション最適化

## インスピレーション
- @codrops: チュートリアル、スクロールアニメ
- @greensock: GSAPショーケース
- @awwwards: 毎日のSite of the Day
- @smashingmag: 深い技術記事
- @css: CSS-Tricks

## Bento Grid / レイアウト
- @bentogrids: Bento Grid専門キュレーション
- @ridd_design: UIデザインインスピレーション

## ノーコード/フレームワーク
- @framer: ノーコードWebビルダー
- @webflow: ノーコードWeb
- @byfranbeltra (Franco): Glass Card、3Dスライダー

---

## jheyのCSS Tipsコード集

### 光るボーダー（offset-path）
```css
.glow::after {
  offset-path: rect(0 100% 100% 0 round var(--radius));
  animation: loop 3s linear infinite;
}
```

### グラデーションボーダー回転（@property）
```css
@property --angle { syntax: '<angle>'; inherits: true; initial-value: 0deg; }
.card { border-image: conic-gradient(from var(--angle), #ff0080, #00d4aa, #ff0080) 1; animation: spin 4s linear infinite; }
@keyframes spin { to { --angle: 360deg; } }
```

### スクロール駆動グローカード
```css
section { animation: vibe; animation-timeline: --list; }
@keyframes vibe { to { --hue: 320; } }
```

### 意図的ホバー（transition-delay）
```css
a:hover::after { scale: 1 1; transform-origin: 0 50%; transition-delay: 0.15s; }
a::after { mix-blend-mode: difference; scale: 0 1; transform-origin: 100% 50%; transition: scale 0.2s; }
```

---

## 無料デザインリソース集

| リソース | URL | 何ができるか |
|---------|-----|-------------|
| **Grainient** | grainient.supply | 1000+ AI生成グラデーション/ガラス背景画像。ダークセクション背景に最適。Moon/Phantom/Nova等の3Dガラス風 |
| **Curated Design** | craftwork.design/curated/websites/ | デザインインスピレーション+UI素材。参考ギャラリー。有料素材中心 |
| **Fontshare** | fontshare.com | 無料高品質フォント（英語のみ）。英語見出し用 |
| **remove.bg** | remove.bg | 画像背景除去AI。チーム写真の切り抜きに |
| **Kling AI** | klingai.com | 動画生成AI。LP背景動画に |
| **Midjourney** | midjourney.com | 画像生成AI |
| **Bento Grids** | bentogrids.com | Bento Gridインスピレーション集。Apple/Vercel/Linear等の実例参照 |
| **Figmify** | figmify.ai | 画像→Figma変換 |

---

## 参考CodePen

- ポケモンカードホロ: codepen.io/simeydotme/pen/PrQKgo
- 3Dカード(CSS-only): codepen.io/t_afif/pen/mdzxJaa
- ガラスカード3D: codepen.io/Wyper/pen/BapJJwm
- ホロフォイル: github.com/simeydotme/pokemon-cards-css
