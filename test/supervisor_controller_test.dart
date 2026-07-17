import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

void main() {
  test('supervisor can build and complete a supervision meeting', () async {
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
      nextStep: 'Обсудить границы контракта с родителем.',
      followUpQuestion: 'Что меняется в следующем похожем эпизоде?',
    );

    expect(controller.upcomingMeetings, hasLength(1));
    expect(controller.requestsForMeeting(meeting.id), hasLength(1));
    expect(
      controller.findRequest(request.id)!.status,
      SupervisionRequestStatus.planned,
    );
    expect(
      controller.findMeeting(meeting.id)!.privatePreparationNotes,
      contains('гипотезу'),
    );

    await controller.completeMeeting(meeting.id);

    expect(controller.upcomingMeetings, isEmpty);
    expect(controller.completedMeetings, hasLength(1));
    expect(
      controller.findRequest(request.id)!.status,
      SupervisionRequestStatus.completed,
    );
    expect(repository.workspace.meetings.single.sharedSummary, isNotEmpty);
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

  test('0.8 workspace JSON migrates with empty meetings and profile fields', () {
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
  });
}
