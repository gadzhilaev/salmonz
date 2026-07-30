# Local development

NestJS API + Flutter client against a local stack. No cloud SaaS required.

## Prerequisites

- Node.js **20+**
- Flutter **3.9+**
- PostgreSQL **16** **or** Docker (Compose)
- **Git LFS** for image assets: `git lfs install && git lfs pull`

## Option A — Postgres on the host + local storage

1. Create a database (example name `salmonz`).
2. Configure backend env:

```bash
cd backend
cp .env.example .env
```

Edit at least:

- `DATABASE_URL`
- `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` (non-empty, long random strings)
- `STORAGE_DRIVER=local` (default) and `PUBLIC_MEDIA_BASE_URL`

3. Install, migrate, seed, run:

```bash
npm ci
npm run prisma:generate
npm run prisma:migrate:deploy
npm run prisma:seed
npm run start:dev
```

- API: `http://localhost:3000/api/v1`
- Swagger: `http://localhost:3000/docs`
- Media (local driver): `http://localhost:3000/media/...`

Seed prints admin / demo user credentials from your `.env` (`ADMIN_*`, `DEMO_USER_*`). Change them before any shared environment.

## Option B — Docker Compose

From the repo root:

```bash
cp docker-compose.example.env .env
# set JWT_ACCESS_SECRET and JWT_REFRESH_SECRET (long random strings)
docker compose up --build
```

Services: `postgres`, `minio`, `minio-init`, `backend`.

The backend container runs **Prisma migrate deploy** and **seed** on start (`docker-entrypoint.sh`), then serves the API with `STORAGE_DRIVER=s3` (MinIO) by default.

For a **host-run** Nest process with only DB/MinIO in Compose, start `postgres` (and optionally `minio`) and point `backend/.env` at `localhost` with `STORAGE_DRIVER=local`.

## Flutter

```bash
cp config/local.example.json config/local.json
```

Set `API_BASE_URL` (scheme + host + port, **without** `/api/v1`):

| Target | Example |
|--------|---------|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator / desktop | `http://127.0.0.1:3000` |
| Physical device | `http://<lan-ip>:3000` |

```bash
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

Tokens use **flutter_secure_storage**. Cart remains in SharedPreferences (device-local).

Do not commit `config/local.json` or `backend/.env`.

## Useful links

- API overview: [API.md](API.md)
- Backend notes: [BACKEND.md](BACKEND.md)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
