# 超一流サイト分析

Awwwards 受賞サイト、Stripe / Linear / Vercel / Notion、日本企業 TOP10 の共通テクニック。「AI っぽくない」理由の解明。

---

## 超一流サイトの 5 つの金則

1. **背景エフェクトは「理由」付きで使う** — 装飾ではなくメッセージ
2. **コントラストを極度に高める** — 中間色排除
3. **「隠す」ことで「見せる」** — ホバー/スクロールで発見
4. **モーションに「意図」を込める** — 「なぜ動く？」に答えられる
5. **カラーパレットは「制限」する** — 3 色以内

---

## 「AI っぽくない」理由の正体

- AI は全要素を「平等に重要」と扱う → **一流は厳しく選別**
- AI は「パッと見で全情報を伝える」→ **一流は「発見の喜び」を与える**
- AI はエフェクトに「理由」がない → **一流は企業メッセージと一体**

---

## グローバル TOP 4

### Stripe
- WebGL miniGL (10KB) でメッシュグラデーション。GPU 計算の可視化 = 技術力の証明
- 余白戦略: 情報が少なく見えるほど信頼度 UP
- ナビに 3D perspective (`rotateX`)

### Linear
- 伝統的グリッドを捨てた「モジュール方式」。各カードが独立した情報形式
- ホバーで高品質画像が瞬時出現（隠して発見させる）
- Lenis カスタムで「意図的に遅い」スクロール = 時間を尊重
- 色を極度に制限（グレースケール主体）

### Vercel
- 黒と白だけ（中間色排除 = 曖昧さなし）
- 自社フォント Geist Sans / Mono
- `overscroll-behavior: contain` / `color-scheme: dark`

### Notion
- 「ユーザーが求めたときだけ出現」の哲学
- 新規ユーザーにだけツールチップ、熟練者には非表示
- 色に頼らない = 形状とレイアウトで情報表現

---

## 日本企業 TOP10（2026 年調査）

| # | 企業 | URL | 特徴 |
|---|------|-----|------|
| 1 | **LayerX** | layerx.co.jp | クリーン+モーション。動きはあるがごちゃごちゃしない |
| 2 | **SmartHR** | smarthr.co.jp | 写真の形バリエーション（丸・楕円・正方形混在） |
| 3 | **SpiralAI** | go-spiral.ai | アニメーションシンボル+ドットテクスチャ背景 |
| 4 | **PLAID** | plaid.co.jp | 背景二重構造。スクロールで裏が「覗き込む」 |
| 5 | **MIMARU** | mimaruhotels.com | CSS Design Awards 4 部門。Travel Style Finder |
| 6 | **Oro DX** | dx.oro.com | Arrow「→」モチーフ全体展開 |
| 7 | **SHINK** | shink-jp.com | Awwwards HM。ホワイトスペースの高級感 |
| 8 | **Bravis** | bravis.com | マルチカラム。グローバル展開 |
| 9 | **Garden-Eight** | garden-eight.com | Awwwards SOTM/SOTD 多数。ミニマル×イラスト |
| 10 | **Denso** | denso.com | 段階的情報開示。1 年かけたブランディング |

---

## Awwwards Site of the Year 2025: Igloo Inc
- UI 全体が WebGL で描画（HTML DOM ではない）
- カスタム氷結晶アルゴリズム
- シェーダー活用テキストグリッチ

---

## パターン抽出（再現可能）

| パターン | 参考サイト | 再現方法 |
|---------|-----------|---------|
| クリーン+モーション | LayerX | GSAP `once: true` + Lenis |
| 写真形バラバラ | SmartHR | `clip-path` で各写真に異なる形 |
| テクスチャ+シンボル | SpiralAI | `radial-gradient` ドット + SVG MotionPath |
| 背景覗き込み | PLAID | `clip-path` 前景 + `position: fixed` 背景 |
| ズームスライド | CyberAgent | GSAP timeline (scale + x) |
| 余白+背景薄文字 | Wantedly | CSS Grid + `::before` 巨大テキスト |
| ドット色変化 | 10X | CSS 変数 + `@property` + IntersectionObserver |
