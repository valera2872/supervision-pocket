import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';

void main() {
  testWidgets('first launch presents the premium product promise', (tester) async {
    final controller = AppController(MemorySecurityStore());
    final caseController = CaseController(MemoryCaseRepository());
    await controller.initialize();
    await caseController.initialize();

    await tester.pumpWidget(
      SupervisionPocketApp(
        controller: controller,
        caseController: caseController,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('После консультации —\nяснее к супервизии'),
      findsOneWidget,
    );
    expect(
      find.text('Для психологов, которые проходят супервизию'),
      findsOneWidget,
    );
    expect(find.text('Эпизод'), findsOneWidget);
    expect(find.text('Реакция'), findsOneWidget);
    expect(find.text('Вопрос'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Продолжить'), findsOneWidget);
  });
}
