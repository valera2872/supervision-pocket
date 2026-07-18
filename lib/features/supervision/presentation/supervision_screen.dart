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
                        'Здесь собраны эпизоды, в которых вы сформулировали вопрос супервизору.',
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
                            Icons.privacy_tip_outlined,
                            color: AppColors.navy,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ничего не отправляется автоматически. Можно передать зашифрованный пакет в Supervision Pocket или обычный текст. Перед отправкой проверьте обезличивание.',
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.caseFile, required this.entry});

  final CaseFile caseFile;
  final ReflectionEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            const SizedBox(height: 12),
            Text(
              entry.supervisionQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            _Part(label: 'Что произошло', value: entry.observedFact),
            _Part(label: 'Как я это понял(а)', value: entry.interpretation),
            _Part(label: 'Что я почувствовал(а)', value: entry.feeling),
            _Part(label: 'Как я отреагировал(а)', value: entry.actionTaken),
            _Part(label: 'Что осталось непонятным', value: entry.stuckPoint),
            const SizedBox(height: 5),
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
          subject: 'Запрос к супервизии: ${caseFile.alias}',
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
    final parts = <String>[
      'Запрос к супервизии',
      'Случай: ${caseFile.alias}, ${caseFile.ageRange}',
      if (caseFile.context.isNotEmpty) 'Краткий контекст: ${caseFile.context}',
      'Что произошло: ${entry.observedFact}',
      if (entry.interpretation.isNotEmpty)
        'Как я это понял(а): ${entry.interpretation}',
      if (entry.feeling.isNotEmpty)
        'Что я почувствовал(а): ${entry.feeling}',
      if (entry.impulse.isNotEmpty)
        'Что мне захотелось сделать: ${entry.impulse}',
      if (entry.actionTaken.isNotEmpty)
        'Как я отреагировал(а): ${entry.actionTaken}',
      if (entry.stuckPoint.isNotEmpty)
        'Что осталось непонятным: ${entry.stuckPoint}',
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
    if (value.isEmpty) return const SizedBox.shrink();
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
            'Запишите сложный эпизод и сформулируйте вопрос. После сохранения он появится здесь.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
