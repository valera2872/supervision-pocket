from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"Expected text not found in {path}: {old[:80]!r}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


# Keep the detailed privacy reminder in onboarding only.
replace_once(
    "lib/features/cases/presentation/reflection_editor_screen.dart",
    "Я проверил(а), что нет имён, адресов, школы, места работы и других узнаваемых деталей",
    "Материал готов к передаче",
)
replace_once(
    "lib/features/supervision/presentation/supervision_screen.dart",
    "Ничего не отправляется автоматически. Перед передачей проверьте, что в тексте нет имён, адресов, школы, места работы и других узнаваемых деталей.",
    "Ничего не отправляется автоматически. Вы сами выбираете, какой материал и когда передать супервизору.",
)
replace_once(
    "lib/features/supervision/presentation/supervision_screen.dart",
    "Icons.privacy_tip_outlined",
    "Icons.info_outline_rounded",
)

transfer_path = Path(
    "lib/features/transfer/presentation/request_transfer_flow.dart"
)
transfer = transfer_path.read_text(encoding="utf-8")
transfer = transfer.replace(
    "Супервизор выберет «Получить запрос» в своём приложении, откроет файл и введёт этот код:",
    "Для открытия супервизору нужны прикреплённый файл .sprequest и этот код:",
    1,
)
transfer = transfer.replace(
    "Код будет добавлен в сообщение вместе с файлом. Перед отправкой ещё раз проверьте, что в карточке нет идентифицирующих данных клиента.",
    "Код будет добавлен в сообщение. Если рядом с сообщением нет файла .sprequest, запрос не был передан.",
    1,
)
transfer = transfer.replace(
    "'Запрос для Supervision Pocket. Код импорта: ${exported.code}'",
    "'Запрос Supervision Pocket.\\n\\n'\n"
    "            '1. Сохраните прикреплённый файл .sprequest.\\n'\n"
    "            '2. Откройте Supervision Pocket Test в роли «Супервизор».\\n'\n"
    "            '3. Нажмите «Открыть файл запроса».\\n'\n"
    "            '4. Выберите файл и введите код: ${exported.code}\\n\\n'\n"
    "            'Без прикреплённого файла один код не откроет запрос.'",
    1,
)

marker = "Future<void> importRequestPackage("
if marker not in transfer:
    raise SystemExit("Import flow marker not found")
head = transfer.split(marker, 1)[0]
new_tail = r'''Future<void> importRequestPackage(
  BuildContext context,
  SupervisorController controller,
) async {
  final ready = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Открыть файл запроса'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Для импорта нужны два элемента: прикреплённый файл .sprequest и восьмисимвольный код из сообщения.',
          ),
          SizedBox(height: 12),
          Text(
            'Один код без файла не содержит запрос и открыть его нельзя.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Выбрать файл'),
        ),
      ],
    ),
  );
  if (ready != true || !context.mounted) {
    return;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
  );
  final pickedFile = picked?.files.single;
  final filePath = pickedFile?.path;
  if (filePath == null || !context.mounted) {
    return;
  }
  if (!(pickedFile?.name.toLowerCase().endsWith(
        '.${SupervisionTransferService.fileExtension}',
      ) ??
      false)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Выберите прикреплённый файл с окончанием .sprequest, а не текст сообщения.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final codeController = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Введите код из сообщения'),
      content: TextField(
        controller: codeController,
        autofocus: true,
        maxLength: 8,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: 'Например: A7K9M2Q4',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Вставить код',
            icon: const Icon(Icons.content_paste_rounded),
            onPressed: () async {
              final clipboard = await Clipboard.getData('text/plain');
              final value = clipboard?.text?.trim().toUpperCase() ?? '';
              if (value.isNotEmpty) {
                codeController.text = value.length > 8
                    ? value.substring(0, 8)
                    : value;
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final value = codeController.text.trim().toUpperCase();
            if (value.length == 8) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: const Text('Открыть запрос'),
        ),
      ],
    ),
  );
  codeController.dispose();
  if (code == null || !context.mounted) {
    return;
  }

  try {
    final payload = await SupervisionTransferService().importRequest(
      filePath: filePath,
      code: code,
    );
    if (!context.mounted) {
      return;
    }

    final superviseeId = await _chooseOrCreateSupervisee(context, controller);
    if (superviseeId == null || !context.mounted) {
      return;
    }
    final profile = controller.findSupervisee(superviseeId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          profile == null
              ? 'Добавить полученный запрос?'
              : 'Добавить запрос для ${profile.displayName}?',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payload.question,
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(payload.toSupervisorContext()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Добавить в кабинет'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await controller.addRequest(
      superviseeId: superviseeId,
      question: payload.question,
      context: payload.toSupervisorContext(),
    );
    if (!context.mounted) {
      return;
    }
    final destination = profile?.displayName ?? 'супервизант';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Запрос сохранён: Супервизанты → $destination → Запросы',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  } on FormatException catch (error) {
    if (!context.mounted) {
      return;
    }
    final wrongCode = error.message == 'Wrong transfer code';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wrongCode
              ? 'Код не подошёл. Проверьте восемь символов и повторите.'
              : 'Выбранный файл не является запросом Supervision Pocket.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Не удалось открыть запрос. Убедитесь, что выбраны файл .sprequest и код из одного сообщения.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<String?> _chooseOrCreateSupervisee(
  BuildContext context,
  SupervisorController controller,
) async {
  if (controller.supervisees.isEmpty) {
    return _createSuperviseeForImport(context, controller);
  }
  if (controller.supervisees.length == 1) {
    return controller.supervisees.first.id;
  }
  final selected = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'Для кого этот запрос?',
          style: Theme.of(sheetContext).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите супервизанта, в чью профессиональную историю добавить материал.',
          style: Theme.of(sheetContext).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.person_add_alt_1_rounded),
          title: const Text('Добавить нового супервизанта'),
          onTap: () => Navigator.pop(sheetContext, '__new__'),
        ),
        const Divider(),
        ...controller.supervisees.map(
          (profile) => ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(profile.displayName),
            subtitle: profile.professionalContext.isEmpty
                ? null
                : Text(profile.professionalContext),
            onTap: () => Navigator.pop(sheetContext, profile.id),
          ),
        ),
      ],
    ),
  );
  if (selected == '__new__' && context.mounted) {
    return _createSuperviseeForImport(context, controller);
  }
  return selected;
}

Future<String?> _createSuperviseeForImport(
  BuildContext context,
  SupervisorController controller,
) async {
  final nameController = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Как подписать супервизанта?'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Имя или рабочее обозначение',
          hintText: 'Например: Анна или Группа 2026',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final value = nameController.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: const Text('Создать и продолжить'),
        ),
      ],
    ),
  );
  nameController.dispose();
  if (name == null) {
    return null;
  }
  final profile = await controller.addSupervisee(
    displayName: name,
    professionalContext: '',
  );
  return profile.id;
}
'''
transfer_path.write_text(head + new_tail, encoding="utf-8")

replace_once(
    "lib/features/supervisor/presentation/supervisor_workspace_host.dart",
    "icon: const Icon(Icons.move_to_inbox_outlined),\n                  label: const Text('Получить запрос'),",
    "icon: const Icon(Icons.folder_open_outlined),\n                  label: const Text('Открыть файл запроса'),",
)
replace_once(
    "pubspec.yaml",
    "version: 0.9.5+16",
    "version: 0.9.6+17",
)

Path("test/import_ux_copy_test.dart").write_text(
    r'''import 'dart:io';

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
''',
    encoding="utf-8",
)

# One-time automation should not remain in main.
Path("scripts/apply_0_9_6.py").unlink(missing_ok=True)
Path(".github/workflows/apply-0.9.6.yml").unlink(missing_ok=True)
