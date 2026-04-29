import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/exercises.dart';
import '../models/exercise_config.dart';
import '../services/scaling_service.dart';
import '../theme/app_theme.dart';
import 'scaling_slider.dart';

/// A card that lets the user view and edit a single active exercise config
/// (target amount + weekly scaling %). Used in DailyQuestSettingsScreen.
class ExerciseConfigTile extends StatelessWidget {
  final ExerciseConfig config;
  final ValueChanged<ExerciseConfig> onChanged;
  final VoidCallback onRemove;

  /// Called when the user taps the edit (pencil) icon. Only supplied for
  /// custom exercises so they can navigate to the edit form.
  final VoidCallback? onEdit;
  final bool useImperial;

  const ExerciseConfigTile({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onRemove,
    this.onEdit,
    this.useImperial = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = exerciseById(config.exerciseId);
    if (def == null) return const SizedBox.shrink();

    final isDistance = def.type == ExerciseType.distance;
    final displayTarget = (isDistance && useImperial)
        ? kmToMi(config.targetAmount)
        : config.targetAmount;
    final displayUnit = (isDistance && useImperial) ? 'mi' : def.unit;
    final nextWeekKm = previewNextWeekTarget(
      config.targetAmount,
      config.scalingPct,
      isDistance: isDistance,
    );
    final displayNextWeek =
        (isDistance && useImperial) ? kmToMi(nextWeekKm) : nextWeekKm;
    final colors = context.slColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: goldCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  def.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textMuted),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit exercise',
                ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.textMuted),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove from quest',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Target: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () => _editTarget(context, def),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: colors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${_fmt(displayTarget)} $displayUnit',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: colors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '(tap to edit)',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ScalingSlider(
            value: config.scalingPct,
            showDecimal: true,
            suffixText: '(next: ~${_fmt(displayNextWeek)} $displayUnit)',
            onChanged: (v) => onChanged(ExerciseConfig(
              exerciseId: config.exerciseId,
              targetAmount: config.targetAmount,
              scalingPct: v,
            )),
          ),
        ],
      ),
    );
  }

  Future<void> _editTarget(BuildContext context, ExerciseDefinition def) async {
    final isDistance = def.type == ExerciseType.distance;

    if (isDistance) {
      final dispVal =
          useImperial ? kmToMi(config.targetAmount) : config.targetAmount;
      final dispUnit = useImperial ? 'mi' : def.unit;
      final controller = TextEditingController(text: _fmt(dispVal));

      final result = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Set target for ${def.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              suffixText: dispUnit,
              suffixStyle: TextStyle(color: context.slColors.accent),
            ),
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.slColors.accent,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final entered = double.tryParse(controller.text);
                if (entered != null && entered > 0) {
                  Navigator.pop(ctx, entered);
                }
              },
              child:
                  Text('Set', style: TextStyle(color: context.slColors.accent)),
            ),
          ],
        ),
      );
      if (result != null) {
        final kmValue = useImperial ? miToKm(result) : result;
        onChanged(ExerciseConfig(
          exerciseId: config.exerciseId,
          targetAmount: kmValue,
          scalingPct: config.scalingPct,
        ));
      }
      return;
    }

    // Reps / duration
    final allowDecimal = def.unit == 'minutes';
    final controller = TextEditingController(text: _fmt(config.targetAmount));

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Set target for ${def.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: allowDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            allowDecimal
                ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                : FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            suffixText: def.unit,
            suffixStyle: TextStyle(color: context.slColors.accent),
          ),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.slColors.accent,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final entered = double.tryParse(controller.text);
              if (entered != null &&
                  entered >= def.minTarget &&
                  entered <= def.maxTarget) {
                Navigator.pop(ctx, entered);
              }
            },
            child:
                Text('Set', style: TextStyle(color: context.slColors.accent)),
          ),
        ],
      ),
    );
    if (result != null) {
      onChanged(ExerciseConfig(
        exerciseId: config.exerciseId,
        targetAmount: result,
        scalingPct: config.scalingPct,
      ));
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
