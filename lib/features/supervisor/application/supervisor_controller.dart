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

  Future<SuperviseeProfile> addSupervisee({
    required String displayName,
    required String professionalContext,
  }) async {
    final profile = SuperviseeProfile(
      id: _newId('supervisee'),
      displayName: displayName.trim(),
      professionalContext: professionalContext.trim(),
      invitationCode: _invitationCode(),
      createdAt: DateTime.now(),
    );
    _workspace = SupervisorWorkspace(
      supervisees: [..._workspace.supervisees, profile],
      requests: _workspace.requests,
    );
    await _persist();
    return profile;
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
    _workspace = SupervisorWorkspace(
      supervisees: _workspace.supervisees,
      requests: [..._workspace.requests, request],
    );
    await _persist();
    return request;
  }

  Future<void> updateRequestStatus(
    String requestId,
    SupervisionRequestStatus status,
  ) async {
    final requests = _workspace.requests
        .map(
          (item) => item.id == requestId ? item.copyWith(status: status) : item,
        )
        .toList();
    _workspace = SupervisorWorkspace(
      supervisees: _workspace.supervisees,
      requests: requests,
    );
    await _persist();
  }

  Future<void> _persist() {
    final snapshot = _workspace;
    _writeQueue = _writeQueue.then((_) => _repository.write(snapshot));
    return _writeQueue.then((_) {
      _error = null;
      notifyListeners();
    }).catchError((Object error) {
      _error = error;
      notifyListeners();
      throw error;
    });
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
