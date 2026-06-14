import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Flat dark card with a subtle border. No blur — clean editorial aesthetic.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double borderWidth;
  final Color? overrideBorder;
  // ignored params kept for API compat
  final double blur;
  final bool blurred;
  final bool strongFill;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.onTap,
    this.borderWidth = 1.0,
    this.overrideBorder,
    this.blur = 0,
    this.blurred = false,
    this.strongFill = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderColor = overrideBorder ??
        (isDark ? AppColors.border : Colors.black12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}
