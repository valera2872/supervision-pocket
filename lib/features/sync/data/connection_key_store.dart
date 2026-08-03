import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervision_pocket/features/sync/domain/secure_sync_models.dart';

class StoredConnectionKey {
  const StoredConnectionKey({
    required this.connectionId,
    required this.keyVersion,
    required this.keyBytes,
  });

  final String connectionId;
  final int keyVersion;
  final List<int> keyBytes;
}

abstract interface class ConnectionKeyStore {
  Future<void> save(StoredConnectionKey value);
  Future<StoredConnectionKey?> read(String connectionId);
  Future<void> delete(String connectionId);
}

class FlutterConnectionKeyStore implements ConnectionKeyStore {
  FlutterConnectionKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'supervision-pocket.connection-key.';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(StoredConnectionKey value) async {
    if (value.connectionId.trim().isEmpty) {
      throw ArgumentError.value(value.connectionId, 'connectionId');
    }
    if (value.keyBytes.length != 32) {
      throw ArgumentError.value(
        value.keyBytes.length,
        'keyBytes',
        'Connection key must contain 32 bytes',
      );
    }
    await _storage.write(
      key: _storageKey(value.connectionId),
      value: jsonEncode({
        'version': value.keyVersion,
        'key': encodeBase64Url(value.keyBytes),
      }),
    );
  }

  @override
  Future<StoredConnectionKey?> read(String connectionId) async {
    final raw = await _storage.read(key: _storageKey(connectionId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Stored connection key is invalid');
      }
      final version = decoded['version'] as int?;
      final encodedKey = decoded['key'] as String?;
      if (version == null || encodedKey == null) {
        throw const FormatException('Stored connection key is incomplete');
      }
      final keyBytes = decodeBase64Url(encodedKey);
      if (keyBytes.length != 32) {
        throw const FormatException('Stored connection key has wrong length');
      }
      return StoredConnectionKey(
        connectionId: connectionId,
        keyVersion: version,
        keyBytes: keyBytes,
      );
    } on FormatException {
      await delete(connectionId);
      rethrow;
    }
  }

  @override
  Future<void> delete(String connectionId) {
    return _storage.delete(key: _storageKey(connectionId));
  }

  String _storageKey(String connectionId) => '$_prefix$connectionId';
}
