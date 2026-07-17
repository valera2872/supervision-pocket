import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';

void main() {
  testWidgets('first launch presents the premium product promise', (tester) async {
    final controller = AppController(MemorySecurityStore());
    final caseController = CaseController(MemoryCaseRepository());
    final supervisorController = SupervisorController(
      MemorySupervisorRepository(),
    );
    await controller.initialize();
    await caseController.initialize();
    await supervisorController.initialize();

    await tester.pumpWidget(
      SupervisionPocketApp(
        controller: controller,
        caseController: caseController,
        supervisorController: supervisorController,
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

  testWidgets('main reflection screen fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemorySecurityStore()
      ..consentVersion = '1.0'
      ..pin = '1357'
      ..role = 'supervisee';
    final controller = AppController(store);
    final caseController = CaseController(MemoryCaseRepository());
    final supervisorController = SupervisorController(
      MemorySupervisorRepository(),
    );
    await controller.initialize();
    await controller.unlock('1357');
    await caseController.initialize();
    await supervisorController.initialize();

    await tester.pumpWidget(
      SupervisionPocketApp(
        controller: controller,
        caseController: caseController,
        supervisorController: supervisorController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Что осталось с вами после консультации?'), findsOneWidget);
    expect(find.text('Записать сложный момент'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
