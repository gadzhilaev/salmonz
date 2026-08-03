#!/usr/bin/env bash
# Bootstrap a fully working local Salmonz demo (users + catalog + images).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== ensure Docker stack =="
docker start salmonz-postgres-1 salmonz-minio-1 salmonz-backend-1 >/dev/null 2>&1 || true
# Prefer compose if available
if [[ -f docker-compose.yml ]]; then
  docker compose up -d postgres minio minio-init backend 2>/dev/null || true
fi

echo "== wait for API =="
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null; then
    echo "API up"
    break
  fi
  sleep 1
done
curl -sf http://127.0.0.1:3000/api/v1/health >/dev/null || {
  echo "Backend not healthy on :3000 — start with: docker compose up --build"
  exit 1
}

echo "== Flutter local config =="
if [[ ! -f config/local.json ]]; then
  cp config/local.example.json config/local.json
  echo "created config/local.json"
fi

echo "== seed database (host → docker Postgres:55432 + MinIO) =="
# Parse backend/.env safely (values may contain !)
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  if [[ "$line" =~ ^(ADMIN_EMAIL|ADMIN_PASSWORD|DEMO_USER_EMAIL|DEMO_USER_PASSWORD|S3_BUCKET|S3_ACCESS_KEY|S3_SECRET_KEY|S3_REGION)= ]]; then
    export "$line"
  fi
done < backend/.env

export DATABASE_URL="${DATABASE_URL_SEED:-postgresql://salmonz:salmonz@127.0.0.1:55432/salmonz?schema=public}"
export STORAGE_DRIVER=s3
export S3_ENDPOINT="${S3_ENDPOINT:-http://127.0.0.1:9000}"
export S3_BUCKET="${S3_BUCKET:-salmonz}"
export S3_ACCESS_KEY="${S3_ACCESS_KEY:-minioadmin}"
export S3_SECRET_KEY="${S3_SECRET_KEY:-minioadmin}"
export S3_FORCE_PATH_STYLE=true
export S3_REGION="${S3_REGION:-us-east-1}"
export ASSETS_ROOT="$ROOT/assets"
export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
export DEMO_USER_EMAIL="${DEMO_USER_EMAIL:-demo@example.com}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD missing in backend/.env}"
: "${DEMO_USER_PASSWORD:?DEMO_USER_PASSWORD missing in backend/.env}"

cd backend
npm run prisma:generate >/dev/null
npm run prisma:migrate:deploy
npm run prisma:seed

echo "== verify =="
python3 - <<'PY'
import json, urllib.request

def get(url, token=None):
  req = urllib.request.Request(url)
  if token:
    req.add_header('Authorization', f'Bearer {token}')
  with urllib.request.urlopen(req) as r:
    return json.load(r)

def post(url, body):
  req = urllib.request.Request(
    url,
    data=json.dumps(body).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST',
  )
  with urllib.request.urlopen(req) as r:
    return json.load(r)

admin = post('http://127.0.0.1:3000/api/v1/auth/login', {
  'email': 'admin@example.com',
  'password': 'ChangeMeAdmin123!',
})
demo = post('http://127.0.0.1:3000/api/v1/auth/login', {
  'email': 'demo@example.com',
  'password': 'ChangeMeDemo123!',
})
cats = get('http://127.0.0.1:3000/api/v1/categories')
prods = get('http://127.0.0.1:3000/api/v1/products?limit=100')
promos = get('http://127.0.0.1:3000/api/v1/promotions')
c_items = cats if isinstance(cats, list) else cats.get('data', [])
p_items = prods.get('data', prods if isinstance(prods, list) else [])
pr_items = promos if isinstance(promos, list) else promos.get('data', [])
print(f"admin login: ok ({admin['user']['role']})")
print(f"demo login:  ok ({demo['user']['role']})")
print(f"categories:  {len(c_items)} — {[c.get('name') for c in c_items]}")
print(f"products:    {len(p_items)}")
print(f"promotions:  {len(pr_items)} — {[p.get('title') for p in pr_items]}")
addrs = get('http://127.0.0.1:3000/api/v1/addresses', demo['accessToken'])
a_items = addrs if isinstance(addrs, list) else addrs.get('data', [])
print(f"demo addresses: {len(a_items)}")
PY

cat <<'EOF'

Готово. Запуск приложения:

  flutter run --dart-define-from-file=config/local.json

Логины:
  ADMIN  admin@example.com / ChangeMeAdmin123!
  USER   demo@example.com  / ChangeMeDemo123!

EOF
