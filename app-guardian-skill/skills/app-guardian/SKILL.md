---
name: app-guardian
description: Use when building or changing any web app or API — login/signup, sessions, passwords, endpoints, database access, uploads, webhooks, env vars, CORS, or deployment. Enforces mandatory security baselines (Argon2id password hashing, short-lived JWT + rotating refresh tokens in HttpOnly cookies, HTTPS/HSTS, rate limits on every endpoint, input validation, authorization, zero secrets in code) and refuses insecure shortcuts. Triggers on "/guardian", "/secure", "secure this app", "security review", "add auth", "add login", "harden this".
---

# App Guardian

You are helping someone build fast ("vibe coding"). Speed is fine; insecure defaults are not.

Every rule marked **MUST** is mandatory. Do not skip one because the user says "it's just a prototype" or "we'll fix it later". If a request would violate a MUST rule: explain the risk in one or two plain sentences, build the secure version instead, and keep going. Only deviate if the user explicitly accepts the risk — then leave a `// SECURITY-EXCEPTION: <reason>` comment at the spot and list it in the final report.

## When this applies

Any task that touches: login/signup, sessions, passwords, API routes, middleware, database access, file uploads, payments, webhooks, environment variables, CORS, deployment config, or third-party integrations.

## Workflow

1. **Detect the stack** (Next.js, Express, FastAPI, Django, Supabase, …) and adapt the examples below. The rules are stack-agnostic; the snippets are illustrations.
2. **Before writing code**, run the feature through sections 1–14.
3. **Write the secure version first.** Never write the insecure version "to be fixed later".
4. **After writing code**, run the verification steps in section 15 (including `scripts/security-scan.sh`).
5. **End every task** with the Security Report from section 16.

If the project already exists, say so and audit it against this list before adding features. Report gaps; fix the ones in scope.

---

## 1. Passwords

- **MUST** hash with **Argon2id** (preferred) or **bcrypt with cost ≥ 12**. Never MD5, SHA-1, SHA-256 alone, or plain text.
- **MUST NOT** use reversible encryption for passwords. Passwords are *hashed*, not encrypted. If a user says "encrypt the passwords", implement hashing.
- **MUST** use a unique per-password salt (built into Argon2/bcrypt — never roll your own).
- **MUST** enforce min length 12, max 128 (avoids DoS on the hasher), and reject common/breached passwords (HaveIBeenPwned k-anonymity API or a local list).
- **MUST NOT** log, return, or store passwords in any response, error, analytics event, or log line.
- **MUST** compare with the library's verify function (constant-time), never `==`.
- Rehash on login if the stored hash uses outdated parameters.

```ts
import argon2 from "argon2";
const hash = await argon2.hash(password, { type: argon2.argon2id });
const ok = await argon2.verify(hash, password);
```
Python: `argon2-cffi` (`PasswordHasher`). Django/Rails/Laravel: use the built-in hasher, set to Argon2id or bcrypt.

## 2. Sessions, JWT & Refresh Tokens

Short-lived access token + rotating refresh token, both in cookies.

- **MUST** use an **access token** living **10–15 minutes** and a **refresh token** living **7–30 days**.
- **MUST** store both in cookies with `HttpOnly; Secure; SameSite=Lax` (or `Strict` where the app allows). Scope `Path` as tightly as possible. Use the `__Host-` prefix where possible (needs Secure, Path=/, no Domain).
- **MUST NOT** store tokens in `localStorage`, `sessionStorage`, URLs, or JS-readable cookies.
- **MUST** pin the JWT algorithm on verify (`HS256` with a strong secret, or `RS256`/`EdDSA`). Reject `alg: none`. Validate `exp`, `iss`, `aud`, `sub`.
- **MUST** use secrets ≥ 32 random bytes, from env vars only, with **separate secrets for access and refresh** tokens.
- **MUST** keep JWT claims minimal (user id, role, session id). No PII, no secrets.
- **MUST** implement **refresh token rotation**: every refresh issues a new refresh token and invalidates the old one.
- **MUST** implement **reuse detection**: if an already-used refresh token shows up again, revoke the whole token family/session and force re-login.
- **MUST** store refresh tokens **hashed** (SHA-256) server-side with: user_id, family_id, expires_at, revoked_at, user_agent, ip.
- **MUST** make logout clear the cookies **and** revoke the refresh token server-side.
- **MUST** revoke all sessions on password change/reset.
- Prefer a well-tested library or provider (Auth.js, Lucia, Supabase Auth, Clerk, Django/Rails built-ins) over hand-rolled auth. If hand-rolling, follow every rule above.

```ts
res.cookie("__Host-access", accessToken, {
  httpOnly: true, secure: true, sameSite: "lax", path: "/", maxAge: 15 * 60 * 1000,
});
res.cookie("__Secure-refresh", refreshToken, {
  httpOnly: true, secure: true, sameSite: "strict", path: "/api/auth/refresh",
  maxAge: 30 * 24 * 60 * 60 * 1000,
});
```

## 3. CSRF

Cookie auth means CSRF protection is required.

- **MUST** set `SameSite` as above **and** protect all state-changing requests (POST/PUT/PATCH/DELETE) with a CSRF token (double-submit cookie or synchronizer token) or strict `Origin`/`Referer` verification.
- **MUST NOT** change state on GET requests.

## 4. HTTPS & Transport

- **MUST** enforce HTTPS in production: redirect HTTP → HTTPS (301/308).
- **MUST** send `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`.
- **MUST** configure proxy trust correctly (`app.set("trust proxy", …)`, `--proxy-headers`, `SECURE_PROXY_SSL_HEADER`) when behind Railway/Vercel/Nginx/Cloudflare, so HTTPS detection and client IPs are accurate.
- **MUST** use TLS for database and Redis connections (`sslmode=require` or equivalent).
- **MUST NOT** disable certificate verification (`rejectUnauthorized: false`, `verify=False`, `NODE_TLS_REJECT_UNAUTHORIZED=0`) anywhere.

## 5. Rate Limiting (CRITICAL — every endpoint)

**Every endpoint MUST be rate limited. No exceptions.** Add a global limiter first, then stricter limiters on sensitive routes.

- **MUST** apply a **global default limiter** (e.g. 100 req/min per IP) to the whole app, including "public" and health routes (higher limit, never none).
- **MUST** apply **stricter per-route limits**:

| Endpoint type | Suggested limit | Key by |
|---|---|---|
| Login | 5 attempts / 15 min | IP + account identifier |
| Signup | 5 / hour | IP |
| Password reset request | 3 / hour | IP + email |
| OTP / 2FA / email verification | 5 / 15 min | IP + account |
| Token refresh | 20 / hour | IP + session |
| Contact / email-sending forms | 5 / hour | IP |
| File upload | 10 / hour | user |
| AI / expensive / paid-API endpoints | 10–30 / min + daily cap | user |
| Search / list endpoints | 30–60 / min | user or IP |
| Webhooks | signature verification + limiter | source |

- **MUST** use a **shared store (Redis / Upstash / DB)** in production. In-memory limiters break on multiple instances and serverless.
- **MUST** return **HTTP 429** with a `Retry-After` header and a generic body.
- **MUST** add progressive delay or temporary lockout after repeated failed logins — without revealing whether the account exists.
- **MUST** key on the real client IP (correct proxy config) and, on authenticated routes, on user id too.
- **MUST** limit request body size (e.g. 1 MB default) and set request timeouts.

```ts
import rateLimit from "express-rate-limit";
app.use(rateLimit({ windowMs: 60_000, limit: 100, standardHeaders: true, legacyHeaders: false }));
app.use("/api/auth/login", rateLimit({ windowMs: 15 * 60_000, limit: 5, skipSuccessfulRequests: true }));
```
FastAPI: `slowapi`. Django: `django-ratelimit`. Next.js: `@upstash/ratelimit` in middleware. When adding a new route, add its limiter in the same change.

## 6. Input Validation & Injection

- **MUST** validate every input (body, query, params, headers, cookies) server-side with a schema library (Zod, Joi, Pydantic, class-validator). Reject unknown fields. Never rely on client-side validation.
- **MUST** use parameterized queries or an ORM. Never build SQL/NoSQL queries by string concatenation.
- **MUST** encode output. Never use `dangerouslySetInnerHTML`, `innerHTML`, or `v-html` with user data unless sanitized (DOMPurify or equivalent).
- **MUST NOT** use `eval`, `new Function`, or shell `exec` with user input. Use `execFile`/argument arrays with fixed commands.
- **MUST** prevent path traversal (never join user input into file paths) and SSRF (allowlist outbound URLs; block internal IP ranges and cloud metadata endpoints when fetching user-supplied URLs).
- **Uploads MUST**: enforce size limits, validate type by content (magic bytes), allowlist extensions, rename files randomly, store outside the web root or in object storage, and never serve uploads as executable content from the app origin.

## 7. Authorization

- **MUST** be deny-by-default: every route requires auth unless explicitly marked public.
- **MUST** check **ownership on every object access** (prevents IDOR): `WHERE id = :id AND user_id = :currentUser`. Never trust an id from the client.
- **MUST** enforce roles/permissions on the server. Hiding a button is not security.
- **MUST NOT** accept `role`, `isAdmin`, `userId`, `price`, or similar from request bodies (mass assignment). Whitelist fields explicitly.
- Supabase/Postgres: **MUST** enable Row Level Security on every table with real policies. Never ship the `service_role` key to a client.
- Admin routes **MUST** have separate, stricter auth (MFA when possible).

## 8. Secrets & Environment Variables (ZERO secrets in code)

### What counts as a secret
API keys, database URLs/passwords, JWT/signing secrets, OAuth client secrets, webhook signing secrets, encryption keys, SMTP passwords, cloud credentials (AWS/GCP, Supabase `service_role`), Stripe secret keys, private keys/certs, session secrets, any third-party token. If it grants access or proves identity, it's a secret.

### Hard rules
- **MUST NOT** hardcode any secret in source, config files, tests, comments, README, Dockerfiles, CI files, notebooks, or example snippets — including "temporary" or "just for testing" keys.
- **MUST** load secrets from **environment variables** or a secret manager (Railway/Vercel env settings, AWS Secrets Manager, Doppler, 1Password, Vault). Read them in **one central config module** and import from there; do not scatter `process.env.X` across the codebase.
- **MUST** validate env vars at startup with a schema (Zod / Pydantic Settings / envalid). **Crash on boot** if a required secret is missing, empty, too short, or still a placeholder. **No fallback defaults** for secrets (`process.env.JWT_SECRET || "secret"` is forbidden).
- **MUST** add `.gitignore` entries **before** creating any `.env` file:
  ```
  .env
  .env.*
  !.env.example
  *.pem
  *.key
  *.p12
  service-account*.json
  ```
- **MUST** commit a `.env.example` listing every variable name with **fake placeholder values and a short comment** (e.g. `JWT_ACCESS_SECRET=replace-with-48-random-bytes  # openssl rand -base64 48`). Real values never go in it.
- **MUST** generate strong secrets with a CSPRNG and show the user how: `openssl rand -base64 48` or `node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"`. Never invent a secret string yourself and put it in code or chat.
- **MUST** use **different secrets per environment** (dev / staging / prod) and **per purpose** (access-token secret ≠ refresh-token secret ≠ cookie secret ≠ encryption key).
- **MUST NOT** put secrets in client-exposed variables. Anything prefixed `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `EXPO_PUBLIC_`, or `PUBLIC_` ships to the browser. Secrets are **server-side only**. If the frontend needs a third-party call that uses a secret, route it through your own backend.
- **MUST NOT** leak secrets via other paths: Docker `ENV`/`ARG` with real values, `docker-compose.yml` literals, GitHub Actions YAML literals (use repo/environment Secrets), Terraform state, Postman exports, IDE configs.
- **MUST NOT** print, log, or return secrets: no `console.log(process.env)`, no config dumps in error pages or `/debug` routes; redact them in logs and error trackers (e.g. Sentry `beforeSend`).
- **MUST NOT** paste real secrets into prompts, chat, issues, or screenshots. If the user pastes one, tell them to **rotate it immediately**.
- **MUST** set production values in the host's dashboard/CLI (Railway, Vercel, Render, Fly), not in committed files.

### Safe pattern
```ts
// src/config/env.ts — the ONLY file that reads process.env
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  DATABASE_URL: z.string().url(),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  COOKIE_SECRET: z.string().min(32),
  STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith("whsec_"),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // names only — never print values
  console.error("Invalid environment configuration:", Object.keys(parsed.error.flatten().fieldErrors));
  process.exit(1);
}
export const env = parsed.data;
```
```python
# FastAPI / pydantic-settings — no defaults for secrets
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_access_secret: str
    jwt_refresh_secret: str
    model_config = {"env_file": ".env", "extra": "ignore"}

settings = Settings()  # raises on missing values
```

### Before writing code that needs a credential
1. Add the variable name to `.env.example` (placeholder only) and to the env schema.
2. Read it through the central config module.
3. Tell the user which variables to set locally in `.env` and in the hosting dashboard.
4. Never write the real value yourself.

### If a secret leaks (committed, pasted, logged, screenshotted)
Deleting the line or the commit is **not enough** — git history, forks, and caches keep it.
1. **Rotate/revoke it at the provider immediately.**
2. Remove it from code and, if the repo is shared, from history (`git filter-repo` / BFG).
3. Check provider logs for misuse.
4. Add a secret scanner so it can't recur.

### Prevention tooling (set up on new projects)
- **MUST** add a pre-commit secret scan (`gitleaks` or `detect-secrets` via husky/pre-commit) and a CI step that fails on findings.
- **SHOULD** enable GitHub Secret Scanning + Push Protection.
- **SHOULD** keep `.env*` out of Docker images (`.dockerignore`) and build artifacts / source maps.
- **SHOULD** rotate long-lived secrets on a schedule (e.g. 90 days) and when a team member leaves.

## 9. Security Headers & CORS

- **MUST** set headers (use `helmet` or the framework equivalent): `Content-Security-Policy` (avoid `unsafe-inline`/`unsafe-eval`), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or CSP `frame-ancestors`), `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (disable unused features). Remove `X-Powered-By`.
- **MUST** configure CORS with an **explicit origin allowlist**. Never `*` with credentials; never reflect the request `Origin` blindly.
- **MUST** allow only the methods and headers actually needed.

## 10. Account Security Flows

- **MUST** use generic messages ("Invalid email or password") and similar response timing to prevent user enumeration — on login, signup, and password reset.
- **MUST** make reset/verify tokens random (≥ 32 bytes, CSPRNG), single-use, short-lived (15–60 min), stored hashed.
- **MUST** verify email before enabling sensitive features.
- **SHOULD** offer MFA (TOTP/passkeys); **MUST** require it for admin accounts when feasible.
- **MUST** email users on password change, new-device login, or email change.
- Use `crypto.randomBytes` / `secrets` / `crypto.randomUUID`. Never `Math.random()` for security values.

## 11. Data Protection

- **MUST** collect the minimum data needed. Card data goes to Stripe or equivalent; never store it.
- **MUST** encrypt highly sensitive fields at rest (AES-256-GCM, keys from env/KMS) and rely on host/DB disk encryption.
- **MUST** run the app with a least-privilege DB user (never superuser). The DB must not be publicly reachable.
- **MUST** configure automated, encrypted backups.
- **MUST NOT** return raw DB rows to clients. Return explicit DTOs (never include `password_hash`, tokens, internal flags).

## 12. Errors, Logging & Monitoring

- **MUST** return generic errors to clients in production — no stack traces, SQL errors, or file paths.
- **MUST** disable debug mode and verbose errors in production; do not publish source maps with secrets or internals.
- **MUST** log security events (failed logins, refresh-token reuse, 403/429 spikes, admin actions) with timestamp, user id, and IP.
- **MUST NOT** log passwords, tokens, card data, or secrets. Redact `Authorization` and `Cookie` headers.
- **SHOULD** alert on repeated auth failures.

## 13. Dependencies & Supply Chain

- **MUST** commit lockfiles and pin versions.
- **MUST** run `npm audit` / `pip-audit` / `osv-scanner` and fix high/critical issues.
- **MUST** verify a package exists and is the legitimate one before installing — AI tools sometimes suggest non-existent or typosquatted packages. Prefer well-maintained, widely used packages.
- **SHOULD** enable Dependabot/Renovate.

## 14. Webhooks, Payments & Third Parties

- **MUST** verify webhook signatures (Stripe, GitHub, …) against the raw body; reject on failure. Add replay protection (timestamp tolerance, idempotency keys).
- **MUST** compute prices and totals server-side and confirm payment via the provider's webhook; never trust client-sent prices or "payment succeeded" flags.
- **MUST** use idempotency keys for payment-related writes.

## 15. Verification (run before saying "done")

Run what the environment allows. For anything you couldn't run, say so in the report.

0. **Bundled scanner**: `bash <skill-dir>/scripts/security-scan.sh [project-path]` — greps for hardcoded secrets, tracked `.env` files, missing `.gitignore` entries, and common red flags. Fix every finding or justify it.
1. **Secrets scan**: `gitleaks detect` (or `trufflehog`). Must be clean.
2. **Dependency audit**: `npm audit --omit=dev` / `pip-audit`.
3. **Rate limit test**: hit login 10× quickly; expect 429 after the limit.
   `for i in $(seq 1 10); do curl -s -o /dev/null -w "%{http_code}\n" -X POST $URL/api/auth/login -H 'content-type: application/json' -d '{}'; done`
4. **Cookie check**: log in and inspect `Set-Cookie` — must show `HttpOnly; Secure; SameSite`.
5. **HTTPS check**: `curl -I http://yourdomain` redirects to https; `Strict-Transport-Security` present.
6. **Headers check**: `curl -I $URL` shows CSP, nosniff, frame protection.
7. **Authz test**: request another user's resource id → 403/404; call protected routes with no token → 401.
8. **Token test**: reuse an old refresh token → session revoked; send a tampered or `alg:none` JWT → rejected.
9. **Red-flag grep**: `localStorage.setItem("token"`, `eval(`, `dangerouslySetInnerHTML`, `rejectUnauthorized: false`, `origin: "*"`, `NEXT_PUBLIC_*(SECRET|KEY)`, string-concatenated SQL, `Math.random` near tokens (the bundled scanner covers most of these).
10. **Env hygiene**: `git check-ignore .env` succeeds; `.env.example` exists with placeholders only; the app refuses to boot with a missing secret; the client bundle contains no secret (`grep -r "<known secret prefix>" .next/static dist build` returns nothing).

## 16. Final Security Report (required output)

End every task with:

```
SECURITY REPORT
✅ Applied: [controls implemented]
⚠️ Exceptions: [SECURITY-EXCEPTIONs the user accepted, or "none"]
❌ Not yet done / needs user action: [e.g. enable RLS, provision Redis, rotate leaked key]
🔑 Env vars to set: [variable names, where (local .env / hosting dashboard), how to generate each]
🧪 Verified: [which checks from section 15 were actually run, with results]
```

Never claim a control is in place unless you implemented and verified it. If you couldn't run a check, say so.

## Pushback script

When the user asks for something insecure, keep it short and plain:

> "I can't keep the token in localStorage — any script on the page can steal it. I've put it in an HttpOnly cookie instead; your frontend code works the same."

Don't lecture. Fix it, explain in one or two lines, continue.

## Never do

- Plain-text, MD5, SHA-only, or reversibly encrypted passwords
- Tokens in localStorage or JS-readable cookies
- Endpoints without rate limits
- `cors({ origin: "*", credentials: true })`
- Secrets in git, client bundles, or logs
- Trusting client-sent ids, roles, prices, or flags
- Raw SQL string concatenation
- HTTP in production
- Disabled TLS verification
- Detailed errors or stack traces in production
