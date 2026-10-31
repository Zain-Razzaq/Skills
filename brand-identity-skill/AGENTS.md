# Brand Identity skill

This repo contains an agent skill for logo and brand-identity design. The skill lives in
`skills/brand-identity/`; its entry point is `skills/brand-identity/SKILL.md`.

**If your agent does not load skills automatically** (Grok, Hermes, Cursor, Copilot, Aider and others that read
`AGENTS.md`), do this:

1. When the user asks for a logo, wordmark, monogram, brand mark, symbol, app icon, favicon, identity system or brand
   guidelines (designed, redesigned, critiqued or compared), read `skills/brand-identity/SKILL.md` first and follow
   its workflow, including the concept checkpoint.
2. Read the files in `skills/brand-identity/references/` only when `SKILL.md` points to them.
3. Run the scripts in `skills/brand-identity/scripts/` with `python3` (`python` or `py -3` on Windows) using the full
   path. They need Python 3.8+ and no packages.

Needs: file read/write and shell access. A model that can view images gives the best results, because the skill
renders its own drafts to PNG and checks them; without vision, the workflow still runs and says so.
