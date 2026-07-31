import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/cases/presentation/reflection_editor_screen.dart';

void main() {
  testWidgets('case preparation uses compact sections without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CaseController(MemoryCaseRepository());
    await controller.initialize();
    final caseFile = await controller.createCase(
      alias: 'Маяк',
      ageRange: '10–12 лет',
      context: '',
    );
    await controller.saveDraft(
      caseFile.id,
      ReflectionDraft(
        updatedAt: DateTime.now(),
        mode: ReflectionMode.casePreparation,
        observedFact: 'Клиент замолчал после вопроса.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReflectionEditorScreen(
          controller: controller,
          caseId: caseFile.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Контекст клиента и работы'), findsOneWidget);
    expect(find.text('5. Запрос на супервизию'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
