# Canvas 2D 最適化ガイド

Canvas を使ったアニメーション背景・エフェクトの軽量化と、よくある落とし穴の回避策。

---

## 軽量化の鉄則: 描画コードを変えるな

Canvas のパフォーマンス改善で最もよくある失敗は、描画ロジックを書き換えて見た目が変わること。
**描画コードは1行も変えず**、以下の3つだけで大抵十分:

1. **DPR を下げる** — `window.devicePixelRatio` を 2→1.5 にするだけでピクセル数 44% 削減。見た目の変化はほぼゼロ
2. **IntersectionObserver で画面外停止** — 見えていない Canvas の rAF を止める。GPU 負荷 75% 削減
3. **DOM 検索キャッシュ** — `getElementById` を毎フレーム呼ばず、変数に保持

```js
// DPR キャップ（1.5x で十分。2x は過剰）
const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
canvas.width = canvas.clientWidth * dpr;
canvas.height = canvas.clientHeight * dpr;
ctx.scale(dpr, dpr);

// 画面外停止
const observer = new IntersectionObserver(([entry]) => {
  if (entry.isIntersecting) startAnimation();
  else stopAnimation();
});
observer.observe(canvas);
```

---

## Canvas が表示されない時の 4 原因

### 1. z-index がコンテンツの下
Canvas z-index:2、コンテンツ z-index:3 → 1px も見えない

**ルール**: `canvas { z-index: 10; pointer-events: none; }`

### 2. CSS `display: none` が効いている
メディアクエリやモバイル対応で `display: none` が残っている

### 3. `matchMedia('(hover:hover)')` で弾かれている
PC でもタッチスクリーン付きモニタだと弾かれることがある

**ルール**: matchMedia で弾かず、`mousemove` イベントが来た時だけ描画

### 4. Canvas の width/height が CSS と JS で二重設定
CSS で `width: 100%` を設定しつつ、JS でも `canvas.width = ...` → 競合

**ルール**: サイズは JS のみで管理。CSS では `position: absolute; inset: 0;` だけ

### デバッグ手順
1. **テストファイルを先に作る**（本番統合前に単体 HTML で確認）
2. DevTools > Computed > z-index 確認
3. `console.log(canvas.width, canvas.height)` で 0x0 チェック
4. viewport 幅が条件を満たしているか確認

---

## iOS Safari スクロールトラップ

### 根本原因
CSS 仕様で `overflow-x: hidden` + `overflow-y: visible` → visible が auto に変換 → スクロールコンテナが暗黙生成 → iOS Safari がタッチイベントを食う

### 解決: `overflow-x: clip` を使う

`clip` はスクロールコンテナを作らないため安全。

### Canvas × モバイルの必須ルール

| ルール | 理由 |
|--------|------|
| `overflow-x: hidden` → `overflow-x: clip` | スクロール乗っ取り防止 |
| canvas に `pointer-events: none` | タッチ操作を邪魔しない |
| touch リスナーはセクションにスコープ | window グローバル禁止 |
| canvas を親の外にはみ出させない | 負の top/left 禁止 |
| `touch-action: manipulation` をセクションに設定 | ダブルタップズーム防止 |
| canvas は `width: 100%` に収める | iOS で横スクロール発生防止 |

---

## パフォーマンス数値目標

| 指標 | 目標 |
|------|------|
| FPS | 60fps（最低 30fps） |
| Canvas DPR | 1.5x キャップ |
| 同時アニメーション Canvas | 2 個まで |
| rAF コールバック内の処理 | 16ms 以内 |

---

## リボン / 曲線描画の滑らかさ

| 層 | 問題 | 解決 |
|----|------|------|
| 解像度 | DPR 1x だと Retina でギザギザ | DPR 1.5x キャップ |
| 曲線補間 | `lineTo()` は直線 → 角が見える | Catmull-Rom → `bezierCurveTo` |
| 波形 | 高周波 sin 波の干渉で折れ目 | sin 波は 2 つまで |
