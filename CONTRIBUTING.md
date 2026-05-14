# 貢献ガイド

このキットは「公開 allowlist 思考」で運用しています。内部素材を移植するのではなく、**公開用に再記述** する設計。PR を送る場合の基本ルールを以下に。

## 公開 allowlist 思考

❌ **やめろ**:
- 自分の業務メモリをそのまま `references/` に置く
- クライアント名・案件名・売上数字を含む事例
- 「○○社長が指摘した」「特定企業の事例で」のような固有性
- 自分の `~/.claude/skills/` をそのままコピー

✅ **やれ**:
- 知見を **汎用例** に書き直す（特定案件 → 架空クライアント例）
- 「ある B2B SaaS 案件で」のように匿名化
- メモリの「Why」「How to apply」を業界一般化

## PR のチェックリスト

- [ ] `gitleaks detect --source . --no-banner` で 0 hit
- [ ] `detect-secrets scan --baseline .secrets.baseline` で 0 new
- [ ] 禁止語辞書 grep で 0 hit:
  ```bash
  grep -rE "(株式会社[A-Za-z]+|クライアント名|顧客名)" --exclude-dir=.git
  ```
- [ ] メール / 電話 / API key 正規表現で 0 hit
- [ ] スクリーンショット・PDF を含む場合、機密情報の有無を目視確認
- [ ] 追加するスキル / コマンド / ガイドが既存と重複していない
- [ ] CLAUDE.md.template / README.md のテーブルを更新

## 機密スクリーニングの正規表現

```regex
# メール
[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}

# 電話（日本）
0\d{1,4}-\d{1,4}-\d{4}

# API キー（よくある形式）
sk-[a-zA-Z0-9]{20,}
AKIA[A-Z0-9]{16}
AIzaSy[a-zA-Z0-9_-]{33}
ghp_[a-zA-Z0-9]{36}

# Slack tokens
xoxb-\d+-\d+-\w+
xoxp-\d+-\d+-\d+-\w+

# Stripe
sk_live_[a-zA-Z0-9]{24,}

# Google OAuth
4/[a-zA-Z0-9_-]+

# 内部 URL（Notion / Drive 等）
https://www\.notion\.so/[a-zA-Z0-9-]+
https://drive\.google\.com/file/d/[a-zA-Z0-9_-]+
```

## 新しいコマンドを追加する場合

1. `commands/<name>.md` に書く
2. CLAUDE.md.template のコマンド表に追加
3. `manifests/skill-requirements.json` に依存を記載
4. `guides/<name>.md` で詳細を解説（任意）
5. 機密スクリーニングを通す

## 新しい skill を追加する場合

1. `skills/<name>/SKILL.md` の frontmatter を整備（name, description が必須）
2. `description` に「いつ発動するか」のキーワードを明示
3. 依存があれば `manifests/skill-requirements.json` に追加
4. README / CLAUDE.md.template に登場させる

## 新しい reference を追加する場合

1. **汎用化を確認**: 業務メモリそのままは NG
2. `references/<name>.md` に配置
3. 適切な profile に紐づける（`install.sh` の `INSTALL_REFERENCES` 配列）

## コミットメッセージ

```
<type>: <subject>

<body>

<footer>
```

Type:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントだけ
- `refactor`: 機能変化なしの整理
- `security`: 機密関連の修正
- `chore`: 周辺整備

例:
```
feat: /research コマンドに CiNii / J-Stage の対応を追加

guides/exa-cinii-jstage.md を新規作成
commands/research.md の振り分けロジックを更新
```

## レビュープロセス

1. PR を作成
2. CI（public-audit.yml）が pass
3. レビュワーが「公開 allowlist 思考」に沿っているか確認
4. merge

## 質問

GitHub Issues か Discussions で。
