# App Guardian

A skill for vibe coders. It makes your coding agent build apps with security baselines on by default — and push back when you ask for something insecure.

## What it enforces

- **Passwords:** hashed with Argon2id (or bcrypt ≥ 12), never stored or logged in plain text
- **Sessions:** short-lived JWT access token + rotating refresh token with reuse detection, both in `HttpOnly; Secure; SameSite` cookies (never `localStorage`)
- **CSRF** protection for cookie auth
- **HTTPS everywhere:** redirect, HSTS, TLS to the database
- **Rate limits on every endpoint**, with stricter limits on login, signup, reset, OTP and expensive routes
- **Zero secrets in code:** env vars only, validated at startup, `.env` gitignored, `.env.example` committed, no secrets in client bundles
- **Input validation**, parameterized queries, output encoding, safe uploads, SSRF/path-traversal guards
- **Authorization:** deny-by-default, ownership checks (no IDOR), no mass assignment, Supabase RLS
- **Security headers and strict CORS**
- **Safe errors and logging**, dependency audits, webhook signature checks

Every task ends with a **Security Report** listing what was applied, what was verified, and what you still need to do (e.g. set env vars).

## Use

The skill activates when your agent works on auth, endpoints, databases, uploads, env vars or deployment. You can also call it directly:

```
/app-guardian
"Add login to this app"
"Audit this project against the security guardrails"
```

It includes `scripts/security-scan.sh`, a dependency-free scanner for hardcoded secrets, tracked `.env` files, insecure cookies/tokens, CORS wildcards, injection sinks and missing rate limiting:

```
bash skills/app-guardian/scripts/security-scan.sh path/to/your/project
```

It is a first pass. Also run `gitleaks` and `npm audit` / `pip-audit`.

## Install

This is a standard `SKILL.md` (name + description frontmatter), so it works with any agent that supports skills.

**Any agent** (Codex, Cursor, Copilot, Gemini CLI, opencode, Claude Code, and more) via the [`skills`](https://github.com/vercel-labs/skills) CLI:

```
npx skills add <repo-url> --skill app-guardian
```

Add `-g` to install globally. Or copy `skills/app-guardian/` into your agent's skills folder by hand:

| Agent | Folder |
|---|---|
| Claude Code | `~/.claude/skills/` (global) or `.claude/skills/` (project) |
| Codex | `~/.codex/skills/` or `.agents/skills/` |
| Others | see your agent's skills docs |

**Claude Code plugin:**

```
/plugin marketplace add <repo-url>
/plugin install app-guardian@app-guardian
```

**Codex plugin:**

```
codex plugin marketplace add <repo-url>
codex plugin add app-guardian@app-guardian
```

**Agents without skill support:** paste the contents of `skills/app-guardian/SKILL.md` into your project's rules file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.).

## Limits

This keeps an AI agent from making common mistakes. It isn't a replacement for a penetration test or a professional security review before handling payments, health data, or other regulated data.

## License

MIT
