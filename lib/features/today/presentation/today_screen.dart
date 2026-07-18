import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/reset_application_dialog.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/presentation/create_case_sheet.dart';
import 'package:supervision_pocket/features/cases/presentation/reflection_editor_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.onLock,
    required this.onChangeRole,
    required this.onResetAll,
    required this.caseController,
    super.key,
  });

  final VoidCallback onLock;
  final VoidCallback onChangeRole;
  final Future<void> Function() onResetAll;
  final CaseController caseController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: caseController,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            final horizontalPadding = compact ? 16.0 : 20.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                28,
              ),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleTeal,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'РЕФЛЕКСИЯ',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Меню',
                      icon: const Icon(Icons.more_horiz_rounded),
                      onSelected: (value) async {
                        if (value == 'role') onChangeRole();
                        if (value == 'lock') onLock();
                        if (value == 'reset') {
                          await showResetApplicationDialog(
                            context,
                            onReset: onResetAll,
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'role',
                          child: ListTile(
                            leading: Icon(Icons.swap_horiz_rounded),
                            title: Text('Сменить роль'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reset',
                          child: ListTile(
                            leading: Icon(Icons.restart_alt_rounded),
                            title: Text('Начать заново'),
                            subtitle: Text('Удалить все локальные данные'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'lock',
                          child: ListTile(
                            leading: Icon(Icons.lock_outline_rounded),
                            title: Text('Заблокировать'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: compact ? 18 : 22),
                Text(
                  'Что осталось с вами после консультации?',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: compact ? 24 : 28,
                        height: 1.16,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Запишите конкретный эпизод: слова клиента, свою реакцию, сомнение или сложность в работе.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 13.5 : 14,
                      ),
                ),
                SizedBox(height: compact ? 20 : 24),
                _CaptureCard(
                  compact: compact,
                  onTap: () => _startCapture(context),
                ),
                const SizedBox(height: 28),
                Text(
                  'Ваши записи',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 17 : 20),
                    child: caseController.reflectionCount == 0
                        ? Column(
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                size: 38,
                                color: AppColors.teal,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Пока нет сохранённых эпизодов',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'После сложной консультации нажмите кнопку выше. Ответы можно надиктовать голосом.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.paleTeal,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_outlined,
                                  color: AppColors.teal,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${caseController.reflectionCount} сохранённых эпизодов',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${caseController.supervisionQuestions.length} вопросов подготовлено к супервизии',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                  padding: const EdgeInsets.all(16),
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
            );
          },
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

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 19 : 22),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _CaptureIcon(size: 50),
                        Spacer(),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _CaptureText(titleSize: 18),
                  ],
                )
              : const Row(
                  children: [
                    _CaptureIcon(size: 54),
                    SizedBox(width: 17),
                    Expanded(child: _CaptureText(titleSize: 19)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CaptureText extends StatelessWidget {
  const _CaptureText({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Записать сложный момент',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            height: 1.22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Что произошло, как вы отреагировали и что хотите спросить у супервизора',
          style: TextStyle(
            color: Color(0xFFDDE8EE),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Icons.mic_none_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
