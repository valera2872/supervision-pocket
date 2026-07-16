import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keys = <String?>['1', '2', '3', '4', '5', '6', '7', '8', '9', null, '0'];
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 58,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            if (index == 11) {
              return IconButton(
                onPressed: enabled ? onBackspace : null,
                icon: const Icon(Icons.backspace_outlined),
                tooltip: 'Удалить цифру',
              );
            }
            final keyValue = keys[index];
            if (keyValue == null) return const SizedBox.shrink();
            return Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outline),
              ),
              child: InkWell(
                onTap: enabled ? () => onDigit(keyValue) : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    keyValue,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PinDots extends StatelessWidget {
  const PinDots({required this.length, this.max = 6, super.key});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Введено цифр: $length',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(max, (index) {
          final filled = index < length;
          return Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.teal : Colors.transparent,
              border: Border.all(
                color: filled ? AppColors.teal : AppColors.outline,
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }
}
