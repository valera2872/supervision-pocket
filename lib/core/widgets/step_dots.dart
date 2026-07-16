import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class StepDots extends StatelessWidget {
  const StepDots({required this.current, required this.total, super.key});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.teal : AppColors.outline,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
