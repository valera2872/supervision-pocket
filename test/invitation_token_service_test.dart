import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/sync/data/invitation_token_service.dart';

void main() {
  const service = InvitationTokenService();

  test('produces stable SHA-256 hex for the server invitation RPC', () {
    expect(
      service.sha256Hex('invite-token'),
      '26a0ba33f2daff0b503b6a757fb6f5bbfe1354cbfccdd49747f806d3e871f5dd',
    );
  });

  test('rejects an empty token', () {
    expect(() => service.sha256Hex('   '), throwsArgumentError);
  });
}
