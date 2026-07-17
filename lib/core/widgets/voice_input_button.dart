import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    required this.controller,
    required this.fieldName,
    super.key,
  });

  final TextEditingController controller;
  final String fieldName;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  static final SpeechToText _speech = SpeechToText();
  static Future<bool>? _initialization;
  static Future<String?>? _russianLocale;
  static _VoiceInputButtonState? _active;
  static bool _noticeAccepted = false;

  bool _listening = false;
  bool _working = false;
  String _textBeforeListening = '';

  @override
  void dispose() {
    if (_active == this) {
      _active = null;
      unawaited(_speech.cancel());
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_working) return;
    if (_listening) {
      await _stopListening();
      return;
    }

    final accepted = await _confirmVoicePrivacy();
    if (!mounted || !accepted) return;

    final previous = _active;
    if (previous != null && previous != this) {
      await previous._stopListening();
    }
    if (!mounted) return;

    setState(() => _working = true);
    final available = await _initializeSpeech();
    if (!mounted) return;
    if (!available) {
      setState(() => _working = false);
      _showMessage(
        'На этом телефоне распознавание речи недоступно. Проверьте разрешение микрофона и установку офлайн-распознавания.',
      );
      return;
    }

    _active = this;
    _textBeforeListening = widget.controller.text.trim();
    _speech
      ..statusListener = _handleStatus
      ..errorListener = _handleError;

    try {
      final localeId = await (_russianLocale ??= _findRussianLocale());
      await _speech.listen(
        onResult: _handleResult,
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          onDevice: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(seconds: 60),
          localeId: localeId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _working = false;
        _listening = _speech.isListening;
      });
      if (!_listening) {
        _active = null;
        _showMessage(
          'Не удалось начать локальное распознавание. Можно использовать микрофон на клавиатуре телефона.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _listening = false;
      });
      _active = null;
      _showMessage(
        'Голосовой ввод не запустился. Проверьте разрешение микрофона и попробуйте ещё раз.',
      );
    }
  }

  Future<bool> _initializeSpeech() {
    return _initialization ??= _speech.initialize(
      options: [SpeechToText.androidNoBluetooth],
    );
  }

  Future<String?> _findRussianLocale() async {
    final locales = await _speech.locales();
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('ru')) {
        return locale.localeId;
      }
    }
    return null;
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted || _active != this) return;
    final recognized = result.recognizedWords.trim();
    if (recognized.isNotEmpty) {
      final separator = _textBeforeListening.isEmpty ? '' : ' ';
      final text = '$_textBeforeListening$separator$recognized';
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (result.finalResult) {
      setState(() => _listening = false);
      _active = null;
    }
  }

  void _handleStatus(String status) {
    if (!mounted || _active != this) return;
    final listening = status == SpeechToText.listeningStatus;
    if (_listening != listening) {
      setState(() {
        _working = false;
        _listening = listening;
      });
    }
    if (!listening) _active = null;
  }

  void _handleError(SpeechRecognitionError error) {
    if (!mounted || _active != this) return;
    setState(() {
      _working = false;
      _listening = false;
    });
    _active = null;
    _showMessage(
      'Распознавание остановлено. Попробуйте говорить короткими фразами без длинных пауз.',
    );
  }

  Future<void> _stopListening() async {
    if (_active == this) {
      await _speech.stop();
      _active = null;
    }
    if (!mounted) return;
    setState(() {
      _working = false;
      _listening = false;
    });
  }

  Future<bool> _confirmVoicePrivacy() async {
    if (_noticeAccepted) return true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перед голосовым вводом'),
        content: const Text(
          'Речь распознаёт системная служба телефона. Приложение не сохраняет аудиозапись. Не называйте настоящие имена, адреса, школы и другие данные, по которым можно узнать клиента.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Понимаю'),
          ),
        ],
      ),
    );
    if (accepted == true) _noticeAccepted = true;
    return accepted ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final color = _listening ? Theme.of(context).colorScheme.error : AppColors.teal;
    return IconButton(
      onPressed: _toggle,
      tooltip: _listening
          ? 'Остановить голосовой ввод'
          : 'Надиктовать: ${widget.fieldName}',
      color: color,
      icon: _working
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
    );
  }
}
