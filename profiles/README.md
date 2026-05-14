# profiles/

`install.sh --profile <name>` で読み込むプロファイル定義。

## 含まれるもの

| Profile | 何が入る | 推奨ユーザー |
|---|---|---|
| `core` (default) | 入口 5 コマンド + 汎用裏方 / hooks 最小 3 / rules 6 / agents 15 / skills 0 / references 5 | 全員 |
| `web` | + Web 用 skills 8 / Web references TOP15 | Web 制作担当 |
| `media` | + 動画/音声 skills 3 / media references | 動画制作・YouTuber |
| `research` | + research skills 2 / research guides | リサーチャー・学生 |
| `full` | core + web + media + research（明示警告付き） | 上級者 |

## 形式

各 profile は `<name>.sh` で:

```bash
#!/usr/bin/env bash
PROFILE_SKILLS=("notebooklm" "veo3" "video")
PROFILE_REFERENCES=("ai-antidote.md" "...")
PROFILE_GUIDES=("notebooklm-pipeline.md")
PROFILE_HOOKS=("learning-observer.sh")
```

`install.sh` が source して読み込みます。

## 追加・削除

```bash
bash install.sh --add web      # web プロファイルを追加適用
bash install.sh --remove web   # web プロファイルが入れたものを抜く
```

詳細は [`../guides/doctor-explained.md`](../guides/doctor-explained.md)。
