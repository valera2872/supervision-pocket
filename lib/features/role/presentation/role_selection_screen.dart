import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({
    required this.currentRole,
    required this.onSelected,
    required this.onLock,
    super.key,
  });

  final UserRole? currentRole;
  final Future<void> Function(UserRole role) onSelected;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Supervision Pocket',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onLock,
                  tooltip: 'Заблокировать',
                  icon: const Icon(Icons.lock_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              currentRole == null ? 'Как вы будете работать?' : 'Выберите рабочее пространство',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'У каждой роли свой интерфейс. Вы сможете изменить выбор позже, не теряя локальные записи.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 26),
            _RoleCard(
              role: UserRole.supervisee,
              icon: Icons.edit_note_rounded,
              eyebrow: 'ЛИЧНАЯ РЕФЛЕКСИЯ',
              title: 'Я психолог',
              description:
                  'Фиксировать сложные эпизоды, готовить вопросы и передавать выбранные материалы супервизору.',
              selected: currentRole == UserRole.supervisee,
              onTap: () => onSelected(UserRole.supervisee),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              role: UserRole.supervisor,
              icon: Icons.groups_2_outlined,
              eyebrow: 'РАБОТА С СУПЕРВИЗАНТАМИ',
              title: 'Я супервизор',
              description:
                  'Вести список супервизантов, собирать запросы к встрече и отмечать договорённости.',
              selected: currentRole == UserRole.supervisor,
              onTap: () => onSelected(UserRole.supervisor),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'На этом этапе оба пространства работают локально. Защищённое подключение между устройствами будет добавлено отдельным серверным этапом.',
                    ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.outline,
            ),
            boxShadow: selected
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0B173B57),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .12)
                      : AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFBFD7DD)
                            : AppColors.teal,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFDCE8ED)
                            : AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
