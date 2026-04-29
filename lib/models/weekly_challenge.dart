import 'package:hive/hive.dart';

part 'weekly_challenge.g.dart';

@HiveType(typeId: 6)
class WeeklyChallenge extends HiveObject {
  /// ISO date string ("yyyy-MM-dd") of the Monday that starts this week.
  @HiveField(0)
  String weekKey;

  /// ISO weekday (1 = Monday … 7 = Sunday) when the card becomes visible.
  @HiveField(1)
  int triggerDay;

  /// The locked exercise the player must attempt.
  /// Empty string ('') when [skippedWeek] is true.
  @HiveField(2)
  String exerciseId;

  /// Target reps/km/seconds — 30 % of the exercise's default, clamped up to minTarget.
  @HiveField(3)
  double targetAmount;

  /// How much the player has logged so far.
  @HiveField(4)
  double completedAmount;

  @HiveField(5)
  bool isCompleted;

  /// Running XP total for delta-tracking (same pattern as DailyQuest).
  @HiveField(6)
  double xpEarned;

  /// Prevents double-awarding the prereq bonus volume.
  @HiveField(7)
  bool bonusVolumeAwarded;

  /// True when no eligible locked exercise was found this week.
  /// Used as a sentinel so we don't re-roll every app open.
  @HiveField(8)
  bool skippedWeek;

  WeeklyChallenge({
    required this.weekKey,
    required this.triggerDay,
    required this.exerciseId,
    required this.targetAmount,
    this.completedAmount = 0,
    this.isCompleted = false,
    this.xpEarned = 0,
    this.bonusVolumeAwarded = false,
    this.skippedWeek = false,
  });

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// True when the random trigger day for this week has arrived.
  bool get isActive => !skippedWeek && DateTime.now().weekday >= triggerDay;

  /// True when the stored weekKey belongs to a previous ISO week.
  bool get isExpired {
    try {
      final parts = weekKey.split('-');
      final storedMonday = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final thisMonday =
          DateTime(now.year, now.month, now.day - (now.weekday - 1));
      return storedMonday.isBefore(thisMonday);
    } catch (_) {
      return true;
    }
  }

  double get progress =>
      targetAmount > 0 ? (completedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Number of days remaining until Sunday midnight.
  int get daysRemaining {
    final now = DateTime.now();
    // Sunday is weekday 7; calculate days until the next Sunday (end of week)
    final daysUntilSunday = 7 - now.weekday;
    return daysUntilSunday;
  }

  /// Returns a copy with updated mutable fields (for state emission).
  WeeklyChallenge copyWith({
    double? completedAmount,
    bool? isCompleted,
    double? xpEarned,
    bool? bonusVolumeAwarded,
  }) {
    return WeeklyChallenge(
      weekKey: weekKey,
      triggerDay: triggerDay,
      exerciseId: exerciseId,
      targetAmount: targetAmount,
      completedAmount: completedAmount ?? this.completedAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      xpEarned: xpEarned ?? this.xpEarned,
      bonusVolumeAwarded: bonusVolumeAwarded ?? this.bonusVolumeAwarded,
      skippedWeek: skippedWeek,
    );
  }
}
