import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/lock/presentation/pin_keypad.dart';

class CreatePinPanel extends StatefulWidget {
  const CreatePinPanel({required this.onCompleted, super.key});

  final Future<void> Function(String pin) onCompleted;

  @override
  State<CreatePinPanel> createState() => _CreatePinPanelState();
}

class _CreatePinPanelState extends State<CreatePinPanel> {
  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  bool _saving = false;
  String? _error;

  String get _current => _confirming ? _confirm : _first;

  void _digit(String value) {
    if (_current.length >= 6 || _saving) return;
    setState(() {
      _error = null;
      if (_confirming) {
        _confirm += value;
      } else {
        _first += value;
      }
    });
  }

  void _backspace() {
    if (_current.isEmpty || _saving) return;
    setState(() {
      _error = null;
      if (_confirming) {
        _confirm = _confirm.substring(0, _confirm.length - 1);
      } else {
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  Future<void> _continue() async {
    if (_current.length < 4) {
      setState(() => _error = 'Введите не менее четырёх цифр');
      return;
    }
    if (!_confirming) {
      setState(() {
        _confirming = true;
        _error = null;
      });
      return;
    }
    if (_confirm != _first) {
      setState(() {
        _confirm = '';
        _error = 'PIN не совпал. Повторите ещё раз';
      });
      return;
    }
    setState(() => _saving = true);
    await widget.onCompleted(_first);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _confirming ? 'Повторите PIN' : 'Введите новый PIN',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        PinDots(length: _current.length),
        SizedBox(
          height: 38,
          child: _error == null
              ? null
              : Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.safety),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        PinKeypad(
          onDigit: _digit,
          onBackspace: _backspace,
          enabled: !_saving,
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _continue,
          child: Text(_saving ? 'Сохраняем…' : 'Продолжить'),
        ),
        if (_confirming)
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                      _first = '';
                      _confirm = '';
                      _confirming = false;
                      _error = null;
                    }),
            child: const Text('Создать другой PIN'),
          ),
      ],
    );
  }
}
