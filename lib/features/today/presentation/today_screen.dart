import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/presentation/create_case_sheet.dart';
import 'package:supervision_pocket/features/cases/presentation/reflection_editor_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.onLock,
    required this.caseController,
    super.key,
  });

  final VoidCallback onLock;
  final CaseController caseController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: caseController,
        builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сегодня', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Что важно сохранить для профессионального размышления?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onLock,
                tooltip: 'Заблокировать',
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _startCapture(context),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Row(
                  children: [
                    _CaptureIcon(),
                    SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сохранить после консультации',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Структурировано и без лишних данных — около минуты',
                            style: TextStyle(color: Color(0xFFDDE8EE), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Можно продолжить', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: caseController.reflectionCount == 0
                  ? Column(
                      children: [
                        const Icon(
                          Icons.spa_outlined,
                          size: 38,
                          color: AppColors.teal,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Пока здесь спокойно',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Сохраняйте только моменты, которые продолжают удерживать ваше внимание.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.paleTeal,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(Icons.auto_stories_outlined, color: AppColors.teal),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${caseController.reflectionCount} профессиональных записей',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${caseController.supervisionQuestions.length} вопросов подготовлено к супервизии',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.paleTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не обязательно анализировать каждую консультацию. Сохраняйте те моменты, которые продолжают удерживать ваше внимание.',
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _startCapture(BuildContext context) async {
    var cases = caseController.cases;
    if (cases.isEmpty) {
      final created = await showCreateCaseSheet(context, caseController);
      if (created == null || !context.mounted) return;
      await openReflectionEditor(context, caseController, created.id);
      return;
    }

    var caseId = cases.length == 1 ? cases.first.id : null;
    if (caseId == null) {
      caseId = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        builder: (context) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text('Для какого случая?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...cases.map(
              (item) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(item.alias),
                subtitle: Text(item.ageRange),
                onTap: () => Navigator.pop(context, item.id),
              ),
            ),
          ],
        ),
      );
    }
    if (caseId != null && context.mounted) {
      await openReflectionEditor(context, caseController, caseId);
    }
  }
}

class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 29),
    );
  }
}
