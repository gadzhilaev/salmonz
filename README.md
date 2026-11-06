![SALMONZ - магазин доставки суши](assets/SALMONZ%20-%20магазин%20доставки%20суши.png)

# SALMONZ — магазин доставки суши

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/NestJS-Backend-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS"/>
  <img src="https://img.shields.io/badge/Next.js-Admin-000000?style=for-the-badge&logo=nextdotjs&logoColor=white" alt="Next.js"/>
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
  <a href="https://github.com/gadzhilaev/salmonz/actions/workflows/flutter.yml"><img src="https://github.com/gadzhilaev/salmonz/actions/workflows/flutter.yml/badge.svg" alt="Flutter CI"/></a>
  <a href="https://github.com/gadzhilaev/salmonz/actions/workflows/backend.yml"><img src="https://github.com/gadzhilaev/salmonz/actions/workflows/backend.yml/badge.svg" alt="Backend CI"/></a>
</p>

<p align="center">
  <b>Портфолио / demo: Flutter · NestJS · Next.js admin · PostgreSQL</b>
</p>

---

## О проекте

**Salmonz** — demo службы доставки японской кухни. Стек: **Flutter** (iOS/Android), **NestJS + Prisma + PostgreSQL**, админ-панель **Next.js** (`admin-web`).

> Это **портфолио / demo**, а не production-ready продукт. Нет платежей, push и жёстких SLA. Не используйте как есть в коммерческой эксплуатации без доработки.

Документация: [LOCAL_DEVELOPMENT](docs/LOCAL_DEVELOPMENT.md) · [ARCHITECTURE](docs/ARCHITECTURE.md) · [API](docs/API.md) · [TESTING](docs/TESTING.md) · [SECURITY](SECURITY.md) · [CONTRIBUTING](CONTRIBUTING.md)

---

## Скриншоты

| Login (iPhone) | Home (iPhone) | Profile dark (iPhone) |
|---|---|---|
| ![login phone](docs/screenshots/01_login.png) | ![home phone](docs/screenshots/02_home_light.png) | ![profile dark](docs/screenshots/05_profile_dark.png) |

| Login (iPad) | Home (iPad landscape) | Cart (iPad) |
|---|---|---|
| ![login ipad](docs/screenshots/09_ipad.png) | ![home ipad](docs/screenshots/11_ipad_home_landscape.png) | ![cart ipad](docs/screenshots/14_ipad_cart.png) |

| Category (iPad) | Offline / Retry (iPhone) |
|---|---|
| ![category ipad](docs/screenshots/15_ipad_category.png) | ![offline](docs/screenshots/16_offline_home.png) |

Снято на iOS Simulator против локального Docker API. На iPad ≥840 логических pt используется `NavigationRail`. Админ-панель — отдельное Next.js-приложение (`admin-web/`), не Flutter.

<p align="center">
  <a href="https://github.com/gadzhilaev/salmonz/actions/workflows/backend-e2e.yml"><img src="https://github.com/gadzhilaev/salmonz/actions/workflows/backend-e2e.yml/badge.svg" alt="Backend E2E"/></a>
</p>

---

## Функциональность

### Пользователь (Flutter)

| Функция | Описание |
|---------|----------|
| Аутентификация | Email/пароль, JWT access + refresh, secure storage |
| Каталог | Категории и товары |
| Корзина | Локально (SharedPreferences) |
| Заказ | Адрес, телефон, комментарий; цены считает сервер (`/orders/quote`) |
| Idempotency | Повторный submit с тем же ключом не создаёт дубликат |
| История заказов | Список и детали |
| Профиль / адреса / support | CRUD адреса, аватар, обращения |
| Тема | System / light / dark |

### Администратор (admin-web)

| Функция | Описание |
|---------|----------|
| Вход | BFF + HttpOnly cookies, роль `ADMIN` |
| Каталог | CRUD категорий, продуктов, акций + upload изображений |
| Заказы | Список и смена статуса |
| Пользователи / support | Просмотр и обработка |

---

## Архитектура

```
Flutter (Dio + flutter_secure_storage)     admin-web (Next.js BFF)
        │  REST  /api/v1                            │
        └────────────────┬──────────────────────────┘
                         ▼
              NestJS · Swagger /docs
                         │
              ┌──────────┴──────────┐
         PostgreSQL            Storage: FS / S3/MinIO
              (Prisma)
```

Подробнее: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Быстрый старт

### Требования

- Flutter SDK 3.9+, Node.js 20+, Docker (рекомендуется)
- **Git LFS** (`git lfs install && git lfs pull`) — PNG-ассеты хранятся в LFS

### Backend (Docker Compose)

```bash
cp docker-compose.example.env .env   # задайте JWT_* (длинные случайные строки)
docker compose up --build
```

Сервисы: `postgres`, `minio`, `minio-init`, `backend` (migrate + seed при старте).

- API: `http://localhost:3000/api/v1`
- Swagger: `http://localhost:3000/docs`
- MinIO console: `http://localhost:9001`

Альтернатива без Docker backend: Postgres в Compose + `STORAGE_DRIVER=local`, см. [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md).

### Flutter

```bash
cp config/local.example.json config/local.json
# iOS Simulator: http://127.0.0.1:3000
# Android emulator: http://10.0.2.2:3000

flutter pub get
flutter run
# optional: flutter run --dart-define-from-file=config/local.json
```

### Admin-web

```bash
cd admin-web
cp .env.example .env.local   # API_BASE_URL → Nest
npm ci && npm run dev
```

Demo-учётки после seed (только локально, **смените** перед любым shared env):

| Role | Email | Password |
|------|-------|----------|
| USER | `t@test.ru` | `12345678` |
| ADMIN | `admin@example.com` | `ChangeMeAdmin123!` |

Секреты не коммитятся: `.env`, `backend/.env`, `config/local.json`, `admin-web/.env.local` в `.gitignore`.

---

## Тесты

```bash
# Backend
cd backend && npm ci && npm run prisma:generate
npm test && npm run lint && npm run build
RUN_E2E=1 npm run test:e2e   # нужен живой API + seed

# Flutter
flutter analyze && flutter test

# Admin-web
cd admin-web && npm ci && npm run lint && npm run build
```

CI: `.github/workflows/backend.yml`, `.github/workflows/flutter.yml`, `.github/workflows/backend-e2e.yml`.

---

## Storage

| `STORAGE_DRIVER` | Поведение |
|------------------|-----------|
| `local` (host-run default) | Файлы в `backend/uploads`, URL `/media/...` |
| `s3` (Compose default) | MinIO/S3-compatible bucket |

---

## Ограничения demo

- Нет эквайринга / push / email
- Seed-пароли только для локальной разработки
- Ранняя Git history могла содержать старый Supabase anon JWT — в текущем HEAD его нет; при необходимости отключите/ротируйте старый Supabase-проект

---

## Лицензия

MIT — [LICENSE](LICENSE).
