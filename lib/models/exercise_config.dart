/// Persisted exercise configuration chosen by the user.
/// Stored separately from DailyQuest so targets survive quest resets.
import 'package:hive/hive.dart';

part 'exercise_config.g.dart';

@HiveType(typeId: 3)
class ExerciseConfig extends HiveObject {
  @HiveField(0)
  String exerciseId;

  @HiveField(1)
  double targetAmount;

  @HiveField(2)
  double scalingPct; // 1.0 – 5.0

  ExerciseConfig({
    required this.exerciseId,
    required this.targetAmount,
    this.scalingPct = 2.0,
  });
}
