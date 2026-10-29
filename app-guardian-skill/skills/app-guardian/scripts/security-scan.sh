#!/usr/bin/env bash
# security-scan.sh — quick, dependency-free security red-flag scan.
# Usage: bash security-scan.sh [project-path]   (default: current directory)
# Exit code: 1 if any HIGH finding, else 0. Complements (does not replace) gitleaks/trufflehog.

ROOT="${1:-.}"
cd "$ROOT" || { echo "Cannot cd to $ROOT"; exit 2; }

HIGH=0
WARN=0
EXCL=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=dist --exclude-dir=build \
      --exclude-dir=.venv --exclude-dir=venv --exclude-dir=__pycache__ --exclude-dir=coverage --exclude-dir=.turbo \
      --exclude=package-lock.json --exclude=pnpm-lock.yaml --exclude=yarn.lock --exclude=*.min.js --exclude=*.map \
      --exclude=security-scan.sh --exclude=*.md)

section() { printf "\n== %s ==\n" "$1"; }
high() { HIGH=$((HIGH+1)); printf "  [HIGH] %s\n" "$1"; }
warn() { WARN=$((WARN+1)); printf "  [WARN] %s\n" "$1"; }

# scan <severity> <label> <extended-regex>
scan() {
  local sev="$1" label="$2" re="$3" out
  out=$(grep -rEIn "${EXCL[@]}" -e "$re" . 2>/dev/null | grep -v '\.env\.example' | head -15)
  if [ -n "$out" ]; then
    "$sev" "$label"
    echo "$out" | sed 's/^/         /'
  fi
}

section "Hardcoded secrets"
scan high "Stripe live/test secret key"      'sk_(live|test)_[0-9A-Za-z]{16,}'
scan high "AWS access key id"                'AKIA[0-9A-Z]{16}'
scan high "Private key block"                '-----BEGIN ((RSA|EC|OPENSSH|DSA) )?PRIVATE KEY-----'
scan high "GitHub token"                     'gh[pousr]_[A-Za-z0-9]{30,}'
scan high "Slack token"                      'xox[baprs]-[A-Za-z0-9-]{10,}'
scan high "Google API key"                   'AIza[0-9A-Za-z_-]{35}'
scan high "Hardcoded JWT"                    'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
scan high "DB URL with inline password"      '(postgres(ql)?|mysql|mongodb(\+srv)?|redis)://[^:/@ ]+:[^@/ ]{3,}@[^ "'"'"']+'
scan high "Hardcoded password/secret/key assignment" '(password|passwd|secret|api[_-]?key|token)[A-Za-z_]*[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9_\-\/+=]{8,}["'"'"']'
scan high "Secret fallback default"          '(process\.env\.[A-Z_]*(SECRET|KEY|TOKEN)[A-Z_]*|os\.(environ\.get|getenv)\([^)]*(SECRET|KEY|TOKEN)[^)]*,)[[:space:]]*(\|\||\?\?|or|,)[[:space:]]*["'"'"'][^"'"'"']+["'"'"']'

section "Secrets exposed to the client bundle"
scan high "Secret in public env var"         '(NEXT_PUBLIC|VITE|REACT_APP|EXPO_PUBLIC|PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|SERVICE_ROLE|PASSWORD)[A-Z0-9_]*'

section "Env file hygiene"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tracked=$(git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v '\.example$' | grep -v '\.sample$')
  [ -n "$tracked" ] && high "Tracked .env file(s) in git (rotate any secrets inside!): $(echo $tracked | tr '\n' ' ')"
  git check-ignore -q .env 2>/dev/null || { [ -f .env ] && high ".env exists but is NOT gitignored"; }
else
  warn "Not a git repo — skipped tracked-file checks"
fi
if [ -f .gitignore ]; then
  grep -qE '^\.env(\*|$|\.)' .gitignore || warn ".gitignore has no .env entry"
else
  warn "No .gitignore found"
fi
ls .env.example >/dev/null 2>&1 || ls .env.sample >/dev/null 2>&1 || warn "No .env.example documenting required variables"

section "Insecure auth / transport"
scan high "localStorage/sessionStorage token" '(localStorage|sessionStorage)\.setItem\([[:space:]]*["'"'"'][^"'"'"']*(token|jwt|session|auth)[^"'"'"']*["'"'"']'
scan high "TLS verification disabled"         'rejectUnauthorized[[:space:]]*:[[:space:]]*false|NODE_TLS_REJECT_UNAUTHORIZED[[:space:]]*=[[:space:]]*["'"'"']?0|verify[[:space:]]*=[[:space:]]*False'
scan high "JWT alg none / verification off"   'algorithms?[[:space:]]*:[[:space:]]*\[[^]]*none|ignoreExpiration[[:space:]]*:[[:space:]]*true|verify_signature["'"'"']?[[:space:]]*:[[:space:]]*False'
scan high "Weak password hashing"             '(createHash|hashlib\.)\(?[[:space:]]*["'"'"']?(md5|sha1|sha256)["'"'"']?\)?.*(password|passwd|pwd)|(md5|sha1)\(.*(password|passwd|pwd)'
scan warn "Math.random near token/secret"     'Math\.random\(\).*(token|secret|session|reset|otp|code)|(token|secret|session|reset|otp).*Math\.random\(\)'
scan warn "Cookie set without httpOnly (check manually)" 'res\.cookie\([^)]*\)' 

section "CORS / headers"
scan high "CORS wildcard origin"              'origin[[:space:]]*:[[:space:]]*["'"'"']\*["'"'"']|Access-Control-Allow-Origin["'"'"']?[[:space:]]*[:,][[:space:]]*["'"'"']\*|allow_origins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'"'"']\*'
scan warn "Reflected CORS origin"             'origin[[:space:]]*:[[:space:]]*(true|req\.headers\.origin)'

section "Injection / dangerous sinks"
scan high "eval / new Function"               '(^|[^A-Za-z_.])eval\(|new Function\('
scan high "dangerouslySetInnerHTML / innerHTML / v-html" 'dangerouslySetInnerHTML|\.innerHTML[[:space:]]*=|v-html='
scan high "Shell exec with interpolation"     '(child_process\.)?exec(Sync)?\([[:space:]]*(`[^`]*\$\{|["'"'"'][^"'"'"']*["'"'"'][[:space:]]*\+)|os\.system\(|subprocess\.[a-z]+\([^)]*shell[[:space:]]*=[[:space:]]*True'
scan high "SQL built by string concatenation / interpolation" '(SELECT[^;]+FROM|INSERT[[:space:]]+INTO|UPDATE[^;]+SET|DELETE[[:space:]]+FROM)[^;]*(["'"'"'`][[:space:]]*\+[[:space:]]*[A-Za-z_]|\$\{[^}]+\}|["'"'"'][[:space:]]*%[[:space:]]*[A-Za-z(]|f["'"'"'][^"'"'"']*\{[^}]+\})'
scan high "Python f-string SQL"                'f["'"'"'][[:space:]]*(SELECT|INSERT|UPDATE|DELETE)[^"'"'"']*\{[^}]+\}'
scan warn "Debug mode enabled"                'DEBUG[[:space:]]*=[[:space:]]*True|app\.run\([^)]*debug[[:space:]]*=[[:space:]]*True'

section "Rate limiting presence"
if grep -rEIl "${EXCL[@]}" -e 'express-rate-limit|rate-limiter-flexible|@upstash/ratelimit|slowapi|django-ratelimit|django_ratelimit|flask-limiter|Flask-Limiter|throttle|RateLimit|rate_limit|ratelimit' . >/dev/null 2>&1; then
  echo "  [ok] a rate limiting library/pattern was found — confirm it covers EVERY route"
else
  if grep -rEIl "${EXCL[@]}" -e 'app\.(get|post|put|patch|delete|use)\(|@(app|router)\.(get|post|put|patch|delete)|export (async )?function (GET|POST|PUT|PATCH|DELETE)|path\(' . >/dev/null 2>&1; then
    high "Endpoints found but no rate limiting library/pattern detected"
  fi
fi

printf "\n---------------------------------\n"
printf "HIGH: %d   WARN: %d\n" "$HIGH" "$WARN"
echo "Also run: gitleaks detect; npm audit --omit=dev / pip-audit. This script is a first pass, not a guarantee."
[ "$HIGH" -gt 0 ] && exit 1
exit 0
