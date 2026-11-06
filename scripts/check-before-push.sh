#!/usr/bin/env bash
# Local gate before push. Exit non-zero on any failure. Never skips silently.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

log() { printf '==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

SKIP_APK="${SKIP_APK:-0}"
SKIP_E2E="${SKIP_E2E:-0}"
SKIP_ADMIN_SMOKE="${SKIP_ADMIN_SMOKE:-1}"

log "Flutter analyze"
flutter analyze || fail "flutter analyze failed"

log "Flutter test"
flutter test || fail "flutter test failed"

if [[ "$SKIP_APK" != "1" ]]; then
  log "Flutter debug APK"
  flutter build apk --debug \
    --dart-define=API_BASE_URL=http://127.0.0.1:3000 \
    --dart-define=APP_ENV=ci \
    --dart-define=APP_DEMO=true \
    || fail "flutter build apk --debug failed"
else
  log "SKIP_APK=1 — APK build skipped (explicit)"
fi

log "Backend unit/lint/build"
(
  cd backend
  npm test || fail "backend npm test failed"
  npm run lint || fail "backend lint failed"
  npm run build || fail "backend build failed"
)

if [[ "$SKIP_E2E" != "1" ]]; then
  if [[ -f backend/.env ]]; then
    # shellcheck disable=SC1091
    set -a
    # Load DATABASE_URL, STORAGE_DRIVER, S3_*, ADMIN_* for live e2e / MinIO.
    source backend/.env
    set +a
  fi
  if [[ -z "${DATABASE_URL:-}" ]]; then
    fail "DATABASE_URL required for e2e (export it or provide backend/.env). Set SKIP_E2E=1 only intentionally."
  fi
  log "Backend live E2E (RUN_E2E=1, STORAGE_DRIVER=${STORAGE_DRIVER:-unset})"
  (
    cd backend
    RUN_E2E=1 npm run test:e2e || fail "backend e2e failed"
  )
else
  log "SKIP_E2E=1 — e2e skipped (explicit)"
fi

log "Admin-web lint/build"
(
  cd admin-web
  # Parent shells sometimes export NODE_ENV=development; Next production build needs production.
  unset NODE_ENV || true
  npm run lint || fail "admin-web lint failed"
  npm run build || fail "admin-web build failed"
)

if [[ "$SKIP_ADMIN_SMOKE" != "1" ]]; then
  log "Admin-web smoke"
  (
    cd admin-web
    export ADMIN_WEB_URL="${ADMIN_WEB_URL:-http://127.0.0.1:3001}"
    # After a fresh production build, bring up next start if nothing answers CSRF.
    if ! curl -sf "${ADMIN_WEB_URL}/api/auth/csrf" >/dev/null 2>&1; then
      port="${ADMIN_WEB_URL##*:}"
      port="${port%%/*}"
      unset NODE_ENV || true
      npx next start -p "${port:-3001}" > /tmp/salmonz-admin-smoke-server.log 2>&1 &
      echo $! > /tmp/salmonz-admin-smoke-server.pid
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        curl -sf "${ADMIN_WEB_URL}/api/auth/csrf" >/dev/null 2>&1 && break
        sleep 1
      done
    fi
    npm run test:smoke || fail "admin-web smoke failed"
    if [[ -f /tmp/salmonz-admin-smoke-server.pid ]]; then
      kill "$(cat /tmp/salmonz-admin-smoke-server.pid)" 2>/dev/null || true
      rm -f /tmp/salmonz-admin-smoke-server.pid
    fi
  )
else
  log "SKIP_ADMIN_SMOKE=1 — smoke skipped (default; needs running API+admin)"
fi

log "All required checks passed"
exit 0
