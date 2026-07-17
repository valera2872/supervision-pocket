import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/presentation/create_case_sheet.dart';
import 'package:supervision_pocket/features/cases/presentation/reflection_editor_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.onLock,
    required this.onChangeRole,
    required this.caseController,
    super.key,
  });

  final VoidCallback onLock;
  final VoidCallback onChangeRole;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Что осталось с вами после консультации?',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Запишите конкретный эпизод, о котором продолжаете думать: слова клиента, свою реакцию, сомнение или сложность в работе.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    IconButton.filledTonal(
                      onPressed: onChangeRole,
                      tooltip: 'Сменить роль',
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                    const SizedBox(height: 8),
                    IconButton.filledTonal(
                      onPressed: onLock,
                      tooltip: 'Заблокировать',
                      icon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                              'Записать сложный момент',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Что произошло, как вы отреагировали и что хотите спросить у супервизора',
                              style: TextStyle(
                                color: Color(0xFFDDE8EE),
                                height: 1.35,
                              ),
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
            Text(
              'Ваши записи',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: caseController.reflectionCount == 0
                    ? Column(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 40,
                            color: AppColors.teal,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Пока нет сохранённых эпизодов',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'После сложной консультации нажмите кнопку выше. Можно надиктовать ответы голосом.',
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
                            child: const Icon(
                              Icons.auto_stories_outlined,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${caseController.reflectionCount} сохранённых эпизодов',
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
                  Icon(Icons.privacy_tip_outlined, color: AppColors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Не называйте настоящие имена, адреса, школы и другие данные, по которым можно узнать клиента.',
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
    final cases = caseController.cases;
    if (cases.isEmpty) {
      final created = await showCreateCaseSheet(context, caseController);
      if (created == null || !context.mounted) return;
      await openReflectionEditor(context, caseController, created.id);
      return;
    }

    var caseId = cases.length == 1 ? cases.first.id : null;
    caseId ??= await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            'К какому клиенту относится эпизод?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
      child: const Icon(
        Icons.mic_none_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}
