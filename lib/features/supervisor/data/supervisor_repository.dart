import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

abstract interface class SupervisorRepository {
  Future<SupervisorWorkspace> read();
  Future<void> write(SupervisorWorkspace workspace);
}

class EncryptedSupervisorRepository implements SupervisorRepository {
  EncryptedSupervisorRepository({
    FlutterSecureStorage? secureStorage,
    Future<Directory> Function()? directoryProvider,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final FlutterSecureStorage _secureStorage;
  final Future<Directory> Function() _directoryProvider;
  final Cipher _cipher = AesGcm.with256bits();

  static const _keyName = 'supervisor_vault_master_key_v1';
  static const _fileName = 'supervisor_workspace.vault';

  @override
  Future<SupervisorWorkspace> read() async {
    final file = await _vaultFile();
    if (!await file.exists()) return const SupervisorWorkspace();

    final envelope = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    if (envelope['version'] != 1) {
      throw const FormatException('Unsupported supervisor vault version');
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
    final decoded = jsonDecode(utf8.decode(clearBytes)) as Map<String, Object?>;
    return SupervisorWorkspace.fromJson(decoded);
  }

  @override
  Future<void> write(SupervisorWorkspace workspace) async {
    final clearBytes = utf8.encode(jsonEncode(workspace.toJson()));
    final box = await _cipher.encrypt(
      clearBytes,
      secretKey: SecretKey(await _masterKey()),
      nonce: _randomBytes(12),
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

class MemorySupervisorRepository implements SupervisorRepository {
  SupervisorWorkspace workspace = const SupervisorWorkspace();

  @override
  Future<SupervisorWorkspace> read() async => workspace;

  @override
  Future<void> write(SupervisorWorkspace value) async {
    workspace = value;
  }
}
