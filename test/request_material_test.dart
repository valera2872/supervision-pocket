import 'package:flutter_test/flutter_test.dart';
import 'package:supervision_pocket/features/supervisor/domain/request_material.dart';

void main() {
  test('parses transferred case into labeled sections', () {
    final material = RequestMaterial.parse(
      'Случай: Маяк, 10–12 лет\n\n'
      'Запрос клиента: Хочу меньше бояться школы.\n\n'
      'Наблюдаемый эпизод: Клиент замолчал после вопроса.\n\n'
      'Рабочая гипотеза: Молчание защищает от стыда.',
    );

    expect(material.isStructured, isTrue);
    expect(material.sections, hasLength(4));
    expect(material.sections[1].label, 'Запрос клиента');
    expect(material.sections[2].value, contains('замолчал'));
  });

  test('preserves an old free-text request', () {
    final material = RequestMaterial.parse(
      'Повторяющийся эпизод в работе с родителем.',
    );

    expect(material.isStructured, isFalse);
    expect(material.sections.single.label, 'Материал');
    expect(material.sections.single.value, contains('родителем'));
  });
}
