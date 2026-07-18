import 'package:flutter/material.dart';

Future<void> showResetApplicationDialog(
  BuildContext context, {
  required Future<void> Function() onReset,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Начать с нового листа?'),
      content: const Text(
        'Будут удалены все случаи, черновики, запросы, супервизанты, встречи, PIN и выбранная роль. Это действие нельзя отменить.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Удалить всё'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await onReset();
}
