import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';

Future<void> openReflectionEditor(
  BuildContext context,
  CaseController controller,
  String caseId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ReflectionEditorScreen(
        controller: controller,
        caseId: caseId,
      ),
    ),
  );
}

class ReflectionEditorScreen extends StatefulWidget {
  const ReflectionEditorScreen({
    required this.controller,
    required this.caseId,
    super.key,
  });

  final CaseController controller;
  final String caseId;

  @override
  State<ReflectionEditorScreen> createState() => _ReflectionEditorScreenState();
}

class _ReflectionEditorScreenState extends State<ReflectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = List.generate(7, (_) => TextEditingController());
  Timer? _draftTimer;
  bool _saving = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.findById(widget.caseId)?.draft;
    if (draft != null) {
      final values = [
        draft.observedFact,
        draft.interpretation,
        draft.feeling,
        draft.impulse,
        draft.actionTaken,
        draft.stuckPoint,
        draft.supervisionQuestion,
      ];
      for (var i = 0; i < _fields.length; i++) {
        _fields[i].text = values[i];
      }
    }
    for (final field in _fields) {
      field.addListener(_scheduleDraft);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_submitted) unawaited(_saveDraft());
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _scheduleDraft() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(_saveDraft());
    });
  }

  ReflectionDraft _draft() => ReflectionDraft(
        updatedAt: DateTime.now(),
        observedFact: _fields[0].text,
        interpretation: _fields[1].text,
        feeling: _fields[2].text,
        impulse: _fields[3].text,
        actionTaken: _fields[4].text,
        stuckPoint: _fields[5].text,
        supervisionQuestion: _fields[6].text,
      );

  Future<void> _saveDraft() {
    return widget.controller.saveDraft(widget.caseId, _draft());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _draftTimer?.cancel();
    setState(() => _saving = true);
    _submitted = true;
    await widget.controller.addReflection(widget.caseId, _draft());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final caseFile = widget.controller.findById(widget.caseId);
    return Scaffold(
      appBar: AppBar(
        title: Text(caseFile?.alias ?? 'Рефлексия'),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              'Сохранить важный момент',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              'Не нужно заполнять всё. Начните с факта, который продолжает удерживать внимание.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            const _SeparationHint(),
            const SizedBox(height: 18),
            _ReflectionField(
              controller: _fields[0],
              number: '1',
              label: 'Что произошло?',
              hint: 'Только наблюдаемые слова, действия и события',
              isRequired: true,
            ),
            _ReflectionField(
              controller: _fields[1],
              number: '2',
              label: 'Как я это понимаю?',
              hint: 'Моя интерпретация или рабочая гипотеза',
            ),
            _ReflectionField(
              controller: _fields[2],
              number: '3',
              label: 'Что я почувствовал(а)?',
              hint: 'Эмоции и телесная реакция',
            ),
            _ReflectionField(
              controller: _fields[3],
              number: '4',
              label: 'Что мне захотелось сделать?',
              hint: 'Первый импульс, даже если вы ему не последовали',
            ),
            _ReflectionField(
              controller: _fields[4],
              number: '5',
              label: 'Что я сделал(а)?',
              hint: 'Мои слова, решение или вмешательство',
            ),
            _ReflectionField(
              controller: _fields[5],
              number: '6',
              label: 'Где возник тупик?',
              hint: 'Что осталось неясным или трудным',
            ),
            _ReflectionField(
              controller: _fields[6],
              number: '7',
              label: 'Вопрос к супервизору',
              hint: 'Что именно я хочу понять на супервизии?',
              accent: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.teal),
                const SizedBox(width: 7),
                Text(
                  'Черновик сохраняется автоматически и локально',
                  style: Theme.of(context).textTheme.bodyMedium,
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
          label: const Text('Сохранить в хронологию'),
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
              'Факт — то, что можно было увидеть или услышать. Гипотеза — то, как вы это объясняете.',
            ),
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
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                filled: accent,
                fillColor: accent ? AppColors.paleBlue : null,
              ),
              validator: isRequired
                  ? (value) => value == null || value.trim().isEmpty
                      ? 'Сначала опишите наблюдаемый факт'
                      : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
