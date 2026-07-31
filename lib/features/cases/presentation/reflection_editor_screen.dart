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
  bool _anonymizationConfirmed = false;

  bool get _editing => widget.entryId != null;
  bool get _full => _mode == ReflectionMode.casePreparation;

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
      for (var index = 0; index < _fields.length; index++) {
        _fields[index].text = values[index];
      }
    }
    for (final field in _fields) {
      field.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_submitted && !_editing) {
      unawaited(
        widget.controller.saveDraft(widget.caseId, _draft()).catchError((_) {}),
      );
    }
    for (final field in _fields) {
      field
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
    if (!_editing && !_clearing) {
      _scheduleDraft();
    }
  }

  void _scheduleDraft() {
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
    if (_editing) {
      return;
    }
    try {
      await widget.controller.saveDraft(widget.caseId, _draft());
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось сохранить последние изменения. Текст остаётся на экране.',
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
              : 'Все введённые и надиктованные ответы будут удалены. Карточка случая и ранее сохранённые записи останутся.',
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
    if (confirmed != true) {
      return;
    }

    _draftTimer?.cancel();
    _clearing = true;
    for (final field in _fields) {
      field.clear();
    }
    setState(() {
      _requestType = SupervisionRequestType.other;
      _anonymizationConfirmed = false;
    });
    try {
      if (!_editing) {
        await widget.controller.clearDraft(widget.caseId);
      }
      if (!mounted) {
        return;
      }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
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
              _full
                  ? 'Подготовьте материал к встрече по смысловым этапам. Заполняйте только то, что помогает понять запрос.'
                  : 'Быстро сохраните сложный эпизод после консультации. Все поля, кроме описания события, можно пропустить.',
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
                if (!_editing) {
                  _scheduleDraft();
                }
              },
            ),
            const SizedBox(height: 16),
            const _VisibilityBanner(),
            const SizedBox(height: 16),
            const _SeparationHint(),
            const SizedBox(height: 16),
            if (_full) _buildFullPreparation() else _buildQuickReflection(),
            const SizedBox(height: 16),
            _ReadinessCard(
              full: _full,
              hasEpisode: _fields[0].text.trim().isNotEmpty,
              hasQuestion: _fields[6].text.trim().isNotEmpty,
              hasContext: !_full ||
                  [_fields[7], _fields[8], _fields[9]]
                      .any((field) => field.text.trim().isNotEmpty),
              anonymizationConfirmed: _anonymizationConfirmed,
              onAnonymizationChanged: (value) {
                setState(() => _anonymizationConfirmed = value);
              },
            ),
            const SizedBox(height: 16),
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
                        : 'Черновик автоматически сохраняется на этом устройстве',
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

  Widget _buildQuickReflection() {
    return Column(
      children: [
        _ReflectionField(
          controller: _fields[0],
          number: '1',
          label: 'Что произошло?',
          hint: 'Что можно было увидеть или услышать — без объяснений',
          isRequired: true,
        ),
        _ReflectionField(
          controller: _fields[1],
          number: '2',
          label: 'Как я это понял(а)?',
          hint: 'Моё предположение или объяснение ситуации',
        ),
        _ReflectionField(
          controller: _fields[2],
          number: '3',
          label: 'Что я почувствовал(а)?',
          hint: 'Например: растерянность, раздражение, тревогу или бессилие',
        ),
        _ReflectionField(
          controller: _fields[3],
          number: '4',
          label: 'Что мне захотелось сделать?',
          hint: 'Первый импульс, даже если я ему не последовал(а)',
        ),
        _ReflectionField(
          controller: _fields[4],
          number: '5',
          label: 'Как я отреагировал(а)?',
          hint: 'Что я сказал(а), сделал(а) или намеренно не сделал(а)',
        ),
        _ReflectionField(
          controller: _fields[5],
          number: '6',
          label: 'Что осталось непонятным?',
          hint: 'Где я сомневаюсь или не понимаю, как двигаться дальше',
        ),
        _ReflectionField(
          controller: _fields[6],
          number: '7',
          label: 'Что я хочу спросить у супервизора?',
          hint: 'Один конкретный вопрос для ближайшей встречи',
          accent: true,
        ),
      ],
    );
  }

  Widget _buildFullPreparation() {
    return Column(
      children: [
        _CaseSection(
          title: '1. Контекст клиента и работы',
          subtitle: _sectionProgress([7, 8, 9]),
          icon: Icons.person_search_outlined,
          initiallyExpanded: true,
          children: [
            _ReflectionField(
              controller: _fields[7],
              label: 'С чем пришёл клиент?',
              hint: 'Запрос клиента без идентифицирующих деталей',
            ),
            _ReflectionField(
              controller: _fields[8],
              label: 'Что важно знать о контексте?',
              hint: 'Только сведения, влияющие на понимание случая',
            ),
            _ReflectionField(
              controller: _fields[9],
              label: 'Что происходит сейчас?',
              hint: 'Динамика работы, изменения и повторяющиеся трудности',
            ),
          ],
        ),
        _CaseSection(
          title: '2. Ключевой эпизод',
          subtitle: _sectionProgress([0, 1]),
          icon: Icons.visibility_outlined,
          initiallyExpanded: true,
          children: [
            _ReflectionField(
              controller: _fields[0],
              label: 'Что произошло?',
              hint: 'Наблюдаемые слова и действия — без объяснений',
              isRequired: true,
            ),
            _ReflectionField(
              controller: _fields[1],
              label: 'Как я это понял(а)?',
              hint: 'Моя интерпретация или предположение',
            ),
          ],
        ),
        _CaseSection(
          title: '3. Моя реакция',
          subtitle: _sectionProgress([2, 3, 4]),
          icon: Icons.self_improvement_outlined,
          children: [
            _ReflectionField(
              controller: _fields[2],
              label: 'Что я почувствовал(а)?',
              hint: 'Эмоции и телесная реакция',
            ),
            _ReflectionField(
              controller: _fields[3],
              label: 'Что мне захотелось сделать?',
              hint: 'Первый импульс, даже если я ему не последовал(а)',
            ),
            _ReflectionField(
              controller: _fields[4],
              label: 'Как я отреагировал(а)?',
              hint: 'Что я реально сказал(а), сделал(а) или не сделал(а)',
            ),
          ],
        ),
        _CaseSection(
          title: '4. Профессиональное осмысление',
          subtitle: _sectionProgress([11, 12, 10, 13, 5]),
          icon: Icons.psychology_alt_outlined,
          children: [
            _ReflectionField(
              controller: _fields[11],
              label: 'Что я уже пробовал(а)?',
              hint: 'Интервенции и их результат',
            ),
            _ReflectionField(
              controller: _fields[12],
              label: 'Что работает или поддерживает?',
              hint: 'Ресурсы клиента, контакта и вашей работы',
            ),
            _ReflectionField(
              controller: _fields[10],
              label: 'Моя рабочая гипотеза',
              hint: 'Предположение для проверки, а не готовый вывод',
            ),
            _ReflectionField(
              controller: _fields[13],
              label: 'Есть ли вопрос границ, этики или безопасности?',
              hint: 'Риск, контракт, компетентность или организационный контекст',
            ),
            _ReflectionField(
              controller: _fields[5],
              label: 'Что осталось непонятным?',
              hint: 'Где я сомневаюсь или застрял(а)',
            ),
          ],
        ),
        _CaseSection(
          title: '5. Запрос на супервизию',
          subtitle: _fields[6].text.trim().isEmpty
              ? 'Нужна конкретная формулировка'
              : 'Вопрос сформулирован',
          icon: Icons.forum_outlined,
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: DropdownButtonFormField<SupervisionRequestType>(
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
                  if (value == null) {
                    return;
                  }
                  setState(() => _requestType = value);
                  if (!_editing) {
                    _scheduleDraft();
                  }
                },
              ),
            ),
            _ReflectionField(
              controller: _fields[6],
              label: 'Что я хочу спросить у супервизора?',
              hint: 'Один вопрос, с которым можно работать во время встречи',
              accent: true,
            ),
          ],
        ),
      ],
    );
  }

  String _sectionProgress(List<int> indexes) {
    final completed = indexes
        .where((index) => _fields[index].text.trim().isNotEmpty)
        .length;
    if (completed == 0) {
      return 'Не заполнено — можно пропустить';
    }
    return 'Заполнено $completed из ${indexes.length}';
  }
}

class _VisibilityBanner extends StatelessWidget {
  const _VisibilityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.paleTeal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, color: AppColors.teal),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Пока вы не нажали «Передать супервизору», запись остаётся только на этом устройстве. При передаче в пакет войдут все заполненные поля, показанные в предварительном просмотре.',
            ),
          ),
        ],
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

class _CaseSection extends StatelessWidget {
  const _CaseSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: AppColors.teal),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        children: children,
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.full,
    required this.hasEpisode,
    required this.hasQuestion,
    required this.hasContext,
    required this.anonymizationConfirmed,
    required this.onAnonymizationChanged,
  });

  final bool full;
  final bool hasEpisode;
  final bool hasQuestion;
  final bool hasContext;
  final bool anonymizationConfirmed;
  final ValueChanged<bool> onAnonymizationChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: AppColors.teal),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Готовность материала',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ReadinessLine(
              ready: hasEpisode,
              text: 'Есть наблюдаемый эпизод',
            ),
            _ReadinessLine(
              ready: hasQuestion,
              text: 'Сформулирован вопрос супервизору',
            ),
            if (full)
              _ReadinessLine(
                ready: hasContext,
                text: 'Добавлен необходимый контекст',
              ),
            CheckboxListTile(
              value: anonymizationConfirmed,
              onChanged: (value) => onAnonymizationChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Я проверил(а), что нет имён, адресов, школы, места работы и других узнаваемых деталей',
              ),
            ),
            Text(
              'Неполный материал можно сохранить. Этот список ничего не блокирует.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessLine extends StatelessWidget {
  const _ReadinessLine({required this.ready, required this.text});

  final bool ready;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: ready ? AppColors.teal : AppColors.muted,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ReflectionField extends StatelessWidget {
  const _ReflectionField({
    required this.controller,
    required this.label,
    required this.hint,
    this.number,
    this.isRequired = false,
    this.accent = false,
  });

  final TextEditingController controller;
  final String? number;
  final String label;
  final String hint;
  final bool isRequired;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
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
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: number == null
          ? field
          : Row(
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
                    number!,
                    style: TextStyle(
                      color: accent ? Colors.white : AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(child: field),
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
