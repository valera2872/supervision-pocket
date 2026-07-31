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
              PopupMenuButton<String>(
                tooltip: 'Действия со случаем',
                onSelected: (value) {
                  if (value == 'archive') _confirmArchive(context);
                  if (value == 'delete') _confirmDeleteCase(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Переместить в архив'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Удалить случай'),
                    ),
                  ),
                ],
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
                    child: _ReflectionCard(
                      entry: entry,
                      onEdit: () => openReflectionEditor(
                        context,
                        controller,
                        caseId,
                        entryId: entry.id,
                      ),
                      onDelete: () => _confirmDeleteEntry(context, entry),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openReflectionEditor(context, controller, caseId),
            icon: Icon(
              caseFile.draft == null
                  ? Icons.add_rounded
                  : Icons.edit_note_rounded,
            ),
            label: Text(
              caseFile.draft == null
                  ? 'Новая запись'
                  : 'Продолжить черновик',
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('В архив'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.archive(caseId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmDeleteCase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить случай безвозвратно?'),
        content: const Text(
          'Будут удалены карточка, все записи и черновик этого случая. Отменить действие нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteCase(caseId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmDeleteEntry(
    BuildContext context,
    ReflectionEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить эту запись?'),
        content: const Text(
          'Запись исчезнет из хронологии и списка запросов к супервизии. Отменить действие нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteReflection(caseId, entry.id);
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
            Text(
              caseFile.context,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
            Text(
              'Записей пока нет',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Сохраните быстрый эпизод после консультации или сразу подготовьте развёрнутый кейс к встрече.',
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
  const _ReflectionCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final ReflectionEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<_ReflectionCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final full = entry.mode == ReflectionMode.casePreparation;
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
                  _ModeChip(full: full),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _formatDate(entry.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Действия с записью',
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Изменить')),
                      PopupMenuItem(value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                entry.observedFact,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
                      const Icon(
                        Icons.forum_outlined,
                        size: 20,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(entry.supervisionQuestion)),
                    ],
                  ),
                ),
              ],
              if (expanded) ...[
                if (full) ...[
                  _Detail(label: 'Запрос клиента', value: entry.clientRequest),
                  _Detail(
                    label: 'Значимый контекст',
                    value: entry.relevantContext,
                  ),
                  _Detail(
                    label: 'Текущая динамика',
                    value: entry.currentDynamics,
                  ),
                ],
                _Detail(
                  label: 'Моя интерпретация',
                  value: entry.interpretation,
                ),
                _Detail(
                  label: 'Что я почувствовал(а)',
                  value: entry.feeling,
                ),
                _Detail(label: 'Первый импульс', value: entry.impulse),
                _Detail(label: 'Что я сделал(а)', value: entry.actionTaken),
                if (full) ...[
                  _Detail(
                    label: 'Что уже пробовал(а)',
                    value: entry.previousAttempts,
                  ),
                  _Detail(label: 'Ресурсы', value: entry.resources),
                  _Detail(
                    label: 'Рабочая гипотеза',
                    value: entry.workingHypothesis,
                  ),
                  _Detail(
                    label: 'Этика, границы и безопасность',
                    value: entry.ethicalContext,
                  ),
                  _Detail(
                    label: 'Тип запроса',
                    value: _requestTypeLabel(entry.requestType),
                  ),
                ],
                _Detail(
                  label: 'Что осталось непонятным',
                  value: entry.stuckPoint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: full ? AppColors.paleBlue : AppColors.paleTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        full ? 'Кейс' : 'Быстро',
        style: TextStyle(
          color: full ? AppColors.navy : AppColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
    if (value.trim().isEmpty) return const SizedBox.shrink();
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

String _requestTypeLabel(SupervisionRequestType type) => switch (type) {
      SupervisionRequestType.understandingCase => 'Понимание случая',
      SupervisionRequestType.therapistReaction => 'Реакция психолога',
      SupervisionRequestType.therapeuticRelationship => 'Отношения и процесс',
      SupervisionRequestType.interventionChoice => 'Выбор интервенции',
      SupervisionRequestType.ethicsAndRisk => 'Этика, границы или риск',
      SupervisionRequestType.settingAndContract => 'Сеттинг или контракт',
      SupervisionRequestType.other => 'Другое / не определено',
    };
