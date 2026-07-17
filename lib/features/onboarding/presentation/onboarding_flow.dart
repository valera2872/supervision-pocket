import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/step_dots.dart';
import 'package:supervision_pocket/features/lock/presentation/create_pin_panel.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onCompleted, super.key});

  final Future<void> Function(String pin) onCompleted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  int _page = 0;
  final _checks = [false, false, false];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomePage(onNext: _next),
                  _PrivacyPage(
                    checks: _checks,
                    onChanged: (index, value) {
                      setState(() => _checks[index] = value);
                    },
                    onNext: _next,
                  ),
                  _PinPage(onCompleted: widget.onCompleted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: StepDots(current: _page, total: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paleTeal,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Для психологов, которые проходят супервизию',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Запишите сложный момент после консультации',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  'Если после встречи вы продолжаете думать о словах клиента, своей реакции или не понимаете, как лучше было ответить, сохраните этот эпизод здесь.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Что произошло → что вы почувствовали → что хотите спросить у супервизора',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const _Benefit(
                  icon: Icons.mic_none_rounded,
                  text: 'Надиктовать запись голосом или ввести текст',
                ),
                const _Benefit(
                  icon: Icons.lock_outline_rounded,
                  text: 'Хранить обезличенные записи в защищённом виде',
                ),
                const _Benefit(
                  icon: Icons.send_outlined,
                  text: 'Подготовить и передать вопрос супервизору',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  child: const Text('Начать'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleTeal,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage({
    required this.checks,
    required this.onChanged,
    required this.onNext,
  });

  final List<bool> checks;
  final void Function(int index, bool value) onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final allChecked = checks.every((value) => value);
    const items = [
      (
        'Использовать псевдонимы',
        'Не вводить имена, инициалы и узнаваемые прозвища.',
      ),
      (
        'Не сохранять идентификаторы',
        'Без адресов, телефонов, названий школ и организаций.',
      ),
      (
        'Сохранять живую супервизию',
        'Приложение не ставит диагнозы и не заменяет экстренную помощь.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 20),
      children: [
        Text(
          'Сначала — безопасность',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Материал остаётся на этом устройстве. Перед началом подтвердите три правила.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 22),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: CheckboxListTile(
                value: checks[index],
                onChanged: (value) => onChanged(index, value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                title: Text(
                  item.$1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(item.$2),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.navy),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'В этой версии нет аккаунта, рекламы, облачной синхронизации и автоматической отправки материалов.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: allChecked ? onNext : null,
          child: const Text('Я понимаю и согласен'),
        ),
      ],
    );
  }
}

class _PinPage extends StatelessWidget {
  const _PinPage({required this.onCompleted});

  final Future<void> Function(String pin) onCompleted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 20),
      children: [
        Text(
          'Защитите вход',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Создайте PIN из 4–6 цифр. Если PIN будет забыт, восстановить локальные записи без удаления данных нельзя.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 26),
        CreatePinPanel(onCompleted: onCompleted),
      ],
    );
  }
}
