import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 76, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.paleTeal,
        borderRadius: BorderRadius.circular(size * .29),
      ),
      child: Icon(
        Icons.forum_outlined,
        size: size * .48,
        color: AppColors.teal,
        semanticLabel: 'Supervision Pocket',
      ),
    );
  }
}
