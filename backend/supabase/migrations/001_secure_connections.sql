-- Supervision Pocket 0.10 secure delivery foundation.
-- The database stores relationship metadata and encrypted payload envelopes only.
-- Clear-text case material and connection encryption keys must never be inserted.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'profile_role') then
    create type public.profile_role as enum ('psychologist', 'supervisor', 'both');
  end if;
  if not exists (select 1 from pg_type where typname = 'connection_state') then
    create type public.connection_state as enum ('active', 'revoked');
  end if;
  if not exists (select 1 from pg_type where typname = 'shared_request_status') then
    create type public.shared_request_status as enum (
      'new_request',
      'seen',
      'planned',
      'completed',
      'continuation',
      'archived'
    );
  end if;
end
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role public.profile_role not null default 'psychologist',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(display_name) <= 120)
);

create table if not exists public.connection_invitations (
  id uuid primary key default gen_random_uuid(),
  supervisor_id uuid not null references public.profiles(id) on delete cascade,
  token_hash bytea not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  revoked_at timestamptz,
  check (expires_at > created_at)
);

create table if not exists public.supervision_connections (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid references public.connection_invitations(id) on delete set null,
  supervisor_id uuid not null references public.profiles(id) on delete cascade,
  supervisee_id uuid not null references public.profiles(id) on delete cascade,
  state public.connection_state not null default 'active',
  key_version integer not null default 1 check (key_version > 0),
  created_at timestamptz not null default now(),
  accepted_at timestamptz not null default now(),
  revoked_at timestamptz,
  check (supervisor_id <> supervisee_id)
);

create unique index if not exists supervision_connections_active_pair_idx
  on public.supervision_connections (supervisor_id, supervisee_id)
  where state = 'active';

create table if not exists public.shared_requests (
  id uuid primary key,
  connection_id uuid not null references public.supervision_connections(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  schema_version integer not null default 1 check (schema_version > 0),
  key_version integer not null default 1 check (key_version > 0),
  nonce text not null,
  cipher_text text not null,
  mac text not null,
  status public.shared_request_status not null default 'new_request',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(nonce) between 12 and 64),
  check (char_length(mac) between 16 and 128),
  check (char_length(cipher_text) > 0)
);

create index if not exists shared_requests_connection_created_idx
  on public.shared_requests (connection_id, created_at desc);

create table if not exists public.request_messages (
  id uuid primary key,
  request_id uuid not null references public.shared_requests(id) on delete cascade,
  connection_id uuid not null references public.supervision_connections(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  schema_version integer not null default 1 check (schema_version > 0),
  key_version integer not null default 1 check (key_version > 0),
  nonce text not null,
  cipher_text text not null,
  mac text not null,
  created_at timestamptz not null default now(),
  check (char_length(cipher_text) > 0)
);

create index if not exists request_messages_request_created_idx
  on public.request_messages (request_id, created_at);

create table if not exists public.connection_audit_events (
  id bigint generated always as identity primary key,
  connection_id uuid not null references public.supervision_connections(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  object_id uuid,
  created_at timestamptz not null default now(),
  check (event_type in (
    'connection_accepted',
    'connection_revoked',
    'request_created',
    'request_status_changed',
    'message_created'
  ))
);

create index if not exists connection_audit_events_connection_created_idx
  on public.connection_audit_events (connection_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists shared_requests_set_updated_at on public.shared_requests;
create trigger shared_requests_set_updated_at
before update on public.shared_requests
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_connection_member(target_connection_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.supervision_connections c
    where c.id = target_connection_id
      and c.state = 'active'
      and auth.uid() in (c.supervisor_id, c.supervisee_id)
  );
$$;

create or replace function public.create_connection_invitation(
  token_hash_hex text,
  requested_expires_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if requested_expires_at <= now() or requested_expires_at > now() + interval '30 days' then
    raise exception 'Invitation expiry must be within 30 days';
  end if;
  if token_hash_hex !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'Invitation token hash must be SHA-256 hex';
  end if;

  insert into public.connection_invitations (
    supervisor_id,
    token_hash,
    expires_at
  ) values (
    auth.uid(),
    decode(lower(token_hash_hex), 'hex'),
    requested_expires_at
  )
  returning id into invitation_id;

  return invitation_id;
end;
$$;

create or replace function public.accept_connection_invitation(raw_invite_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation public.connection_invitations%rowtype;
  connection_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into invitation
  from public.connection_invitations
  where token_hash = digest(raw_invite_token, 'sha256')
    and accepted_at is null
    and revoked_at is null
    and expires_at > now()
  for update;

  if invitation.id is null then
    raise exception 'Invitation is invalid or expired';
  end if;
  if invitation.supervisor_id = auth.uid() then
    raise exception 'Supervisor cannot accept their own invitation';
  end if;

  select id into connection_id
  from public.supervision_connections
  where supervisor_id = invitation.supervisor_id
    and supervisee_id = auth.uid()
    and state = 'active'
  limit 1;

  if connection_id is null then
    insert into public.supervision_connections (
      invitation_id,
      supervisor_id,
      supervisee_id
    ) values (
      invitation.id,
      invitation.supervisor_id,
      auth.uid()
    )
    returning id into connection_id;
  end if;

  update public.connection_invitations
  set accepted_at = now()
  where id = invitation.id;

  insert into public.connection_audit_events (
    connection_id,
    actor_id,
    event_type
  ) values (
    connection_id,
    auth.uid(),
    'connection_accepted'
  );

  return connection_id;
end;
$$;

create or replace function public.revoke_supervision_connection(target_connection_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.supervision_connections
  set state = 'revoked', revoked_at = now()
  where id = target_connection_id
    and state = 'active'
    and auth.uid() in (supervisor_id, supervisee_id);

  if not found then
    raise exception 'Active connection not found';
  end if;

  insert into public.connection_audit_events (
    connection_id,
    actor_id,
    event_type
  ) values (
    target_connection_id,
    auth.uid(),
    'connection_revoked'
  );
end;
$$;

create or replace function public.protect_shared_request()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' then
    if new.id <> old.id or
       new.connection_id <> old.connection_id or
       new.sender_id <> old.sender_id or
       new.created_at <> old.created_at then
      raise exception 'Request identity fields are immutable';
    end if;
    if auth.uid() <> old.sender_id and (
      new.schema_version <> old.schema_version or
      new.key_version <> old.key_version or
      new.nonce <> old.nonce or
      new.cipher_text <> old.cipher_text or
      new.mac <> old.mac
    ) then
      raise exception 'Only the sender can replace encrypted request content';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists shared_requests_protect_content on public.shared_requests;
create trigger shared_requests_protect_content
before update on public.shared_requests
for each row execute function public.protect_shared_request();

create or replace function public.audit_shared_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.connection_audit_events (
      connection_id, actor_id, event_type, object_id
    ) values (
      new.connection_id, new.sender_id, 'request_created', new.id
    );
  elsif new.status is distinct from old.status then
    insert into public.connection_audit_events (
      connection_id, actor_id, event_type, object_id
    ) values (
      new.connection_id, auth.uid(), 'request_status_changed', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists shared_requests_audit on public.shared_requests;
create trigger shared_requests_audit
after insert or update on public.shared_requests
for each row execute function public.audit_shared_request();

create or replace function public.audit_request_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.connection_audit_events (
    connection_id, actor_id, event_type, object_id
  ) values (
    new.connection_id, new.sender_id, 'message_created', new.id
  );
  return new;
end;
$$;

drop trigger if exists request_messages_audit on public.request_messages;
create trigger request_messages_audit
after insert on public.request_messages
for each row execute function public.audit_request_message();

alter table public.profiles enable row level security;
alter table public.connection_invitations enable row level security;
alter table public.supervision_connections enable row level security;
alter table public.shared_requests enable row level security;
alter table public.request_messages enable row level security;
alter table public.connection_audit_events enable row level security;

drop policy if exists profiles_select_relevant on public.profiles;
create policy profiles_select_relevant
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.supervision_connections c
    where c.state = 'active'
      and (
        (c.supervisor_id = auth.uid() and c.supervisee_id = profiles.id)
        or (c.supervisee_id = auth.uid() and c.supervisor_id = profiles.id)
      )
  )
);

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists invitations_select_own on public.connection_invitations;
create policy invitations_select_own
on public.connection_invitations for select
to authenticated
using (supervisor_id = auth.uid());

drop policy if exists invitations_revoke_own on public.connection_invitations;
create policy invitations_revoke_own
on public.connection_invitations for update
to authenticated
using (supervisor_id = auth.uid() and accepted_at is null)
with check (supervisor_id = auth.uid());

drop policy if exists connections_select_members on public.supervision_connections;
create policy connections_select_members
on public.supervision_connections for select
to authenticated
using (auth.uid() in (supervisor_id, supervisee_id));

drop policy if exists shared_requests_select_members on public.shared_requests;
create policy shared_requests_select_members
on public.shared_requests for select
to authenticated
using (public.is_connection_member(connection_id));

drop policy if exists shared_requests_insert_sender on public.shared_requests;
create policy shared_requests_insert_sender
on public.shared_requests for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_connection_member(connection_id)
);

drop policy if exists shared_requests_update_members on public.shared_requests;
create policy shared_requests_update_members
on public.shared_requests for update
to authenticated
using (public.is_connection_member(connection_id))
with check (public.is_connection_member(connection_id));

drop policy if exists shared_requests_delete_sender on public.shared_requests;
create policy shared_requests_delete_sender
on public.shared_requests for delete
to authenticated
using (sender_id = auth.uid() and public.is_connection_member(connection_id));

drop policy if exists request_messages_select_members on public.request_messages;
create policy request_messages_select_members
on public.request_messages for select
to authenticated
using (public.is_connection_member(connection_id));

drop policy if exists request_messages_insert_sender on public.request_messages;
create policy request_messages_insert_sender
on public.request_messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_connection_member(connection_id)
  and exists (
    select 1 from public.shared_requests r
    where r.id = request_id and r.connection_id = request_messages.connection_id
  )
);

drop policy if exists request_messages_delete_sender on public.request_messages;
create policy request_messages_delete_sender
on public.request_messages for delete
to authenticated
using (sender_id = auth.uid() and public.is_connection_member(connection_id));

drop policy if exists audit_events_select_members on public.connection_audit_events;
create policy audit_events_select_members
on public.connection_audit_events for select
to authenticated
using (public.is_connection_member(connection_id));

grant select, update on public.profiles to authenticated;
grant select, update on public.connection_invitations to authenticated;
grant select on public.supervision_connections to authenticated;
grant select, insert, update, delete on public.shared_requests to authenticated;
grant select, insert, delete on public.request_messages to authenticated;
grant select on public.connection_audit_events to authenticated;
grant execute on function public.is_connection_member(uuid) to authenticated;
grant execute on function public.create_connection_invitation(text, timestamptz) to authenticated;
grant execute on function public.accept_connection_invitation(text) to authenticated;
grant execute on function public.revoke_supervision_connection(uuid) to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1
      from pg_publication_rel pr
      join pg_publication p on p.oid = pr.prpubid
      join pg_class c on c.oid = pr.prrelid
      join pg_namespace n on n.oid = c.relnamespace
      where p.pubname = 'supabase_realtime'
        and n.nspname = 'public'
        and c.relname = 'shared_requests'
    ) then
      alter publication supabase_realtime add table public.shared_requests;
    end if;
    if not exists (
      select 1
      from pg_publication_rel pr
      join pg_publication p on p.oid = pr.prpubid
      join pg_class c on c.oid = pr.prrelid
      join pg_namespace n on n.oid = c.relnamespace
      where p.pubname = 'supabase_realtime'
        and n.nspname = 'public'
        and c.relname = 'request_messages'
    ) then
      alter publication supabase_realtime add table public.request_messages;
    end if;
  end if;
end
$$;
