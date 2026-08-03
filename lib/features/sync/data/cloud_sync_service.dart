import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervision_pocket/config/supabase_config.dart';
import 'package:supervision_pocket/features/sync/data/connection_key_store.dart';
import 'package:supervision_pocket/features/sync/data/invitation_token_service.dart';
import 'package:supervision_pocket/features/sync/data/secure_sync_crypto_service.dart';
import 'package:supervision_pocket/features/sync/domain/secure_sync_models.dart';

class CreatedCloudInvitation {
  const CreatedCloudInvitation({
    required this.invitationId,
    required this.shareLink,
    required this.expiresAt,
  });

  final String invitationId;
  final String shareLink;
  final DateTime expiresAt;
}

class CloudConnection {
  const CloudConnection({
    required this.id,
    required this.supervisorId,
    required this.superviseeId,
    required this.peerId,
    required this.peerName,
    required this.keyVersion,
    required this.keyAvailable,
    this.invitationId,
  });

  final String id;
  final String? invitationId;
  final String supervisorId;
  final String superviseeId;
  final String peerId;
  final String peerName;
  final int keyVersion;
  final bool keyAvailable;
}

class CloudRequestItem {
  const CloudRequestItem({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.status,
    required this.createdAt,
    required this.payload,
    this.decryptionError,
  });

  final String id;
  final String connectionId;
  final String senderId;
  final String status;
  final DateTime createdAt;
  final Map<String, Object?>? payload;
  final String? decryptionError;
}

class CloudSyncService {
  CloudSyncService({
    SupabaseClient? client,
    SecureSyncCryptoService? crypto,
    InvitationTokenService? tokenService,
    ConnectionKeyStore? keyStore,
  })  : _client = client ?? Supabase.instance.client,
        _crypto = crypto ?? SecureSyncCryptoService(),
        _tokenService = tokenService ?? const InvitationTokenService(),
        _keyStore = keyStore ?? FlutterConnectionKeyStore();

  final SupabaseClient _client;
  final SecureSyncCryptoService _crypto;
  final InvitationTokenService _tokenService;
  final ConnectionKeyStore _keyStore;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'display_name': displayName.trim(),
        'role': role,
      },
    );
    if (response.session != null) {
      await ensureProfile(displayName: displayName, role: role);
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await ensureProfile(displayName: displayName, role: role);
    return response;
  }

  Future<void> ensureProfile({
    required String displayName,
    required String role,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'display_name': displayName.trim(),
      'role': role,
    }).eq('id', user.id);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<CreatedCloudInvitation> createInvitation() async {
    _requireUser();
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 7));
    final secret = await _crypto.createInvitation(
      joinBaseUri: Uri.parse(SupabaseConfig.invitationBaseUrl),
    );
    final rawId = await _client.rpc(
      'create_connection_invitation',
      params: {
        'token_hash_hex': _tokenService.sha256Hex(secret.inviteToken),
        'requested_expires_at': expiresAt.toIso8601String(),
      },
    );
    final invitationId = rawId.toString();
    await _keyStore.save(
      StoredConnectionKey(
        connectionId: _pendingKeyId(invitationId),
        keyVersion: secret.keyVersion,
        keyBytes: secret.connectionKey,
      ),
    );
    final shareUri = secret.uri.replace(
      queryParameters: {
        ...secret.uri.queryParameters,
        'iid': invitationId,
      },
    );
    return CreatedCloudInvitation(
      invitationId: invitationId,
      shareLink: shareUri.toString(),
      expiresAt: expiresAt,
    );
  }

  Future<String> acceptInvitation(String link) async {
    _requireUser();
    final secret = ConnectionInvitationSecret.parse(Uri.parse(link.trim()));
    final rawConnectionId = await _client.rpc(
      'accept_connection_invitation',
      params: {'raw_invite_token': secret.inviteToken},
    );
    final connectionId = rawConnectionId.toString();
    await _keyStore.save(
      StoredConnectionKey(
        connectionId: connectionId,
        keyVersion: secret.keyVersion,
        keyBytes: secret.connectionKey,
      ),
    );
    return connectionId;
  }

  Future<List<CloudConnection>> listConnections() async {
    final user = _requireUser();
    final rawRows = await _client
        .from('supervision_connections')
        .select(
          'id, invitation_id, supervisor_id, supervisee_id, state, key_version, created_at',
        )
        .eq('state', 'active')
        .order('created_at');
    final rows = (rawRows as List).cast<Map<String, dynamic>>();

    for (final row in rows) {
      final invitationId = row['invitation_id'] as String?;
      if (invitationId == null) continue;
      final pending = await _keyStore.read(_pendingKeyId(invitationId));
      if (pending == null) continue;
      final connectionId = row['id'] as String;
      await _keyStore.save(
        StoredConnectionKey(
          connectionId: connectionId,
          keyVersion: pending.keyVersion,
          keyBytes: pending.keyBytes,
        ),
      );
      await _keyStore.delete(_pendingKeyId(invitationId));
    }

    final peerIds = <String>{};
    for (final row in rows) {
      final supervisorId = row['supervisor_id'] as String;
      final superviseeId = row['supervisee_id'] as String;
      peerIds.add(supervisorId == user.id ? superviseeId : supervisorId);
    }
    final names = <String, String>{};
    if (peerIds.isNotEmpty) {
      final rawProfiles = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', peerIds.toList());
      for (final row in (rawProfiles as List).cast<Map<String, dynamic>>()) {
        names[row['id'] as String] = row['display_name'] as String? ?? '';
      }
    }

    final result = <CloudConnection>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final supervisorId = row['supervisor_id'] as String;
      final superviseeId = row['supervisee_id'] as String;
      final peerId = supervisorId == user.id ? superviseeId : supervisorId;
      final storedKey = await _keyStore.read(id);
      result.add(
        CloudConnection(
          id: id,
          invitationId: row['invitation_id'] as String?,
          supervisorId: supervisorId,
          superviseeId: superviseeId,
          peerId: peerId,
          peerName: (names[peerId] ?? '').trim().isEmpty
              ? 'Подключённый специалист'
              : names[peerId]!,
          keyVersion: row['key_version'] as int? ?? 1,
          keyAvailable: storedKey != null,
        ),
      );
    }
    return result;
  }

  Future<void> revokeConnection(String connectionId) async {
    _requireUser();
    await _client.rpc(
      'revoke_supervision_connection',
      params: {'target_connection_id': connectionId},
    );
    await _keyStore.delete(connectionId);
  }

  Future<String> sendRequest({
    required CloudConnection connection,
    required Map<String, Object?> payload,
  }) async {
    final user = _requireUser();
    final storedKey = await _keyStore.read(connection.id);
    if (storedKey == null) {
      throw StateError(
        'На этом устройстве нет ключа связи. Обновите подключение по приглашению.',
      );
    }
    final requestId = _newUuid();
    final encrypted = await _crypto.encryptJson(
      connectionId: connection.id,
      objectId: requestId,
      connectionKey: storedKey.keyBytes,
      payload: payload,
      keyVersion: storedKey.keyVersion,
    );
    await _client.from('shared_requests').insert({
      'id': requestId,
      'connection_id': connection.id,
      'sender_id': user.id,
      'schema_version': encrypted.schemaVersion,
      'key_version': encrypted.keyVersion,
      'nonce': encrypted.nonce,
      'cipher_text': encrypted.cipherText,
      'mac': encrypted.mac,
      'status': 'new_request',
    });
    return requestId;
  }

  Future<List<CloudRequestItem>> listRequests() async {
    _requireUser();
    final rawRows = await _client
        .from('shared_requests')
        .select(
          'id, connection_id, sender_id, schema_version, key_version, nonce, cipher_text, mac, status, created_at',
        )
        .order('created_at', ascending: false);
    final rows = (rawRows as List).cast<Map<String, dynamic>>();
    final result = <CloudRequestItem>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final connectionId = row['connection_id'] as String;
      final storedKey = await _keyStore.read(connectionId);
      Map<String, Object?>? payload;
      String? error;
      if (storedKey == null) {
        error = 'Ключ связи отсутствует на этом устройстве';
      } else {
        try {
          payload = await _crypto.decryptJson(
            connectionId: connectionId,
            objectId: id,
            connectionKey: storedKey.keyBytes,
            payload: EncryptedSyncPayload(
              schemaVersion: row['schema_version'] as int? ?? 1,
              keyVersion: row['key_version'] as int? ?? 1,
              nonce: row['nonce'] as String,
              cipherText: row['cipher_text'] as String,
              mac: row['mac'] as String,
            ),
          );
        } catch (_) {
          error = 'Не удалось расшифровать запрос';
        }
      }
      result.add(
        CloudRequestItem(
          id: id,
          connectionId: connectionId,
          senderId: row['sender_id'] as String,
          status: row['status'] as String? ?? 'new_request',
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
          payload: payload,
          decryptionError: error,
        ),
      );
    }
    return result;
  }

  Future<void> markRequestSeen(String requestId) async {
    _requireUser();
    await _client
        .from('shared_requests')
        .update({'status': 'seen'}).eq('id', requestId);
  }

  User _requireUser() {
    final user = currentUser;
    if (user == null) throw StateError('Требуется вход в аккаунт');
    return user;
  }

  String _pendingKeyId(String invitationId) => 'pending:$invitationId';

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
