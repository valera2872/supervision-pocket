import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review build does not block screenshots', () {
    final source = File(
      'android/app/src/main/kotlin/com/supervisionpocket/app/MainActivity.kt',
    ).readAsStringSync();

    expect(source, isNot(contains('FLAG_SECURE')));
    expect(source, isNot(contains('WindowManager')));
  });
}
