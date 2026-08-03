import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('working screens do not repeat detailed privacy warning', () {
    const files = [
      'lib/features/cases/presentation/reflection_editor_screen.dart',
      'lib/features/supervision/presentation/supervision_screen.dart',
      'lib/features/transfer/presentation/request_transfer_flow.dart',
    ];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('имён, адресов, школы, места работы')));
    }
  });

  test('import copy explains that file and code are both required', () {
    final source = File(
      'lib/features/transfer/presentation/request_transfer_flow.dart',
    ).readAsStringSync();
    expect(source, contains('Один код без файла не содержит запрос'));
    expect(source, contains('Открыть файл запроса'));
    expect(source, contains('FileType.any'));
  });
}
