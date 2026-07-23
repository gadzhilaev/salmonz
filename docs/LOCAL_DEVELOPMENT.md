# Local development

Run NestJS API + Flutter client against a local stack.

## 1. Start backend

```bash
cd backend
cp .env.example .env   # first time only
npm ci
npm run prisma:generate
npm run prisma:migrate:deploy
npm run prisma:seed
npm run start:dev
```

API: `http://localhost:3000/api/v1`  
Swagger: `http://localhost:3000/docs`

## 2. Configure Flutter

Copy the example config:

```bash
cp config/local.example.json config/local.json
```

Edit `API_BASE_URL`:

| Target | URL |
|--------|-----|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator / desktop | `http://127.0.0.1:3000` |
| Physical device | `http://<your-lan-ip>:3000` |

## 3. Run the app

```bash
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

Tokens are stored in **flutter_secure_storage**. Cart stays in SharedPreferences (local only).

## Seed admin

See backend seed output / `docs/BACKEND.md` for the default admin credentials.
