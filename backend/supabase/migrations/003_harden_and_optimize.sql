-- Security and performance hardening applied after 001/002.

revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function public.is_connection_member(uuid) to authenticated;
grant execute on function public.create_connection_invitation(text, timestamptz) to authenticated;
grant execute on function public.accept_connection_invitation(text) to authenticated;
grant execute on function public.revoke_supervision_connection(uuid) to authenticated;

create index if not exists connection_invitations_supervisor_idx
  on public.connection_invitations (supervisor_id);
create index if not exists supervision_connections_invitation_idx
  on public.supervision_connections (invitation_id);
create index if not exists supervision_connections_supervisee_idx
  on public.supervision_connections (supervisee_id);
create index if not exists shared_requests_sender_idx
  on public.shared_requests (sender_id);
create index if not exists request_messages_connection_idx
  on public.request_messages (connection_id);
create index if not exists request_messages_sender_idx
  on public.request_messages (sender_id);
create index if not exists connection_audit_events_actor_idx
  on public.connection_audit_events (actor_id);

drop policy if exists profiles_select_relevant on public.profiles;
create policy profiles_select_relevant
on public.profiles for select
to authenticated
using (
  id = (select auth.uid())
  or exists (
    select 1 from public.supervision_connections c
    where c.state = 'active'
      and (
        (c.supervisor_id = (select auth.uid()) and c.supervisee_id = profiles.id)
        or (c.supervisee_id = (select auth.uid()) and c.supervisor_id = profiles.id)
      )
  )
);

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
on public.profiles for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists invitations_select_own on public.connection_invitations;
create policy invitations_select_own
on public.connection_invitations for select
to authenticated
using (supervisor_id = (select auth.uid()));

drop policy if exists invitations_revoke_own on public.connection_invitations;
create policy invitations_revoke_own
on public.connection_invitations for update
to authenticated
using (supervisor_id = (select auth.uid()) and accepted_at is null)
with check (supervisor_id = (select auth.uid()));

drop policy if exists connections_select_members on public.supervision_connections;
create policy connections_select_members
on public.supervision_connections for select
to authenticated
using ((select auth.uid()) in (supervisor_id, supervisee_id));

drop policy if exists shared_requests_insert_sender on public.shared_requests;
create policy shared_requests_insert_sender
on public.shared_requests for insert
to authenticated
with check (
  sender_id = (select auth.uid())
  and public.is_connection_member(connection_id)
);

drop policy if exists shared_requests_delete_sender on public.shared_requests;
create policy shared_requests_delete_sender
on public.shared_requests for delete
to authenticated
using (
  sender_id = (select auth.uid())
  and public.is_connection_member(connection_id)
);

drop policy if exists request_messages_insert_sender on public.request_messages;
create policy request_messages_insert_sender
on public.request_messages for insert
to authenticated
with check (
  sender_id = (select auth.uid())
  and public.is_connection_member(connection_id)
  and exists (
    select 1 from public.shared_requests r
    where r.id = request_id
      and r.connection_id = request_messages.connection_id
  )
);

drop policy if exists request_messages_delete_sender on public.request_messages;
create policy request_messages_delete_sender
on public.request_messages for delete
to authenticated
using (
  sender_id = (select auth.uid())
  and public.is_connection_member(connection_id)
);
