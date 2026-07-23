-- Storage buckets + policies aligned with Flutter upload paths.
-- avatars: {auth.uid()}/...
-- categories_imgs / promotions / Menu: admin-only write, public read

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('categories_imgs', 'categories_imgs', true, 10485760, array['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('promotions', 'promotions', true, 10485760, array['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('Menu', 'Menu', true, 10485760, array['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Helper reused by policies (optional inline)
-- Public read for catalog + avatars (UI uses getPublicUrl)
create policy storage_public_read_salmonz_buckets
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id in ('avatars', 'categories_imgs', 'promotions', 'Menu'));

-- Avatars: owner folder only
create policy storage_avatars_insert_own
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_avatars_update_own
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_avatars_delete_own
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Catalog images: admin only write
create policy storage_catalog_insert_admin
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id in ('categories_imgs', 'promotions', 'Menu')
    and public.is_admin()
  );

create policy storage_catalog_update_admin
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id in ('categories_imgs', 'promotions', 'Menu')
    and public.is_admin()
  )
  with check (
    bucket_id in ('categories_imgs', 'promotions', 'Menu')
    and public.is_admin()
  );

create policy storage_catalog_delete_admin
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id in ('categories_imgs', 'promotions', 'Menu')
    and public.is_admin()
  );
