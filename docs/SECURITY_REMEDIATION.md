# Security remediation (Salmonz)

No key values are listed in this document.

## What was found

- A Supabase project URL and **publishable (anon)** key were previously hardcoded in the Flutter client and present in Git history.
- SQL migrations, RLS policies, Storage policies, and seed were missing from the repository.
- Admin capability was gated mainly by a client-readable `user.is_admin` flag.
- Admin editors used `signInAnonymously()` as a workaround for uploads.
- Live project RLS status was **not verified** in the audit (and must not be assumed safe).

## Publishable key vs service-role key

- The **publishable / anon** key is intended for mobile/web clients.
- Data safety depends on **PostgreSQL grants + Row Level Security**, not on hiding the anon key.
- The **service-role / secret** key bypasses RLS and must **never** be shipped in a Flutter app, CI logs for client builds, or public docs.

See Supabase docs: [API keys](https://supabase.com/docs/guides/getting-started/api-keys), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

## Why create a new demo project anyway

Even when only the publishable key leaked:

1. Anyone can call the Data API as `anon` / with their own signups.
2. If live RLS was incomplete, data may already be exposed.
3. A public portfolio should use a **disposable demo** project (or local Supabase), not a personal production database.
4. Rotating keys on a compromised project is still recommended after inspection.

## Owner checklist

1. Create a **new** Supabase project for public demo (or use local CLI only).
2. Apply `supabase/migrations` and load `supabase/seed.sql` (or `supabase db reset` locally).
3. Configure Flutter via `config/local.json` / `--dart-define` (see `docs/LOCAL_BACKEND.md`).
4. On the **old** project: review Auth users, tables, Storage; tighten or disable; rotate publishable key if the project remains online.
5. Search Git history yourself for strings like `service_role`, `sb_secret_`, private keys, and service-account JSON.
6. If a **service-role / secret** key ever appeared in Git or chat logs: **revoke it immediately** in the Supabase dashboard. Do not paste it into issues or commits.
7. Treat Git history rewrite as a **separate** decision (filter-repo / new orphan repo). This stage intentionally does **not** rewrite history.
8. Confirm image/asset licensing before marketing screenshots.

## What this stage changed in the repo

- Client reads URL + publishable key only from compile-time defines.
- No service-role usage in Flutter.
- Local schema + RLS + Storage policies + demo seed checked into `supabase/`.
- Admin anonymous sign-in removed; admin writes rely on authenticated session + RLS.

## What this stage did **not** do

- Did not call or modify the old live Supabase project.
- Did not rotate remote keys (owner action).
- Did not rewrite Git history.
- Did not claim the checkout path is production-secure (client-trusted prices remain a known risk).
