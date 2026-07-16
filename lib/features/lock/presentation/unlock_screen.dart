import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/app_logo.dart';
import 'package:supervision_pocket/features/lock/presentation/pin_keypad.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String _pin = '';
  String? _error;
  bool _checking = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _digit(String value) {
    if (_pin.length >= 6 || _checking || widget.controller.remainingBlock != null) {
      return;
    }
    setState(() {
      _error = null;
      _pin += value;
    });
  }

  void _backspace() {
    if (_pin.isEmpty || _checking) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _unlock() async {
    if (_pin.length < 4) return;
    setState(() => _checking = true);
    final valid = await widget.controller.unlock(_pin);
    if (!mounted || valid) return;
    final blocked = widget.controller.remainingBlock;
    setState(() {
      _checking = false;
      _pin = '';
      _error = blocked == null
          ? 'PIN не подошёл'
          : 'Слишком много попыток. Подождите 30 секунд';
    });
    if (blocked != null) {
      _timer = Timer(const Duration(seconds: 30), () {
        if (mounted) setState(() => _error = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = widget.controller.remainingBlock != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
          children: [
            const Center(child: AppLogo(size: 68)),
            const SizedBox(height: 24),
            Text(
              'Supervision Pocket',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Введите PIN, чтобы открыть профессиональные записи',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),
            PinDots(length: _pin.length),
            SizedBox(
              height: 42,
              child: _error == null
                  ? null
                  : Center(
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.safety),
                      ),
                    ),
            ),
            PinKeypad(
              onDigit: _digit,
              onBackspace: _backspace,
              enabled: !_checking && !blocked,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _pin.length >= 4 && !_checking && !blocked ? _unlock : null,
              child: Text(_checking ? 'Проверяем…' : 'Открыть'),
            ),
          ],
        ),
      ),
    );
  }
}
