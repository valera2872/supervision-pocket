import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';

void main() {
  testWidgets('first launch shows the product promise', (tester) async {
    final controller = AppController(MemorySecurityStore());
    await controller.initialize();

    await tester.pumpWidget(SupervisionPocketApp(controller: controller));
    await tester.pumpAndSettle();

    expect(
      find.text('Сохраняйте важное между консультацией и супервизией'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Продолжить'), findsOneWidget);
  });
}
