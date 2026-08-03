import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:supervision_pocket/features/sync/domain/secure_sync_models.dart';

class SecureSyncCryptoService {
  SecureSyncCryptoService({Cipher? cipher})
      : _cipher = cipher ?? AesGcm.with256bits();

  final Cipher _cipher;

  Future<ConnectionInvitationSecret> createInvitation({
    required Uri joinBaseUri,
    int keyVersion = 1,
  }) async {
    final key = _randomBytes(32);
    final inviteToken = encodeBase64Url(_randomBytes(24));
    final fragment = Uri(
      queryParameters: {
        'key': encodeBase64Url(key),
        'v': '$keyVersion',
      },
    ).query;
    final uri = joinBaseUri.replace(
      queryParameters: {
        ...joinBaseUri.queryParameters,
        'invite': inviteToken,
      },
      fragment: fragment,
    );
    return ConnectionInvitationSecret(
      uri: uri,
      inviteToken: inviteToken,
      connectionKey: key,
      keyVersion: keyVersion,
    );
  }

  Future<EncryptedSyncPayload> encryptJson({
    required String connectionId,
    required String objectId,
    required List<int> connectionKey,
    required Map<String, Object?> payload,
    int schemaVersion = 1,
    int keyVersion = 1,
  }) async {
    _validateKey(connectionKey);
    final nonce = _randomBytes(12);
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: SecretKey(connectionKey),
      nonce: nonce,
      aad: _aad(
        connectionId: connectionId,
        objectId: objectId,
        schemaVersion: schemaVersion,
        keyVersion: keyVersion,
      ),
    );
    return EncryptedSyncPayload(
      schemaVersion: schemaVersion,
      keyVersion: keyVersion,
      nonce: encodeBase64Url(box.nonce),
      cipherText: encodeBase64Url(box.cipherText),
      mac: encodeBase64Url(box.mac.bytes),
    );
  }

  Future<Map<String, Object?>> decryptJson({
    required String connectionId,
    required String objectId,
    required List<int> connectionKey,
    required EncryptedSyncPayload payload,
  }) async {
    _validateKey(connectionKey);
    final clearBytes = await _cipher.decrypt(
      SecretBox(
        decodeBase64Url(payload.cipherText),
        nonce: decodeBase64Url(payload.nonce),
        mac: Mac(decodeBase64Url(payload.mac)),
      ),
      secretKey: SecretKey(connectionKey),
      aad: _aad(
        connectionId: connectionId,
        objectId: objectId,
        schemaVersion: payload.schemaVersion,
        keyVersion: payload.keyVersion,
      ),
    );
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Secure sync payload must be a JSON object');
    }
    return decoded;
  }

  List<int> _aad({
    required String connectionId,
    required String objectId,
    required int schemaVersion,
    required int keyVersion,
  }) {
    return utf8.encode(
      'supervision-pocket|$connectionId|$objectId|$schemaVersion|$keyVersion',
    );
  }

  void _validateKey(List<int> key) {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'connectionKey', 'Must be 32 bytes');
    }
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
