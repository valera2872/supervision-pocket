-- Run after 001_secure_connections.sql.
-- The auth trigger covers new registrations; this migration covers accounts
-- that existed before the secure connection schema was installed.

insert into public.profiles (id, display_name)
select
  users.id,
  coalesce(users.raw_user_meta_data ->> 'display_name', '')
from auth.users as users
on conflict (id) do nothing;
