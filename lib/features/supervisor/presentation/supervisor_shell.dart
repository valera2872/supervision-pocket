import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/voice_input_button.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';
import 'package:supervision_pocket/features/supervisor/presentation/meeting_editor_screen.dart';
import 'package:supervision_pocket/features/supervisor/presentation/supervisee_detail_screen.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({
    required this.controller,
    required this.onLock,
    required this.onChangeRole,
    super.key,
  });

  final SupervisorController controller;
  final VoidCallback onLock;
  final VoidCallback onChangeRole;

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Сегодня', 'Супервизанты', 'Встречи'];
    final pages = [
      _SupervisorToday(
        controller: widget.controller,
        onOpenPeople: () => setState(() => _index = 1),
        onOpenMeetings: () => setState(() => _index = 2),
      ),
      _SuperviseesPage(controller: widget.controller),
      _MeetingsPage(controller: widget.controller),
    ];
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_index]),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Настройки рабочего пространства',
              onSelected: (value) {
                if (value == 'role') widget.onChangeRole();
                if (value == 'lock') widget.onLock();
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
                  value: 'lock',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text('Заблокировать'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded),
              label: 'Сегодня',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Люди',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Встречи',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupervisorToday extends StatelessWidget {
  const _SupervisorToday({
    required this.controller,
    required this.onOpenPeople,
    required this.onOpenMeetings,
  });

  final SupervisorController controller;
  final VoidCallback onOpenPeople;
  final VoidCallback onOpenMeetings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final nextMeetings = controller.upcomingMeetings.take(3).toList();
        final newRequests = controller.newRequests.take(3).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'РАБОЧЕЕ ПРОСТРАНСТВО СУПЕРВИЗОРА',
                    style: TextStyle(
                      color: Color(0xFFBFD7DD),
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Люди, запросы и встречи — в одной профессиональной истории',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Подготовьте повестку, сохраните личные наблюдения и сформулируйте общий итог встречи.',
                    style: TextStyle(
                      color: Color(0xFFDCE8ED),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    value: '${controller.supervisees.length}',
                    label: 'супервизантов',
                    icon: Icons.groups_2_outlined,
                    onTap: onOpenPeople,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    value: '${controller.upcomingMeetings.length}',
                    label: 'встреч впереди',
                    icon: Icons.event_available_outlined,
                    onTap: onOpenMeetings,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    value: '${controller.newRequests.length}',
                    label: 'новых запросов',
                    icon: Icons.mark_unread_chat_alt_outlined,
                    onTap: onOpenPeople,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Ближайшие встречи',
              actionLabel: 'Все',
              onAction: onOpenMeetings,
            ),
            const SizedBox(height: 10),
            if (nextMeetings.isEmpty)
              _ActionEmptyPanel(
                icon: Icons.event_note_outlined,
                title: 'Нет запланированных встреч',
                text: 'Откройте карточку супервизанта и назначьте дату.',
                buttonLabel: 'Открыть супервизантов',
                onPressed: onOpenPeople,
              )
            else
              ...nextMeetings.map(
                (meeting) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MeetingListCard(
                    controller: controller,
                    meeting: meeting,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Новые запросы',
              actionLabel: 'К людям',
              onAction: onOpenPeople,
            ),
            const SizedBox(height: 10),
            if (newRequests.isEmpty)
              const _EmptyPanel(
                icon: Icons.forum_outlined,
                title: 'Новых запросов нет',
                text:
                    'Переданные запросы появятся в карточке конкретного супервизанта.',
              )
            else
              ...newRequests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NewRequestCard(
                    controller: controller,
                    request: request,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sync_lock_outlined, color: AppColors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Версия 0.9.0 хранит кабинет только на этом устройстве. Передача между аккаунтами появится после подключения защищённого сервера.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuperviseesPage extends StatelessWidget {
  const _SuperviseesPage({required this.controller});

  final SupervisorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            'Профессиональные истории супервизантов',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            'Откройте человека, чтобы увидеть его запросы, ближайшую встречу, личные заметки и историю супервизий.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showAddSuperviseeSheet(context, controller),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Добавить супервизанта'),
          ),
          const SizedBox(height: 18),
          if (controller.supervisees.isEmpty)
            const _EmptyPanel(
              icon: Icons.groups_outlined,
              title: 'Список пока пуст',
              text:
                  'Добавьте первого супервизанта. Клиентские данные в этой карточке не нужны.',
            )
          else
            ...controller.supervisees.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _SuperviseeCard(
                  controller: controller,
                  profile: profile,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingsPage extends StatelessWidget {
  const _MeetingsPage({required this.controller});

  final SupervisorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            'Супервизионные встречи',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            'Планируйте повестку до встречи и сохраняйте общий итог после неё.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.supervisees.isEmpty
                ? null
                : () => _chooseSuperviseeForMeeting(context, controller),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Запланировать встречу'),
          ),
          const SizedBox(height: 22),
          Text(
            'Предстоящие',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (controller.upcomingMeetings.isEmpty)
            const _EmptyPanel(
              icon: Icons.event_available_outlined,
              title: 'Предстоящих встреч нет',
              text: 'Назначьте дату и затем добавьте запросы в повестку.',
            )
          else
            ...controller.upcomingMeetings.map(
              (meeting) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MeetingListCard(
                  controller: controller,
                  meeting: meeting,
                ),
              ),
            ),
          const SizedBox(height: 22),
          Text(
            'Завершённые',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (controller.completedMeetings.isEmpty)
            const _EmptyPanel(
              icon: Icons.history_rounded,
              title: 'История пока пуста',
              text:
                  'После завершения встречи здесь останутся её повестка, итог и договорённости.',
            )
          else
            ...controller.completedMeetings.map(
              (meeting) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MeetingListCard(
                  controller: controller,
                  meeting: meeting,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuperviseeCard extends StatelessWidget {
  const _SuperviseeCard({required this.controller, required this.profile});

  final SupervisorController controller;
  final SuperviseeProfile profile;

  @override
  Widget build(BuildContext context) {
    final requests = controller.requestsForSupervisee(profile.id);
    final active = requests
        .where(
          (item) => item.status != SupervisionRequestStatus.completed &&
              item.status != SupervisionRequestStatus.deferred,
        )
        .length;
    final nextMeeting = controller.nextMeetingFor(profile.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openSuperviseeDetail(context, controller, profile.id),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  profile.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.professionalRole.isNotEmpty
                          ? profile.professionalRole
                          : profile.professionalContext.isNotEmpty
                              ? profile.professionalContext
                              : 'Профессиональный контекст не заполнен',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      nextMeeting == null
                          ? '$active активных запросов · встреча не назначена'
                          : '$active активных запросов · ${_dateLabel(nextMeeting.scheduledAt)}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingListCard extends StatelessWidget {
  const _MeetingListCard({required this.controller, required this.meeting});

  final SupervisorController controller;
  final SupervisionMeeting meeting;

  @override
  Widget build(BuildContext context) {
    final profile = controller.findSupervisee(meeting.superviseeId);
    final completed = meeting.status == SupervisionMeetingStatus.completed;
    final count = controller.requestsForMeeting(meeting.id).length;
    return Card(
      child: ListTile(
        onTap: () => openMeetingEditor(context, controller, meeting.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: completed ? AppColors.paleTeal : AppColors.paleBlue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.event_note_rounded,
            color: completed ? AppColors.teal : AppColors.navy,
          ),
        ),
        title: Text(profile?.displayName ?? 'Супервизант'),
        subtitle: Text(
          '${_dateTimeLabel(meeting.scheduledAt)} · $count запросов',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({required this.controller, required this.request});

  final SupervisorController controller;
  final SharedSupervisionRequest request;

  @override
  Widget build(BuildContext context) {
    final profile = controller.findSupervisee(request.superviseeId);
    return Card(
      child: InkWell(
        onTap: profile == null
            ? null
            : () => openSuperviseeDetail(context, controller, profile.id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.displayName ?? 'Супервизант',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                request.question,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (request.context.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  request.context,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.teal, size: 21),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.teal),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionEmptyPanel extends StatelessWidget {
  const _ActionEmptyPanel({
    required this.icon,
    required this.title,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.teal),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 13),
            TextButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddSuperviseeSheet(
  BuildContext context,
  SupervisorController controller,
) async {
  final name = TextEditingController();
  final contextText = TextEditingController();
  final role = TextEditingController();
  final experience = TextEditingController();
  final approach = TextEditingController();
  final cadence = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Новый супервизант',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 7),
              Text(
                'Заполните профессиональные сведения. Клиентские данные здесь не нужны.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _VoiceField(
                controller: name,
                label: 'Имя или рабочий псевдоним',
                fieldName: 'имя супервизанта',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите имя или псевдоним'
                    : null,
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: role,
                label: 'Профессиональный статус',
                hint: 'Например: начинающий детский психолог',
                fieldName: 'профессиональный статус',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: experience,
                label: 'Опыт работы',
                hint: 'Например: 1 год практики',
                fieldName: 'опыт работы',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: approach,
                label: 'Подход или направление',
                fieldName: 'профессиональный подход',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: cadence,
                label: 'Регулярность встреч',
                hint: 'Например: каждые две недели',
                fieldName: 'регулярность встреч',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: contextText,
                label: 'Рабочий контекст',
                fieldName: 'рабочий контекст',
                minLines: 2,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext, true);
                  }
                },
                child: const Text('Добавить супервизанта'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    final profile = await controller.addSupervisee(
      displayName: name.text,
      professionalContext: contextText.text,
      professionalRole: role.text,
      experience: experience.text,
      approach: approach.text,
      meetingCadence: cadence.text,
    );
    if (context.mounted) {
      await openSuperviseeDetail(context, controller, profile.id);
    }
  }
  for (final item in [name, contextText, role, experience, approach, cadence]) {
    item.dispose();
  }
}

Future<void> _chooseSuperviseeForMeeting(
  BuildContext context,
  SupervisorController controller,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text(
          'Для кого запланировать встречу?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...controller.supervisees.map(
          (profile) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(profile.displayName),
            subtitle: profile.professionalRole.isEmpty
                ? null
                : Text(profile.professionalRole),
            onTap: () => Navigator.pop(context, profile.id),
          ),
        ),
      ],
    ),
  );
  if (selected == null || !context.mounted) return;
  await showCreateMeetingSheet(context, controller, selected);
}

class _VoiceField extends StatelessWidget {
  const _VoiceField({
    required this.controller,
    required this.label,
    required this.fieldName,
    this.hint,
    this.minLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String fieldName;
  final String? hint;
  final int minLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 2 : 5,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: VoiceInputButton(
          controller: controller,
          fieldName: fieldName,
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

String _dateTimeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_dateLabel(value)} · $hour:$minute';
}
