-- Demo seed only. No real PII.
-- Images use public placeholders (not production assets).
-- Auth users / admin accounts are NOT created here (no passwords in repo).
--
-- To create a local admin after signup:
--   update public."user" set is_admin = true where email = 'your-local-demo@example.com';
-- Run that as postgres/service_role in local Studio SQL, never from the Flutter client.

truncate table public.support_messages restart identity cascade;
truncate table public.orders restart identity cascade;
truncate table public.addresses restart identity cascade;
truncate table public.products restart identity cascade;
truncate table public.promotions restart identity cascade;
truncate table public.categories restart identity cascade;
-- Do not truncate public."user" — linked to auth.users from local signups.

insert into public.categories (title, type, img, position) values
  ('Роллы', 'rolls', 'https://placehold.co/600x400/png?text=Rolls', 1),
  ('Суши', 'sushi', 'https://placehold.co/600x400/png?text=Sushi', 2),
  ('Сеты', 'sets', 'https://placehold.co/600x400/png?text=Sets', 3),
  ('Напитки', 'drinks', 'https://placehold.co/600x400/png?text=Drinks', 4),
  ('Десерты', 'deserts', 'https://placehold.co/600x400/png?text=Desserts', 5);

insert into public.products (name, description, price, img, type, gramm, amount, is_stock) values
  ('Филадельфия', 'Лосось, сыр, огурец', 459.00, 'https://placehold.co/600x400/png?text=Philadelphia', 'rolls', 270, 8, true),
  ('Калифорния', 'Краб, авокадо, огурец', 399.00, 'https://placehold.co/600x400/png?text=California', 'rolls', 250, 8, true),
  ('Дракон', 'Угорь, авокадо, унаги соус', 529.00, 'https://placehold.co/600x400/png?text=Dragon', 'rolls', 280, 8, true),
  ('Лосось нигири', 'Рис, лосось', 149.00, 'https://placehold.co/600x400/png?text=Salmon+Nigiri', 'sushi', 40, 1, true),
  ('Унаги нигири', 'Рис, угорь', 169.00, 'https://placehold.co/600x400/png?text=Unagi', 'sushi', 45, 1, true),
  ('Сет №1', 'Ассорти роллов на компанию', 1299.00, 'https://placehold.co/600x400/png?text=Set+1', 'sets', 900, 1, true),
  ('Сет №2', 'Ролл + суши', 999.00, 'https://placehold.co/600x400/png?text=Set+2', 'sets', 750, 1, true),
  ('Морс клюквенный', 'Домашний морс 0.5 л', 120.00, 'https://placehold.co/600x400/png?text=Mors', 'drinks', 500, 1, true),
  ('Зелёный чай', 'Чай в чайнике', 90.00, 'https://placehold.co/600x400/png?text=Tea', 'drinks', 400, 1, true),
  ('Чизкейк', 'Классический чизкейк', 249.00, 'https://placehold.co/600x400/png?text=Cheesecake', 'deserts', 120, 1, true),
  ('Тропический ролл', 'Банан, киви (нет в наличии)', 320.00, 'https://placehold.co/600x400/png?text=OOS', 'deserts', 200, 6, false);

insert into public.promotions (img) values
  ('https://placehold.co/800x300/png?text=Promo+Delivery'),
  ('https://placehold.co/800x300/png?text=Promo+Sets');
