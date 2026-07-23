# Architecture

Salmonz is a **portfolio / demo** modular stack: mobile client + REST API + PostgreSQL.

```
┌─────────────────────┐
│  Flutter app        │  Dio HTTP client, JWT in secure storage,
│  (lib/)             │  local cart (SharedPreferences)
└──────────┬──────────┘
           │  HTTPS/HTTP  Authorization: Bearer <access>
           ▼
┌─────────────────────┐
│  NestJS (/api/v1)   │  Auth, users, catalog, addresses,
│  Swagger /docs      │  orders, support, admin modules
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
 PostgreSQL   Storage
 (Prisma)     local FS  or  S3-compatible (MinIO/AWS)
```

## Responsibilities

| Layer | Role |
|-------|------|
| Flutter | UI, navigation, admin screens for `ADMIN`, offline cart |
| NestJS | AuthZ/AuthN, validation, pricing, order status machine, uploads |
| Prisma / PostgreSQL | Users, refresh tokens, catalog, orders, support |
| Storage | Avatars, product/promotion images (`STORAGE_DRIVER=local` or `s3`) |

## Design notes

- **Server-priced orders** — client sends product IDs + quantities; prices and delivery fee are computed on the API.
- **Roles** — `USER` / `ADMIN`; self-registration is always `USER`.
- **Pagination** — list endpoints return `{ data, meta }` (`page`, `limit`, `total`, `totalPages`).
- **Idempotent order create** — `idempotencyKey` per user.

Not production infrastructure: no CDN, multi-region HA, or payment gateway in this repo.
