import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/transfer/data/supervision_transfer_service.dart';

Future<void> showRequestTransferOptions(
  BuildContext context, {
  required CaseFile caseFile,
  required ReflectionEntry entry,
  required Future<void> Function() onShareAsText,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Как передать запрос?',
            style: Theme.of(sheetContext).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите передачу в кабинет Supervision Pocket или обычный текст для любого мессенджера.',
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('В Supervision Pocket'),
              subtitle: const Text(
                'Зашифрованный файл и короткий код для импорта в кабинет супервизора',
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => Navigator.pop(sheetContext, 'package'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Отправить как текст'),
              subtitle: const Text(
                'Для супервизора, который не использует приложение',
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => Navigator.pop(sheetContext, 'text'),
            ),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'text') {
    await onShareAsText();
    return;
  }
  await _sharePackage(context, caseFile: caseFile, entry: entry);
}

Future<void> _sharePackage(
  BuildContext context, {
  required CaseFile caseFile,
  required ReflectionEntry entry,
}) async {
  try {
    final service = SupervisionTransferService();
    final exported = await service.exportRequest(
      TransferRequestPayload(
        caseAlias: caseFile.alias,
        ageRange: caseFile.ageRange,
        caseContext: caseFile.context,
        mode: entry.mode.name,
        observedFact: entry.observedFact,
        interpretation: entry.interpretation,
        feeling: entry.feeling,
        impulse: entry.impulse,
        actionTaken: entry.actionTaken,
        stuckPoint: entry.stuckPoint,
        question: entry.supervisionQuestion,
        clientRequest: entry.clientRequest,
        relevantContext: entry.relevantContext,
        currentDynamics: entry.currentDynamics,
        workingHypothesis: entry.workingHypothesis,
        previousAttempts: entry.previousAttempts,
        resources: entry.resources,
        ethicalContext: entry.ethicalContext,
        requestType: entry.requestType.name,
        createdAt: entry.createdAt,
      ),
    );
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Пакет для супервизора готов'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Для открытия супервизору нужны прикреплённый файл .sprequest и этот код:',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                exported.code,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Код будет добавлен в сообщение. Если рядом с сообщением нет файла .sprequest, запрос не был передан.',
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
            icon: const Icon(Icons.send_outlined),
            label: const Text('Отправить файл'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await Clipboard.setData(ClipboardData(text: exported.code));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            exported.file.path,
            mimeType: SupervisionTransferService.mimeType,
            name: exported.file.uri.pathSegments.last,
          ),
        ],
        text:
            'Запрос Supervision Pocket.\n\n'
            '1. Сохраните прикреплённый файл .sprequest.\n'
            '2. Откройте Supervision Pocket Test в роли «Супервизор».\n'
            '3. Нажмите «Открыть файл запроса».\n'
            '4. Выберите файл и введите код: ${exported.code}\n\n'
            'Без прикреплённого файла один код не откроет запрос.',
        subject: 'Запрос к супервизии: ${caseFile.alias}',
        title: 'Передать запрос в Supervision Pocket',
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Не удалось создать пакет. Можно отправить запрос как обычный текст.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> importRequestPackage(
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
