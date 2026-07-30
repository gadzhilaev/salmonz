# Salmonz NestJS Backend

Primary API for Salmonz. The Flutter client talks to this NestJS service over REST (`/api/v1`).

For running API + Flutter locally, see [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md).

## Stack

- NestJS 11 modular monolith
- Prisma 7 + PostgreSQL 16
- Argon2id passwords, JWT access + rotating refresh tokens
- Storage: **`STORAGE_DRIVER=local`** (filesystem under `LOCAL_UPLOAD_DIR`, served via `PUBLIC_MEDIA_BASE_URL`) **or** `s3` (MinIO/AWS-compatible)
- Swagger UI at `/docs`
- Global API prefix: `/api/v1`

## Quick start (local, no Docker on host)

1. Provide PostgreSQL. For images, keep `STORAGE_DRIVER=local` (default in `.env.example`) or run MinIO and set `STORAGE_DRIVER=s3`.
2. Copy env:

```bash
cp backend/.env.example backend/.env
# set DATABASE_URL and JWT_* secrets
```

3. Install & generate & migrate & seed:

```bash
cd backend
npm ci
npm run prisma:generate
npm run prisma:migrate:deploy
npm run prisma:seed
npm run start:dev
```

4. Open Swagger: http://localhost:3000/docs

## Docker Compose

From repo root (requires Docker):

```bash
cp docker-compose.example.env .env
docker compose up --build
```

Services: `postgres`, `minio`, `minio-init`, `backend`.

## Scripts

| Script | Purpose |
|--------|---------|
| `npm run prisma:generate` | Generate Prisma Client |
| `npm run prisma:migrate:dev` | Dev migrations |
| `npm run prisma:migrate:deploy` | Apply migrations |
| `npm run prisma:seed` | Seed catalog + admin |
| `npm run openapi:export` | Write `docs/openapi.json` |
| `npm test` | Unit tests (no DB) |
| `npm run lint` | ESLint |
| `npm run build` | Compile |
| `npm run test:e2e` | E2E (needs DB; optional) |

## Delivery fee

Server-side rule (RUB): delivery fee is **0** when order subtotal ≥ **1500**, otherwise **249**.

## Auth highlights

- Register always creates `USER` (cannot self-assign `ADMIN`)
- Refresh tokens stored as SHA-256 hashes only
- Refresh rotation; reuse of a revoked token revokes all user refresh tokens and is rejected

## Pagination

List endpoints return:

```json
{
  "data": [ /* … */ ],
  "meta": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 }
}
```

Query: `?page=1&limit=20` (limit max 100).

## Storage keys

- Avatars: `avatars/{userId}/{uuid}.ext`
- Products / promotions: `products/{uuid}.ext`, `promotions/...`
- Allowed MIME: jpeg, png, gif, webp — max 5MB — SVG rejected
