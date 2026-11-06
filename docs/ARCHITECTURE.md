# Architecture

Salmonz is a **portfolio / demo** stack: Flutter mobile client, Next.js admin, NestJS API, PostgreSQL.

```
┌──────────────────────┐     ┌──────────────────────┐
│ Flutter (iOS/Android)│     │ admin-web (Next.js)  │
│ Dio + secure storage │     │ BFF + HttpOnly cookies│
└──────────┬───────────┘     └──────────┬───────────┘
           │  REST /api/v1               │
           └─────────────┬───────────────┘
                         ▼
              ┌─────────────────────┐
              │ NestJS · Swagger    │
              │ /api/v1 · /docs     │
              └──────────┬──────────┘
                   ┌─────┴─────┐
                   ▼           ▼
             PostgreSQL    Storage (FS / S3/MinIO)
               Prisma
```

## Responsibilities

| Layer | Role |
|-------|------|
| Flutter | User UI, cart (local), checkout against server quote |
| admin-web | Admin CRUD, orders, users, support (role `ADMIN`) |
| NestJS | Auth, validation, pricing, order status, uploads |
| Prisma / PostgreSQL | Users, refresh tokens, catalog, orders, support |
| Storage | Avatars and catalog images (`STORAGE_DRIVER=local` or `s3`) |

## Design notes

- **Server-priced orders** — client sends product IDs + quantities; API computes prices and delivery fee
- **Roles** — `USER` / `ADMIN`; self-registration is always `USER`
- **Pagination** — `{ data, meta }` (`page`, `limit`, `total`, `totalPages`)
- **Idempotent order create** — `idempotencyKey` per user
- **Auth refresh** — single-flight client refresh; server detects refresh-token reuse

Backend layout: Nest modules under `backend/src/` (`auth`, `catalog`, `orders`, `users`, `support`, `admin`, `storage`). Env templates: `backend/.env.example`, `docker-compose.example.env`.

Not production infrastructure: no CDN, multi-region HA, or payment gateway in this repo.
