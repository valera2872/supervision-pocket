import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/voice_input_button.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

Future<CaseFile?> showCreateCaseSheet(
  BuildContext context,
  CaseController controller,
) async {
  final input = await showModalBottomSheet<_CaseInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CreateCaseSheet(),
  );
  if (input == null) return null;

  try {
    return await controller.createCase(
      alias: input.alias,
      ageRange: input.ageRange,
      context: input.context,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось создать карточку. Данные не потеряны — попробуйте ещё раз.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }
}

class _CaseInput {
  const _CaseInput({
    required this.alias,
    required this.ageRange,
    required this.context,
  });

  final String alias;
  final String ageRange;
  final String context;
}

class _CreateCaseSheet extends StatefulWidget {
  const _CreateCaseSheet();

  @override
  State<_CreateCaseSheet> createState() => _CreateCaseSheetState();
}

class _CreateCaseSheetState extends State<_CreateCaseSheet> {
  final _aliasController = TextEditingController();
  final _contextController = TextEditingController();
  String _ageRange = '7–9 лет';
  bool _confirmed = false;

  @override
  void dispose() {
    _aliasController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _submit() {
    final alias = _aliasController.text.trim();
    if (alias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите псевдоним клиента')),
      );
      return;
    }
    Navigator.pop(
      context,
      _CaseInput(
        alias: alias,
        ageRange: _ageRange,
        context: _contextController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Карточка клиента',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте условное обозначение, чтобы затем добавлять к нему сложные эпизоды после консультаций.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _aliasController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Псевдоним клиента',
                hintText: 'Например: Клиент А или Маяк',
                border: const OutlineInputBorder(),
                helperText: 'Не используйте имя или инициалы клиента',
                suffixIcon: VoiceInputButton(
                  controller: _aliasController,
                  fieldName: 'псевдоним клиента',
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ageRange,
              decoration: const InputDecoration(
                labelText: 'Возрастной диапазон',
                border: OutlineInputBorder(),
              ),
              items: const [
                '3–6 лет',
                '7–9 лет',
                '10–12 лет',
                '13–15 лет',
                '16–17 лет',
                '18 лет и старше',
              ]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _ageRange = value ?? _ageRange);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contextController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Что нужно знать о ситуации?',
                hintText:
                    'Например: первая встреча, ребёнок 9 лет, обращение из-за школьной тревоги',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                suffixIcon: VoiceInputButton(
                  controller: _contextController,
                  fieldName: 'контекст ситуации',
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('В карточке нет личных данных клиента'),
              subtitle: const Text(
                'Без настоящих имён, школы, адреса и телефона.',
              ),
              onChanged: (value) {
                setState(() => _confirmed = value ?? false);
              },
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _confirmed ? _submit : null,
              child: const Text('Создать карточку'),
            ),
          ],
        ),
      ),
    );
  }
}
