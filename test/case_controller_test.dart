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

  test('full case preparation survives JSON migration and restart', () async {
    final repository = MemoryCaseRepository();
    final controller = CaseController(repository);
    await controller.initialize();
    final caseFile = await controller.createCase(
      alias: 'Компас',
      ageRange: '13–15 лет',
      context: 'Индивидуальная работа',
    );
    final draft = ReflectionDraft(
      updatedAt: DateTime.now(),
      mode: ReflectionMode.casePreparation,
      clientRequest: 'Хочу меньше конфликтовать с родителями.',
      relevantContext: 'Работа длится три месяца.',
      currentDynamics: 'Стал чаще говорить о злости.',
      observedFact: 'Подросток несколько раз сменил тему.',
      interpretation: 'Возможно, избегал разговора о стыде.',
      workingHypothesis: 'Смена темы защищает от уязвимости.',
      previousAttempts: 'Возвращал к теме прямым вопросом.',
      resources: 'Умеет замечать телесное напряжение.',
      ethicalContext: 'Нужно уточнить границы информации для родителей.',
      requestType: SupervisionRequestType.therapeuticRelationship,
      supervisionQuestion: 'Как оставаться рядом, не усиливая давление?',
    );

    await controller.addReflection(caseFile.id, draft);
    final restored = CaseController(repository);
    await restored.initialize();
    final entry = restored.cases.single.entries.single;

    expect(entry.mode, ReflectionMode.casePreparation);
    expect(entry.workingHypothesis, contains('уязвимости'));
    expect(entry.requestType, SupervisionRequestType.therapeuticRelationship);
  });

  test('reflection can be edited and deleted separately', () async {
    final controller = CaseController(MemoryCaseRepository());
    await controller.initialize();
    final caseFile = await controller.createCase(
      alias: 'Парус',
      ageRange: 'Взрослый',
      context: '',
    );
    await controller.addReflection(
      caseFile.id,
      ReflectionDraft(
        updatedAt: DateTime.now(),
        observedFact: 'Клиент замолчал.',
        supervisionQuestion: 'Что делать?',
      ),
    );
    final entryId = controller.cases.single.entries.single.id;

    await controller.updateReflection(
      caseFile.id,
      entryId,
      ReflectionDraft(
        updatedAt: DateTime.now(),
        observedFact: 'Клиент замолчал после вопроса о злости.',
        supervisionQuestion: 'Как исследовать молчание без давления?',
      ),
    );

    expect(
      controller.cases.single.entries.single.observedFact,
      contains('после вопроса'),
    );
    await controller.deleteReflection(caseFile.id, entryId);
    expect(controller.cases.single.entries, isEmpty);
  });

  test('old 0.9.2 reflection JSON receives safe defaults', () {
    final entry = ReflectionEntry.fromJson({
      'id': 'entry-1',
      'createdAt': '2026-07-30T12:00:00.000',
      'observedFact': 'Факт',
      'interpretation': 'Гипотеза',
      'feeling': '',
      'impulse': '',
      'actionTaken': '',
      'stuckPoint': '',
      'supervisionQuestion': 'Вопрос',
    });

    expect(entry.mode, ReflectionMode.quick);
    expect(entry.clientRequest, isEmpty);
    expect(entry.requestType, SupervisionRequestType.other);
  });
}
