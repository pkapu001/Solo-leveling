import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared weekly-scaling-percentage slider.
///
/// Displays a labelled [Slider] from [kScalingMin]% to [kScalingMax]%.
/// Use this widget in every screen that lets the user pick the weekly
/// progression rate so the range and appearance are always in sync.
const double kScalingMin = 1.0;
const double kScalingMax = 50.0;

class ScalingSlider extends StatelessWidget {
  /// Current value in percent (e.g. 5.0 = 5 %).
  final double value;

  /// Called whenever the slider moves.
  final ValueChanged<double> onChanged;

  /// Optional suffix text shown after the percentage (e.g. a unit preview).
  final String? suffixText;

  /// Whether to show one decimal place (true) or round to int (false).
  final bool showDecimal;

  const ScalingSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.suffixText,
    this.showDecimal = false,
  });

  String _label(double v) =>
      showDecimal ? '+${v.toStringAsFixed(1)}%' : '+${v.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final colors = context.slColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Weekly increase: ${_label(value)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.accent),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffixText != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  suffixText!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.accent,
            thumbColor: colors.accent,
            inactiveTrackColor: AppColors.cardBorder,
            overlayColor: colors.accent.withValues(alpha: 0.15),
            valueIndicatorColor: colors.accentDeep,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Slider(
            value: value,
            min: kScalingMin,
            max: kScalingMax,
            divisions: ((kScalingMax - kScalingMin)).toInt(),
            label: _label(value),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
