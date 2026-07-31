import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/voice_input_button.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

Future<void> openReflectionEditor(
  BuildContext context,
  CaseController controller,
  String caseId, {
  String? entryId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ReflectionEditorScreen(
        controller: controller,
        caseId: caseId,
        entryId: entryId,
      ),
    ),
  );
}

class ReflectionEditorScreen extends StatefulWidget {
  const ReflectionEditorScreen({
    required this.controller,
    required this.caseId,
    this.entryId,
    super.key,
  });

  final CaseController controller;
  final String caseId;
  final String? entryId;

  @override
  State<ReflectionEditorScreen> createState() =>
      _ReflectionEditorScreenState();
}

class _ReflectionEditorScreenState extends State<ReflectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = List.generate(14, (_) => TextEditingController());
  Timer? _draftTimer;
  ReflectionMode _mode = ReflectionMode.quick;
  SupervisionRequestType _requestType = SupervisionRequestType.other;
  bool _saving = false;
  bool _submitted = false;
  bool _clearing = false;

  bool get _editing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    final source = _editing
        ? widget.controller.findEntry(widget.caseId, widget.entryId!)?.toDraft()
        : widget.controller.findById(widget.caseId)?.draft;
    if (source != null) {
      _mode = source.mode;
      _requestType = source.requestType;
      final values = [
        source.observedFact,
        source.interpretation,
        source.feeling,
        source.impulse,
        source.actionTaken,
        source.stuckPoint,
        source.supervisionQuestion,
        source.clientRequest,
        source.relevantContext,
        source.currentDynamics,
        source.workingHypothesis,
        source.previousAttempts,
        source.resources,
        source.ethicalContext,
      ];
      for (var i = 0; i < _fields.length; i++) {
        _fields[i].text = values[i];
      }
    }
    if (!_editing) {
      for (final field in _fields) {
        field.addListener(_scheduleDraft);
      }
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_submitted && !_editing) {
      final draft = _draft();
      unawaited(
        widget.controller.saveDraft(widget.caseId, draft).catchError((_) {}),
      );
    }
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _scheduleDraft() {
    if (_clearing || _editing) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(_saveDraft());
    });
  }

  ReflectionDraft _draft() => ReflectionDraft(
        updatedAt: DateTime.now(),
        mode: _mode,
        observedFact: _fields[0].text,
        interpretation: _fields[1].text,
        feeling: _fields[2].text,
        impulse: _fields[3].text,
        actionTaken: _fields[4].text,
        stuckPoint: _fields[5].text,
        supervisionQuestion: _fields[6].text,
        clientRequest: _fields[7].text,
        relevantContext: _fields[8].text,
        currentDynamics: _fields[9].text,
        workingHypothesis: _fields[10].text,
        previousAttempts: _fields[11].text,
        resources: _fields[12].text,
        ethicalContext: _fields[13].text,
        requestType: _requestType,
      );

  Future<void> _saveDraft() async {
    if (_editing) return;
    try {
      await widget.controller.saveDraft(widget.caseId, _draft());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось сохранить последние изменения. Проверьте свободное место и продолжите запись.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _clearDraft() async {
    if (_fields.every((field) => field.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все поля уже пусты'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_editing ? 'Очистить все поля?' : 'Очистить этот черновик?'),
        content: Text(
          _editing
              ? 'Текст исчезнет с экрана, но сохранённая запись изменится только после нажатия «Сохранить изменения».'
              : 'Все надиктованные и введённые ответы на этом экране будут удалены. Карточка случая и ранее сохранённые эпизоды останутся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _draftTimer?.cancel();
    _clearing = true;
    for (final field in _fields) {
      field.clear();
    }
    setState(() {
      _requestType = SupervisionRequestType.other;
    });
    try {
      if (!_editing) await widget.controller.clearDraft(widget.caseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Поля очищены'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _clearing = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _draftTimer?.cancel();
    setState(() => _saving = true);
    try {
      if (_editing) {
        await widget.controller.updateReflection(
          widget.caseId,
          widget.entryId!,
          _draft(),
        );
      } else {
        await widget.controller.addReflection(widget.caseId, _draft());
      }
      _submitted = true;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Запись не сохранилась. Текст остаётся на экране — попробуйте ещё раз.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseFile = widget.controller.findById(widget.caseId);
    final full = _mode == ReflectionMode.casePreparation;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Изменить запись' : caseFile?.alias ?? 'Сложный момент',
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _clearDraft,
            tooltip: 'Очистить поля',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              _editing
                  ? 'Проверьте и уточните материал'
                  : 'Что вы хотите сохранить?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              full
                  ? 'Соберите кейс к встрече: от контекста и запроса клиента до своей гипотезы и конкретного вопроса супервизору.'
                  : 'Быстро зафиксируйте эпизод сразу после консультации. Все поля, кроме описания события, можно пропустить.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SegmentedButton<ReflectionMode>(
              segments: const [
                ButtonSegment(
                  value: ReflectionMode.quick,
                  icon: Icon(Icons.bolt_outlined),
                  label: Text('Быстро'),
                ),
                ButtonSegment(
                  value: ReflectionMode.casePreparation,
                  icon: Icon(Icons.fact_check_outlined),
                  label: Text('Подготовить кейс'),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
                _scheduleDraft();
              },
            ),
            const SizedBox(height: 18),
            const _SeparationHint(),
            const SizedBox(height: 18),
            if (full) ...[
              const _SectionLabel(
                icon: Icons.person_search_outlined,
                title: 'Контекст клиента и работы',
              ),
              _ReflectionField(
                controller: _fields[7],
                number: '1',
                label: 'С чем пришёл клиент?',
                hint:
                    'Запрос клиента своими словами, без идентифицирующих деталей',
              ),
              _ReflectionField(
                controller: _fields[8],
                number: '2',
                label: 'Что важно знать о контексте?',
                hint:
                    'Только сведения, которые действительно влияют на понимание случая',
              ),
              _ReflectionField(
                controller: _fields[9],
                number: '3',
                label: 'Что происходит сейчас?',
                hint:
                    'Динамика работы, изменения, повторяющиеся темы или трудности',
              ),
              const _SectionLabel(
                icon: Icons.visibility_outlined,
                title: 'Ключевой эпизод',
              ),
            ],
            _ReflectionField(
              controller: _fields[0],
              number: full ? '4' : '1',
              label: 'Что произошло?',
              hint:
                  'Что можно было увидеть или услышать — без объяснений и диагнозов',
              isRequired: true,
            ),
            _ReflectionField(
              controller: _fields[1],
              number: full ? '5' : '2',
              label: 'Как я это понял(а)?',
              hint:
                  'Моя интерпретация, предположение или объяснение ситуации',
            ),
            _ReflectionField(
              controller: _fields[2],
              number: full ? '6' : '3',
              label: 'Что я почувствовал(а)?',
              hint:
                  'Например: растерянность, раздражение, тревогу или бессилие',
            ),
            _ReflectionField(
              controller: _fields[3],
              number: full ? '7' : '4',
              label: 'Что мне захотелось сделать?',
              hint: 'Первый импульс, даже если я ему не последовал(а)',
            ),
            _ReflectionField(
              controller: _fields[4],
              number: full ? '8' : '5',
              label: 'Как я отреагировал(а)?',
              hint:
                  'Что я сказал(а), сделал(а) или намеренно не сделал(а)',
            ),
            if (full) ...[
              const _SectionLabel(
                icon: Icons.psychology_alt_outlined,
                title: 'Профессиональное осмысление',
              ),
              _ReflectionField(
                controller: _fields[11],
                number: '9',
                label: 'Что я уже пробовал(а)?',
                hint: 'Интервенции, способы разговора и их результат',
              ),
              _ReflectionField(
                controller: _fields[12],
                number: '10',
                label: 'Что работает или поддерживает?',
                hint:
                    'Ресурсы клиента, терапевтического контакта и вашей работы',
              ),
              _ReflectionField(
                controller: _fields[10],
                number: '11',
                label: 'Моя рабочая гипотеза',
                hint:
                    'Предположение, которое нужно проверить, а не готовый вывод',
              ),
              _ReflectionField(
                controller: _fields[13],
                number: '12',
                label: 'Есть ли вопрос границ, этики или безопасности?',
                hint:
                    'Конфиденциальность, риск, контракт, компетентность или организационный контекст',
              ),
            ],
            _ReflectionField(
              controller: _fields[5],
              number: full ? '13' : '6',
              label: 'Что осталось непонятным?',
              hint:
                  'Где я сомневаюсь, застрял(а) или не понимаю, как двигаться дальше',
            ),
            if (full) ...[
              DropdownButtonFormField<SupervisionRequestType>(
                initialValue: _requestType,
                decoration: const InputDecoration(
                  labelText: 'Какого рода помощь нужна?',
                  border: OutlineInputBorder(),
                ),
                items: SupervisionRequestType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_requestTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _requestType = value);
                  _scheduleDraft();
                },
              ),
              const SizedBox(height: 17),
            ],
            _ReflectionField(
              controller: _fields[6],
              number: full ? '14' : '7',
              label: 'Что я хочу спросить у супервизора?',
              hint:
                  'Один конкретный вопрос, на который можно работать во время встречи',
              accent: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _editing
                        ? 'Изменения сохранятся только после подтверждения'
                        : 'Черновик сохраняется автоматически на этом устройстве',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_editing ? 'Сохранить изменения' : 'Сохранить запись'),
        ),
      ),
    );
  }
}

class _SeparationHint extends StatelessWidget {
  const _SeparationHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.filter_alt_outlined, color: AppColors.navy),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Разделяйте наблюдаемое, своё объяснение и эмоциональную реакцию. Это помогает не превращать гипотезу в факт.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 13),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _ReflectionField extends StatelessWidget {
  const _ReflectionField({
    required this.controller,
    required this.number,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.accent = false,
  });

  final TextEditingController controller;
  final String number;
  final String label;
  final String hint;
  final bool isRequired;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? AppColors.navy : AppColors.paleTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: accent ? Colors.white : AppColors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextFormField(
              controller: controller,
              minLines: 2,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                filled: accent,
                fillColor: accent ? AppColors.paleBlue : null,
                suffixIcon: VoiceInputButton(
                  controller: controller,
                  fieldName: label,
                ),
              ),
              validator: isRequired
                  ? (value) => value == null || value.trim().isEmpty
                      ? 'Коротко опишите наблюдаемый эпизод'
                      : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _requestTypeLabel(SupervisionRequestType type) => switch (type) {
      SupervisionRequestType.understandingCase =>
        'Понять случай или динамику клиента',
      SupervisionRequestType.therapistReaction => 'Разобрать мою реакцию',
      SupervisionRequestType.therapeuticRelationship =>
        'Исследовать отношения и процесс',
      SupervisionRequestType.interventionChoice =>
        'Выбрать интервенцию или следующий шаг',
      SupervisionRequestType.ethicsAndRisk =>
        'Разобрать этику, границы или риск',
      SupervisionRequestType.settingAndContract =>
        'Уточнить сеттинг или контракт',
      SupervisionRequestType.other => 'Пока не определено / другое',
    };
