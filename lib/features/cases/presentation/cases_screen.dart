import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/cases/presentation/case_detail_screen.dart';
import 'package:supervision_pocket/features/cases/presentation/create_case_sheet.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({required this.controller, super.key});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null) {
            return _VaultError(error: controller.error!);
          }
          final cases = controller.cases;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Случаи',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Псевдонимы, профессиональная хронология и вопросы к супервизии.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => _create(context),
                        tooltip: 'Создать случай',
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              if (cases.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyCases(onCreate: () => _create(context)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _CaseCard(
                      caseFile: cases[index],
                      onTap: () => _open(context, cases[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final created = await showCreateCaseSheet(context, controller);
    if (created != null && context.mounted) _open(context, created);
  }

  void _open(BuildContext context, CaseFile caseFile) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CaseDetailScreen(
          controller: controller,
          caseId: caseFile.id,
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.caseFile, required this.onTap});

  final CaseFile caseFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.folder_outlined, color: AppColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseFile.alias,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${caseFile.ageRange} · ${caseFile.entries.length} ${_entryWord(caseFile.entries.length)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (caseFile.draft != null) ...[
                      const SizedBox(height: 7),
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 18, color: AppColors.safety),
                          SizedBox(width: 5),
                          Text(
                            'Есть сохранённый черновик',
                            style: TextStyle(
                              color: AppColors.safety,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCases extends StatelessWidget {
  const _EmptyCases({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_outlined, size: 62, color: AppColors.teal),
          const SizedBox(height: 18),
          Text(
            'Создайте первый случай',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 9),
          Text(
            'Используйте только псевдоним и возрастной диапазон. Имя ребёнка, школа и контакты здесь не нужны.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Создать карточку'),
          ),
        ],
      ),
    );
  }
}

class _VaultError extends StatelessWidget {
  const _VaultError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 58, color: AppColors.safety),
          const SizedBox(height: 16),
          Text(
            'Не удалось открыть защищённое хранилище',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Данные не изменены. Перезапустите приложение. Если ошибка повторится, не переустанавливайте приложение до создания резервной копии.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _entryWord(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'запись';
  if ([2, 3, 4].contains(count % 10) && !(12 <= count % 100 && count % 100 <= 14)) {
    return 'записи';
  }
  return 'записей';
}
