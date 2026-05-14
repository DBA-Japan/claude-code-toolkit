# skills/

Anthropic plugin-style skills (`SKILL.md` 形式)。

各サブディレクトリは独立した skill。`SKILL.md` の frontmatter `description` がロード判定のキー。

## 含まれるもの

| Skill | 用途 | 依存 |
|---|---|---|
| `humanizer` | AI 臭い文章を自然な文章に修正 | なし |
| `notebooklm` | Google NotebookLM API（ポッドキャスト生成等） | Google OAuth |
| `veo3` | Google AI Studio で写真 → 動画 | Gemini API key |
| `video` | 素材動画 → YouTube + ショート | ffmpeg, whisper-cpp, yt-dlp |
| `hyperframes` | HTML/GSAP 起点の動画制作 | hyperframes-cli (npx) |
| `hyperframes-cli` | hyperframes 用 CLI ラッパー | npx |
| `gsap` | GSAP アニメーション辞典 | なし |
| `website-to-hyperframes` | URL → 動画 | Playwright MCP, hyperframes-cli |
| `design-extract` | 参考サイトのデザイン要素抽出 | Chrome 拡張 or Playwright |
| `seo-audit` | Web ページの SEO 監査 | Playwright MCP（任意） |
| `skill-creator` | 新しい skill を作る／評価 | なし |
| `self-improving-agent` | MEMORY.md 棚卸し・パターン昇格 | なし |
| `ui-ux-lookup` | UI/UX データベース引き当て | なし |
| `latent-demand` | 提案文・ヒアリング・CTA の「既存行動寄生」検査 | なし |

## 配置方法

`install.sh` が `~/.claude/skills/` にコピーします。手動で配置する場合は同じパスへ。

## 依存の確認

`/doctor` を打つと、各 skill が要求する依存（API key, brew, npm 等）の不足を表示します。
