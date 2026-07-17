import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

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
                      Text('Супервизия', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Подготовленные запросы из профессиональной хронологии.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (questions.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _EmptySupervision())
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
                          Icon(Icons.info_outline_rounded, color: AppColors.navy),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Перед передачей материала ещё раз проверьте, что в нём нет настоящих имён и других идентификаторов.',
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
            Row(
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
                const Spacer(),
                IconButton(
                  onPressed: () => _copy(context),
                  tooltip: 'Скопировать запрос',
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(entry.supervisionQuestion, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            _Part(label: 'Наблюдаемый эпизод', value: entry.observedFact),
            _Part(label: 'Моя гипотеза', value: entry.interpretation),
            _Part(label: 'Моя реакция', value: entry.feeling),
            _Part(label: 'Где я застрял(а)', value: entry.stuckPoint),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _requestText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Супервизионный запрос скопирован'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _requestText() {
    final parts = <String>[
      'Случай: ${caseFile.alias}, ${caseFile.ageRange}',
      if (caseFile.context.isNotEmpty) 'Контекст: ${caseFile.context}',
      'Наблюдаемый эпизод: ${entry.observedFact}',
      if (entry.interpretation.isNotEmpty) 'Моя рабочая гипотеза: ${entry.interpretation}',
      if (entry.feeling.isNotEmpty) 'Моя реакция: ${entry.feeling}',
      if (entry.actionTaken.isNotEmpty) 'Что я сделал(а): ${entry.actionTaken}',
      if (entry.stuckPoint.isNotEmpty) 'Где возник тупик: ${entry.stuckPoint}',
      'Вопрос к супервизору: ${entry.supervisionQuestion}',
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
            decoration: const BoxDecoration(color: AppColors.paleBlue, shape: BoxShape.circle),
            child: const Icon(Icons.forum_outlined, size: 38, color: AppColors.navy),
          ),
          const SizedBox(height: 18),
          Text(
            'Запросов пока нет',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте вопрос к супервизору в рефлексии — приложение соберёт рядом факт, гипотезу, реакцию и точку затруднения.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
