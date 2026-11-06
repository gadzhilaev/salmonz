# Security Policy

## Supported versions

This repository is a **portfolio / demo**. There is no formal support window. Fixes may be applied on a best-effort basis on the default branch.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security-sensitive findings.

Prefer GitHub **Security Advisories** / private vulnerability reporting (if enabled), or contact the repository owner via the profile email on GitHub.

Include: affected component, steps to reproduce, impact, and an optional suggested fix. There is no bug bounty program.

## Demo security model

- Passwords: **Argon2id**
- Auth: short-lived JWT **access** + rotating **refresh** (stored hashed; refresh reuse revokes the set)
- Registration always creates role `USER`
- Order prices and delivery fee are computed **on the server**
- Client tokens live in **flutter_secure_storage** — never put JWT/DB secrets in the Flutter app
- Uploads: jpeg/png/gif/webp with size limits; SVG rejected

## Operational hygiene

- Copy secrets from `backend/.env.example` / `docker-compose.example.env` — never commit real `.env`
- Change seed `ADMIN_*` / `DEMO_USER_*` before any shared environment
- Restrict `CORS_ORIGINS` when exposing the API beyond localhost

## Historical note

Early history prototyped with Supabase. The **current** stack is Flutter + NestJS + Prisma + PostgreSQL. Disable or rotate any old Supabase project keys if they still exist — removing a token from Git does not revoke it.
