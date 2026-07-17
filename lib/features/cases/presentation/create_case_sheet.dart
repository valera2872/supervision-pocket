import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

Future<CaseFile?> showCreateCaseSheet(
  BuildContext context,
  CaseController controller,
) async {
  final aliasController = TextEditingController();
  final contextController = TextEditingController();
  var ageRange = '7–9 лет';
  var confirmed = false;

  final input = await showModalBottomSheet<({String alias, String age, String context})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
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
              Text('Новый случай', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Создайте узнаваемую для себя, но обезличенную карточку.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: aliasController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Псевдоним',
                  hintText: 'Например: Маяк, Случай А',
                  border: OutlineInputBorder(),
                  helperText: 'Не используйте имя или инициалы ребёнка',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ageRange,
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
                ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => ageRange = value ?? ageRange,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contextController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Короткий контекст',
                  hintText: 'Что привело семью к психологу?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: confirmed,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('В карточке нет идентифицирующих данных'),
                subtitle: const Text('Без школы, адреса, телефона и настоящих имён.'),
                onChanged: (value) => setState(() => confirmed = value ?? false),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: confirmed
                    ? () {
                        final alias = aliasController.text.trim();
                        if (alias.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Введите псевдоним случая')),
                          );
                          return;
                        }
                        Navigator.pop(
                          sheetContext,
                          (alias: alias, age: ageRange, context: contextController.text),
                        );
                      }
                    : null,
                child: const Text('Создать защищённую карточку'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  aliasController.dispose();
  contextController.dispose();
  if (input == null) return null;
  return controller.createCase(
    alias: input.alias,
    ageRange: input.age,
    context: input.context,
  );
}
