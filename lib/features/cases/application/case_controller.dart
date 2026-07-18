import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

class CaseController extends ChangeNotifier {
  CaseController(this._repository);

  final CaseRepository _repository;
  final List<CaseFile> _cases = [];
  Future<void> _writeQueue = Future<void>.value();

  bool _loading = true;
  Object? _error;

  bool get loading => _loading;
  Object? get error => _error;

  List<CaseFile> get cases {
    final result = _cases.where((item) => !item.archived).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(result);
  }

  int get reflectionCount => _cases.fold(
        0,
        (count, item) => count + item.entries.length,
      );

  List<({CaseFile caseFile, ReflectionEntry entry})> get supervisionQuestions {
    final result = <({CaseFile caseFile, ReflectionEntry entry})>[];
    for (final caseFile in cases) {
      for (final entry in caseFile.entries) {
        if (entry.supervisionQuestion.trim().isNotEmpty) {
          result.add((caseFile: caseFile, entry: entry));
        }
      }
    }
    result.sort((a, b) => b.entry.createdAt.compareTo(a.entry.createdAt));
    return result;
  }

  Future<void> initialize() async {
    try {
      _cases
        ..clear()
        ..addAll(await _repository.readAll());
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  CaseFile? findById(String id) {
    for (final item in _cases) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<CaseFile> createCase({
    required String alias,
    required String ageRange,
    required String context,
  }) async {
    final now = DateTime.now();
    final caseFile = CaseFile(
      id: _newId('case'),
      alias: alias.trim(),
      ageRange: ageRange,
      context: context.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _cases.add(caseFile);
    await _persist();
    return caseFile;
  }

  Future<void> saveDraft(String caseId, ReflectionDraft draft) async {
    final index = _indexOf(caseId);
    _cases[index] = _cases[index].copyWith(
      draft: draft.isEmpty ? null : draft,
      clearDraft: draft.isEmpty,
      updatedAt: DateTime.now(),
    );
    await _persist(notify: false);
  }

  Future<void> clearDraft(String caseId) async {
    final index = _indexOf(caseId);
    _cases[index] = _cases[index].copyWith(
      clearDraft: true,
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> addReflection(String caseId, ReflectionDraft draft) async {
    final index = _indexOf(caseId);
    final current = _cases[index];
    final entries = [...current.entries, draft.toEntry(_newId('entry'))];
    _cases[index] = current.copyWith(
      entries: entries,
      clearDraft: true,
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> archive(String caseId) async {
    final index = _indexOf(caseId);
    _cases[index] = _cases[index].copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> clearAll() async {
    _cases.clear();
    await _persist();
  }

  int _indexOf(String id) {
    final index = _cases.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Case not found');
    return index;
  }

  Future<void> _persist({bool notify = true}) async {
    final snapshot = List<CaseFile>.unmodifiable(_cases);
    final operation = _writeQueue.then(
      (_) => _repository.writeAll(snapshot),
    );
    _writeQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );

    try {
      await operation;
      _error = null;
    } catch (error) {
      _error = error;
      if (notify) notifyListeners();
      rethrow;
    }
    if (notify) notifyListeners();
  }

  String _newId(String prefix) {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}
