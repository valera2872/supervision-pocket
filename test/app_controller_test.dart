import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';

void main() {
  test('new user is sent to onboarding', () async {
    final controller = AppController(MemorySecurityStore());
    await controller.initialize();
    expect(controller.gate, AppGate.onboarding);
  });

  test('onboarding stores consent and unlocks the app', () async {
    final store = MemorySecurityStore();
    final controller = AppController(store);
    await controller.initialize();
    await controller.finishOnboarding('2468');

    expect(controller.gate, AppGate.ready);
    expect(await store.hasAcceptedPrivacyRules(), isTrue);
    expect(await store.verifyPin('2468'), isTrue);
  });

  test('existing user starts locked and valid pin unlocks', () async {
    final store = MemorySecurityStore()
      ..consentVersion = '1.0'
      ..pin = '1357';
    final controller = AppController(store);
    await controller.initialize();

    expect(controller.gate, AppGate.locked);
    expect(await controller.unlock('0000'), isFalse);
    expect(await controller.unlock('1357'), isTrue);
    expect(controller.gate, AppGate.ready);
  });
}
