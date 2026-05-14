---
name: Canvas制作 教訓集（軽量化・落とし穴・iOS・リボン描画）
description: Canvas 2D制作の全教訓。軽量化の鉄則(描画変えずインフラ最適化)、表示されない4原因(z-index/display:none/matchMedia/サイズ)、iOSスクロールトラップ(overflow-x:clip)、リボン描画(DPR 1.5x+Catmull-Rom+低周波2波)
type: feedback
---

# Canvas制作 教訓集

## 1. 軽量化の鉄則: 描画コードを変えるな

**失敗**: 二重キャンバスに書き換えたら見た目が完全に変わった
**成功**: 描画コード1行も変えず、以下だけ変更:
- DPR 2→1（ピクセル数75%削減、見た目変化ゼロ）
- IntersectionObserver（画面外停止、GPU75%節約）
- DOM検索キャッシュ（getElementByIdを60回/秒→0に）
- scrollハンドラ rAFゲート

**ルール**: Canvas軽量化を頼まれたら「描画コードは変えません」と宣言してから最適化。DPR下げ+IntersectionObserver+キャッシュの3つで大抵十分。

## 2. Canvas表示されない時の4原因

### z-indexがコンテンツの下（最大の罠）
Canvas z-index:2、コンテンツ z-index:3 → 1pxも見えない
**ルール**: Canvas = z-index:10 + pointer-events:none

### モバイルCSS display:none がデスクトップでも効く
開発中は `display:none` を入れない

### matchMedia('(hover:hover)') が弾く
**ルール**: matchMediaで弾かず、mousemoveが来た時だけ描画

### Canvas width/height がCSSとJSで二重設定
**ルール**: サイズはJSのみ。CSSでは position:absolute;top:0;left:0 だけ

### デバッグ手順
1. **テストファイルを先に作る**（本番統合前に単体HTML確認）
2. DevTools > Computed > z-index確認
3. viewport幅が768px以上か確認
4. console.log(cv.width, cv.height) で0x0チェック

## 3. iOSスクロールトラップ

**根本原因**: CSS仕様で `overflow-x:hidden` + `overflow-y:visible` → visibleが自動的にautoに変換 → スクロールコンテナが暗黙生成 → iOS Safariがタッチイベントを食う

**解決**: `overflow-x: clip` を使う（clipはスクロールコンテナを作らない）

### 全Web制作で必ず適用するルール
1. `overflow-x: hidden` → `overflow-x: clip` に置き換え
2. canvas要素に `pointer-events: none`
3. touchリスナーはセクションにスコープ（windowグローバル禁止）
4. モバイルでcanvasを親の外に飛び出させない（負のtop/bottom禁止）
5. `touch-action: manipulation` をcanvas含むセクションに設定
6. touchstart+clickの両方でShockwave発火させない

## 4. リボン/Canvas描画の好み: 液体の滑らかさ

### 3層の滑らかさ
| 層 | 問題 | 解決 |
|----|------|------|
| 解像度 | DPR 1xだとRetinaでギザギザ | **DPR 1.5xキャップ** |
| 曲線補間 | lineTo()は直線→角が見える | **Catmull-Rom → bezierCurveTo** |
| 波形 | 高周波sin波の干渉で折れ目 | **2波まで**、freq*0.7以下 |

### 絶対NG
- lineTo()だけでリボンのエッジを描画
- 3つ以上のsin波の重ね合わせ
- DPR 1xのCanvas
- 高周波成分（freq * 1.4以上）
- smoothing 0.03以上のタッチ追従

### ダーク背景のビジュアル = リボンX交差
- 2束のリボンが対角に交差するデザインが最高評価
- 粒子・ブロブ・Vanta・DNA螺旋は全却下
- Apple壁紙のシルクリボンが参考

### 炎トレイル
- radialGradientの球体はNG（ボールになる）
- リボン形状が正解（パスに沿って法線ベクトル+テーパーポリゴン）
- 透明度: 外層0.07、中間0.12、コア0.18
- 持続時間: 1800ms
