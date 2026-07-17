import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/voice_input_button.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';
import 'package:supervision_pocket/features/supervisor/presentation/meeting_editor_screen.dart';

Future<void> openSuperviseeDetail(
  BuildContext context,
  SupervisorController controller,
  String superviseeId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SuperviseeDetailScreen(
        controller: controller,
        superviseeId: superviseeId,
      ),
    ),
  );
}

class SuperviseeDetailScreen extends StatelessWidget {
  const SuperviseeDetailScreen({
    required this.controller,
    required this.superviseeId,
    super.key,
  });

  final SupervisorController controller;
  final String superviseeId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final profile = controller.findSupervisee(superviseeId);
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Супервизант не найден')),
          );
        }
        final requests = controller.requestsForSupervisee(profile.id);
        final meetings = controller.meetingsForSupervisee(profile.id);
        final nextMeeting = controller.nextMeetingFor(profile.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(profile.displayName),
            actions: [
              IconButton(
                onPressed: () => showEditSuperviseeSheet(
                  context,
                  controller,
                  profile,
                ),
                tooltip: 'Редактировать карточку',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => showCreateMeetingSheet(
                        context,
                        controller,
                        profile.id,
                      ),
                      icon: const Icon(Icons.event_available_outlined),
                      label: const Text('Встреча'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showAddRequestForSuperviseeSheet(
                        context,
                        controller,
                        profile.id,
                      ),
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Запрос'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (nextMeeting != null) ...[
                Text(
                  'Ближайшая встреча',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _MeetingCard(
                  meeting: nextMeeting,
                  requestCount:
                      controller.requestsForMeeting(nextMeeting.id).length,
                  onTap: () => openMeetingEditor(
                    context,
                    controller,
                    nextMeeting.id,
                  ),
                ),
                const SizedBox(height: 22),
              ],
              _PrivateNotesCard(
                notes: profile.privateNotes,
                onEdit: () => showEditSuperviseeSheet(
                  context,
                  controller,
                  profile,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Запросы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${requests.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (requests.isEmpty)
                const _EmptyPanel(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Запросов пока нет',
                  text:
                      'Добавьте запрос, который супервизант передал для обсуждения.',
                )
              else
                ...requests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(
                      request: request,
                      onStatusChanged: (status) =>
                          controller.updateRequestStatus(request.id, status),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'История встреч',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${meetings.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (meetings.isEmpty)
                const _EmptyPanel(
                  icon: Icons.event_note_outlined,
                  title: 'Встреч ещё нет',
                  text:
                      'Запланируйте первую супервизию и добавьте запросы в её повестку.',
                )
              else
                ...meetings.map(
                  (meeting) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MeetingCard(
                      meeting: meeting,
                      requestCount:
                          controller.requestsForMeeting(meeting.id).length,
                      onTap: () => openMeetingEditor(
                        context,
                        controller,
                        meeting.id,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final SuperviseeProfile profile;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (profile.professionalRole.isNotEmpty)
        (Icons.badge_outlined, profile.professionalRole),
      if (profile.experience.isNotEmpty)
        (Icons.timeline_outlined, profile.experience),
      if (profile.approach.isNotEmpty)
        (Icons.account_tree_outlined, profile.approach),
      if (profile.meetingCadence.isNotEmpty)
        (Icons.repeat_rounded, profile.meetingCadence),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  profile.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (profile.professionalContext.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        profile.professionalContext,
                        style: const TextStyle(color: Color(0xFFDCE8ED)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(detail.$1, color: const Color(0xFFBFD7DD), size: 19),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detail.$2,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, color: Colors.white, size: 19),
                const SizedBox(width: 9),
                const Text(
                  'Код подключения: ',
                  style: TextStyle(color: Color(0xFFDCE8ED)),
                ),
                Text(
                  profile.invitationCode,
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.white,
                  tooltip: 'Скопировать код',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: profile.invitationCode),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Код скопирован')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 19),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateNotesCard extends StatelessWidget {
  const _PrivateNotesCard({required this.notes, required this.onEdit});

  final String notes;
  final VoidCallback onEdit;

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
              const Icon(Icons.visibility_off_outlined, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Личная заметка супервизора',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Редактировать',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            notes.isEmpty
                ? 'Здесь можно хранить профессиональные наблюдения, которые не передаются супервизанту.'
                : notes,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.meeting,
    required this.requestCount,
    required this.onTap,
  });

  final SupervisionMeeting meeting;
  final int requestCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = meeting.status == SupervisionMeetingStatus.completed;
    return Card(
      child: ListTile(
        onTap: onTap,
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
        title: Text(
          _dateTimeLabel(meeting.scheduledAt),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          completed
              ? 'Завершена · $requestCount запросов'
              : 'Запланирована · $requestCount в повестке',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onStatusChanged,
  });

  final SharedSupervisionRequest request;
  final ValueChanged<SupervisionRequestStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.question,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<SupervisionRequestStatus>(
                  onSelected: onStatusChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: SupervisionRequestStatus.newRequest,
                      child: Text('Новый'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.planned,
                      child: Text('В повестке'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.completed,
                      child: Text('Разобран'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.continuing,
                      child: Text('Требует продолжения'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.deferred,
                      child: Text('Отложен'),
                    ),
                  ],
                ),
              ],
            ),
            if (request.context.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(request.context, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 10),
            Text(
              _requestStatusLabel(request.status),
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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

Future<void> showEditSuperviseeSheet(
  BuildContext context,
  SupervisorController controller,
  SuperviseeProfile profile,
) async {
  final name = TextEditingController(text: profile.displayName);
  final contextText = TextEditingController(text: profile.professionalContext);
  final role = TextEditingController(text: profile.professionalRole);
  final experience = TextEditingController(text: profile.experience);
  final approach = TextEditingController(text: profile.approach);
  final cadence = TextEditingController(text: profile.meetingCadence);
  final privateNotes = TextEditingController(text: profile.privateNotes);
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
                'Карточка супервизанта',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
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
                hint: 'Например: интегративный подход',
                fieldName: 'подход супервизанта',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: cadence,
                label: 'Регулярность встреч',
                hint: 'Например: каждые две недели',
                fieldName: 'регулярность супервизий',
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: contextText,
                label: 'Рабочий контекст',
                hint: 'Только профессионально необходимые сведения',
                fieldName: 'рабочий контекст',
                minLines: 2,
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: privateNotes,
                label: 'Личная заметка супервизора',
                hint: 'Эта запись не предназначена для передачи',
                fieldName: 'личная заметка о супервизанте',
                minLines: 3,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext, true);
                  }
                },
                child: const Text('Сохранить карточку'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (accepted == true) {
    await controller.updateSupervisee(
      id: profile.id,
      displayName: name.text,
      professionalContext: contextText.text,
      professionalRole: role.text,
      approach: approach.text,
      experience: experience.text,
      meetingCadence: cadence.text,
      privateNotes: privateNotes.text,
    );
  }
  for (final item in [
    name,
    contextText,
    role,
    experience,
    approach,
    cadence,
    privateNotes,
  ]) {
    item.dispose();
  }
}

Future<void> showAddRequestForSuperviseeSheet(
  BuildContext context,
  SupervisorController controller,
  String superviseeId,
) async {
  final question = TextEditingController();
  final contextText = TextEditingController();
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
                'Переданный запрос',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              _VoiceField(
                controller: question,
                label: 'Вопрос к супервизии',
                hint: 'Что супервизант хочет понять или обсудить?',
                fieldName: 'вопрос к супервизии',
                minLines: 2,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите вопрос'
                    : null,
              ),
              const SizedBox(height: 12),
              _VoiceField(
                controller: contextText,
                label: 'Короткий обезличенный контекст',
                fieldName: 'контекст запроса',
                minLines: 2,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext, true);
                  }
                },
                child: const Text('Сохранить запрос'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (accepted == true) {
    await controller.addRequest(
      superviseeId: superviseeId,
      question: question.text,
      context: contextText.text,
    );
  }
  question.dispose();
  contextText.dispose();
}

Future<void> showCreateMeetingSheet(
  BuildContext context,
  SupervisorController controller,
  String superviseeId,
) async {
  var scheduledAt = DateTime.now().add(const Duration(days: 7));
  scheduledAt = DateTime(
    scheduledAt.year,
    scheduledAt.month,
    scheduledAt.day,
    18,
  );
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Запланировать супервизию',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Дата и время'),
              subtitle: Text(_dateTimeLabel(scheduledAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: scheduledAt,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(scheduledAt),
                );
                if (time == null) return;
                setState(() {
                  scheduledAt = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Создать встречу'),
            ),
          ],
        ),
      ),
    ),
  );
  if (accepted != true || !context.mounted) return;
  final meeting = await controller.createMeeting(
    superviseeId: superviseeId,
    scheduledAt: scheduledAt,
  );
  if (!context.mounted) return;
  await openMeetingEditor(context, controller, meeting.id);
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
      maxLines: minLines == 1 ? 2 : 6,
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

String _requestStatusLabel(SupervisionRequestStatus status) {
  return switch (status) {
    SupervisionRequestStatus.newRequest => 'НОВЫЙ',
    SupervisionRequestStatus.planned => 'В ПОВЕСТКЕ',
    SupervisionRequestStatus.completed => 'РАЗОБРАН',
    SupervisionRequestStatus.continuing => 'ТРЕБУЕТ ПРОДОЛЖЕНИЯ',
    SupervisionRequestStatus.deferred => 'ОТЛОЖЕН',
  };
}

String _dateTimeLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} · $hour:$minute';
}
