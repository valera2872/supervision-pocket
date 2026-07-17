import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

abstract interface class CaseRepository {
  Future<List<CaseFile>> readAll();
  Future<void> writeAll(List<CaseFile> cases);
}

class EncryptedCaseRepository implements CaseRepository {
  EncryptedCaseRepository({
    FlutterSecureStorage? secureStorage,
    Future<Directory> Function()? directoryProvider,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final FlutterSecureStorage _secureStorage;
  final Future<Directory> Function() _directoryProvider;
  final Cipher _cipher = AesGcm.with256bits();

  static const _keyName = 'case_vault_master_key_v1';
  static const _fileName = 'cases.vault';

  @override
  Future<List<CaseFile>> readAll() async {
    final file = await _vaultFile();
    if (!await file.exists()) return [];

    final envelope = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    if (envelope['version'] != 1) {
      throw const FormatException('Unsupported case vault version');
    }

    final secretBox = SecretBox(
      base64Url.decode(envelope['cipherText']! as String),
      nonce: base64Url.decode(envelope['nonce']! as String),
      mac: Mac(base64Url.decode(envelope['mac']! as String)),
    );
    final clearBytes = await _cipher.decrypt(
      secretBox,
      secretKey: SecretKey(await _masterKey()),
    );
    final decoded = jsonDecode(utf8.decode(clearBytes)) as List<Object?>;
    return decoded
        .map((item) => CaseFile.fromJson(item! as Map<String, Object?>))
        .toList();
  }

  @override
  Future<void> writeAll(List<CaseFile> cases) async {
    final clearBytes = utf8.encode(
      jsonEncode(cases.map((item) => item.toJson()).toList()),
    );
    final nonce = _randomBytes(12);
    final box = await _cipher.encrypt(
      clearBytes,
      secretKey: SecretKey(await _masterKey()),
      nonce: nonce,
    );
    final envelope = jsonEncode({
      'version': 1,
      'nonce': base64UrlEncode(box.nonce),
      'cipherText': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    });

    final file = await _vaultFile();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(envelope, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<File> _vaultFile() async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}/$_fileName');
  }

  Future<List<int>> _masterKey() async {
    final stored = await _secureStorage.read(key: _keyName);
    if (stored != null) return base64Url.decode(stored);
    final key = _randomBytes(32);
    await _secureStorage.write(key: _keyName, value: base64UrlEncode(key));
    return key;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

class MemoryCaseRepository implements CaseRepository {
  List<CaseFile> stored = [];

  @override
  Future<List<CaseFile>> readAll() async => List.of(stored);

  @override
  Future<void> writeAll(List<CaseFile> cases) async {
    stored = List.of(cases);
  }
}
