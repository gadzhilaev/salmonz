![SALMONZ - магазин доставки суши](assets/SALMONZ%20-%20магазин%20доставки%20суши.png)

# SALMONZ — магазин доставки суши

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/NestJS-Backend-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS"/>
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <b>Портфолио / demo: Flutter-клиент + NestJS REST API</b>
</p>

---

## О проекте

**Salmonz** — кроссплатформенное приложение службы доставки японской кухни. Проект демонстрирует связку **Flutter + NestJS + Prisma + PostgreSQL** (аутентификация, каталог, заказы, админ-панель).

> Это **портфолио / demo**, а не production-ready продукт. Нет платежей, push-уведомлений, полноценного мониторинга и жёстких SLA. Не используйте как есть в реальной коммерческой эксплуатации без доработки.

Документация:

| Документ | Содержание |
|----------|------------|
| [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) | Локальный запуск |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Архитектура |
| [docs/API.md](docs/API.md) | Обзор REST API |
| [docs/BACKEND.md](docs/BACKEND.md) | NestJS backend |
| [docs/TESTING.md](docs/TESTING.md) | Тесты |
| [docs/SECURITY.md](docs/SECURITY.md) | Заметки по безопасности |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Вклад в проект |
| [SECURITY.md](SECURITY.md) | Сообщения об уязвимостях |

---

## Функциональность

### Для пользователей

| Функция | Описание |
|---------|----------|
| Аутентификация | Регистрация и вход (email/пароль), JWT access + refresh |
| Каталог | Категории и товары меню |
| Корзина | Локальная корзина (SharedPreferences) |
| Заказ | Адрес, телефон, комментарий; цены считает сервер |
| История заказов | Список и детали своих заказов |
| Профиль | Данные пользователя, аватар |
| Адреса | CRUD адресов доставки |
| Мультиязычность | RU / EN / ES |
| Акции | Промо-баннеры |
| Поддержка | Обращения в поддержку |

### Для администраторов

| Функция | Описание |
|---------|----------|
| Админ-панель | Роль `ADMIN` в Flutter-клиенте |
| Каталог | CRUD категорий, продуктов, акций |
| Заказы | Просмотр и смена статуса |
| Пользователи | Список пользователей |
| Поддержка | Обработка обращений |

---

## Архитектура

```
Flutter (Dio + secure storage)
        │  REST  /api/v1
        ▼
NestJS modular monolith
        │
   ┌────┴────┐
   ▼         ▼
PostgreSQL  Storage (local FS или S3/MinIO)
(Prisma 7)
```

Подробнее: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Стек

| Слой | Технологии |
|------|------------|
| Клиент | Flutter 3.9+, Dart 3, Dio, flutter_secure_storage, shared_preferences, image_picker |
| API | NestJS 11, Passport JWT, Argon2id, Swagger (`/docs`) |
| Данные | Prisma 7, PostgreSQL 16 |
| Файлы | `STORAGE_DRIVER=local` (по умолчанию) или S3-совместимое хранилище |
| Инфра (опц.) | Docker Compose: Postgres + MinIO + backend |

---

## Быстрый старт

### Требования

- Flutter SDK 3.9+
- Node.js 20+
- PostgreSQL 16 **или** Docker Compose

### Backend

```bash
# Вариант A: свой Postgres
cd backend
cp .env.example .env   # задайте DATABASE_URL и JWT_* секреты
npm ci
npm run prisma:generate
npm run prisma:migrate:deploy
npm run prisma:seed
npm run start:dev

# Вариант B: docker compose (из корня репо)
cp docker-compose.example.env .env
docker compose up --build
```

API: `http://localhost:3000/api/v1` · Swagger: `http://localhost:3000/docs`

### Flutter

```bash
cp config/local.example.json config/local.json
# Android emulator: API_BASE_URL=http://10.0.2.2:3000
# iOS / desktop:    API_BASE_URL=http://127.0.0.1:3000

flutter pub get
flutter run --dart-define-from-file=config/local.json
```

Секреты и URL **не** коммитятся: используйте `.env` / `config/local.json` (см. `.gitignore`).

Полная инструкция: [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md).

---

## Безопасность (кратко)

- Пароли: Argon2id; refresh-токены хранятся как хеши, с ротацией
- Регистрация создаёт только роль `USER` (нельзя самоназначить `ADMIN`)
- Заказы: серверный расчёт цен, проверка адреса владельца, idempotency key
- Токены на клиенте — в `flutter_secure_storage`

Подробнее: [docs/SECURITY.md](docs/SECURITY.md). Сообщения об уязвимостях: [SECURITY.md](SECURITY.md).

---

## Тесты

```bash
# Backend unit
cd backend && npm test && npm run lint && npm run build

# Flutter
flutter analyze
flutter test
```

См. [docs/TESTING.md](docs/TESTING.md).

---

## Ограничения demo

- Нет реальных платежей / эквайринга
- Нет push / email-рассылок
- Локальное хранилище файлов не рассчитано на прод-нагрузку
- Seed-учётки только для локальной разработки — смените пароли
- CI покрывает lint/unit; e2e с БД опционален

---

## Скриншоты

Скриншоты будут добавлены после QA.

---

## Лицензия

MIT — см. [LICENSE](LICENSE).

---

<p align="center">
  <img src="assets/icon/logo_salmonz_small.png" alt="Salmonz" width="60"/>
  <br/>
  <sub>Портфолио-проект · © Salmonz</sub>
</p>
