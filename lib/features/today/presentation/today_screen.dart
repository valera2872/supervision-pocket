import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({required this.onLock, super.key});

  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сегодня', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Что важно сохранить для профессионального размышления?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onLock,
                tooltip: 'Заблокировать',
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _comingNext(context),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Row(
                  children: [
                    _CaptureIcon(),
                    SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сохранить после консультации',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Голосом или текстом — около одной минуты',
                            style: TextStyle(color: Color(0xFFDDE8EE), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Можно продолжить', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    size: 38,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Пока здесь спокойно',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Здесь появятся записи, к которым вы захотите вернуться, когда будет достаточно времени и внимания.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.paleTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не обязательно анализировать каждую консультацию. Сохраняйте те моменты, которые продолжают удерживать ваше внимание.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _comingNext(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Быстрая фиксация появится в сборке 0.3.0'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 29),
    );
  }
}
