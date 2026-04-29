import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/quest_item.dart';
import '../constants/exercises.dart';

class QuestItemCard extends StatelessWidget {
  final QuestItem item;

  /// Called with the amount to add (always in km for distance, reps for reps, etc.).
  final void Function(double amount)? onLog;
  final VoidCallback? onUndo;

  /// Whether to display distance in miles (converts km↔mi for display/input only).
  final bool useImperial;

  /// Whether the current completedAmount is a new personal record.
  final bool isPersonalRecord;

  /// Called to log the remaining amount and mark the exercise complete in one tap.
  final VoidCallback? onComplete;

  const QuestItemCard({
    super.key,
    required this.item,
    this.onLog,
    this.onUndo,
    this.useImperial = false,
    this.isPersonalRecord = false,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final def = exerciseById(item.exerciseId);
    if (def == null) return const SizedBox.shrink();

    final progress = item.progress;
    final isComplete = item.isCompleted;
    final isDistance = def.type == ExerciseType.distance;
    final colors = context.slColors;

    // Convert stored km values to display units if imperial is on
    final displayCompleted = (isDistance && useImperial)
        ? kmToMi(item.completedAmount)
        : item.completedAmount;
    final displayTarget = (isDistance && useImperial)
        ? kmToMi(item.targetAmount)
        : item.targetAmount;
    final displayUnit = (isDistance && useImperial) ? 'mi' : def.unit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration:
          isComplete ? goldGlowDecoration(context) : goldCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            def.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPersonalRecord) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: colors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '◆ PR',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${_fmt(displayCompleted)} / ${_fmt(displayTarget)} $displayUnit',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isComplete)
                Icon(Icons.check_circle, color: colors.accent, size: 28),
              // Undo is always visible when there is progress (even if complete)
              if (onUndo != null && item.completedAmount > 0)
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.textMuted, size: 22),
                  tooltip: 'Undo',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              if (!isComplete && onComplete != null)
                IconButton(
                  onPressed: onComplete,
                  icon: Icon(Icons.check_circle_outline,
                      color: colors.accent, size: 22),
                  tooltip: 'Mark complete',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              if (onLog != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _handleLog(context, def),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // Dimmed when in bonus territory (already complete)
                      color: isComplete ? colors.accentDark : colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add,
                        color: AppColors.background, size: 22),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: isComplete
                          ? [colors.accentDeep, colors.accent]
                          : [colors.accentDeep, colors.accentDark],
                    ),
                    boxShadow: isComplete
                        ? [
                            BoxShadow(
                              color: colors.accentGlow,
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
          // Bonus indicator when over the daily target
          if (item.completedAmount > item.targetAmount) ...[
            const SizedBox(height: 4),
            Text(
              '✦ +${_fmt(displayCompleted - displayTarget)} $displayUnit over goal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.accent,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  void _handleLog(BuildContext context, ExerciseDefinition def) {
    onLog?.call(dynamicStepFor(item.targetAmount, def));
  }
}
