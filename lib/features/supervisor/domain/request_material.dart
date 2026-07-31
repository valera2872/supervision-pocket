class RequestMaterialSection {
  const RequestMaterialSection({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class RequestMaterial {
  const RequestMaterial({
    required this.sections,
    required this.isStructured,
  });

  final List<RequestMaterialSection> sections;
  final bool isStructured;

  factory RequestMaterial.parse(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return const RequestMaterial(sections: [], isStructured: false);
    }

    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final sections = <RequestMaterialSection>[];
    var recognized = 0;

    for (final paragraph in paragraphs) {
      final colon = paragraph.indexOf(':');
      if (colon <= 0) {
        sections.add(
          RequestMaterialSection(label: 'Материал', value: paragraph),
        );
        continue;
      }
      final rawLabel = paragraph.substring(0, colon).trim();
      final value = paragraph.substring(colon + 1).trim();
      if (value.isEmpty) {
        continue;
      }
      final normalized = _knownLabels[rawLabel.toLowerCase()];
      if (normalized != null) {
        recognized += 1;
      }
      sections.add(
        RequestMaterialSection(
          label: normalized ?? rawLabel,
          value: value,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(RequestMaterialSection(label: 'Материал', value: text));
    }
    return RequestMaterial(
      sections: List.unmodifiable(sections),
      isStructured: recognized >= 2,
    );
  }
}

const _knownLabels = <String, String>{
  'случай': 'Случай',
  'краткий контекст': 'Краткий контекст',
  'запрос клиента': 'Запрос клиента',
  'значимый контекст': 'Значимый контекст',
  'текущая динамика': 'Текущая динамика',
  'наблюдаемый эпизод': 'Наблюдаемый эпизод',
  'что произошло': 'Наблюдаемый эпизод',
  'интерпретация психолога': 'Интерпретация психолога',
  'как это понял психолог': 'Интерпретация психолога',
  'чувства психолога': 'Реакция психолога',
  'первый импульс': 'Первый импульс',
  'реакция психолога': 'Действия психолога',
  'что уже пробовали': 'Что уже пробовали',
  'ресурсы и то, что работает': 'Ресурсы и опоры',
  'рабочая гипотеза': 'Рабочая гипотеза',
  'этика, границы или безопасность': 'Этика, границы и безопасность',
  'что осталось непонятным': 'Что осталось непонятным',
  'тип запроса': 'Тип запроса',
};
