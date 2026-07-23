# Salmonz NestJS Backend

Primary API for Salmonz. The Flutter app will migrate from Supabase to this NestJS service.

## Legacy note

The `supabase/` directory is **transitional / legacy**. Prefer this NestJS backend (`backend/`) for new work. Do not treat Supabase migrations or RLS as the long-term source of truth once the Nest cutover is complete.

## Stack

- NestJS 11 modular monolith
- Prisma 7 + PostgreSQL 16
- Argon2id passwords, JWT access + rotating refresh tokens
- S3-compatible object storage (MinIO locally)
- Swagger UI at `/docs`
- Global API prefix: `/api/v1`

## Quick start (local, no Docker on host)

1. Provide PostgreSQL and MinIO (or use `docker-compose.yml` on a machine that has Docker).
2. Copy env:

```bash
cp backend/.env.example backend/.env
# edit secrets
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
| `npm run build` | Compile |

## Delivery fee

Server-side rule (RUB): delivery fee is **0** when order subtotal ≥ **1500**, otherwise **249**.

## Auth highlights

- Register always creates `USER` (cannot self-assign `ADMIN`)
- Refresh tokens stored as SHA-256 hashes only
- Refresh rotation; reuse of a revoked token revokes all user refresh tokens and is rejected

## Storage keys

- Avatars: `avatars/{userId}/{uuid}.ext`
- Products / promotions: `products/{uuid}.ext`, `promotions/...`
- Allowed MIME: jpeg, png, gif, webp — max 5MB — SVG rejected
