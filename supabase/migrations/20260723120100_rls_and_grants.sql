-- Grants + RLS for Salmonz public tables.
-- Publishable/anon key is safe only with these policies + grants.

-- ---------------------------------------------------------------------------
-- Reset default privileges: revoke broad public access, then grant minimally.
-- ---------------------------------------------------------------------------
revoke all on table public."user" from anon, authenticated;
revoke all on table public.categories from anon, authenticated;
revoke all on table public.products from anon, authenticated;
revoke all on table public.promotions from anon, authenticated;
revoke all on table public.addresses from anon, authenticated;
revoke all on table public.orders from anon, authenticated;
revoke all on table public.support_messages from anon, authenticated;

-- Catalog read for guests + signed-in users
grant select on table public.categories to anon, authenticated;
grant select on table public.products to anon, authenticated;
grant select on table public.promotions to anon, authenticated;

-- Catalog write: authenticated only (RLS further restricts to admins)
grant insert, update, delete on table public.categories to authenticated;
grant insert, update, delete on table public.products to authenticated;
grant insert, update, delete on table public.promotions to authenticated;

-- Profile: select own/admin via RLS; column-level update excludes is_admin
grant select on table public."user" to authenticated;
grant update (name, email, phone, img, lang, birthdate) on table public."user" to authenticated;

-- Addresses / orders / support
grant select, insert, update, delete on table public.addresses to authenticated;
grant select, insert on table public.orders to authenticated;
grant select, insert on table public.support_messages to authenticated;

-- Sequences for identity columns
grant usage, select on all sequences in schema public to authenticated;

-- Functions
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
-- handle_new_user / prevent_* are trigger-only; no client execute needed
revoke all on function public.handle_new_user() from public;
revoke all on function public.prevent_is_admin_escalation() from public;
revoke all on function public.set_updated_at() from public;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
alter table public."user" enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.promotions enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.support_messages enable row level security;

-- Force RLS for table owners in API contexts (supabase roles still respect policies)
alter table public."user" force row level security;
alter table public.categories force row level security;
alter table public.products force row level security;
alter table public.promotions force row level security;
alter table public.addresses force row level security;
alter table public.orders force row level security;
alter table public.support_messages force row level security;

-- ---------------------------------------------------------------------------
-- user
-- ---------------------------------------------------------------------------
create policy user_select_own
  on public."user"
  for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

create policy user_update_own_safe_cols
  on public."user"
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- No insert policy for authenticated: profile comes from trigger only.
-- No delete policy for clients.

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
create policy categories_select_all
  on public.categories
  for select
  to anon, authenticated
  using (true);

create policy categories_insert_admin
  on public.categories
  for insert
  to authenticated
  with check (public.is_admin());

create policy categories_update_admin
  on public.categories
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy categories_delete_admin
  on public.categories
  for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
create policy products_select_all
  on public.products
  for select
  to anon, authenticated
  using (true);

create policy products_insert_admin
  on public.products
  for insert
  to authenticated
  with check (public.is_admin());

create policy products_update_admin
  on public.products
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy products_delete_admin
  on public.products
  for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- promotions
-- ---------------------------------------------------------------------------
create policy promotions_select_all
  on public.promotions
  for select
  to anon, authenticated
  using (true);

create policy promotions_insert_admin
  on public.promotions
  for insert
  to authenticated
  with check (public.is_admin());

create policy promotions_update_admin
  on public.promotions
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy promotions_delete_admin
  on public.promotions
  for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- addresses (owner only; admin has no need in current app)
-- ---------------------------------------------------------------------------
create policy addresses_select_own
  on public.addresses
  for select
  to authenticated
  using (user_id = auth.uid());

create policy addresses_insert_own
  on public.addresses
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy addresses_update_own
  on public.addresses
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy addresses_delete_own
  on public.addresses
  for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- orders
-- RISK NOTE: INSERT trusts client price_list/summ — not production-secure checkout.
-- ---------------------------------------------------------------------------
create policy orders_select_own_or_admin
  on public.orders
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy orders_insert_own
  on public.orders
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- No update/delete policies: orders are immutable from clients in current app.

-- ---------------------------------------------------------------------------
-- support_messages
-- ---------------------------------------------------------------------------
create policy support_insert_own
  on public.support_messages
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy support_select_own_or_admin
  on public.support_messages
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- No client update of status in this stage (admin inbox UI not wired).
