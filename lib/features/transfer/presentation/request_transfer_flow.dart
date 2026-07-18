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
        observedFact: entry.observedFact,
        interpretation: entry.interpretation,
        feeling: entry.feeling,
        impulse: entry.impulse,
        actionTaken: entry.actionTaken,
        stuckPoint: entry.stuckPoint,
        question: entry.supervisionQuestion,
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
              'Супервизор выберет «Получить запрос» в своём приложении, откроет файл и введёт этот код:',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
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
              'Код будет добавлен в сообщение вместе с файлом. Перед отправкой ещё раз проверьте, что в карточке нет идентифицирующих данных клиента.',
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
            'Запрос для Supervision Pocket. Код импорта: ${exported.code}',
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
  if (controller.supervisees.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Сначала добавьте супервизанта, чтобы связать с ним полученный запрос.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const [SupervisionTransferService.fileExtension],
    allowMultiple: false,
  );
  final filePath = picked?.files.single.path;
  if (filePath == null || !context.mounted) return;

  final codeController = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Введите код пакета'),
      content: TextField(
        controller: codeController,
        autofocus: true,
        maxLength: 8,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'Например: A7K9M2Q4',
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
            final value = codeController.text.trim().toUpperCase();
            if (value.length == 8) Navigator.pop(dialogContext, value);
          },
          child: const Text('Открыть'),
        ),
      ],
    ),
  );
  codeController.dispose();
  if (code == null || !context.mounted) return;

  try {
    final payload = await SupervisionTransferService().importRequest(
      filePath: filePath,
      code: code,
    );
    if (!context.mounted) return;

    final superviseeId = await _chooseSupervisee(context, controller);
    if (superviseeId == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить полученный запрос?'),
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
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.addRequest(
      superviseeId: superviseeId,
      question: payload.question,
      context: payload.toSupervisorContext(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Запрос добавлен в кабинет супервизора'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on FormatException catch (error) {
    if (!context.mounted) return;
    final wrongCode = error.message == 'Wrong transfer code';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wrongCode
              ? 'Код не подошёл. Проверьте восемь символов и повторите импорт.'
              : 'Файл не является корректным пакетом Supervision Pocket.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось открыть пакет запроса.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<String?> _chooseSupervisee(
  BuildContext context,
  SupervisorController controller,
) async {
  if (controller.supervisees.length == 1) {
    return controller.supervisees.first.id;
  }
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'От кого получен запрос?',
          style: Theme.of(sheetContext).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите супервизанта, в чью профессиональную историю добавить материал.',
          style: Theme.of(sheetContext).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
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
}
