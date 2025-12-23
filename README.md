![SALMONZ - магазин доставки суши](assets/SALMONZ%20-%20магазин%20доставки%20суши.png)
# SALMONZ — магазин доставки суши

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <b>Мобильное приложение для доставки японской кухни</b>
</p>

---

## 📱 О проекте

**Salmonz** — это современное кроссплатформенное приложение для службы доставки японской кухни. Проект создан как демонстрация навыков разработки мобильных приложений на Flutter с полноценным бэкендом на Supabase.

> ⚠️ **Важно**: Это портфолио-проект. Все ключи API и подключения к базе данных оставлены открытыми намеренно для демонстрации работоспособности приложения. В реальном проекте они должны храниться в защищённых переменных окружения.

---

## ✨ Функциональность

### 👤 Для пользователей

| Функция | Описание |
|---------|----------|
| 🔐 **Аутентификация** | Регистрация и вход через email/пароль |
| 📋 **Каталог продуктов** | Категории: роллы, суши, сеты, лапша, напитки, соусы, закуски, десерты |
| 🛒 **Корзина** | Добавление товаров, изменение количества, локальное сохранение |
| 📦 **Оформление заказа** | Выбор адреса доставки, телефон, комментарий к заказу |
| 📜 **История заказов** | Просмотр всех заказов с детализацией |
| 👨‍💼 **Профиль** | Редактирование данных, загрузка аватара |
| 🏠 **Адреса доставки** | Добавление, редактирование, удаление адресов |
| 🌍 **Мультиязычность** | Поддержка русского, английского и испанского языков |
| 📣 **Акции** | Просмотр текущих промо-предложений |
| 💬 **Поддержка** | Форма обратной связи |

### 👨‍💻 Для администраторов

| Функция | Описание |
|---------|----------|
| 📊 **Панель управления** | Полноценная админ-панель |
| 🍜 **Управление продуктами** | CRUD операции над товарами |
| 📁 **Управление категориями** | Создание и редактирование категорий меню |
| 📦 **Управление заказами** | Просмотр и обработка всех заказов |
| 👥 **Управление пользователями** | Просмотр списка пользователей |
| 🎉 **Управление акциями** | Создание промо-баннеров |

---

## 🛠 Технологический стек

```
┌─────────────────────────────────────────────────────────────┐
│                          FRONTEND                           │
├─────────────────────────────────────────────────────────────┤
│  Flutter 3.9+            │  Кроссплатформенный UI фреймворк │
│  Dart 3.0+               │  Язык программирования           │
│  shared_preferences      │  Локальное хранилище данных      │
│  image_picker            │  Загрузка изображений            │
├─────────────────────────────────────────────────────────────┤
│                        BACKEND                              │
├─────────────────────────────────────────────────────────────┤
│  Supabase                │  Backend-as-a-Service            │
│  PostgreSQL              │  Реляционная база данных         │
│  Supabase Auth           │  Аутентификация пользователей    │
│  Supabase Storage        │  Хранение изображений            │
│  Realtime Subscriptions  │  Подписки на изменения в БД      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 Структура проекта

```
lib/
├── main.dart                 # Точка входа приложения
├── admin/                    # Админ-панель
│   ├── admin_panel_page.dart
│   ├── categories/           # Управление категориями
│   ├── orders/               # Управление заказами
│   ├── products/             # Управление продуктами
│   ├── promotions/           # Управление акциями
│   └── users/                # Управление пользователями
├── auth/                     # Аутентификация
│   ├── login.dart
│   └── register.dart
├── nav_bar/                  # Основные экраны навигации
│   ├── main_screen.dart      # Главный экран с категориями
│   ├── basket.dart           # Корзина
│   ├── orders.dart           # История заказов
│   └── profile.dart          # Профиль пользователя
├── pages/                    # Дополнительные страницы
│   ├── checkout_page.dart    # Оформление заказа
│   └── order_details_page.dart
├── products_pages/           # Страницы продуктов
│   ├── product.dart          # Детальная страница товара
│   └── products.dart         # Список товаров категории
├── profile/                  # Настройки профиля
│   ├── addresses_page.dart   # Управление адресами
│   ├── edit_profile_page.dart
│   ├── support_page.dart
│   └── legal/                # Юридические документы
├── utils/                    # Утилиты
│   ├── category.dart
│   ├── promo.dart
│   └── ru_phone_formatter.dart
└── widgets/                  # Переиспользуемые виджеты
    ├── app_nav_bar.dart      # Нижняя навигация
    └── cart.dart             # Синглтон корзины
```

---

## 🗄 Структура базы данных

```sql
-- Основные таблицы
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    user      │     │  categories  │     │   products   │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id (uuid)    │     │ id           │     │ id           │
│ email        │     │ title        │     │ name         │
│ name         │     │ type         │     │ description  │
│ phone        │     │ img          │     │ price        │
│ img          │     │ position     │     │ img          │
│ is_admin     │     └──────────────┘     │ type         │
│ lang         │                          │ gramm        │
└──────────────┘                          │ amount       │
                                          │ is_stock     │
┌──────────────┐     ┌──────────────┐     └──────────────┘
│   orders     │     │  addresses   │
├──────────────┤     ├──────────────┤     ┌──────────────┐
│ id           │     │ id           │     │  promotions  │
│ user_id      │     │ user_id      │     ├──────────────┤
│ product_list │     │ country      │     │ id           │
│ value_list   │     │ city         │     │ img          │
│ price_list   │     │ line         │     └──────────────┘
│ summ         │     │ created_at   │
│ address      │     └──────────────┘
│ phone        │
│ comment      │
│ created_at   │
└──────────────┘
```

---

## 🚀 Запуск проекта

### Предварительные требования

- Flutter SDK 3.9+
- Dart SDK 3.0+
- Android Studio / Xcode (для запуска на эмуляторах)

### Установка

```bash
# 1. Клонирование репозитория
git clone https://github.com/gadzhilaev/salmonz.git
cd salmonz

# 2. Установка зависимостей
flutter pub get

# 3. Запуск приложения
flutter run
```

### Сборка релиза

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🎨 Дизайн-система

### Цветовая палитра

| Цвет | HEX | Использование |
|------|-----|---------------|
| 🟠 Primary Orange | `#FF5E1C` | Кнопки, акценты, иконки |
| ⬛ Dark Text | `#26351E` | Заголовки |
| ⬜ Background | `#FFFFFF` | Фон страниц |
| 🔲 Tile Background | `#FAFAFA` | Фон карточек |
| ⚫ Secondary Text | `#282828` | Описания |

### Типографика

- **Шрифт**: Inter
- **Заголовки**: Inter Black (900), 24px, letter-spacing 4%
- **Подзаголовки**: Inter Bold (700), 18px
- **Основной текст**: Inter Medium/Regular (500/400), 14px

---

## 📸 Скриншоты

<p align="center">
  <i>Скриншоты приложения будут добавлены позже</i>
</p>

---

## 🔐 Конфигурация Supabase

> ⚠️ **Внимание**: Ключи ниже оставлены открытыми для демонстрации. В продакшене используйте переменные окружения!

```dart
// lib/main.dart
await Supabase.initialize(
  url: 'https://vwerkkbccwosrnkozgza.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

Для своего проекта создайте файл `.env`:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

---

## 📦 Зависимости

```yaml
dependencies:
  flutter: sdk
  supabase_flutter: ^2.5.7    # Backend & Auth
  shared_preferences: ^2.2.2   # Локальное хранение
  image_picker: ^1.0.7         # Выбор изображений
  cupertino_icons: ^1.0.8      # iOS иконки

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # Генерация иконок
  flutter_native_splash: ^2.4.0    # Splash screen
  flutter_lints: ^5.0.0            # Линтинг
```

---

## 🤝 Вклад в проект

Проект открыт для предложений и улучшений! 

1. Fork репозитория
2. Создайте ветку для фичи (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
4. Push в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

---

## 📄 Лицензия

Этот проект распространяется под лицензией **MIT**. Это означает, что вы можете свободно:

- ✅ Использовать в коммерческих проектах
- ✅ Модифицировать
- ✅ Распространять
- ✅ Использовать в частных проектах

Подробнее см. файл [LICENSE](LICENSE).

---

## 👨‍💻 Автор

<p align="center">
  <b>Разработано с ❤️ для демонстрации навыков мобильной разработки</b>
</p>

<p align="center">
  <i>Этот проект создан в качестве портфолио и демонстрирует владение технологиями Flutter, Dart и Supabase</i>
</p>

---

<p align="center">
  <img src="assets/icon/logo_salmonz_small.png" alt="Salmonz" width="60"/>
  <br/>
  <sub>© 2024 Salmonz. All rights reserved.</sub>
</p>
