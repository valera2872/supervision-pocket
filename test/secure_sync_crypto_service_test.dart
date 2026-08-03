import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/sync/data/secure_sync_crypto_service.dart';
import 'package:supervision_pocket/features/sync/domain/secure_sync_models.dart';

void main() {
  final service = SecureSyncCryptoService();

  test('invitation keeps the acceptance token and encryption key separate', () async {
    final invitation = await service.createInvitation(
      joinBaseUri: Uri.parse('https://example.test/join'),
    );

    expect(invitation.uri.queryParameters['invite'], invitation.inviteToken);
    expect(invitation.uri.fragment, contains('key='));
    expect(invitation.uri.toString(), isNot(contains('connectionKey')));

    final parsed = ConnectionInvitationSecret.parse(invitation.uri);
    expect(parsed.inviteToken, invitation.inviteToken);
    expect(parsed.connectionKey, invitation.connectionKey);
    expect(parsed.keyVersion, 1);
  });

  test('encrypted request round-trips with bound metadata', () async {
    final invitation = await service.createInvitation(
      joinBaseUri: Uri.parse('https://example.test/join'),
    );
    final encrypted = await service.encryptJson(
      connectionId: 'connection-1',
      objectId: 'request-1',
      connectionKey: invitation.connectionKey,
      payload: const {
        'question': 'Как понять мою реакцию?',
        'observedFact': 'Клиент замолчал.',
      },
    );

    final decrypted = await service.decryptJson(
      connectionId: 'connection-1',
      objectId: 'request-1',
      connectionKey: invitation.connectionKey,
      payload: EncryptedSyncPayload.fromJson(encrypted.toJson()),
    );

    expect(decrypted['question'], 'Как понять мою реакцию?');
    expect(decrypted['observedFact'], 'Клиент замолчал.');
  });

  test('a different connection key cannot decrypt a request', () async {
    final invitation = await service.createInvitation(
      joinBaseUri: Uri.parse('https://example.test/join'),
    );
    final otherInvitation = await service.createInvitation(
      joinBaseUri: Uri.parse('https://example.test/join'),
    );
    final encrypted = await service.encryptJson(
      connectionId: 'connection-1',
      objectId: 'request-1',
      connectionKey: invitation.connectionKey,
      payload: const {'question': 'Проверить гипотезу'},
    );

    await expectLater(
      service.decryptJson(
        connectionId: 'connection-1',
        objectId: 'request-1',
        connectionKey: otherInvitation.connectionKey,
        payload: encrypted,
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('ciphertext cannot be moved to another request id', () async {
    final invitation = await service.createInvitation(
      joinBaseUri: Uri.parse('https://example.test/join'),
    );
    final encrypted = await service.encryptJson(
      connectionId: 'connection-1',
      objectId: 'request-1',
      connectionKey: invitation.connectionKey,
      payload: const {'question': 'Что я не замечаю?'},
    );

    await expectLater(
      service.decryptJson(
        connectionId: 'connection-1',
        objectId: 'request-2',
        connectionKey: invitation.connectionKey,
        payload: encrypted,
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
