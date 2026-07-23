# Local backend (Salmonz)

Portfolio-safe local Supabase workflow. **Never** point these commands at production.

## Requirements

- Flutter SDK (project `pubspec.yaml` constraint)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker Desktop (required by `supabase start`)

This machine may not have CLI/Docker yet — install them before running the steps below.

## Start local stack

```bash
cd salmonz
supabase start
supabase db reset
```

`db reset` applies `supabase/migrations/*` and then `supabase/seed.sql`.

## Keys for Flutter

After `supabase start`, the CLI prints local API URL and **publishable (anon)** key.

Copy them into a gitignored file:

```bash
cp config/local.example.json config/local.json
# edit config/local.json with local URL + publishable key only
```

Never put the **service_role / secret** key into Flutter or into git.

## Run the app

```bash
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

Equivalent explicit defines:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<local-publishable-key> \
  --dart-define=APP_ENV=local \
  --dart-define=APP_DEMO=true
```

## Demo admin (local only)

Seed does **not** create Auth users or passwords.

1. Sign up in the app (or Studio Auth).
2. In local Studio SQL (as postgres / service role):

```sql
update public."user"
set is_admin = true
where email = 'your-local-demo@example.com';
```

Clients cannot set `is_admin` (column grants + trigger + RLS).

## Reset only local data

```bash
supabase db reset
```

This wipes the **local** database and re-seeds. It does not touch cloud projects.

## Forbidden without a separate explicit decision

- `supabase db push` / link to an old live project
- remote `db reset` / remote seed
- using production URL/keys in day-to-day development
- putting service_role into the mobile client

## RLS smoke SQL

Structural checks live in `supabase/tests/rls_smoke.sql` (run against local DB only).
