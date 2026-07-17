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
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 690;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 34),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  SizedBox(height: compact ? 18 : 26),
                  SizedBox(
                    height: compact ? 302 : 352,
                    child: const _PremiumHero(),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  Text(
                    'Зафиксируйте сложный эпизод голосом. Приложение поможет превратить его в ясный вопрос к супервизору.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 15),
                  const _PrivacyLine(),
                  const Spacer(),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Продолжить'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUPERVISION POCKET',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Для психологов, которые проходят супервизию',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153B57), Color(0xFF275B68)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            const Positioned(
              right: -76,
              top: -84,
              child: _GlowCircle(size: 230, opacity: .07),
            ),
            const Positioned(
              left: -58,
              bottom: -86,
              child: _GlowCircle(size: 205, opacity: .055),
            ),
            Positioned(
              right: 24,
              top: 25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: .14)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Личная запись',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.warmAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'После консультации —\nяснее к супервизии',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 31,
                          height: 1.08,
                          letterSpacing: -.7,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Сохраните то, что осталось с вами.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Expanded(child: _FlowStep(number: '01', label: 'Эпизод')),
                      _FlowArrow(),
                      Expanded(child: _FlowStep(number: '02', label: 'Реакция')),
                      _FlowArrow(),
                      Expanded(child: _FlowStep(number: '03', label: 'Вопрос')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 34,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .52),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 15,
        color: Colors.white.withValues(alpha: .42),
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.paleTeal,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Локально · обезличенно · под PIN',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
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
