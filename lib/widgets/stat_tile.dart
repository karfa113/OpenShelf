import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color tint;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
    this.tint = AppColors.accentStrong,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      overrideBorder: tint.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.35),
                  tint.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tint.withValues(alpha: 0.65)),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: t.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: t.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: t.textTheme.bodySmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
