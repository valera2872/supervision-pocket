import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Случаи', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Только обезличенные карточки и профессиональная хронология.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            const Icon(Icons.folder_open_outlined, size: 58, color: AppColors.teal),
            const SizedBox(height: 16),
            Text(
              'Карточек пока нет',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'В следующей сборке здесь можно будет создать случай с псевдонимом и возрастным диапазоном.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Создать карточку'),
            ),
          ],
        ),
      ),
    );
  }
}
