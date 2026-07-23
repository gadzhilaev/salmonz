-- Manual RLS smoke checks for local Supabase only.
-- Do NOT run against production.
--
-- Prerequisites:
-- 1) supabase start && supabase db reset
-- 2) Create two Auth users via Studio (email confirmations disabled in config.toml)
-- 3) Mark one admin:
--      update public."user" set is_admin = true where email = 'admin@example.test';
--    (service_role / SQL editor as postgres)
--
-- Then run sections below with set request.jwt.claim.sub / role as needed,
-- or use Supabase client integration tests.

-- Example expectations (document for humans):
-- * authenticated non-admin cannot update is_admin
-- * authenticated non-admin cannot insert into categories
-- * authenticated admin can insert into categories
-- * authenticated user A cannot select addresses of user B
-- * authenticated user A cannot select orders of user B
-- * anon can select products/categories/promotions
-- * anon cannot insert orders

-- Placeholder assertions for psql when connected as postgres:
do $$
begin
  if not exists (
    select 1 from pg_policies where tablename = 'user' and policyname = 'user_select_own'
  ) then
    raise exception 'RLS policy user_select_own missing';
  end if;
  if not exists (
    select 1 from pg_policies where tablename = 'orders' and policyname = 'orders_insert_own'
  ) then
    raise exception 'RLS policy orders_insert_own missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'is_admin'
  ) then
    raise exception 'function is_admin missing';
  end if;
  raise notice 'RLS smoke structural checks OK';
end $$;
