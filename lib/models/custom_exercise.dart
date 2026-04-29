import 'package:hive/hive.dart';
import '../constants/exercises.dart';

part 'custom_exercise.g.dart';

@HiveType(typeId: 5)
class CustomExercise extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  /// ExerciseType index: 0=reps, 1=distance, 2=duration
  @HiveField(3)
  int typeIndex;

  @HiveField(4)
  String unit;

  /// ExerciseMuscleGroup index
  @HiveField(5)
  int muscleGroupIndex;

  @HiveField(6)
  int defaultTarget;

  @HiveField(7)
  int stepSize;

  /// Difficulty 1–5 (mirrors ExerciseDefinition.difficulty)
  @HiveField(8)
  int difficulty;

  /// Computed XP per unit — stored so the value is stable over time.
  @HiveField(9)
  double xpPerUnit;

  CustomExercise({
    required this.id,
    required this.name,
    required this.emoji,
    required this.typeIndex,
    required this.unit,
    required this.muscleGroupIndex,
    required this.defaultTarget,
    required this.stepSize,
    this.difficulty = 1,
    this.xpPerUnit = 1.5,
  });

  ExerciseDefinition toDefinition() => ExerciseDefinition(
        id: id,
        name: name,
        emoji: emoji,
        type: ExerciseType
            .values[typeIndex.clamp(0, ExerciseType.values.length - 1)],
        unit: unit,
        muscleGroup: ExerciseMuscleGroup.values[
            muscleGroupIndex.clamp(0, ExerciseMuscleGroup.values.length - 1)],
        defaultTarget: defaultTarget,
        minTarget: 1,
        maxTarget: 99999,
        stepSize: stepSize,
        difficulty: difficulty.clamp(1, 5),
      );
}
