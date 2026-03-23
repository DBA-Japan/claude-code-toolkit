---
name: instinct
description: 継続学習ダッシュボード＋パターン進化（自動モード判定）
---

# Instinct（継続学習システム）

## モード自動判定

| ユーザーの意図 | モード |
|--------------|--------|
| 「学習状況は？」「パターン見せて」引数なし | **Status** → 50件以上なら Evolve 提案 |
| 「パターンを抽出」「スキルに進化」「evolve」 | **Evolve** |

## 共通: データ分析

`~/.claude/instincts/observations.jsonl` を Read。存在しない/空なら「まだ観察データがありません」で終了。以下を Bash 実行（引数 `status` or `evolve`）:

```bash
python3 - "$MODE" << 'PYEOF'
import json,os,sys
from collections import Counter,defaultdict
from datetime import datetime
H=os.path.expanduser("~");OBS=H+"/.claude/instincts/observations.jsonl";IDIR=H+"/.claude/instincts/instincts"
MODE=sys.argv[1] if len(sys.argv)>1 else "status"
obs=[]
try:
 with open(OBS) as f:
  for l in f:
   l=l.strip()
   if l:
    try:obs.append(json.loads(l))
    except:pass
except FileNotFoundError:print("NO_DATA");sys.exit(0)
if not obs:print("NO_DATA");sys.exit(0)
N=len(obs)
if MODE=="evolve" and N<10:print(f"INSUFFICIENT:{N}");sys.exit(0)
tc=Counter(o.get('tool','?') for o in obs)
fc=Counter();dc=Counter()
for o in obs:
 f=o.get('file','')
 if f:fc[f]+=1;dc[os.path.dirname(f)]+=1
pairs=Counter()
for i in range(N-1):
 a,b=obs[i].get('tool',''),obs[i+1].get('tool','')
 if a and b:pairs[f"{a} -> {b}"]+=1
hc=Counter()
ts_list=[]
for o in obs:
 ts=o.get('ts','')
 if ts:
  try:d=datetime.fromisoformat(ts);hc[d.hour]+=1;ts_list.append(d)
  except:pass
first=min(ts_list).strftime('%Y-%m-%d') if ts_list else 'N/A'
last=max(ts_list).strftime('%Y-%m-%d') if ts_list else 'N/A'
days=max(1,(max(ts_list)-min(ts_list)).days) if ts_list else 0
ic=len([x for x in os.listdir(IDIR) if x.endswith('.md')]) if os.path.exists(IDIR) else 0
sc=Counter()
for o in obs:
 a=o.get('action','')
 if a.startswith('skill:'):sc[a[6:]]+=1
print(f"TOTAL:{N}|PERIOD:{first}~{last}({days}d)|INSTINCTS:{ic}")
print("==TOOLS==")
for t,c in tc.most_common(10):print(f"{t}|{c}|{round(c/N*100,1)}%")
print("==FILES==")
for f,c in fc.most_common(10):print(f"{f.replace(H,'~')}|{c}")
print("==PAIRS==")
for s,c in pairs.most_common(10):
 if c>=2:print(f"{s}|{c}")
print("==HOURS==")
for h in sorted(hc):print(f"{h:02d}|{hc[h]}|{'#'*min(25,hc[h])}")
if sc:
 print("==SKILLS==")
 for s,c in sc.most_common(10):print(f"{s}|{c}")
if MODE=="evolve":
 tri=Counter()
 for i in range(N-2):
  a,b,c=obs[i].get('tool',''),obs[i+1].get('tool',''),obs[i+2].get('tool','')
  if a and b and c:tri[f"{a}->{b}->{c}"]+=1
 print("==TRIPLES==")
 for s,c in tri.most_common(15):
  if c>=3:print(f"{s}|{c}")
 fep=defaultdict(list)
 for o in obs:
  f,t=o.get('file',''),o.get('tool','')
  if f and t in('Read','Edit','Write'):fep[f].append(t)
 print("==FREQ_FILES==")
 for f,ops in sorted(fep.items(),key=lambda x:-len(x[1])):
  if len(ops)>=5:print(f"{f.replace(H,'~')}|{len(ops)}|{Counter(ops).most_common()}")
 bc=Counter()
 for o in obs:
  a=o.get('action','')
  if a.startswith('bash:'):bc[a[5:]]+=1
 print("==BASH==")
 for cmd,c in bc.most_common(10):
  if c>=3:print(f"{cmd}|{c}")
 print("==EXISTING==")
 if os.path.exists(IDIR):
  for fn in sorted(os.listdir(IDIR)):
   if fn.endswith('.md'):print(fn)
PYEOF
```

## Mode: Status（ダッシュボード）

`status` で実行。出力を日本語ダッシュボードに整形:
- **概要**: 総観察数/期間/抽出済みInstinct数
- **ツール使用頻度 TOP10**: テーブル（ツール/回数/割合）
- **よく編集するファイル TOP10**: テーブル
- **ワークフローパターン**: テーブル + 各パターンの意味を解説
- **活動時間帯**: バーチャート + コメント
- **スキル使用状況**: あれば表示

`~/.claude/projects/memory/user-patterns.md` と比較し新パターンに「NEW」。50件以上なら Evolve 提案。

## Mode: Evolve（パターン抽出と進化）

`evolve` で実行。`user-patterns.md` と `~/.claude/instincts/instincts/*.md` を読み重複除外。

**抽出基準**: 5回以上 / 未記録 / 自明でない（Read->Read等除外）
**カテゴリ**: `workflow` / `preference` / `pattern`
**信頼度**: 5-9回=0.3 / 10-19回=0.5 / 20-49回=0.7 / 50回+=0.9

パターンごとに `~/.claude/instincts/instincts/カテゴリ-名前.md`（kebab-case）を作成:
```markdown
---
name: [名] | confidence: [0.3-0.9] | observations: [回数] | last_seen: [日付] | category: [分類]
---
[説明] / **根拠**: [データ要約] / **アクション**: [提案] / **昇格候補**: user-patterns / CLAUDE.md / 新スキル
```

結果レポート: 新規一覧 + スキップ一覧 + 推奨アクション。実行前にユーザー確認。

## 関連
- 観察フック: `learning-observer.sh`（PreToolUse + PostToolUse）
- データ: `~/.claude/instincts/observations.jsonl`
- 手動パターン: `~/.claude/projects/memory/user-patterns.md`
