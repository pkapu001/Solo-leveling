import 'package:hive/hive.dart';

part 'quest_item.g.dart';

/// A single exercise target within a DailyQuest.
@HiveType(typeId: 1)
class QuestItem extends HiveObject {
  @HiveField(0)
  String exerciseId;

  /// Target amount (reps / km / seconds / minutes)
  @HiveField(1)
  double targetAmount;

  /// How much the user has logged so far today
  @HiveField(2)
  double completedAmount;

  /// Weekly scaling percentage (1–5%)
  @HiveField(3)
  double scalingPct;

  QuestItem({
    required this.exerciseId,
    required this.targetAmount,
    this.completedAmount = 0,
    this.scalingPct = 2.0,
  });

  bool get isCompleted => completedAmount >= targetAmount;

  /// Progress ratio clamped to [0.0, 1.0]
  double get progress => targetAmount > 0
      ? (completedAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;
}
