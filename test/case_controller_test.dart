import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

void main() {
  test('creates an anonymized case and persists it', () async {
    final repository = MemoryCaseRepository();
    final controller = CaseController(repository);
    await controller.initialize();

    final created = await controller.createCase(
      alias: 'Маяк',
      ageRange: '7–9 лет',
      context: 'Трудности адаптации',
    );

    expect(controller.cases, hasLength(1));
    expect(controller.cases.single.id, created.id);
    expect(repository.stored.single.alias, 'Маяк');
  });

  test('draft survives controller restart', () async {
    final repository = MemoryCaseRepository();
    final first = CaseController(repository);
    await first.initialize();
    final caseFile = await first.createCase(
      alias: 'Случай А',
      ageRange: '10–12 лет',
      context: '',
    );
    await first.saveDraft(
      caseFile.id,
      ReflectionDraft(
        updatedAt: DateTime.now(),
        observedFact: 'Ребёнок отвернулся и замолчал.',
      ),
    );

    final restored = CaseController(repository);
    await restored.initialize();

    expect(restored.cases.single.draft?.observedFact, contains('замолчал'));
  });

  test('reflection produces a supervision question and clears draft', () async {
    final controller = CaseController(MemoryCaseRepository());
    await controller.initialize();
    final caseFile = await controller.createCase(
      alias: 'Компас',
      ageRange: '13–15 лет',
      context: '',
    );
    final draft = ReflectionDraft(
      updatedAt: DateTime.now(),
      observedFact: 'Подросток несколько раз сменил тему.',
      stuckPoint: 'Не понимаю, стоит ли возвращать разговор.',
      supervisionQuestion: 'Как удерживать тему, не усиливая давление?',
    );

    await controller.saveDraft(caseFile.id, draft);
    await controller.addReflection(caseFile.id, draft);

    expect(controller.cases.single.entries, hasLength(1));
    expect(controller.cases.single.draft, isNull);
    expect(controller.supervisionQuestions, hasLength(1));
  });
}
