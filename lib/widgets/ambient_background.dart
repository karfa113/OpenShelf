import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.bg
        : AppColors.lightBg;
    return ColoredBox(color: bg, child: child);
  }
}
