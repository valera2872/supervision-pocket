import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/voice_input_button.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

Future<void> openMeetingEditor(
  BuildContext context,
  SupervisorController controller,
  String meetingId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MeetingEditorScreen(
        controller: controller,
        meetingId: meetingId,
      ),
    ),
  );
}

class MeetingEditorScreen extends StatefulWidget {
  const MeetingEditorScreen({
    required this.controller,
    required this.meetingId,
    super.key,
  });

  final SupervisorController controller;
  final String meetingId;

  @override
  State<MeetingEditorScreen> createState() => _MeetingEditorScreenState();
}

class _MeetingEditorScreenState extends State<MeetingEditorScreen> {
  late DateTime _scheduledAt;
  late final TextEditingController _privateNotes;
  late final TextEditingController _sharedSummary;
  late final TextEditingController _nextStep;
  late final TextEditingController _followUp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final meeting = widget.controller.findMeeting(widget.meetingId)!;
    _scheduledAt = meeting.scheduledAt;
    _privateNotes = TextEditingController(text: meeting.privatePreparationNotes);
    _sharedSummary = TextEditingController(text: meeting.sharedSummary);
    _nextStep = TextEditingController(text: meeting.nextStep);
    _followUp = TextEditingController(text: meeting.followUpQuestion);
  }

  @override
  void dispose() {
    _privateNotes.dispose();
    _sharedSummary.dispose();
    _nextStep.dispose();
    _followUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final meeting = widget.controller.findMeeting(widget.meetingId);
        if (meeting == null) {
          return const Scaffold(
            body: Center(child: Text('Встреча не найдена')),
          );
        }
        final supervisee = widget.controller.findSupervisee(meeting.superviseeId);
        final agenda = widget.controller.requestsForMeeting(meeting.id);
        final completed = meeting.status == SupervisionMeetingStatus.completed;
        return Scaffold(
          appBar: AppBar(
            title: Text(supervisee?.displayName ?? 'Супервизия'),
            actions: [
              IconButton(
                onPressed: _saving ? null : _save,
                tooltip: 'Сохранить',
                icon: const Icon(Icons.save_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              _MeetingHeader(
                meeting: meeting,
                scheduledAt: _scheduledAt,
                onChangeDate: completed ? null : _pickDateTime,
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'Повестка встречи',
                subtitle:
                    'Только запросы, которые действительно будут обсуждаться.',
                action: completed
                    ? null
                    : TextButton.icon(
                        onPressed: () => _chooseRequest(meeting),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Добавить'),
                      ),
              ),
              const SizedBox(height: 10),
              if (agenda.isEmpty)
                const _EmptyAgenda()
              else
                ...agenda.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AgendaCard(
                      request: request,
                      completed: completed,
                      onRemove: () => widget.controller.removeRequestFromMeeting(
                        meetingId: meeting.id,
                        requestId: request.id,
                      ),
                      onStatusChanged: (status) =>
                          widget.controller.updateRequestStatus(
                        request.id,
                        status,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              _NoteBlock(
                title: 'Личная подготовка супервизора',
                subtitle:
                    'Гипотезы, наблюдения и вопросы. Супервизант эту заметку не увидит.',
                icon: Icons.visibility_off_outlined,
                controller: _privateNotes,
                fieldName: 'личная подготовка супервизора',
                enabled: !completed,
              ),
              const SizedBox(height: 18),
              _NoteBlock(
                title: 'Общий итог встречи',
                subtitle:
                    'Формулировка, которую можно обсудить и передать супервизанту.',
                icon: Icons.handshake_outlined,
                controller: _sharedSummary,
                fieldName: 'общий итог встречи',
                enabled: !completed,
              ),
              const SizedBox(height: 18),
              _NoteBlock(
                title: 'Следующий профессиональный шаг',
                subtitle: 'Что супервизант попробует или проверит в работе.',
                icon: Icons.next_plan_outlined,
                controller: _nextStep,
                fieldName: 'следующий профессиональный шаг',
                enabled: !completed,
                minLines: 2,
              ),
              const SizedBox(height: 18),
              _NoteBlock(
                title: 'Что продолжить исследовать',
                subtitle:
                    'Вопрос, который остаётся открытым или переносится дальше.',
                icon: Icons.explore_outlined,
                controller: _followUp,
                fieldName: 'вопрос для продолжения',
                enabled: !completed,
                minLines: 2,
              ),
              const SizedBox(height: 24),
              if (!completed) ...[
                FilledButton.icon(
                  onPressed: _saving ? null : () => _complete(meeting),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Завершить встречу'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Сохранить без завершения'),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => widget.controller.reopenMeeting(meeting.id),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Вернуть встречу в работу'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _chooseRequest(SupervisionMeeting meeting) async {
    final agendaIds = meeting.agendaRequestIds.toSet();
    final available = widget.controller
        .requestsForSupervisee(meeting.superviseeId)
        .where(
          (item) => !agendaIds.contains(item.id) &&
              item.status != SupervisionRequestStatus.completed,
        )
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет новых запросов для добавления в повестку'),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            'Добавить в повестку',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          ...available.map(
            (request) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(request.question),
              subtitle: request.context.isEmpty ? null : Text(request.context),
              onTap: () => Navigator.pop(context, request.id),
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await widget.controller.addRequestToMeeting(
      meetingId: meeting.id,
      requestId: selected,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.saveMeeting(
        meetingId: widget.meetingId,
        scheduledAt: _scheduledAt,
        privatePreparationNotes: _privateNotes.text,
        sharedSummary: _sharedSummary.text,
        nextStep: _nextStep.text,
        followUpQuestion: _followUp.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Встреча сохранена')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить встречу')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _complete(SupervisionMeeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить встречу?'),
        content: const Text(
          'Запросы со статусом «В повестке» будут отмечены завершёнными. Запросы «Продолжить» и «Отложен» сохранят свой статус.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save();
    if (!mounted) return;
    await widget.controller.completeMeeting(meeting.id);
  }
}

class _MeetingHeader extends StatelessWidget {
  const _MeetingHeader({
    required this.meeting,
    required this.scheduledAt,
    required this.onChangeDate,
  });

  final SupervisionMeeting meeting;
  final DateTime scheduledAt;
  final VoidCallback? onChangeDate;

  @override
  Widget build(BuildContext context) {
    final completed = meeting.status == SupervisionMeetingStatus.completed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: completed ? AppColors.paleTeal : AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.event_note_rounded,
            color: completed ? AppColors.teal : Colors.white,
            size: 34,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? 'Встреча завершена' : 'Запланированная встреча',
                  style: TextStyle(
                    color: completed ? AppColors.teal : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _dateTimeLabel(scheduledAt),
                  style: TextStyle(
                    color: completed ? AppColors.ink : const Color(0xFFDCE8ED),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onChangeDate != null)
            IconButton(
              onPressed: onChangeDate,
              tooltip: 'Изменить дату',
              color: Colors.white,
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.request,
    required this.completed,
    required this.onRemove,
    required this.onStatusChanged,
  });

  final SharedSupervisionRequest request;
  final bool completed;
  final VoidCallback onRemove;
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
                if (!completed)
                  PopupMenuButton<SupervisionRequestStatus>(
                    tooltip: 'Результат работы с запросом',
                    onSelected: onStatusChanged,
                    itemBuilder: (_) => const [
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
            Row(
              children: [
                _RequestStatusChip(status: request.status),
                const Spacer(),
                if (!completed)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Убрать'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.status});

  final SupervisionRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SupervisionRequestStatus.newRequest => 'Новый',
      SupervisionRequestStatus.planned => 'В повестке',
      SupervisionRequestStatus.completed => 'Разобран',
      SupervisionRequestStatus.continuing => 'Продолжить',
      SupervisionRequestStatus.deferred => 'Отложен',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.controller,
    required this.fieldName,
    required this.enabled,
    this.minLines = 3,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final TextEditingController controller;
  final String fieldName;
  final bool enabled;
  final int minLines;

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
                Icon(icon, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              enabled: enabled,
              minLines: minLines,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: enabled ? 'Запишите или надиктуйте…' : 'Нет записи',
                border: const OutlineInputBorder(),
                suffixIcon: enabled
                    ? VoiceInputButton(
                        controller: controller,
                        fieldName: fieldName,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.playlist_add_rounded, color: AppColors.navy),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Повестка пока пуста. Добавьте один или несколько запросов супервизанта.',
            ),
          ),
        ],
      ),
    );
  }
}

String _dateTimeLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} · $hour:$minute';
}
