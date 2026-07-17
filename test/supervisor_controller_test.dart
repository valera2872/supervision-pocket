import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

void main() {
  test('supervisor can add a supervisee and prepare a request', () async {
    final repository = MemorySupervisorRepository();
    final controller = SupervisorController(repository);
    await controller.initialize();

    final supervisee = await controller.addSupervisee(
      displayName: 'Анна',
      professionalContext: 'Начинающий детский психолог',
    );
    final request = await controller.addRequest(
      superviseeId: supervisee.id,
      question: 'Как удержать границы и не уходить в спасательство?',
      context: 'Повторяющийся эпизод в работе с родителем.',
    );

    expect(controller.supervisees, hasLength(1));
    expect(controller.newRequests, hasLength(1));
    expect(supervisee.invitationCode, hasLength(6));

    await controller.updateRequestStatus(
      request.id,
      SupervisionRequestStatus.planned,
    );

    expect(controller.newRequests, isEmpty);
    expect(controller.plannedRequests, hasLength(1));
    expect(repository.workspace.requests.single.status,
        SupervisionRequestStatus.planned);
  });
}
