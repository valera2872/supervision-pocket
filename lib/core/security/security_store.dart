import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecurityStore {
  Future<bool> hasAcceptedPrivacyRules();
  Future<void> acceptPrivacyRules(String version);
  Future<bool> hasPin();
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
}

class FlutterSecurityStore implements SecurityStore {
  FlutterSecurityStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _consentVersionKey = 'privacy_consent_version';
  static const _pinSaltKey = 'pin_salt';
  static const _pinHashKey = 'pin_hash';

  @override
  Future<bool> hasAcceptedPrivacyRules() async {
    return (await _storage.read(key: _consentVersionKey)) != null;
  }

  @override
  Future<void> acceptPrivacyRules(String version) {
    return _storage.write(key: _consentVersionKey, value: version);
  }

  @override
  Future<bool> hasPin() async {
    final salt = await _storage.read(key: _pinSaltKey);
    final hash = await _storage.read(key: _pinHashKey);
    return salt != null && hash != null;
  }

  @override
  Future<void> savePin(String pin) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(24, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _constantTimeEquals(_hashPin(pin, salt), storedHash);
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}

class MemorySecurityStore implements SecurityStore {
  String? consentVersion;
  String? pin;

  @override
  Future<void> acceptPrivacyRules(String version) async {
    consentVersion = version;
  }

  @override
  Future<bool> hasAcceptedPrivacyRules() async => consentVersion != null;

  @override
  Future<bool> hasPin() async => pin != null;

  @override
  Future<void> savePin(String value) async {
    pin = value;
  }

  @override
  Future<bool> verifyPin(String value) async => value == pin;
}
