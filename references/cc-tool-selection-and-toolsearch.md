---
name: CC ツール選択ロジック & ToolSearch 完全解析
description: Claude Codeのツール選択判断・ToolSearch遅延ロード・MCPツール競合・descriptionの最適な書き方・並列実行判断・トークン消費。ソースコードリーク+公式ドキュメント+分析記事から抽出
type: reference
---

# Claude Code ツール選択ロジック & ToolSearch 完全解析

> 2026-03-31ソースコードリーク、公式APIドキュメント、15以上の分析記事から抽出。MCPサーバーを多数接続している環境での最適化に特化。

---

## 1. ツール選択の仕組み：モデルはどうやってツールを選ぶか

### 1-1. 基本原理

Claude Code（=Claudeモデル）がツールを選ぶのは、**システムプロンプトに書かれたツールdescription（説明文）を読んで判断している**だけ。特別なアルゴリズムではなく、「説明文を読んで一番合いそうなツールを選ぶ」というLLMの自然言語理解そのもの。

つまり:
- descriptionが曖昧 → 間違ったツールを選ぶ
- descriptionが明確 → 正しいツールを選ぶ
- 似た名前のツールが複数ある（例: `github_create_issue` と `gh_new_issue`） → モデルが迷う

### 1-2. システムプロンプトでの指示

ソースコードから判明した、ツール選択に関する明示的な指示:

- **「Bashよりも専用ツールを優先せよ」** — Grep/Read/Edit/Write/Globがある場合、`grep`や`cat`や`sed`のBash実行より専用ツールを使うよう指示
- **「並列で呼べるものは並列で」** — 独立した操作は同時実行するよう指示
- **「ツール呼び出し間のテキストは25語以下」** — 余計な説明を書かずすぐツールを呼べ
- **「最終回答は100語以下」** — 簡潔に

### 1-3. ツールの分類（ソースから判明）

```
並列実行可能（concurrent = 読み取り専用）:
  Read, Grep, Glob, WebSearch, WebFetch, ListMcpResources, ReadMcpResource

直列実行のみ（serialized = 変更を伴う）:
  Bash, Edit, Write, NotebookEdit
```

並列可能ツールは同時に複数実行できるが、直列ツールは1つずつ。これはハーネス（CC本体）が強制する。

---

## 2. 遅延ツール（Deferred Tools）の全体像

### 2-1. 問題: コンテキスト汚染

MCPサーバーを接続すると、各ツールの**スキーマ（名前+説明+パラメータ定義）**がシステムプロンプトに注入される。

具体例:
- Chrome DevTools MCP → 約30ツール
- Playwright MCP → 約20ツール  
- Gmail MCP → 約10ツール
- Google Calendar MCP → 約10ツール
- Notion MCP → 約15ツール
- context7 MCP → 2ツール

**合計100個以上のツールスキーマ = 約55,000〜77,000トークン**がシステムプロンプトに載る。これだけで200Kコンテキストの25-40%を消費。

### 2-2. 解決策: ToolSearch + defer_loading

Claude Codeの解決策:

1. **ツールに`defer_loading: true`を付ける** → そのツールのスキーマ（パラメータ定義）はシステムプロンプトに載らない
2. **代わりにツール名だけがリストで見える**（`system-reminder`メッセージとして）
3. **ToolSearchという「メタツール」だけは常にフルロード** → モデルがToolSearchを呼んで必要なツールを探す
4. **ToolSearchの結果として、マッチしたツールのフルスキーマが会話に注入される** → モデルがそのツールを呼べるようになる

### 2-3. 遅延にするかしないかの基準

**自動判定（`ENABLE_TOOL_SEARCH=auto`の場合）:**
- 全MCPツールのスキーマ合計サイズが**コンテキストウィンドウの10%を超える**場合 → 超過分を`defer_loading: true`にする
- 具体的には、全ツール説明の合計が**10,000トークン**を超えると遅延ロードが発動

**常にフルロードされるツール（遅延されない）:**
- Bash, Read, Edit, Write, Glob, Grep, Skill, ToolSearch自体
- その他の「コアツール」約20個（セクション4-2参照）

**常に遅延されるツール:**
- MCPサーバーのツール全般（スキーマ合計が閾値を超えた場合）
- あまり使われない組み込みツール

### 2-4. 環境変数 `ENABLE_TOOL_SEARCH` の設定

| 値 | 動作 |
|----|------|
| `true`（デフォルト） | ToolSearchを有効化。MCPツールは遅延ロード |
| `false` | ToolSearch無効。全ツールスキーマを毎ターン全ロード。**ツール10個以下の小規模環境向け** |
| `auto` | コンテキスト10%超過時のみ遅延ロード発動 |
| `auto:X` | Xバイト超過時のみ発動（カスタム閾値） |

---

## 3. ToolSearchのマッチングアルゴリズム

### 3-1. 2つの検索モード

**モード1: Regex（正規表現）マッチング**
- モデルが`"weather"`や`"get_.*_data"`のようなパターンを構築
- ツール名、description、パラメータ名を対象に正規表現マッチ
- **既知のツール名を探すとき**に高速・正確
- 例: `"select:Read,Edit,Grep"` → 名前完全一致で取得

**モード2: BM25（キーワードベース自然言語検索）**
- モデルが自然言語クエリを投げる（例: `"notebook jupyter"`）
- BM25アルゴリズムで類似度スコアリング
- **「やりたいこと」からツールを探すとき**に有効
- セマンティック検索ではないが、キーワード重み付けで十分な精度

**モード3: カスタム埋め込み（オプション）**
- APIユーザーが自前のembedding検索を実装可能
- `tool_reference`ブロックを返すカスタムツールとして実装
- Claude Code内部では使用されていない（Regex + BM25で十分）

### 3-2. 検索対象フィールド

ToolSearchが検索する情報:
1. **ツール名**（例: `mcp__chrome-devtools__take_screenshot`）
2. **description**（ツールの説明文）
3. **パラメータ名**（例: `uid`, `value`, `includeSnapshot`）
4. **パラメータのdescription**

**ツール名が最も重要**。`mcp__chrome-devtools__take_screenshot`なら「screenshot」で検索ヒットする。

### 3-3. 検索結果の扱い

- 1回のToolSearch呼び出しで**3-5個**のツールスキーマが返される（`max_results`で制御可能）
- 返されたスキーマは`tool_reference`ブロックとして会話に追加
- **一度発見されたツールは、そのセッション中ずっと使える**（再検索不要）
- ToolSearchの結果は**プロンプトキャッシュを壊さない**（遅延ツールはキャッシュキー計算から除外される）

### 3-4. 実際のToolSearch呼び出し例

今のセッションで実際に起きていること:

```
ユーザーの環境: 100+ MCPツール（Chrome DevTools, Playwright, Gmail, Calendar, Notion, context7, claude-peers）

→ Claude Codeが見えるもの:
  - コアツール20個（フルスキーマ）
  - ToolSearch（フルスキーマ）
  - 遅延ツール100個+（名前のリストのみ）

→ WebSearchが必要になったとき:
  モデルがToolSearchを呼ぶ: query="select:WebSearch"
  → WebSearchのフルスキーマが注入される
  → モデルがWebSearchを呼べるようになる
```

---

## 4. MCPツール vs 組み込みツール：登録と競合

### 4-1. ツール登録の流れ

1. **組み込みツール**: `getAllBaseTools()`で40以上が登録。フィーチャーゲート・ユーザータイプ・環境フラグでフィルタリング
2. **MCPツール**: MCPサーバー接続時に動的に追加。名前は`mcp__{サーバー名}__{ツール名}`の形式
3. **名前衝突チェック**: 同名ツールがある場合、MCPツール側にサーバー名プレフィックスが付く

### 4-2. 優先順位

**明確な優先順位は存在しない**。モデルがdescriptionを読んで判断する。ただし:

- **組み込みツールはフルロード** → 常にスキーマが見える → 選ばれやすい
- **MCPツールは遅延ロード** → ToolSearchで見つけるまでスキーマが見えない → 見つけてもらう必要がある
- **システムプロンプトの指示が最優先** → 「Bashよりも専用ツールを使え」「MCPのCLIツールを活用しろ」等

### 4-3. MCPサーバーの`instructions`フィールド

MCPサーバーは`instructions`（サーバー説明）を返せる。これが重要:

```
例: context7サーバーの instructions:
"Use this server to fetch current documentation whenever the user asks 
about a library, framework, SDK, API, CLI tool, or cloud service..."
```

この`instructions`は**システムプロンプトに注入される**（ただし2KB上限で切り詰め）。モデルは「ライブラリの質問が来たらcontext7を使おう」と学習する。

### 4-4. 競合の回避方法

**同じことができるツールが複数あるとき:**
- Chrome DevTools MCP の `take_screenshot` vs Playwright MCP の `browser_take_screenshot`
- → **サーバーのinstructionsで使い分けを明示する**のが最善
- → または、使わないサーバーのツールを設定で無効化

### 4-5. descriptionとinstructionsの切り詰め

**重要**: Claude Codeは以下を切り詰める:
- 各ツールのdescription → **2KB上限**
- 各MCPサーバーのinstructions → **2KB上限**
- ツール結果 → **25,000トークン上限**（デフォルト）

**対策**: 重要な情報はdescriptionの**先頭**に書く。2KB超えた分は消える。

---

## 5. ツールdescriptionの最適な書き方

### 5-1. モデルの選択に最も影響する要素（重要度順）

1. **ツール名** — `take_screenshot`なら「スクリーンショット」と即座にわかる。最も強い手がかり
2. **descriptionの1文目** — モデルが最初に読む。ここで80%決まる
3. **パラメータ名** — `url`, `query`, `file_path`等。タスクとの関連性を示す
4. **descriptionの詳細** — いつ使うか/使わないかの条件
5. **MCP server instructions** — 「このサーバーはXXの場面で使え」

### 5-2. 良いdescriptionの書き方

**原則: 「このツールは何をするか」+「いつ使うか」+「いつ使わないか」**

```
悪い例:
"A tool for interacting with the browser"

良い例:
"Takes a screenshot of the current browser page. Use when you need to 
visually verify page layout, check CSS rendering, or capture UI state. 
Do NOT use for reading text content — use browser_snapshot instead."
```

**キーワードリッチにする:**
- ToolSearchはキーワードマッチング（BM25）を使う
- ユーザーが使いそうな言葉をdescriptionに含める
- 例: 「screenshot」「capture」「image」「visual」「page」

**否定条件を書く:**
- 「Do NOT use for...」は競合ツールとの区別に極めて有効
- モデルが迷ったとき、否定条件で正しいツールに誘導される

### 5-3. MCPサーバーのinstructions最適化

```
良い例（context7の実際のinstructions）:
"Use this server to fetch current documentation whenever the user asks 
about a library, framework, SDK, API, CLI tool, or cloud service 
-- even well-known ones like React, Next.js, Prisma...
Do not use for: refactoring, writing scripts, debugging business logic..."
```

ポイント:
- **トリガー条件を具体的に列挙** — 「library」「framework」「SDK」「API」
- **「使わない場面」も書く** — 不要な呼び出しを防ぐ
- **2KB以内に収める** — 超過分は切り詰められる

---

## 6. 並列ツール呼び出しの判断

### 6-1. モデルの判断ロジック

並列/直列の判断はモデル（LLM）が行う。ハーネス側の制約:
- **concurrent（読み取り専用）ツール**: 並列実行OK
- **serialized（変更系）ツール**: 直列のみ

モデルが並列を選ぶ条件:
1. **データ依存がない** — AとBの結果が互いに必要ない
2. **副作用がない** — 両方とも読み取り専用
3. **ユーザーが明示的に並列を指示** — 「AとBを同時に」

### 6-2. 並列実行を促すコツ

```
並列になりやすい書き方:
「ファイルAとファイルBを読んで」
「git statusとgit diffを確認して」
「3つのURLを同時に検索して」

直列になる書き方:
「ファイルを読んで、その結果に基づいて修正して」
「検索して、見つかったファイルを編集して」
```

### 6-3. サブエージェントによる並列化

通常のツール並列とは別に、**サブエージェント（Fork/Teammate/Worktree）**による並列化もある:
- Fork: 親コンテキストのコピーを継承。キャッシュ共有で**5体起動してもコスト約1体分**
- Teammate: tmux別ペインで完全独立
- Worktree: Gitワークツリーで隔離

---

## 7. ツール結果のコンテキスト消費と切り詰めルール

### 7-1. ツール結果のトークン消費

| ツール | 典型的なトークン消費 |
|--------|-------------------|
| Read（2000行） | 5,000〜15,000トークン |
| Grep（250件） | 2,000〜5,000トークン |
| Glob | 500〜2,000トークン |
| Bash（コマンド出力） | 可変（数百〜数万） |
| WebSearch | 2,000〜5,000トークン |
| ToolSearch | 1,000〜3,000トークン（返されたスキーマ分） |

### 7-2. 切り詰めルール

1. **50,000文字超のツール結果** → ディスクに保存、コンテキスト内は**2,000バイトのプレビュー**に置換
2. **ツールresult全般** → デフォルト**25,000トークン上限**
3. **Read結果** → **2,000行上限**（超過分は読めない）
4. **Grep結果** → **250件上限**（`head_limit`パラメータ）

### 7-3. コンパクション時のツール結果

AutoCompact（約167,000トークンで発動）時:
- **古いツール結果は削除される**（最初に消えるもの）
- **最近アクセスした5ファイル**のみ再注入（各5,000トークン上限）
- **ユーザーメッセージは全保持**
- **50,000トークンの要約**に圧縮

MicroCompact（ローカル編集）:
- 古いツール出力を**LLM呼び出しなしで直接削除**
- 最も軽量な圧縮方法

### 7-4. ToolSearchの結果のトークン効率

**Before（遅延ロードなし）:**
- 100個のMCPツール × 約770トークン/ツール = **約77,000トークン**

**After（ToolSearch利用）:**
- ToolSearchメタツール: 約500トークン
- 遅延ツール名リスト: 約2,000トークン
- 実際に使うツール3-5個: 約3,000〜5,000トークン
- **合計: 約5,500〜7,500トークン**（**85%以上削減**）

---

## 8. 今の環境への実践的な提案

### 8-1. MCP設定の最適化

**現在の接続MCPサーバー:**
- Chrome DevTools（約30ツール）
- Playwright（約20ツール）
- Gmail（約10ツール）
- Google Calendar（約10ツール）
- Notion（約15ツール）
- context7（2ツール）
- claude-peers（4ツール）

**提案:**

1. **Chrome DevToolsとPlaywrightは重複が多い** — ブラウザ操作はどちらか1つに絞ると、モデルの混乱が減る。現状、`click`、`screenshot`、`fill`等が2サーバーに存在
2. **context7は軽量（2ツール）** — 遅延ロードの恩恵は少ない。フルロードでOK
3. **claude-peersは軽量（4ツール）** — 同上

### 8-2. ToolSearchを効果的にトリガーするコツ

ToolSearchはモデルが「必要なツールが今のコンテキストにない」と判断したときに自動で呼ばれる。ただし:

- **最初のターンで使いたいMCPツールを明示する** — 「Gmailで○○を検索して」と書けば、モデルがToolSearchでGmailツールを取得する
- **曖昧な指示は避ける** — 「メール確認して」だとモデルが何を使うか迷う。「Gmailで最新メール3件読んで」ならGmail MCPに直行

### 8-3. MCPツールのdescription改善テンプレート

自作MCPサーバーを作る場合:

```
name: "明確な動作を表す名前"（例: search_emails, create_event）
description: |
  1文目: このツールは何をするか（動詞で始める）
  2文目: いつ使うか（トリガー条件）
  3文目: いつ使わないか（否定条件）
  4文目以降: 重要なパラメータの説明（任意）
```

### 8-4. 遅延ツールの命名規則

ToolSearchのキーワードマッチングで見つけやすくするために:

```
良い命名:
  gmail_search_messages → 「gmail」「search」「messages」でヒット
  calendar_create_event → 「calendar」「create」「event」でヒット

悪い命名:
  do_action → 何も特定できない
  util_helper → 汎用すぎてマッチしない
```

### 8-5. `ENABLE_TOOL_SEARCH` の推奨設定

現在の環境（100+ツール）では:
- **`ENABLE_TOOL_SEARCH=true`（デフォルト）が最適**
- `false`にすると77,000トークンがシステムプロンプトを圧迫
- `auto`でも問題ないが、明示的に`true`が安全

---

## 9. 偽ツール注入（Anti-Distillation）との関係

### 9-1. 偽ツールとは

`ANTI_DISTILLATION_CC`フラグがONの場合、APIリクエストに`anti_distillation: ['fake_tools']`が送信され、サーバー側が**偽のツール定義をシステムプロンプトに注入**する。

これは:
- 競合がClaude CodeのAPIトラフィックを記録して自社モデルを訓練しようとしたとき、偽ツールが訓練データを汚染する仕組み
- `tengu_anti_distill_fake_tool_injection` GrowthBookフラグでゲート
- **ファーストパーティCLIセッションのみ有効**

### 9-2. ユーザーへの影響

- 偽ツールはモデルには見えるが、**ユーザーが意図的に呼ぶものではない**
- ToolSearchの結果には偽ツールは含まれない（サーバー側で分離）
- パフォーマンスへの影響は軽微（数百トークン程度）

---

## ソース

- [Anthropic公式 Tool Search Tool ドキュメント](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)
- [Anthropic公式 Tool Reference ドキュメント](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-reference)
- [Anthropic Engineering - Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)
- [Engineer's Codex - Diving into Claude Code's Source Code Leak](https://read.engineerscodex.com/p/diving-into-claude-codes-source-code)
- [Alex Kim - fake tools, frustration regexes, undercover mode](https://alex000kim.com/posts/2026-03-31-claude-code-source-leak/)
- [Penligent - Inside Claude Code Architecture](https://www.penligent.ai/hackinglabs/inside-claude-code-the-architecture-behind-tools-memory-hooks-and-mcp/)
- [DEV Community - Leaked Architecture Reveals About Building Production MCP Servers](https://dev.to/shekharp1536/what-claude-codes-leaked-architecture-reveals-about-building-production-mcp-servers-2026-10on)
- [KubeSimplify - What Claude Code's Leaked Source Teaches](https://blog.kubesimplify.com/claude-code-leak-what-the-source-actually-teaches)
- [atcyrus - What is MCP Tool Search?](https://www.atcyrus.com/stories/mcp-tool-search-claude-code-context-pollution-guide)
- [ClaudeFast - Claude Code MCP Tool Search](https://claudefa.st/blog/tools/mcp-extensions/mcp-tool-search)
- [Superframeworks - Claude Code Source Code Leaked](https://superframeworks.com/articles/claude-code-source-code-leak)
- [Linas Substack - What 512,000 Lines Reveal](https://linas.substack.com/p/claudecodesource)
- [Scaling MCP Tools with Anthropic's Defer Loading](https://unified.to/blog/scaling_mcp_tools_with_anthropic_defer_loading)
- [GitHub Issue #18397 - Tool Search activation](https://github.com/anthropics/claude-code/issues/18397)
- [GitHub Issue #19445 - Deferred Loading for Task Agents](https://github.com/anthropics/claude-code/issues/19445)
