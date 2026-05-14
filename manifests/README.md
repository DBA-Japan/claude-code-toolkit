# manifests/

`/doctor` コマンドが読む構造化マニフェスト。

## 含まれるもの

- `skill-requirements.json` — 各 skill / command が要求する依存（env, brew, pip, npm, MCP）の一覧

## 形式

```jsonc
{
  "skills": {
    "veo3": {
      "env": ["GEMINI_API_KEY"],
      "pip": ["google-genai"]
    },
    "video": {
      "brew": ["ffmpeg", "whisper-cpp", "yt-dlp"]
    }
  },
  "mcp": {
    "exa": { "env": ["EXA_API_KEY"] }
  }
}
```

## カスタマイズ

新しい skill を追加したら、ここに依存を追記してください。`/doctor` が自動で診断対象に含めます。
