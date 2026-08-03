import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/transfer/presentation/request_transfer_flow.dart';

class SupervisionScreen extends StatelessWidget {
  const SupervisionScreen({required this.controller, super.key});

  final CaseController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final questions = controller.supervisionQuestions;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'К ближайшей супервизии',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Здесь собраны подготовленные вопросы и материалы, которые вы решили вынести на встречу.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (questions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptySupervision(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.paleBlue,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.navy,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ничего не отправляется автоматически. Вы сами выбираете, какой материал и когда передать супервизору.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = questions[index];
                      return _QuestionCard(
                        caseFile: item.caseFile,
                        entry: item.entry,
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({required this.caseFile, required this.entry});

  final CaseFile caseFile;
  final ReflectionEntry entry;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final caseFile = widget.caseFile;
    final entry = widget.entry;
    final full = entry.mode == ReflectionMode.casePreparation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paleTeal,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${caseFile.alias} · ${caseFile.ageRange}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (full)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paleBlue,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Подготовленный кейс',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.supervisionQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => setState(() => expanded = !expanded),
              icon: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(expanded ? 'Скрыть материал' : 'Показать материал'),
            ),
            if (expanded) ...[
              if (full) ...[
                _Part(label: 'Запрос клиента', value: entry.clientRequest),
                _Part(
                  label: 'Значимый контекст',
                  value: entry.relevantContext,
                ),
                _Part(
                  label: 'Текущая динамика',
                  value: entry.currentDynamics,
                ),
              ],
              _Part(label: 'Наблюдаемый эпизод', value: entry.observedFact),
              _Part(label: 'Моя интерпретация', value: entry.interpretation),
              _Part(label: 'Моя реакция', value: entry.feeling),
              _Part(label: 'Первый импульс', value: entry.impulse),
              _Part(label: 'Что я сделал(а)', value: entry.actionTaken),
              if (full) ...[
                _Part(
                  label: 'Что уже пробовал(а)',
                  value: entry.previousAttempts,
                ),
                _Part(label: 'Ресурсы', value: entry.resources),
                _Part(
                  label: 'Рабочая гипотеза',
                  value: entry.workingHypothesis,
                ),
                _Part(
                  label: 'Этика, границы и безопасность',
                  value: entry.ethicalContext,
                ),
                _Part(
                  label: 'Тип запроса',
                  value: _requestTypeLabel(entry.requestType),
                ),
              ],
              _Part(
                label: 'Что осталось непонятным',
                value: entry.stuckPoint,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showRequestTransferOptions(
                      context,
                      caseFile: caseFile,
                      entry: entry,
                      onShareAsText: () => _shareAsText(context),
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Передать супервизору'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _copy(context),
                  tooltip: 'Скопировать текст',
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsText(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _requestText(),
          subject: 'Запрос к супервизии: ${widget.caseFile.alias}',
          title: 'Передать запрос как текст',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось открыть меню передачи. Скопируйте текст соседней кнопкой.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _requestText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запрос скопирован'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _requestText() {
    final caseFile = widget.caseFile;
    final entry = widget.entry;
    final parts = <String>[
      'Запрос к супервизии',
      'Случай: ${caseFile.alias}, ${caseFile.ageRange}',
      if (caseFile.context.isNotEmpty) 'Краткий контекст: ${caseFile.context}',
      if (entry.clientRequest.isNotEmpty)
        'Запрос клиента: ${entry.clientRequest}',
      if (entry.relevantContext.isNotEmpty)
        'Значимый контекст: ${entry.relevantContext}',
      if (entry.currentDynamics.isNotEmpty)
        'Текущая динамика: ${entry.currentDynamics}',
      'Наблюдаемый эпизод: ${entry.observedFact}',
      if (entry.interpretation.isNotEmpty)
        'Моя интерпретация: ${entry.interpretation}',
      if (entry.feeling.isNotEmpty) 'Моя реакция: ${entry.feeling}',
      if (entry.impulse.isNotEmpty) 'Первый импульс: ${entry.impulse}',
      if (entry.actionTaken.isNotEmpty)
        'Что я сделал(а): ${entry.actionTaken}',
      if (entry.previousAttempts.isNotEmpty)
        'Что уже пробовал(а): ${entry.previousAttempts}',
      if (entry.resources.isNotEmpty) 'Ресурсы: ${entry.resources}',
      if (entry.workingHypothesis.isNotEmpty)
        'Рабочая гипотеза: ${entry.workingHypothesis}',
      if (entry.ethicalContext.isNotEmpty)
        'Этика, границы или безопасность: ${entry.ethicalContext}',
      if (entry.stuckPoint.isNotEmpty)
        'Что осталось непонятным: ${entry.stuckPoint}',
      'Тип запроса: ${_requestTypeLabel(entry.requestType)}',
      'Мой вопрос: ${entry.supervisionQuestion}',
    ];
    return parts.join('\n\n');
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
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

class _EmptySupervision extends StatelessWidget {
  const _EmptySupervision();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paleBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 38,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Пока нечего передавать супервизору',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Запишите сложный эпизод или подготовьте кейс и сформулируйте конкретный вопрос.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
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
