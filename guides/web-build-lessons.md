# Web 制作の致命的ミス集 & 解決パターン

実際のプロジェクトで何度も繰り返した致命的ミスと、二度と起こさないための解決パターン。

---

## CRITICAL: サイト全壊レベル

### 1. HTML ID を変更したら JS 参照も全て変更する

**何が起きる**: CTA セクションの ID を変更 → JS が `getElementById('旧ID')` のまま → null → TypeError → **以降の全 JS が死亡**

**解決**:
```bash
# ID 変更前に必ず実行
grep -n "旧ID名" index.html main.js style.css
# 全箇所を確認してから一括置換
```

### 2. 変数を削除する前に参照箇所を全チェック

**何が起きる**: `const hasHover = true` を削除 → 他の関数が参照 → ReferenceError → 全セクション消失

**解決**:
```bash
grep -n "変数名" index.html main.js
# 参照が 0 になるまで削除しない
```

### 3. 一括修正は絶対にしない（1 機能ずつ）

**何が起きる**: 5 機能を同時に修正 → 変数名衝突 → JS 構文エラー → 復元が必要

**解決**:
1. 1 機能だけ修正
2. `node -e "new Function(require('fs').readFileSync('main.js','utf8'))"` で構文チェック
3. ローカルで全セクション表示確認
4. 問題なければ次の機能へ

### 4. デプロイ前に必ずバックアップ

```bash
cp index.html index-safe-backup.html  # 修正開始前
# 修正 + 確認が通ったら:
cp index.html index-v2-backup.html    # バージョン管理
```

---

## HIGH: 機能が壊れるミス

### 5. IntersectionObserver のタイミング不一致

**何が起きる**: カウンターの IO が早く発火 → opacity: 0 の間にカウントアップ完了 → ユーザーには「動きがない」

**解決**: `transitionend` イベントで reveal 完了を待ってから開始:
```js
element.addEventListener('transitionend', (e) => {
  if (e.propertyName === 'opacity') setTimeout(startCount, 200);
});
```

### 6. Netlify Forms は手動デプロイで動かない

`netlify deploy --prod` ではビルドパイプラインが走らず、フォームが検出されない。

**代替**:
- **GAS**（Google Apps Script）でメール送信エンドポイント
- **Formsubmit.co**（signup 不要）
- **Formspree**（高機能）

### 7. inline style は CSS で上書きできない

`<p style="white-space:nowrap">` → メディアクエリで上書き不可。

**解決**: inline style にレスポンシブ関連のプロパティを入れない。CSS クラスで管理。

### 8. Canvas smoothing はタッチとマウスで分ける

```js
const smoothing = ('ontouchstart' in window) ? 0.18 : 0.04;
smoothedX += (mouseX - smoothedX) * smoothing;
```

マウス: 0.04（滑らか）、タッチ: 0.18（即応性）

### 9. Canvas width:120% は iOS で横スクロール発生

Canvas は `width: 100%` に収め、JS 側で座標を画面外まで計算する。

---

## MEDIUM: 見た目の問題

### 10. 複数の @media ブロックが同じプロパティを `!important` で競合

**解決**: 同じセレクタ + プロパティの `!important` は 1 箇所だけに統合。

### 11. LINE の OG キャッシュは即時更新できない

OG タグは最初から正しく設定する。変更後は新しいメッセージで URL を再送信。

---

## 修正チェックリスト

```
□ grep で変更対象の ID / 変数名の全参照箇所を確認したか
□ 削除する変数 / 関数の参照が 0 になることを確認したか
□ node -e で構文チェックしたか
□ ローカルで全セクション表示されるか確認したか
□ モバイル幅 (375px) で overflow / はみ出しがないか確認したか
□ バックアップ（index-safe-backup.html）を作ったか
□ 1 機能だけの変更か（複数機能を同時に入れてないか）
```
