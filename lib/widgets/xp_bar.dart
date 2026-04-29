import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/xp_config.dart';

class XpBar extends StatelessWidget {
  final double totalXp;
  final double height;
  final bool showLabel;

  const XpBar({
    super.key,
    required this.totalXp,
    this.height = 10,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelFromXp(totalXp);
    final current = xpInCurrentLevel(totalXp);
    final needed = xpNeededForNextLevel(level);
    final progress = needed > 0 ? (current / needed).clamp(0.0, 1.0) : 0.0;
    final colors = context.slColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'XP  $current / $needed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            // Track
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    colors: [colors.accentDeep, colors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentGlow,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
