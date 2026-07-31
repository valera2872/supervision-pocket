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
    MaterialPageRoute<void>(
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
  late final Map<String, TextEditingController> _text;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final meeting = widget.controller.findMeeting(widget.meetingId)!;
    _scheduledAt = meeting.scheduledAt;
    _text = {
      'private': TextEditingController(text: meeting.privatePreparationNotes),
      'clear': TextEditingController(text: meeting.whatBecameClear),
      'perspectives': TextEditingController(
        text: meeting.perspectivesConsidered,
      ),
      'hypothesis': TextEditingController(text: meeting.workingHypothesis),
      'uncertainty': TextEditingController(text: meeting.remainingUncertainty),
      'next': TextEditingController(text: meeting.nextStep),
      'marker': TextEditingController(text: meeting.attentionMarker),
      'question': TextEditingController(text: meeting.followUpQuestion),
      'summary': TextEditingController(text: meeting.sharedSummary),
      'result': TextEditingController(text: meeting.followUpResult),
    };
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
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
                onPressed: _saving
                    ? null
                    : completed
                        ? _saveFollowUp
                        : _saveMeeting,
                tooltip: 'Сохранить',
                icon: const Icon(Icons.save_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            children: [
              _header(meeting, completed),
              const SizedBox(height: 22),
              _title(
                'Повестка встречи',
                'Запросы и подготовка по каждому из них.',
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
                    child: _requestCard(request, meeting, completed),
                  ),
                ),
              const SizedBox(height: 18),
              _textCard(
                keyName: 'private',
                title: 'Личная подготовка супервизора',
                hint:
                    'Предварительные наблюдения и гипотезы. Супервизант эту заметку не увидит.',
                icon: Icons.visibility_off_outlined,
                enabled: !completed,
              ),
              const SizedBox(height: 22),
              _title(
                'Итог встречи',
                'Отделите новые понимания, гипотезы и следующий профессиональный шаг.',
              ),
              const SizedBox(height: 10),
              _textCard(
                keyName: 'clear',
                title: 'Что стало яснее',
                hint: 'Главное новое понимание после обсуждения.',
                icon: Icons.lightbulb_outline_rounded,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'perspectives',
                title: 'Какие перспективы рассматривались',
                hint: 'Фокусы, модели и альтернативные объяснения.',
                icon: Icons.view_in_ar_outlined,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'hypothesis',
                title: 'Рабочая гипотеза',
                hint: 'Что решили проверить, а не принять за окончательный вывод.',
                icon: Icons.science_outlined,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'uncertainty',
                title: 'Что осталось неопределённым',
                hint: 'Где данных пока недостаточно.',
                icon: Icons.help_outline_rounded,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'next',
                title: 'Следующий профессиональный шаг',
                hint: 'Одно наблюдаемое действие или эксперимент в работе.',
                icon: Icons.next_plan_outlined,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'marker',
                title: 'На что обратить внимание',
                hint: 'Маркер изменения или повторения паттерна.',
                icon: Icons.track_changes_outlined,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'question',
                title: 'Что продолжить исследовать',
                hint: 'Открытый вопрос для следующей встречи.',
                icon: Icons.explore_outlined,
                enabled: !completed,
              ),
              _gap,
              _textCard(
                keyName: 'summary',
                title: 'Короткий общий итог',
                hint: 'Формулировка, которую можно передать супервизанту.',
                icon: Icons.handshake_outlined,
                enabled: !completed,
              ),
              if (completed) ...[
                const SizedBox(height: 22),
                _textCard(
                  keyName: 'result',
                  title: 'Проверка после супервизии',
                  hint:
                      'Что удалось попробовать, что изменилось и требуется ли продолжение?',
                  icon: Icons.update_rounded,
                  enabled: true,
                ),
                if (meeting.followUpCheckedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Проверено ${_dateLabel(meeting.followUpCheckedAt!)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveFollowUp,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Сохранить проверку'),
                ),
              ],
              const SizedBox(height: 24),
              if (!completed) ...[
                FilledButton.icon(
                  onPressed: _saving ? null : () => _complete(meeting),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Завершить встречу'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving ? null : _saveMeeting,
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

  Widget get _gap => const SizedBox(height: 14);

  Widget _header(SupervisionMeeting meeting, bool completed) {
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
          const SizedBox(width: 14),
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
                  _dateLabel(_scheduledAt),
                  style: TextStyle(
                    color: completed ? AppColors.ink : const Color(0xFFDCE8ED),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!completed)
            IconButton(
              onPressed: _pickDateTime,
              tooltip: 'Изменить дату',
              color: Colors.white,
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
        ],
      ),
    );
  }

  Widget _title(String title, String subtitle, {Widget? action}) {
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
        if (action != null) action,
      ],
    );
  }

  Widget _textCard({
    required String keyName,
    required String title,
    required String hint,
    required IconData icon,
    required bool enabled,
  }) {
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
            Text(hint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _text[keyName],
              enabled: enabled,
              minLines: 2,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: enabled ? 'Запишите или надиктуйте…' : 'Нет записи',
                border: const OutlineInputBorder(),
                suffixIcon: enabled
                    ? VoiceInputButton(
                        controller: _text[keyName]!,
                        fieldName: title,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(
    SharedSupervisionRequest request,
    SupervisionMeeting meeting,
    bool completed,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (request.context.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                request.context,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (request.selectedFocuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: request.selectedFocuses
                    .map(
                      (focus) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(_focusLabel(focus)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _StatusChip(status: request.status),
                TextButton.icon(
                  onPressed: () => _prepareRequest(request),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Подготовить'),
                ),
                if (!completed)
                  PopupMenuButton<SupervisionRequestStatus>(
                    onSelected: (status) => widget.controller
                        .updateRequestStatus(request.id, status),
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Text('Статус'),
                    ),
                  ),
                if (!completed)
                  TextButton.icon(
                    onPressed: () => widget.controller.removeRequestFromMeeting(
                      meetingId: meeting.id,
                      requestId: request.id,
                    ),
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

  Future<void> _prepareRequest(SharedSupervisionRequest request) async {
    final missing = TextEditingController(text: request.missingInformation);
    final questions = TextEditingController(text: request.preparationQuestions);
    final ethical = TextEditingController(text: request.ethicalOrSystemicNotes);
    var role = request.suggestedRole;
    final focuses = request.selectedFocuses.toSet();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Подготовка запроса',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 7),
                Text(request.question),
                const SizedBox(height: 18),
                Text(
                  'Фокусы рассмотрения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: SupervisionFocus.values
                      .map(
                        (focus) => FilterChip(
                          selected: focuses.contains(focus),
                          label: Text(_focusLabel(focus)),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                focuses.add(focus);
                              } else {
                                focuses.remove(focus);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SupervisorRole>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Предполагаемая роль супервизора',
                    border: OutlineInputBorder(),
                  ),
                  items: SupervisorRole.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_roleLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setModalState(() => role = value);
                  },
                ),
                const SizedBox(height: 14),
                _PreparationField(
                  controller: missing,
                  label: 'Какой информации не хватает?',
                ),
                const SizedBox(height: 14),
                _PreparationField(
                  controller: questions,
                  label: 'Вопросы для встречи',
                ),
                const SizedBox(height: 14),
                _PreparationField(
                  controller: ethical,
                  label: 'Этика, риск или системный контекст',
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Сохранить подготовку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true) {
      await widget.controller.saveRequestPreparation(
        requestId: request.id,
        selectedFocuses: focuses.toList(),
        suggestedRole: role,
        missingInformation: missing.text,
        preparationQuestions: questions.text,
        ethicalOrSystemicNotes: ethical.text,
      );
    }
    missing.dispose();
    questions.dispose();
    ethical.dispose();
  }

  Future<void> _saveMeeting() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.saveMeeting(
        meetingId: widget.meetingId,
        scheduledAt: _scheduledAt,
        privatePreparationNotes: _text['private']!.text,
        sharedSummary: _text['summary']!.text,
        whatBecameClear: _text['clear']!.text,
        perspectivesConsidered: _text['perspectives']!.text,
        workingHypothesis: _text['hypothesis']!.text,
        remainingUncertainty: _text['uncertainty']!.text,
        nextStep: _text['next']!.text,
        attentionMarker: _text['marker']!.text,
        followUpQuestion: _text['question']!.text,
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

  Future<void> _saveFollowUp() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.saveFollowUp(
        meetingId: widget.meetingId,
        result: _text['result']!.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверка результата сохранена')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить результат')),
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
    await _saveMeeting();
    if (!mounted) return;
    await widget.controller.completeMeeting(meeting.id);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _PreparationField extends StatelessWidget {
  const _PreparationField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        suffixIcon: VoiceInputButton(
          controller: controller,
          fieldName: label,
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

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} · $hour:$minute';
}

String _focusLabel(SupervisionFocus focus) => switch (focus) {
      SupervisionFocus.client => 'Клиент',
      SupervisionFocus.interventions => 'Интервенции',
      SupervisionFocus.therapeuticRelationship => 'Отношения',
      SupervisionFocus.therapistProcess => 'Состояние психолога',
      SupervisionFocus.supervisionRelationship => 'Отношения в супервизии',
      SupervisionFocus.supervisorProcess => 'Впечатления супервизора',
      SupervisionFocus.widerContext => 'Широкий контекст',
    };

String _roleLabel(SupervisorRole role) => switch (role) {
      SupervisorRole.facilitator => 'Фасилитатор — помочь осмыслить',
      SupervisorRole.consultant => 'Консультант — исследовать вместе',
      SupervisorRole.teacher => 'Учитель — добавить знания и навыки',
      SupervisorRole.expert => 'Эксперт — дать оценку и ориентиры',
    };
