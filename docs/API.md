# Salmonz API overview

Base URL: `/api/v1`  
Swagger UI: `/docs`  
OpenAPI export: `docs/openapi.json` (via `npm run openapi:export` in `backend/`)

Authenticate with `Authorization: Bearer <accessToken>` where noted.

## Pagination

List endpoints return `{ data, meta }` (not `items`):

```json
{
  "data": [],
  "meta": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 }
}
```

Query params: `page` (default 1), `limit` (default 20, max 100).

## Auth

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/auth/register` | — | Creates USER only |
| POST | `/auth/login` | — | Returns access + refresh |
| POST | `/auth/refresh` | — | Rotates refresh token |
| POST | `/auth/logout` | — | Revokes one refresh token |
| POST | `/auth/logout-all` | Bearer | Revokes all refresh tokens |
| GET | `/auth/me` | Bearer | Current user |

## Users

| Method | Path | Auth |
|--------|------|------|
| GET | `/users/me` | Bearer |
| PATCH | `/users/me` | Bearer |
| POST | `/users/me/avatar` | Bearer (multipart `file`) |

## Catalog (public)

| Method | Path |
|--------|------|
| GET | `/categories` |
| GET | `/categories/:idOrSlug` |
| GET | `/products` |
| GET | `/products/:id` |
| GET | `/promotions` |

## Addresses

| Method | Path | Auth |
|--------|------|------|
| GET/POST | `/addresses` | Bearer |
| GET/PATCH/DELETE | `/addresses/:id` | Bearer |

## Orders

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/orders` | Bearer | Server-priced; idempotencyKey |
| GET | `/orders` | Bearer | |
| GET | `/orders/:id` | Bearer | |

Create body: `addressId`, `phone`, `comment?`, `items[{productId,quantity}]`, `idempotencyKey`.

Delivery fee: `0` if subtotal ≥ 1500 else `249` (RUB).

## Support

| Method | Path | Auth |
|--------|------|------|
| POST/GET | `/support` | Bearer |
| GET | `/support/:id` | Bearer |

## Admin (role `ADMIN`)

| Method | Path |
|--------|------|
| CRUD | `/admin/categories`, `/admin/products`, `/admin/promotions` |
| GET | `/admin/orders`, `/admin/orders/:id` |
| PATCH | `/admin/orders/:id/status` |
| GET | `/admin/support` |
| PATCH | `/admin/support/:id/status` |
| GET | `/admin/users` |

### Order status transitions

- `NEW` → `CONFIRMED` \| `CANCELLED`
- `CONFIRMED` → `PREPARING` \| `CANCELLED`
- `PREPARING` → `READY`
- `READY` → `DELIVERING` \| `COMPLETED`
- `DELIVERING` → `COMPLETED`
- Terminal: `COMPLETED`, `CANCELLED`

## Health

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | DB ping |
| GET | `/health/live` | Liveness only |
