# Testing

## Backend (`backend/`)

| Command | What |
|---------|------|
| `npm test` | Unit tests (Jest, no DB required) |
| `npm run lint` | ESLint |
| `npm run build` | Nest compile (`prisma generate` needed first) |
| `npm run test:e2e` | E2E (needs running Postgres / env; optional in CI) |

Unit coverage focuses on money rules, order status transitions, roles, password hashing, MIME checks.

```bash
cd backend
npm ci
npm run prisma:generate
npm test
npm run lint
npm run build
```

## Flutter (repo root)

| Command | What |
|---------|------|
| `flutter analyze` | Static analysis |
| `flutter test` | Widget / unit / contract tests |
| `flutter test integration_test` | Integration tests (device + live API) |
| `flutter build apk` | Optional Android artifact |

```bash
flutter pub get
flutter analyze
flutter test
```

Contract tests assert the client no longer depends on Supabase.

### Integration tests

Require a running local backend and a device/emulator. Pass API config via
`--dart-define-from-file=config/local.json` (copy from `config/local.example.json`).
For the Android emulator, `API_BASE_URL` should be `http://10.0.2.2:3000`.

```bash
flutter test integration_test -d emulator-5554 --dart-define-from-file=config/local.json
```

Individual suites:

```bash
flutter test integration_test/app_test.dart -d emulator-5554 --dart-define-from-file=config/local.json
flutter test integration_test/admin_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/local.json
```

Demo users (seeded by backend):

| Role | Email | Password |
|------|-------|----------|
| User | `demo@example.com` | `ChangeMeDemo123!` |
| Admin | `admin@example.com` | `ChangeMeAdmin123!` |

`app_test.dart` covers login validation, demo login, home → category → cart →
checkout quote (`quoteTotal`), and logout. Placing an order is optional and left
for manual QA when an address exists. `admin_smoke_test.dart` logs in as admin
and opens the admin panel.

If no emulator is available, integration tests still compile; run
`flutter analyze` and `flutter test` locally instead.

## CI

See `.github/workflows/backend.yml` and `.github/workflows/flutter.yml`.
