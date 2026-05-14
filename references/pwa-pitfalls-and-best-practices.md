---
name: PWA 制作の躓きポイント + ベストプラクティス
description: ふだん (fudan-app) で 17 Phase 通った経験を元に、他 PWA 案件で同じ事故を防ぐためのチェックリスト + 解決パターン集
type: reference
originSessionId: 45b44262-1937-4233-aa52-e050d398dd6d
---
# PWA 制作 躓きポイント & 最短化ガイド

> ふだん (家計簿×冷蔵庫×献立×食事ログ PWA / 30-45 歳専業主婦向け / Vanilla JS + Netlify Functions) で 27 個の P0/P1 を 17 Phase で潰した経験から抽出。  
> **新 PWA 案件着手時に先頭で必読**。

---

## 0. 最も致命的な事故 (Top 3)

### 0-1. **Netlify project link 事故** (運用致命)
**症状**: `netlify deploy --prod` で別プロジェクトに誤デプロイ → 既存サイト破壊
**原因**: `.netlify/state.json` が空・無 → グローバル設定 (`~/.netlify/...`) のリンクが使われる  
**再発防止**:
```bash
# 案件着手直後に必ず実行
echo '{"siteId": "<本物のsite-id>"}' > .netlify/state.json
git add .netlify/state.json && git commit -m "chore: pin netlify site link"
```
**デプロイ前チェック (毎回)**:
```bash
cat .netlify/state.json && netlify status | grep "Current project"
```
事故った時の復旧:
```bash
netlify api listSiteDeploys --data '{"site_id":"..."}' | head -50  # 過去 deploys 確認
netlify api restoreSiteDeploy --data '{"site_id":"...","deploy_id":"前の正しい id"}'
```

### 0-2. **SVG 巨大化バグ** (UI 致命)
**症状**: ダークモード時に SVG アイコンが画面の半分を占める / テキストが縦書きに圧迫
**原因**: 
- `base.css` の共通 reset `img, svg, video { max-width:100%; height:auto; }`
- SVG に `width=` `height=` HTML 属性がなく `viewBox` のみ → 親 flex 幅まで stretch
**再発防止**:
```css
/* SVG を共通 reset から外す */
img, video {
  display: block;
  max-width: 100%;
  height: auto;
}
svg {
  display: inline-block;
  vertical-align: middle;
}

/* SVG を flex 内に置く時は必ず物理サイズ固定 */
.icon {
  inline-size: 18px;
  block-size: 18px;
  flex: 0 0 18px;
  max-width: 18px;
}
```
**HTML 側にも直書き** (CSS 読込前 FOUC 対策):
```html
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true">
```

### 0-3. **連続モーダル click intercept**
**症状**: モーダル閉じた直後に次のモーダル開けない / Playwright が「pointer events intercepted」で止まる
**原因**: `.modal-backdrop` が `opacity: 0` に transition 中、`pointer-events: auto` のまま
**再発防止** (closeModal で即座 pointer-events 解除):
```js
function closeModal(modal) {
  modal.classList.remove('is-show');
  modal.style.pointerEvents = 'none'; // ★ transition と独立に即座 intercept 解除
  setTimeout(() => {
    modal.hidden = true;
    modal.style.pointerEvents = '';
  }, 240);
  document.body.style.overflow = '';
}
```

---

## 1. 認証 (Auth) ハマりどころ

### 1-1. **userId をメールから生成すると衝突する** (Codex F001)
**NG パターン**:
```js
// a.b@example.com と ab@example.com が同じ userId に !!!
function userIdFromEmail(email) {
  return 'u_' + email.toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 32);
}
```
**正解**:
```js
import { randomUUID } from 'node:crypto';
function newUserId() { return 'u_' + randomUUID().replace(/-/g, ''); }

// メール検索は email-index 経由
async function findUserIdByEmail(email) {
  const idx = getStore({ name: 'users-by-email', consistency: 'strong' });
  const key = await sha256Hex(email.toLowerCase());
  return await idx.get(key);
}

// signup 時に index 登録
await idx.set(key, userId);
```
**移行戦略**: 既存ユーザーは migrate せず legacy fallback を残す (Codex Phase 1 推奨)
```js
const userId = (await findUserIdByEmail(email)) || userIdFromEmail(email);
```

### 1-2. **dev_mode auto-login の穴**
**NG**: `RESEND_API_KEY` 未設定の dev_mode で `verify_url` を JSON で返却 → クライアントが auto navigate → セキュリティ穴
**正解**:
```js
const isLocalDev = process.env.NETLIFY_DEV === 'true' && process.env.CONTEXT !== 'production';
if (!resendKey) {
  if (isLocalDev) {
    return Response.json({ ok: true, dev_mode: true, verify_url });
  }
  return Response.json({ error: 'mail_not_configured' }, { status: 503 });
}
```
クライアント側も auto-navigate を必ず無効化:
```js
if (data?.dev_mode && data?.verify_url) {
  // auto-navigate 廃止 → 手動コピーリンク表示のみ
  showLinkManually(data.verify_url);
}
```

### 1-3. **scrypt timing 攻撃**
**NG**: ユーザー不在時に scryptVerify を呼ばない → 応答時間差でメール存在推測可能
**正解**: ダミー hash (正しい 6 parts 形式) で必ず scrypt を実行
```js
const DUMMY_HASH = 'scrypt$16384$8$1$' + '00'.repeat(16) + '$' + '11'.repeat(64);
const expectedHash = user?.passwordHash || DUMMY_HASH;
const valid = (await scryptVerify(password, expectedHash)) && Boolean(user?.passwordHash);
```

### 1-4. **sessionVersion 検証 fail-open**
**NG**: Blob 読み失敗時に JWT を通す → 高負荷時に失効済みトークン復活
**正解**: `payload.v` 付き JWT は Blob 失敗で **fail-closed**

---

## 2. AI API 呼び出し (Gemini / Anthropic)

### 2-1. **Gemini 2.5 Flash の thinking モード**
**NG**: `thinkingConfig` 指定なし → 思考トークンで体感速度 2-3 倍遅延
**正解**: 構造化抽出タスクは `thinkingBudget: 0` で切る
```js
generationConfig: {
  responseMimeType: 'application/json',
  responseSchema: {...},
  thinkingConfig: { thinkingBudget: 0 },  // ★
}
```

### 2-2. **画像 base64 サイズ無制限 → DoS**
**NG**: image を req.json() でそのまま受けて Gemini に渡す → 巨大 payload で関数メモリ + Gemini コスト爆発
**正解**: `_lib/payload.js` に `assertImagePayload()` 共通 helper
```js
const MAX_IMAGE_BASE64_LEN = 2.5 * 1024 * 1024;
if (image.length > MAX_IMAGE_BASE64_LEN) return { error:'image_too_large', status:413 };
```

### 2-3. **AI 商品名捏造 (ハルシネーション)**
**NG**: バーコード番号を Gemini に渡して「商品名を推測」させる → 全然違う商品が出る (ポイフル → 赤きつねうどん)
**正解**: identity (商品同定) と nutrition (栄養) を分離
- 商品同定: 公式 API (Yahoo!ショッピング JAN / 楽天 productCode / Open Food Facts)
- 栄養: Open Food Facts のみ
- AI に「JAN → 商品名」を絶対やらせない
- 不確かなら `not_found` (間違えるより空振り)

### 2-4. **Anthropic vs Gemini 価格 (2026-04 時点)**
- Claude Sonnet 4: input $3/MTok, output $15/MTok
- Gemini 2.5 Flash: input $0.30/MTok, output $2.50/MTok
- → **DB ベース選択モード (候補から 3 件選ぶ)** なら Gemini で十分。Claude は過剰
- 切替時の API 互換性: `system + user` メッセージは両者ほぼ同じ。response_format 指定は別

### 2-5. **API 失敗時の DB fallback 必須**
**正解の優先順位**: 主 AI → 副 AI → DB ランダム選択
```js
try { text = await callGemini({...}); }
catch { try { text = await callAnthropic({...}); }
catch { try { text = await callPerplexity({...}); }
catch { return dbFallbackResponse(); }}}
```
ユーザーは「エラー画面」より「とりあえず 3 案出た」体験を求める。

---

## 3. デザイン (UI/UX)

### 3-1. **「ファンシー化」で振りすぎてはいけない方向**
ターゲット 30-45 歳専業主婦の感想:
- 控えめテラコッタ装飾 + 18px section-icon → **「変わってない」**
- 大型料理写真 + テラコッタ overlay → **「これだ」**
**結論**: 文章主体ヒーロー → 情景主体ヒーローに振り切る。Apple/iOS 17 風の controlled 静謐感より、雑誌表紙のような **ビジュアル直球**

### 3-2. **AI Antidote 厳守**
- 純白 #FFFFFF / 純黒 #000000 → NG (#F4EFE6 / #2A2520 等の暖色寄り使う)
- 青系 → フード系業界 NG (食欲減退)
- ChatGPT 緑 #10A37F → NG
- 紫青グラデ → NG
- 絵文字 → NG (絵本調 SVG で代替)
- 3 列均等カード Bento → 雑誌的非対称序列に
- 中央揃え hero → 左寄せが鉄則

### 3-3. **強弱フォント 3 階層必須**
全部同じ size = AI っぽい。1 ブロック内に 3 階層以上の差を:
- 数字・固有名詞・実績値 → 巨大 + bold (terracotta 主役化)
- キーワード → 中サイズ + カラー強調
- 補助テキスト → 小サイズ + 薄グレー

### 3-4. **モーダル spring 物理**
```css
.modal {
  transform: translateY(28px) scale(0.98);
  transition: transform 320ms cubic-bezier(0.34, 1.56, 0.64, 1);
}
.modal-backdrop.is-show .modal { transform: translateY(0) scale(1); }
```
オーバーシュート系で「ふんわり立ち上がる手触り」。Reduced motion では transition: 1ms に。

### 3-5. **写真は幽霊化処理**
```css
.hero-bg {
  background-image: url("/images/hero/breakfast.jpg");
  filter: saturate(0.92) brightness(0.78);
}
/* 上に色 overlay (テラコッタ → 深い茶) */
::after {
  background: linear-gradient(180deg,
    rgba(154, 86, 52, 0.40) 0%,
    rgba(74, 50, 38, 0.65) 60%,
    rgba(42, 37, 32, 0.82) 100%);
}
```
テキストは `text-shadow: 0 1px 12px rgba(0,0,0,0.35)` で可読性確保。

### 3-6. **時間帯連動が効く**
`getHours()` で 5 区分:
- 5-11 朝: おはよう / 朝食写真
- 11-16 昼: こんにちは / 昼食写真
- 16-20 夕: お疲れさま / 夕食写真
- 20-24 夜: こんばんは
- 0-5 深夜: おやすみ前

専業主婦向けは「朝起きて開いたら朝の挨拶」が刺さる。

---

## 4. データ永続化

### 4-1. **localStorage QuotaExceeded ハンドリング**
**NG**: setItem を裸で呼ぶ → quota 超過で UI 巻き込み停止
**正解**: 共通 `safeSetItem` + CustomEvent で UI 通知
```js
function safeSetItem(key, value) {
  try { localStorage.setItem(key, value); return true; }
  catch (err) {
    window.dispatchEvent(new CustomEvent('storage-failed', { detail: { key, quota: err.name === 'QuotaExceededError' }}));
    return false;
  }
}
```

### 4-2. **Netlify Blobs の eventual consistency 罠**
- `consistency: 'eventual'` で list-after-write が反映されない時間がある
- 大事なデータ (users / 削除確認) は **strong** で
- list() は単一ページ前提 NG → paginate

### 4-3. **last-write-wins の落とし穴**
複数端末同時更新で古いデータが新しいのを潰す。最低限 `updatedAt` 比較:
```js
if (incomingUpdatedAt < serverUpdatedAt) return Response.json({ error: 'stale_snapshot' }, { status: 409 });
```

### 4-4. **クラウド同期の fire-and-forget 禁止**
**NG**: `fetch().catch(()=>{})` で失敗を握りつぶす
**正解**: `cloudSync()` helper で失敗時にトースト
```js
export function cloudSync(promise, label) {
  return promise.then(r => {
    if (!r.ok) showToast('端末内には保存しました（クラウド同期は後でリトライ）', { tone: 'alert' });
    return r.ok;
  });
}
```

---

## 5. PWA / Service Worker

### 5-1. **SW cache invalidation**
- リリース時 `CACHE_NAME` を必ず bump (`v6` → `v7-2026-04-26-phase-x`)
- ユーザー通知: 「アプリを削除して再追加」が確実
- 大きいデータ (recipes.json 等) は precache から外して dynamic import

### 5-2. **lazy import で初期 JS 削減**
```js
// 検索 lane に切り替えた瞬間にロード
let RECIPES = null;
async function ensureRecipes() {
  if (RECIPES) return RECIPES;
  const m = await import('/data/recipes.js');
  RECIPES = m.RECIPES;
  return RECIPES;
}
```

### 5-3. **iOS Safari の地雷**
- `<input type="date">` は OS picker → ユーザーには「カレンダーが見えない」と映る → カスタム ボトムシート picker を併設
- `overflow-x: hidden` は iOS で sticky を壊す → `overflow-x: clip` 必須
- `100vh` ≠ `100dvh` (iOS Safari の URL バー考慮) → `100dvh` を使う

### 5-4. **モーダル画面のフルスクリーン化**
```css
.modal.modal-fullscreen {
  width: 100%; max-width: 100%;
  height: 100dvh; max-height: 100dvh;
  border-radius: 0; padding: 0;
  display: flex; flex-direction: column;
}
.modal-backdrop:has(> .modal.modal-fullscreen) {
  align-items: stretch;
}
```
バーコードスキャナのような「ボタン押下で即フル画面」UI には必須。

---

## 6. テスト戦略 (Playwright + 並列 Agent)

### 6-1. **5 並列 Agent E2E が最強コスパ**
- 1 Agent あたり 1 機能領域 (認証 / 家計簿 / 冷蔵庫 / 献立 / 食事 + 設定)
- 各 Agent は独自テストアカウント (`curl signup`) で完全分離
- 共通テスト基盤: `/tmp/fudan-pw/` に Playwright + chromium キャッシュ
- 結果: `/tmp/fudan-e2e-{a1..a5}.json` に出力

### 6-2. **本番テストは要注意**
本番に書込みテスト = 実ユーザーデータ汚染リスク。テストアカウントは必ず `e2e-...@example.test` 等。

### 6-3. **scope-based agent 分担 (20 並列の例)**
- 1-5: API 仕様調査・UI 設計
- 6-10: 既存コード読込・依存洗い出し
- 11-15: 候補実装試験
- 16-20: 検証・QA・Release docs
- 書き込み owner は 4 人に絞る (merge conflict 防止)

---

## 7. デプロイ運用

### 7-1. **commit 戦略**
1 機能 = 1 commit。一気にやらず順次 deploy。本番影響大なら 2 commit (UI と API 分離)。

### 7-2. **Netlify CLI コマンド集**
```bash
netlify status                                  # link 確認
netlify env:list --context production           # 本番 env
netlify env:set KEY "value"                     # env 設定
netlify deploy --prod --dir=public --functions=netlify/functions
netlify api listSiteDeploys --data '{"site_id":"..."}'  # 履歴
netlify api restoreSiteDeploy --data '{"site_id":"...","deploy_id":"..."}'  # rollback
netlify functions:logs                          # function 実行ログ
```

### 7-3. **デプロイ前 5 点チェック**
1. `cat .netlify/state.json` で正しい siteId
2. `netlify status | grep "Current project"` で正しいプロジェクト名
3. `bash RULES/check.sh` で AI Antidote 全タグクリア
4. Playwright スモーク (5 ページ Console error 0)
5. git diff の規模確認 (大規模なら 2 commit に分割)

---

## 8. Codex セカンドオピニオン活用法

### 8-1. **発火条件**
- 「これでいけるか?」と迷う設計判断
- 自分の修正が「過剰 / 不足 / 別の見方」が欲しい時
- 大規模リファクタ前
- 課金開始前のセキュリティレビュー

### 8-2. **プロンプトの書き方**
- 文脈を 3-5 行で凝縮 (アプリ概要 / 既知問題 / 制約)
- 質問は番号付きで具体的に (3-5 個)
- 「忖度なし・点数で評価」を明示
- 「実装は私側でやるので提案だけ」 (Codex に書かせない)
- 出力フォーマット指定 (JSON / 箇条書き) で集約効率 ↑

### 8-3. **コスト管理**
- 1 セッションで 3-4 回が上限目安 (利用上限注意)
- BG 並列 (`run_in_background: true`) で待ち時間ゼロ
- 結果は `/tmp/codex-*.txt` に出力させる (パース容易)

---

## 9. 案件着手チェックリスト (新 PWA)

```
□ .netlify/state.json に siteId 明示
□ 暖色軸 + ダークモード CSS トークン定義
□ AI Antidote ルール RULES/check.sh 配置
□ svg を共通 reset から外す (img, video のみ)
□ モーダル spring 物理 + closeModal で pointerEvents 即解除
□ safeSetItem (localStorage QuotaExceeded 対応)
□ cloudSync helper (fire-and-forget 禁止)
□ Auth: UUID 発番 + email-index (userId 衝突防止)
□ AI 呼出: thinkingBudget:0 + responseSchema + 画像 size 上限
□ AI fallback: DB / Gemini / Anthropic 多層
□ SW cache_name は date 入れる (v8-2026-04-27 等)
□ lazy import (大容量データは初期から外す)
□ iOS Safari 対応: 100dvh / overflow-x:clip / カレンダー併設
□ Playwright 5 並列 E2E スモーク
□ デプロイ前 5 点チェック
```

---

## 10. 「躓きから最短化」の哲学

ふだんで 27 件の P0/P1 を潰した経験から:

1. **同じ事故は 2 度起きる** → memory に書く + 案件着手時に必ず読む
2. **ユーザーフィードバックで方向 180 度変えるのは正常** (控えめ装飾 → 写真主役は 2 ターン目で受容)
3. **Codex の点数は素直に受ける** (6.5/5.5/5 から 7.5/7.5/7.5 まで上げた)
4. **エンジニアの判断より ユーザーの "言葉" を信じる** (「派手じゃない」=派手にする)
5. **デプロイは小さく頻繁に** (1 commit = 1 機能)
6. **環境変数は最初から ` netlify env:list --context production` で確認**
7. **巨大化 / 縦書き / 黒塗り = SVG 共通 reset の罠** を常に疑う

---

## 関連 memory
- `fudan-app.md` — 案件本体・Phase 履歴
- `pwa-netlify-recipe.md` — PWA + Netlify セットアップ全般
- `cc-agent-parallel-bulk-generation.md` — 並列 Agent でデータ大量生成
- `ai-antidote.md` — AI っぽさ解毒原則 (Web 制作全般)
- `web-weapons-ranking.md` — 武器ランキング (継続更新)
