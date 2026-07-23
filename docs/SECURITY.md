# Security notes (demo)

This project is a **portfolio demo**. Treat defaults as development-only.

## Auth

- Passwords hashed with **Argon2id**
- Short-lived JWT **access** + rotating **refresh** tokens
- Refresh tokens stored as **SHA-256 hashes** only; reuse of a revoked refresh invalidates the user's refresh set
- `POST /auth/register` always creates role `USER`

## Orders

- Prices and delivery fee are calculated **on the server**
- Address must belong to the authenticated user
- Create uses **idempotencyKey** (unique per user)

## Client

- Access/refresh tokens in **flutter_secure_storage**
- Never put JWT secrets or DB credentials in the Flutter app / `--dart-define`
- `API_BASE_URL` is a public endpoint base, not a secret

## Storage uploads

- Allowed images: jpeg, png, gif, webp; size limit enforced; SVG rejected
- Prefer `STORAGE_DRIVER=local` for laptop demos; use S3-compatible storage when you need object storage

## Operational hygiene

- Copy secrets from `backend/.env.example` / `docker-compose.example.env` — never commit real `.env`
- Change seed `ADMIN_*` / `DEMO_USER_*` passwords
- Restrict `CORS_ORIGINS` when exposing the API beyond localhost

Report vulnerabilities via [SECURITY.md](../SECURITY.md).

## Git history note (public release)

A historical scan found a **likely project Supabase anon/publishable JWT** and `supabase.co` URL in early commits (`bbf8b85`, `98830d3`, `lib/main.dart`).

- Current working tree no longer embeds that key (REST + dart-define only).
- Before making the repository public: **revoke** the old Supabase key in the project dashboard, then decide on history cleanup (filter-repo / new orphan branch). Do **not** force-push casually.
- Working-tree mentions of `supabase` remain only in tests that forbid reintroduction.

