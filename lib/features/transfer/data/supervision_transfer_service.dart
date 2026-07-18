import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

class TransferRequestPayload {
  const TransferRequestPayload({
    required this.caseAlias,
    required this.ageRange,
    required this.caseContext,
    required this.observedFact,
    required this.interpretation,
    required this.feeling,
    required this.impulse,
    required this.actionTaken,
    required this.stuckPoint,
    required this.question,
    required this.createdAt,
  });

  final String caseAlias;
  final String ageRange;
  final String caseContext;
  final String observedFact;
  final String interpretation;
  final String feeling;
  final String impulse;
  final String actionTaken;
  final String stuckPoint;
  final String question;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'caseAlias': caseAlias,
        'ageRange': ageRange,
        'caseContext': caseContext,
        'observedFact': observedFact,
        'interpretation': interpretation,
        'feeling': feeling,
        'impulse': impulse,
        'actionTaken': actionTaken,
        'stuckPoint': stuckPoint,
        'question': question,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransferRequestPayload.fromJson(Map<String, Object?> json) {
    return TransferRequestPayload(
      caseAlias: json['caseAlias'] as String? ?? 'Случай',
      ageRange: json['ageRange'] as String? ?? '',
      caseContext: json['caseContext'] as String? ?? '',
      observedFact: json['observedFact'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
      feeling: json['feeling'] as String? ?? '',
      impulse: json['impulse'] as String? ?? '',
      actionTaken: json['actionTaken'] as String? ?? '',
      stuckPoint: json['stuckPoint'] as String? ?? '',
      question: json['question'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toSupervisorContext() {
    final parts = <String>[
      'Случай: $caseAlias${ageRange.isEmpty ? '' : ', $ageRange'}',
      if (caseContext.isNotEmpty) 'Краткий контекст: $caseContext',
      if (observedFact.isNotEmpty) 'Что произошло: $observedFact',
      if (interpretation.isNotEmpty) 'Как это понял психолог: $interpretation',
      if (feeling.isNotEmpty) 'Чувства психолога: $feeling',
      if (impulse.isNotEmpty) 'Первый импульс: $impulse',
      if (actionTaken.isNotEmpty) 'Реакция психолога: $actionTaken',
      if (stuckPoint.isNotEmpty) 'Что осталось непонятным: $stuckPoint',
    ];
    return parts.join('\n\n');
  }
}

class TransferExport {
  const TransferExport({required this.file, required this.code});

  final File file;
  final String code;
}

class SupervisionTransferService {
  SupervisionTransferService({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getTemporaryDirectory;

  final Future<Directory> Function() _directoryProvider;
  final Cipher _cipher = AesGcm.with256bits();
  final KdfAlgorithm _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static const fileExtension = 'sprequest';
  static const mimeType = 'application/vnd.supervisionpocket.request+json';

  Future<TransferExport> exportRequest(TransferRequestPayload payload) async {
    final code = _newCode();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(code, salt);
    final clearBytes = utf8.encode(jsonEncode(payload.toJson()));
    final box = await _cipher.encrypt(
      clearBytes,
      secretKey: key,
      nonce: nonce,
    );
    final envelope = {
      'format': 'supervision-pocket-request',
      'version': 1,
      'kdf': 'pbkdf2-sha256-100000',
      'salt': base64UrlEncode(salt),
      'nonce': base64UrlEncode(box.nonce),
      'cipherText': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };

    final directory = await _directoryProvider();
    if (!await directory.exists()) await directory.create(recursive: true);
    final safeAlias = payload.caseAlias
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/request_${safeAlias.isEmpty ? 'case' : safeAlias}_$timestamp.$fileExtension',
    );
    await file.writeAsString(jsonEncode(envelope), flush: true);
    return TransferExport(file: file, code: code);
  }

  Future<TransferRequestPayload> importRequest({
    required String filePath,
    required String code,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('Transfer file not found');
    }
    final envelope = jsonDecode(await file.readAsString());
    if (envelope is! Map<String, Object?> ||
        envelope['format'] != 'supervision-pocket-request' ||
        envelope['version'] != 1) {
      throw const FormatException('Unsupported transfer package');
    }
    try {
      final salt = base64Url.decode(envelope['salt']! as String);
      final key = await _deriveKey(code.trim().toUpperCase(), salt);
      final box = SecretBox(
        base64Url.decode(envelope['cipherText']! as String),
        nonce: base64Url.decode(envelope['nonce']! as String),
        mac: Mac(base64Url.decode(envelope['mac']! as String)),
      );
      final clearBytes = await _cipher.decrypt(box, secretKey: key);
      final decoded = jsonDecode(utf8.decode(clearBytes));
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid transfer payload');
      }
      final payload = TransferRequestPayload.fromJson(decoded);
      if (payload.question.trim().isEmpty) {
        throw const FormatException('Request question is empty');
      }
      return payload;
    } on SecretBoxAuthenticationError {
      throw const FormatException('Wrong transfer code');
    }
  }

  Future<SecretKey> _deriveKey(String code, List<int> salt) {
    return _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(code.trim().toUpperCase())),
      nonce: salt,
    );
  }

  String _newCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
