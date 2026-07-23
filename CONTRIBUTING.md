# Contributing

Thanks for interest in Salmonz. This is a portfolio / demo project — small, focused PRs are welcome.

## Setup

Follow [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md).

## Workflow

1. Fork and create a branch (`feature/...`, `fix/...`, `docs/...`).
2. Keep changes scoped (docs, Flutter, or `backend/` as appropriate).
3. Run checks before opening a PR:

```bash
# Backend
cd backend && npm ci && npm run prisma:generate && npm test && npm run lint && npm run build

# Flutter (repo root)
flutter pub get && flutter analyze && flutter test
```

4. Open a PR using the template; describe *why* and how you tested.

## Guidelines

- Do not commit secrets (`.env`, `config/local.json`, keys, passwords).
- Do not reintroduce Supabase client SDKs or anon keys in the Flutter app.
- Prefer matching existing code style (Prettier/ESLint, `flutter_lints`).
- Be respectful — see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Security issues

Please use [SECURITY.md](SECURITY.md) instead of a public issue for vulnerabilities.
