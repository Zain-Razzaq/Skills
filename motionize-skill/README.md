# Motionize Skill

Turn what you built into a short, shareable launch video — music, motion, and share copy included. One command.

## Use

Run `/motionize` inside a project, or give it a website:

```
/motionize
/motionize https://example.com
/motionize --tone polished --format vertical --duration 20
```

Options: `--tone` (`default`, `polished`, `yc-parody`, `chaotic`, `deadpan`, `cinematic`, `app-store`, or freeform), `--format` (`landscape`, `vertical`, `square`), `--duration` (seconds, default ~20).

Output goes to `motionize-output/`: the video (`motionize.mp4`), a poster frame (`motionize.jpg`), and `share-copy.txt`.

## Install

Motionize is a standard `SKILL.md` (name + description frontmatter), so it works with any coding agent that supports skills, and the same file is used everywhere.

**Any agent** (Codex, Cursor, Copilot, Gemini CLI, opencode, Claude Code, and more) via the [`skills`](https://github.com/vercel-labs/skills) CLI:

```
npx skills add <repo-url> --skill motionize
```

Add `-g` to install globally. Or copy `skills/motionize/` into your agent's skills folder by hand.

**Claude Code plugin:**

```
/plugin marketplace add <repo-url>
/plugin install motionize@motionize
```

**Codex plugin:**

```
codex plugin marketplace add <repo-url>
codex plugin add motionize@motionize
```

Motionize needs an agent that can read files, run commands and render video on your machine. Plain chat apps without tool access (the ChatGPT or Grok web chat) can't run it.

## License

MIT
