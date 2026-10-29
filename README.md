# Skills by Zain

A collection of agent skills. Each one is a standard `SKILL.md` (name + description frontmatter) that works with coding agents that support skills, such as Claude Code, Codex, Cursor and opencode.

## Skills

| Skill | What it does | Folder |
|---|---|---|
| **App Guardian** | Makes your agent build apps with security baselines on by default: Argon2id password hashing, short-lived JWT + rotating refresh tokens in `HttpOnly` cookies, HTTPS/HSTS, rate limits on every endpoint, zero secrets in code, input validation and authorization checks. Pushes back on insecure requests and ends every task with a security report. Includes a bundled scanner script. | [`app-guardian-skill/`](app-guardian-skill) |
| **Motionize** | Turns a project or a website into a short, shareable launch video, with music, motion and share copy. | [`motionize-skill/`](motionize-skill) |
| **Multicam** | Turns one talking-head take into a virtual multi-camera edit prompt for Google Omni, with cuts placed on the speech beats. | [`multicam/`](multicam) |

## Install

Every skill has its own README with exact install steps and requirements. The short version:

1. Clone this repo:
   ```
   git clone https://github.com/Zain-Razzaq/Skills-by-Zain.git
   ```
2. Copy the skill folder into your agent's skills directory:

   | Agent | Skills folder |
   |---|---|
   | Claude Code | `~/.claude/skills/` (global) or `.claude/skills/` (project) |
   | Codex | `~/.codex/skills/` or `.agents/skills/` |
   | Others | see your agent's skills docs |

   The folder you copy is the one containing `SKILL.md`:
   - App Guardian: `app-guardian-skill/skills/app-guardian/`
   - Motionize: `motionize-skill/skills/motionize/`
   - Multicam: `multicam/`

3. Restart your agent session so it picks the skill up.

Agents without skill support can paste a skill's `SKILL.md` into their rules file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.).

## Repo layout

```
Skills-by-Zain/
├── app-guardian-skill/   # security guardrails (+ scripts/security-scan.sh)
├── motionize-skill/      # launch video generator
└── multicam/             # virtual multi-camera prompt builder (+ Python scripts)
```

## Credits

App Guardian is by Zain Razzaq / Collective. Motionize and Multicam keep their original authors and licenses. See the `LICENSE` file in each folder.

## License

Each skill carries its own license (MIT) in its folder.
