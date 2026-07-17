import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

class SupervisorController extends ChangeNotifier {
  SupervisorController(this._repository);

  final SupervisorRepository _repository;

  SupervisorWorkspace _workspace = const SupervisorWorkspace();
  bool _loading = true;
  Object? _error;
  Future<void> _writeQueue = Future.value();

  bool get loading => _loading;
  Object? get error => _error;

  List<SuperviseeProfile> get supervisees {
    final result = [..._workspace.supervisees]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return List.unmodifiable(result);
  }

  List<SharedSupervisionRequest> get requests {
    final result = [..._workspace.requests]
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return List.unmodifiable(result);
  }

  List<SupervisionMeeting> get meetings {
    final result = [..._workspace.meetings]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return List.unmodifiable(result);
  }

  List<SupervisionMeeting> get upcomingMeetings => meetings
      .where((item) => item.status == SupervisionMeetingStatus.planned)
      .toList(growable: false);

  List<SupervisionMeeting> get completedMeetings {
    final result = meetings
        .where((item) => item.status == SupervisionMeetingStatus.completed)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return List.unmodifiable(result);
  }

  List<SharedSupervisionRequest> get newRequests => requests
      .where((item) => item.status == SupervisionRequestStatus.newRequest)
      .toList(growable: false);

  List<SharedSupervisionRequest> get plannedRequests => requests
      .where((item) => item.status == SupervisionRequestStatus.planned)
      .toList(growable: false);

  Future<void> initialize() async {
    try {
      _workspace = await _repository.read();
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  SuperviseeProfile? findSupervisee(String id) {
    for (final item in _workspace.supervisees) {
      if (item.id == id) return item;
    }
    return null;
  }

  SharedSupervisionRequest? findRequest(String id) {
    for (final item in _workspace.requests) {
      if (item.id == id) return item;
    }
    return null;
  }

  SupervisionMeeting? findMeeting(String id) {
    for (final item in _workspace.meetings) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<SharedSupervisionRequest> requestsForSupervisee(String superviseeId) {
    return requests
        .where((item) => item.superviseeId == superviseeId)
        .toList(growable: false);
  }

  List<SupervisionMeeting> meetingsForSupervisee(String superviseeId) {
    final result = meetings
        .where((item) => item.superviseeId == superviseeId)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return List.unmodifiable(result);
  }

  List<SharedSupervisionRequest> requestsForMeeting(String meetingId) {
    final meeting = findMeeting(meetingId);
    if (meeting == null) return const [];
    return meeting.agendaRequestIds
        .map(findRequest)
        .whereType<SharedSupervisionRequest>()
        .toList(growable: false);
  }

  SupervisionMeeting? nextMeetingFor(String superviseeId) {
    final candidates = upcomingMeetings
        .where((item) => item.superviseeId == superviseeId)
        .toList();
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<SuperviseeProfile> addSupervisee({
    required String displayName,
    required String professionalContext,
    String professionalRole = '',
    String approach = '',
    String experience = '',
    String meetingCadence = '',
  }) async {
    final profile = SuperviseeProfile(
      id: _newId('supervisee'),
      displayName: displayName.trim(),
      professionalContext: professionalContext.trim(),
      invitationCode: _invitationCode(),
      createdAt: DateTime.now(),
      professionalRole: professionalRole.trim(),
      approach: approach.trim(),
      experience: experience.trim(),
      meetingCadence: meetingCadence.trim(),
    );
    await _commit(
      SupervisorWorkspace(
        supervisees: [..._workspace.supervisees, profile],
        requests: _workspace.requests,
        meetings: _workspace.meetings,
      ),
    );
    return profile;
  }

  Future<void> updateSupervisee({
    required String id,
    required String displayName,
    required String professionalContext,
    required String professionalRole,
    required String approach,
    required String experience,
    required String meetingCadence,
    required String privateNotes,
  }) async {
    final updated = _workspace.supervisees
        .map(
          (item) => item.id == id
              ? item.copyWith(
                  displayName: displayName.trim(),
                  professionalContext: professionalContext.trim(),
                  professionalRole: professionalRole.trim(),
                  approach: approach.trim(),
                  experience: experience.trim(),
                  meetingCadence: meetingCadence.trim(),
                  privateNotes: privateNotes.trim(),
                )
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: updated,
        requests: _workspace.requests,
        meetings: _workspace.meetings,
      ),
    );
  }

  Future<SharedSupervisionRequest> addRequest({
    required String superviseeId,
    required String question,
    required String context,
  }) async {
    if (findSupervisee(superviseeId) == null) {
      throw StateError('Supervisee not found');
    }
    final request = SharedSupervisionRequest(
      id: _newId('request'),
      superviseeId: superviseeId,
      question: question.trim(),
      context: context.trim(),
      receivedAt: DateTime.now(),
    );
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: [..._workspace.requests, request],
        meetings: _workspace.meetings,
      ),
    );
    return request;
  }

  Future<void> updateRequestStatus(
    String requestId,
    SupervisionRequestStatus status,
  ) async {
    final updated = _workspace.requests
        .map(
          (item) => item.id == requestId ? item.copyWith(status: status) : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: updated,
        meetings: _workspace.meetings,
      ),
    );
  }

  Future<SupervisionMeeting> createMeeting({
    required String superviseeId,
    required DateTime scheduledAt,
  }) async {
    if (findSupervisee(superviseeId) == null) {
      throw StateError('Supervisee not found');
    }
    final meeting = SupervisionMeeting(
      id: _newId('meeting'),
      superviseeId: superviseeId,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    );
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: _workspace.requests,
        meetings: [..._workspace.meetings, meeting],
      ),
    );
    return meeting;
  }

  Future<void> saveMeeting({
    required String meetingId,
    required DateTime scheduledAt,
    required String privatePreparationNotes,
    required String sharedSummary,
    required String nextStep,
    required String followUpQuestion,
  }) async {
    final updated = _workspace.meetings
        .map(
          (item) => item.id == meetingId
              ? item.copyWith(
                  scheduledAt: scheduledAt,
                  privatePreparationNotes: privatePreparationNotes.trim(),
                  sharedSummary: sharedSummary.trim(),
                  nextStep: nextStep.trim(),
                  followUpQuestion: followUpQuestion.trim(),
                )
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: _workspace.requests,
        meetings: updated,
      ),
    );
  }

  Future<void> addRequestToMeeting({
    required String meetingId,
    required String requestId,
  }) async {
    final meeting = findMeeting(meetingId);
    final request = findRequest(requestId);
    if (meeting == null || request == null) return;
    if (request.superviseeId != meeting.superviseeId) {
      throw StateError('Request belongs to another supervisee');
    }
    final agenda = {...meeting.agendaRequestIds, requestId}.toList();
    final updatedMeetings = _workspace.meetings
        .map(
          (item) => item.id == meetingId
              ? item.copyWith(agendaRequestIds: agenda)
              : item,
        )
        .toList();
    final updatedRequests = _workspace.requests
        .map(
          (item) => item.id == requestId
              ? item.copyWith(
                  meetingId: meetingId,
                  status: SupervisionRequestStatus.planned,
                )
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: updatedRequests,
        meetings: updatedMeetings,
      ),
    );
  }

  Future<void> removeRequestFromMeeting({
    required String meetingId,
    required String requestId,
  }) async {
    final meeting = findMeeting(meetingId);
    if (meeting == null) return;
    final agenda = meeting.agendaRequestIds
        .where((item) => item != requestId)
        .toList();
    final updatedMeetings = _workspace.meetings
        .map(
          (item) => item.id == meetingId
              ? item.copyWith(agendaRequestIds: agenda)
              : item,
        )
        .toList();
    final updatedRequests = _workspace.requests
        .map(
          (item) => item.id == requestId && item.meetingId == meetingId
              ? item.copyWith(
                  status: SupervisionRequestStatus.newRequest,
                  clearMeeting: true,
                )
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: updatedRequests,
        meetings: updatedMeetings,
      ),
    );
  }

  Future<void> completeMeeting(String meetingId) async {
    final now = DateTime.now();
    final meeting = findMeeting(meetingId);
    if (meeting == null) return;
    final agendaIds = meeting.agendaRequestIds.toSet();
    final updatedMeetings = _workspace.meetings
        .map(
          (item) => item.id == meetingId
              ? item.copyWith(
                  status: SupervisionMeetingStatus.completed,
                  completedAt: now,
                )
              : item,
        )
        .toList();
    final updatedRequests = _workspace.requests
        .map(
          (item) => agendaIds.contains(item.id) &&
                  item.status == SupervisionRequestStatus.planned
              ? item.copyWith(status: SupervisionRequestStatus.completed)
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: updatedRequests,
        meetings: updatedMeetings,
      ),
    );
  }

  Future<void> reopenMeeting(String meetingId) async {
    final updated = _workspace.meetings
        .map(
          (item) => item.id == meetingId
              ? item.copyWith(
                  status: SupervisionMeetingStatus.planned,
                  clearCompletedAt: true,
                )
              : item,
        )
        .toList();
    await _commit(
      SupervisorWorkspace(
        supervisees: _workspace.supervisees,
        requests: _workspace.requests,
        meetings: updated,
      ),
    );
  }

  Future<void> _commit(SupervisorWorkspace next) async {
    final previous = _workspace;
    _workspace = next;
    _error = null;
    notifyListeners();
    final snapshot = next;
    _writeQueue = _writeQueue.then((_) => _repository.write(snapshot));
    try {
      await _writeQueue;
    } catch (error) {
      if (identical(_workspace, next)) _workspace = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  String _newId(String prefix) {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  String _invitationCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
