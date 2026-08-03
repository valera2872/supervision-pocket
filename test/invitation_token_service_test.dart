import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/sync/data/invitation_token_service.dart';

void main() {
  const service = InvitationTokenService();

  test('produces stable SHA-256 hex for the server invitation RPC', () {
    expect(
      service.sha256Hex('invite-token'),
      'f9e3c47d452a8fab2dc56ef07d766534cb2cd31c5f63de7107412acc65daa5b8',
    );
  });

  test('rejects an empty token', () {
    expect(() => service.sha256Hex('   '), throwsArgumentError);
  });
}
