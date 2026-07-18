import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/transfer/data/supervision_transfer_service.dart';

void main() {
  test('request package round trips with its code', () async {
    final directory = await Directory.systemTemp.createTemp('sp-transfer-test');
    addTearDown(() => directory.delete(recursive: true));
    final service = SupervisionTransferService(
      directoryProvider: () async => directory,
    );
    final payload = TransferRequestPayload(
      caseAlias: 'Клиент А',
      ageRange: '8–10 лет',
      caseContext: 'Работа с тревогой',
      observedFact: 'Клиент замолчал после вопроса.',
      interpretation: 'Я решил, что слишком тороплю.',
      feeling: 'Растерянность',
      impulse: 'Сменить тему',
      actionTaken: 'Выдержал паузу',
      stuckPoint: 'Не понимаю, когда возвращаться к теме.',
      question: 'Как выдерживать паузу и не уходить в спасательство?',
      createdAt: DateTime(2026, 7, 18, 20, 0),
    );

    final exported = await service.exportRequest(payload);
    final imported = await service.importRequest(
      filePath: exported.file.path,
      code: exported.code,
    );

    expect(await exported.file.exists(), isTrue);
    expect(exported.code, hasLength(8));
    expect(imported.caseAlias, payload.caseAlias);
    expect(imported.question, payload.question);
    expect(imported.toSupervisorContext(), contains(payload.observedFact));
  });

  test('wrong code does not open a request package', () async {
    final directory = await Directory.systemTemp.createTemp('sp-transfer-test');
    addTearDown(() => directory.delete(recursive: true));
    final service = SupervisionTransferService(
      directoryProvider: () async => directory,
    );
    final exported = await service.exportRequest(
      TransferRequestPayload(
        caseAlias: 'Случай',
        ageRange: '',
        caseContext: '',
        observedFact: 'Эпизод',
        interpretation: '',
        feeling: '',
        impulse: '',
        actionTaken: '',
        stuckPoint: '',
        question: 'Вопрос?',
        createdAt: DateTime(2026, 7, 18),
      ),
    );

    expect(
      () => service.importRequest(
        filePath: exported.file.path,
        code: 'AAAAAAAA',
      ),
      throwsFormatException,
    );
  });
}
