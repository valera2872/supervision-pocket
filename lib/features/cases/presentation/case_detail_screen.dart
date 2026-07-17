import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/cases/presentation/reflection_editor_screen.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({
    required this.controller,
    required this.caseId,
    super.key,
  });

  final CaseController controller;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final caseFile = controller.findById(caseId);
        if (caseFile == null) {
          return const Scaffold(body: Center(child: Text('Случай не найден')));
        }
        final entries = caseFile.entries.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(caseFile.alias),
            actions: [
              IconButton(
                onPressed: () => _confirmArchive(context),
                tooltip: 'Архивировать',
                icon: const Icon(Icons.archive_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              _CaseHeader(caseFile: caseFile),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Профессиональная хронология',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${entries.length}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const _NoReflections()
              else
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReflectionCard(entry: entry),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openReflectionEditor(context, controller, caseId),
            icon: Icon(caseFile.draft == null ? Icons.add_rounded : Icons.edit_note_rounded),
            label: Text(caseFile.draft == null ? 'Новая рефлексия' : 'Продолжить черновик'),
          ),
        );
      },
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переместить в архив?'),
        content: const Text(
          'Карточка исчезнет из активных случаев, но останется в защищённом хранилище.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('В архив')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.archive(caseId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.caseFile});

  final CaseFile caseFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paleTeal,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.teal),
              const SizedBox(width: 9),
              Text(
                caseFile.ageRange,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'Локально зашифровано',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          if (caseFile.context.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(caseFile.context, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _NoReflections extends StatelessWidget {
  const _NoReflections();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.notes_rounded, size: 38, color: AppColors.teal),
            const SizedBox(height: 12),
            Text('Записей пока нет', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'После сложной консультации сохраните наблюдаемый факт, свою реакцию и вопрос к супервизору.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatefulWidget {
  const _ReflectionCard({required this.entry});

  final ReflectionEntry entry;

  @override
  State<_ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<_ReflectionCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Card(
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(entry.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(entry.observedFact, style: Theme.of(context).textTheme.bodyLarge),
              if (entry.supervisionQuestion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.forum_outlined, size: 20, color: AppColors.navy),
                      const SizedBox(width: 9),
                      Expanded(child: Text(entry.supervisionQuestion)),
                    ],
                  ),
                ),
              ],
              if (expanded) ...[
                _Detail(label: 'Моя интерпретация', value: entry.interpretation),
                _Detail(label: 'Что я почувствовал(а)', value: entry.feeling),
                _Detail(label: 'Первый импульс', value: entry.impulse),
                _Detail(label: 'Что я сделал(а)', value: entry.actionTaken),
                _Detail(label: 'Где возник тупик', value: entry.stuckPoint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year} · ${two(value.hour)}:${two(value.minute)}';
}
