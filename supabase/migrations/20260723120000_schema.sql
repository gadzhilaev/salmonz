-- Salmonz schema (compatible with current Flutter client).
-- Table name "user" is preserved for app compatibility.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Helpers: updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- public."user" (profile)
-- ---------------------------------------------------------------------------
create table public."user" (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  name text not null default '',
  phone text,
  img text not null default '',
  is_admin boolean not null default false,
  lang text not null default 'ru',
  birthdate date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger user_set_updated_at
before update on public."user"
for each row execute function public.set_updated_at();

create index user_is_admin_idx on public."user" (is_admin) where is_admin = true;

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
create table public.categories (
  id bigint generated always as identity primary key,
  title text not null,
  type text not null,
  img text not null,
  position integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  constraint categories_type_unique unique (type),
  constraint categories_position_nonneg check (position >= 0)
);

create index categories_position_idx on public.categories (position);

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
create table public.products (
  id bigint generated always as identity primary key,
  name text not null,
  description text not null default '',
  price numeric(12, 2) not null,
  img text not null,
  type text not null,
  gramm integer not null default 0,
  amount integer not null default 1,
  is_stock boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  constraint products_price_positive check (price > 0),
  constraint products_gramm_nonneg check (gramm >= 0),
  constraint products_amount_positive check (amount > 0),
  constraint products_type_fkey foreign key (type) references public.categories (type)
    on update cascade on delete restrict
);

create index products_type_idx on public.products (type);
create index products_is_stock_idx on public.products (is_stock);

-- ---------------------------------------------------------------------------
-- promotions
-- ---------------------------------------------------------------------------
create table public.promotions (
  id bigint generated always as identity primary key,
  img text not null,
  created_at timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------------
-- addresses
-- ---------------------------------------------------------------------------
create table public.addresses (
  id bigint generated always as identity primary key,
  user_id uuid not null references public."user" (id) on delete cascade,
  country text not null default '',
  city text not null default '',
  line text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create index addresses_user_id_idx on public.addresses (user_id);
create index addresses_user_created_idx on public.addresses (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- orders
-- Client-supplied price arrays are accepted for schema compatibility.
-- RISK: checkout is NOT production-secure — prices are trusted from the client.
-- Next stage: RPC that recomputes prices server-side in one transaction.
-- ---------------------------------------------------------------------------
create table public.orders (
  id bigint generated always as identity primary key,
  user_id uuid not null references public."user" (id) on delete cascade,
  product_list bigint[] not null default '{}',
  value_list integer[] not null default '{}',
  price_list numeric(12, 2)[] not null default '{}',
  summ numeric(12, 2) not null,
  address text not null default '',
  phone text not null default '',
  comment text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  constraint orders_summ_nonneg check (summ >= 0),
  constraint orders_arrays_same_length check (
    cardinality(product_list) = cardinality(value_list)
    and cardinality(product_list) = cardinality(price_list)
  )
);

create index orders_user_id_idx on public.orders (user_id);
create index orders_user_created_idx on public.orders (user_id, created_at desc);
create index orders_created_at_idx on public.orders (created_at desc);

-- ---------------------------------------------------------------------------
-- support_messages
-- ---------------------------------------------------------------------------
create table public.support_messages (
  id bigint generated always as identity primary key,
  user_id uuid not null references public."user" (id) on delete cascade,
  name text not null default '',
  email text not null default '',
  message text not null,
  status text not null default 'new',
  created_at timestamptz not null default timezone('utc', now()),
  constraint support_messages_message_not_empty check (length(trim(message)) > 0)
);

create index support_messages_user_id_idx on public.support_messages (user_id);
create index support_messages_status_idx on public.support_messages (status);

-- ---------------------------------------------------------------------------
-- Auth → profile trigger (idempotent)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public."user" (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

comment on function public.handle_new_user() is
  'Creates a public.user profile row after auth.users insert. Idempotent.';

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Admin check + is_admin escalation guard
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select u.is_admin from public."user" u where u.id = auth.uid()),
    false
  );
$$;

comment on function public.is_admin() is
  'Returns true when the current auth.uid() has is_admin=true. Used by RLS.';

create or replace function public.prevent_is_admin_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.is_admin is distinct from old.is_admin then
    -- Allow only service_role (migrations / SQL console), never self-service.
    if coalesce(auth.jwt() ->> 'role', '') = 'service_role' then
      return new;
    end if;
    raise exception 'Forbidden: is_admin cannot be changed by clients'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

comment on function public.prevent_is_admin_escalation() is
  'Blocks client updates to user.is_admin. Change roles only via service_role SQL.';

create trigger user_prevent_is_admin_escalation
before update on public."user"
for each row execute function public.prevent_is_admin_escalation();

-- ---------------------------------------------------------------------------
-- Realtime (matches Flutter .stream() usage)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.categories;
alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.promotions;
alter publication supabase_realtime add table public.addresses;
