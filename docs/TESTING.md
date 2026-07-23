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
| `flutter build apk` | Optional Android artifact |

```bash
flutter pub get
flutter analyze
flutter test
```

Contract tests assert the client no longer depends on Supabase.

## CI

See `.github/workflows/backend.yml` and `.github/workflows/flutter.yml`.
