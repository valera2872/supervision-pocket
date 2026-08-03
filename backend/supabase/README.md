# Supabase backend for Supervision Pocket 0.10

This directory contains the server schema for direct encrypted delivery between a psychologist and a supervisor.

## Important security rule

Only metadata and AES-GCM envelopes may be sent to the backend. Never add clear-text case fields, questions, comments, client aliases or private notes to server tables or logs.

## Project creation

1. Create a Supabase project in a European region.
2. Disable public Realtime channels.
3. Keep the service-role key outside the mobile application and repository.
4. Apply migrations in numeric order:
   - `001_secure_connections.sql`
   - `002_backfill_existing_profiles.sql`
5. Configure authentication for the closed beta.
6. Add the project URL and publishable client key through build-time environment variables. Do not commit them to source control.

## Planned Flutter configuration

```text
--dart-define=SP_SUPABASE_URL=https://PROJECT.supabase.co
--dart-define=SP_SUPABASE_PUBLISHABLE_KEY=PUBLIC_CLIENT_KEY
--dart-define=SP_JOIN_URL=https://DOMAIN/join
```

The publishable key is designed for client applications; authorization is enforced by Row Level Security. The service-role key bypasses RLS and must never appear in an APK.

## Invitation flow

1. The supervisor's device generates a random invitation token and a separate 32-byte connection key.
2. The device sends only the SHA-256 token hash to `create_connection_invitation`.
3. The invitation URL contains the raw token in the query and the encryption key in the URI fragment.
4. The supervisee authenticates and calls `accept_connection_invitation` with the raw token.
5. Both devices store the connection key in secure storage.
6. All professional text is encrypted locally before insertion into `shared_requests` or `request_messages`.

## Database checks before beta

- An unrelated authenticated user cannot select any connection, request, message or audit row.
- A participant of one connection cannot move ciphertext into another connection.
- Only the request sender can replace encrypted content.
- Either member can revoke an active connection.
- Expired and already used invitations fail.
- Realtime subscriptions return only rows allowed by RLS.
- SQL logs, push messages and analytics contain no case content.

## Not included yet

- production credentials;
- email templates;
- push notification provider;
- key transfer to a second device;
- server-side PDF export;
- billing or marketplace functions.
