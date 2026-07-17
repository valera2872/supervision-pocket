import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supervision_pocket/core/security/security_store.dart';

enum AppGate { loading, onboarding, locked, roleSelection, ready }

enum UserRole { supervisee, supervisor }

extension UserRoleValue on UserRole {
  String get storageValue => switch (this) {
        UserRole.supervisee => 'supervisee',
        UserRole.supervisor => 'supervisor',
      };

  String get title => switch (this) {
        UserRole.supervisee => 'Я психолог и прохожу супервизию',
        UserRole.supervisor => 'Я супервизор',
      };

  static UserRole? fromStorage(String? value) {
    return switch (value) {
      'supervisee' => UserRole.supervisee,
      'supervisor' => UserRole.supervisor,
      _ => null,
    };
  }
}

class AppController extends ChangeNotifier {
  AppController(this._securityStore);

  final SecurityStore _securityStore;

  AppGate _gate = AppGate.loading;
  AppGate get gate => _gate;

  UserRole? _role;
  UserRole? get role => _role;

  int _failedAttempts = 0;
  DateTime? _blockedUntil;
  int get failedAttempts => _failedAttempts;
  Duration? get remainingBlock {
    final until = _blockedUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<void> initialize() async {
    final hasConsent = await _securityStore.hasAcceptedPrivacyRules();
    final hasPin = await _securityStore.hasPin();
    _role = UserRoleValue.fromStorage(await _securityStore.readRole());
    _gate = hasConsent && hasPin ? AppGate.locked : AppGate.onboarding;
    notifyListeners();
  }

  Future<void> finishOnboarding(String pin) async {
    await _securityStore.savePin(pin);
    await _securityStore.acceptPrivacyRules('1.0');
    _failedAttempts = 0;
    _blockedUntil = null;
    _gate = _role == null ? AppGate.roleSelection : AppGate.ready;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final remaining = remainingBlock;
    if (remaining != null) return false;

    final valid = await _securityStore.verifyPin(pin);
    if (valid) {
      _failedAttempts = 0;
      _blockedUntil = null;
      _gate = _role == null ? AppGate.roleSelection : AppGate.ready;
      notifyListeners();
      return true;
    }

    _failedAttempts += 1;
    if (_failedAttempts >= 5) {
      _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
      _failedAttempts = 0;
    }
    notifyListeners();
    return false;
  }

  Future<void> chooseRole(UserRole role) async {
    await _securityStore.saveRole(role.storageValue);
    _role = role;
    _gate = AppGate.ready;
    notifyListeners();
  }

  void requestRoleSelection() {
    if (_gate != AppGate.ready) return;
    _gate = AppGate.roleSelection;
    notifyListeners();
  }

  void lock() {
    if (_gate != AppGate.ready && _gate != AppGate.roleSelection) return;
    _gate = AppGate.locked;
    notifyListeners();
  }
}
