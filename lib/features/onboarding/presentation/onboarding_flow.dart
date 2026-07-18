import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/core/widgets/step_dots.dart';
import 'package:supervision_pocket/features/lock/presentation/create_pin_panel.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onCompleted, super.key});

  final Future<void> Function(String pin, UserRole role) onCompleted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  final _checks = [false, false, false];
  int _page = 0;
  UserRole? _role;

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

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectRole(UserRole role) {
    setState(() => _role = role);
    _next();
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
                  _RoleEntryPage(onSelected: _selectRole),
                  _RoleOverviewPage(
                    role: _role ?? UserRole.supervisee,
                    onBack: _back,
                    onNext: _next,
                  ),
                  _PrivacyPage(
                    checks: _checks,
                    onChanged: (index, value) {
                      setState(() => _checks[index] = value);
                    },
                    onBack: _back,
                    onNext: _next,
                  ),
                  _PinPage(
                    role: _role ?? UserRole.supervisee,
                    onBack: _back,
                    onCompleted: (pin) => widget.onCompleted(
                      pin,
                      _role ?? UserRole.supervisee,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, top: 6),
              child: StepDots(current: _page, total: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleEntryPage extends StatelessWidget {
  const _RoleEntryPage({required this.onSelected});

  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 34),
        Text(
          'Как вы будете работать?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Выберите роль, чтобы открыть нужный кабинет. Её можно изменить позже без удаления записей.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _RoleCard(
          icon: Icons.edit_note_rounded,
          title: 'Я психолог',
          description:
              'Записывать сложные эпизоды, готовить вопросы и передавать супервизору только выбранные материалы.',
          onTap: () => onSelected(UserRole.supervisee),
        ),
        const SizedBox(height: 14),
        _RoleCard(
          icon: Icons.groups_2_outlined,
          title: 'Я супервизор',
          description:
              'Вести супервизантов, собирать запросы, готовить встречи и фиксировать итоги.',
          onTap: () => onSelected(UserRole.supervisor),
        ),
        const SizedBox(height: 22),
        const _SecurityLine(
          text: 'Данные хранятся локально и защищаются PIN',
        ),
      ],
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
                'Для психологов и супервизоров',
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B173B57),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: AppColors.teal, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.42,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOverviewPage extends StatelessWidget {
  const _RoleOverviewPage({
    required this.role,
    required this.onBack,
    required this.onNext,
  });

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isSupervisor = role == UserRole.supervisor;
    final title = isSupervisor
        ? 'Супервизанты, запросы и встречи — в одном месте'
        : 'От сложного эпизода — к ясному вопросу';
    final description = isSupervisor
        ? 'Ведите карточки супервизантов, собирайте повестку, сохраняйте личные заметки и общий итог встречи.'
        : 'После консультации зафиксируйте, что произошло, как вы отреагировали и что важно обсудить на супервизии.';
    final steps = isSupervisor
        ? const ['Люди', 'Повестка', 'Итог']
        : const ['Эпизод', 'Реакция', 'Вопрос'];
    final features = isSupervisor
        ? const [
            'Карточки и история работы',
            'Личная подготовка супервизора',
            'Общие итоги и следующие шаги',
          ]
        : const [
            'Голосовой ввод или текст',
            'Личные записи остаются закрытыми',
            'Передаётся только выбранный материал',
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Изменить роль'),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF153B57), Color(0xFF275B68)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .2),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warmAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSupervisor
                          ? Icons.groups_2_outlined
                          : Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSupervisor
                          ? 'КАБИНЕТ СУПЕРВИЗОРА'
                          : 'КАБИНЕТ ПСИХОЛОГА',
                      style: const TextStyle(
                        color: Color(0xFFD6E5E9),
                        fontSize: 11,
                        letterSpacing: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.12,
                      letterSpacing: -.45,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .8),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < steps.length; index++)
                    _FlowChip(number: index + 1, label: steps[index]),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _FeatureLine(text: feature),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sync_lock_outlined, color: AppColors.navy),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Пока оба кабинета работают локально. Защищённое соединение между устройствами будет добавлено на серверном этапе.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Продолжить'),
        ),
      ],
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Text(
        '0$number  $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.paleTeal,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 18,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityLine extends StatelessWidget {
  const _SecurityLine({required this.text});

  final String text;

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
            text,
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
    required this.onBack,
    required this.onNext,
  });

  final List<bool> checks;
  final void Function(int index, bool value) onChanged;
  final VoidCallback onBack;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Назад'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Сначала — безопасность',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Перед началом подтвердите три правила работы с профессиональными материалами.',
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
        const SizedBox(height: 10),
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
                  'В этой версии нет рекламы, автоматической отправки материалов и доступа к вашим данным у третьих лиц.',
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
  const _PinPage({
    required this.role,
    required this.onBack,
    required this.onCompleted,
  });

  final UserRole role;
  final VoidCallback onBack;
  final Future<void> Function(String pin) onCompleted;

  @override
  Widget build(BuildContext context) {
    final workspace = role == UserRole.supervisor
        ? 'кабинет супервизора'
        : 'кабинет психолога';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Назад'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Защитите вход',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Создайте PIN из 4–6 цифр. Он будет защищать $workspace и локальные записи.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Если PIN будет забыт, восстановить зашифрованные данные без их удаления нельзя.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        CreatePinPanel(onCompleted: onCompleted),
      ],
    );
  }
}
