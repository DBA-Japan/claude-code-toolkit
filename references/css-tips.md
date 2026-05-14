---
name: CSS Tips集
description: 頻出CSSテクニック。object-position、SP属性セレクタ、ロゴ透過、letter-spacing、npmキャッシュ回避
type: reference
---

# CSS Tips集

- `object-position: center XX%` → %上げる=表示位置下=被写体の顔が上に上がる
- PC=inline style、SP=属性セレクタ`[src="filename"]`+`!important`。両方同時に変えない
- ロゴ透過: 明背景=`mix-blend-mode:multiply` / 暗背景=`filter:invert(1) brightness(1.5)`+`lighten`
- `letter-spacing`: SP版は必ず縮小（改行崩れ防止）
- npmキャッシュにroot所有ファイル → `npm install --cache /tmp/npm-cache-tmp` で回避
