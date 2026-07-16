import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class SupervisionScreen extends StatelessWidget {
  const SupervisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Супервизия', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Подготовленные запросы и выводы после живых встреч.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.paleBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 38,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Пакетов пока нет',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'После первой рефлексии здесь появится материал, который вы сознательно выбрали для супервизии.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
