import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 0)
class Player extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double totalXp;

  @HiveField(2)
  int streakDays;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime? lastCompletedDate;

  @HiveField(5)
  int lastScaledWeek; // week number when scaling was last applied

  @HiveField(6)
  int notificationHour;

  @HiveField(7)
  int notificationMinute;

  @HiveField(8)
  bool useImperial;

  @HiveField(9)
  int eveningNotifHour;

  @HiveField(10)
  int eveningNotifMinute;

  @HiveField(11)
  int longestStreak;

  @HiveField(12)
  String? lastRestDayKey;

  /// Exercise IDs the player reported they cannot do during onboarding.
  /// These remain locked in the exercise picker until enough volume is logged
  /// with a prerequisite exercise.
  @HiveField(13)
  List<String> abilityLocked;

  /// Bonus volume (per exercise ID) earned by completing Shadow Trial challenges.
  /// Added to lifetime totals so challenge wins count toward exercise unlock thresholds.
  @HiveField(14)
  Map<String, double> challengeBonusVolume;

  /// Bonus volume keyed by the TARGET exercise ID (the Shadow Trial exercise itself).
  /// Accumulated across all completions of Shadow Trials for that exercise.
  /// Used alongside logged D-1 prereq volume to determine unlock readiness.
  @HiveField(15)
  Map<String, double> exerciseBonusVolume;

  Player({
    required this.name,
    this.totalXp = 0.0,
    this.streakDays = 0,
    required this.startDate,
    this.lastCompletedDate,
    this.lastScaledWeek = 0,
    this.notificationHour = 7,
    this.notificationMinute = 0,
    this.useImperial = false,
    this.eveningNotifHour = 20,
    this.eveningNotifMinute = 0,
    this.longestStreak = 0,
    this.lastRestDayKey,
    this.abilityLocked = const [],
    this.challengeBonusVolume = const {},
    this.exerciseBonusVolume = const {},
  });
}
