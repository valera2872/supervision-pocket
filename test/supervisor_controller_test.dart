import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

void main() {
  test('supervisor can prepare, complete and follow up a meeting', () async {
    final repository = MemorySupervisorRepository();
    final controller = SupervisorController(repository);
    await controller.initialize();

    final supervisee = await controller.addSupervisee(
      displayName: 'Анна',
      professionalContext: 'Работает с детьми и родителями',
      professionalRole: 'Начинающий детский психолог',
      approach: 'Интегративный подход',
      experience: '1 год практики',
      meetingCadence: 'Каждые две недели',
    );
    final request = await controller.addRequest(
      superviseeId: supervisee.id,
      question: 'Как удержать границы и не уходить в спасательство?',
      context: 'Повторяющийся эпизод в работе с родителем.',
    );
    await controller.saveRequestPreparation(
      requestId: request.id,
      selectedFocuses: const [
        SupervisionFocus.therapistProcess,
        SupervisionFocus.widerContext,
      ],
      suggestedRole: SupervisorRole.facilitator,
      missingInformation: 'Как устроен контракт с родителем?',
      preparationQuestions: 'В какой момент появляется импульс спасать?',
      ethicalOrSystemicNotes: 'Проверить распределение ответственности.',
    );
    final meeting = await controller.createMeeting(
      superviseeId: supervisee.id,
      scheduledAt: DateTime(2026, 7, 24, 18),
    );

    await controller.addRequestToMeeting(
      meetingId: meeting.id,
      requestId: request.id,
    );
    await controller.saveMeeting(
      meetingId: meeting.id,
      scheduledAt: meeting.scheduledAt,
      privatePreparationNotes: 'Проверить гипотезу о спасательстве.',
      sharedSummary: 'Замечать момент потери профессиональной позиции.',
      whatBecameClear: 'Спасательство включается при беспомощности родителя.',
      perspectivesConsidered: 'Отношения, контекст и реакция психолога.',
      workingHypothesis: 'Импульс снижает собственную тревогу психолога.',
      remainingUncertainty: 'Неясна роль второго родителя.',
      nextStep: 'Обсудить границы контракта с родителем.',
      attentionMarker: 'Желание немедленно дать готовое решение.',
      followUpQuestion: 'Что меняется в следующем похожем эпизоде?',
    );

    expect(controller.upcomingMeetings, hasLength(1));
    expect(controller.requestsForMeeting(meeting.id), hasLength(1));
    expect(
      controller.findRequest(request.id)!.selectedFocuses,
      contains(SupervisionFocus.therapistProcess),
    );

    await controller.completeMeeting(meeting.id);
    await controller.saveFollowUp(
      meetingId: meeting.id,
      result: 'Удалось выдержать паузу и вернуть ответственность родителю.',
    );

    expect(controller.upcomingMeetings, isEmpty);
    expect(controller.completedMeetings, hasLength(1));
    expect(
      controller.findRequest(request.id)!.status,
      SupervisionRequestStatus.completed,
    );
    expect(
      controller.findMeeting(meeting.id)!.followUpResult,
      contains('выдержать паузу'),
    );
    expect(controller.findMeeting(meeting.id)!.followUpCheckedAt, isNotNull);
  });

  test('continuing request keeps its status when meeting completes', () async {
    final repository = MemorySupervisorRepository();
    final controller = SupervisorController(repository);
    await controller.initialize();
    final supervisee = await controller.addSupervisee(
      displayName: 'Мария',
      professionalContext: '',
    );
    final request = await controller.addRequest(
      superviseeId: supervisee.id,
      question: 'Что требует дальнейшего исследования?',
      context: '',
    );
    final meeting = await controller.createMeeting(
      superviseeId: supervisee.id,
      scheduledAt: DateTime(2026, 8, 1, 12),
    );
    await controller.addRequestToMeeting(
      meetingId: meeting.id,
      requestId: request.id,
    );
    await controller.updateRequestStatus(
      request.id,
      SupervisionRequestStatus.continuing,
    );
    await controller.completeMeeting(meeting.id);

    expect(
      controller.findRequest(request.id)!.status,
      SupervisionRequestStatus.continuing,
    );
  });

  test('0.8 workspace JSON migrates with methodology fields empty', () {
    final workspace = SupervisorWorkspace.fromJson({
      'supervisees': [
        {
          'id': 's-1',
          'displayName': 'Анна',
          'professionalContext': 'Психолог',
          'invitationCode': 'ABC234',
          'createdAt': '2026-07-17T12:00:00.000',
        },
      ],
      'requests': [
        {
          'id': 'r-1',
          'superviseeId': 's-1',
          'question': 'Вопрос',
          'context': '',
          'receivedAt': '2026-07-17T12:30:00.000',
          'status': 'newRequest',
        },
      ],
    });

    expect(workspace.meetings, isEmpty);
    expect(workspace.supervisees.single.approach, isEmpty);
    expect(workspace.requests.single.meetingId, isNull);
    expect(workspace.requests.single.selectedFocuses, isEmpty);
  });

  test('0.9.2 meeting JSON migrates with structured outcome defaults', () {
    final meeting = SupervisionMeeting.fromJson({
      'id': 'm-1',
      'superviseeId': 's-1',
      'scheduledAt': '2026-07-30T12:00:00.000',
      'createdAt': '2026-07-29T12:00:00.000',
      'status': 'completed',
      'agendaRequestIds': <String>[],
      'privatePreparationNotes': '',
      'sharedSummary': 'Старый итог',
      'nextStep': 'Шаг',
      'followUpQuestion': 'Вопрос',
      'completedAt': '2026-07-30T13:00:00.000',
    });

    expect(meeting.sharedSummary, 'Старый итог');
    expect(meeting.whatBecameClear, isEmpty);
    expect(meeting.followUpResult, isEmpty);
  });
}
