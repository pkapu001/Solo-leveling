import '../models/player.dart';
import '../models/daily_quest.dart';
import '../models/weekly_challenge.dart';
import '../constants/xp_config.dart';
import '../constants/exercises.dart';
import 'storage_service.dart';

class XpService {
  final StorageService _storage;

  XpService(this._storage);

  /// Award/deduct XP based on the current state of a quest.
  /// Uses delta tracking so decrements correctly reduce totalXp.
  /// Returns (newTotalXp, leveledUp, newLevel, newPersonalRecords).
  Future<
      ({
        double totalXp,
        bool leveledUp,
        int newLevel,
        List<String> newPersonalRecords,
      })> awardQuestXp(
    Player player,
    DailyQuest quest,
  ) async {
    // Calculate raw exercise XP — full floating-point precision to avoid
    // rounding loss between small increments.
    double rawXp = 0;
    for (final item in quest.items) {
      final xpu = xpPerUnitFor(item.exerciseId);
      rawXp += calculateExerciseXp(
        completedAmount: item.completedAmount,
        targetAmount: item.targetAmount,
        xpPerUnit: xpu,
      );
    }

    // Apply streak multiplier (captured at quest creation)
    double newQuestXp = rawXp * quest.streakMultiplier;

    // Flat all-quest completion bonus
    final allComplete = quest.items.isNotEmpty &&
        quest.items.every(
            (i) => i.targetAmount > 0 && i.completedAmount >= i.targetAmount);
    if (allComplete) {
      newQuestXp += kQuestCompletionBonus;
    }

    // Delta tracking (handles both + and -); no rounding — accumulate as double.
    final delta = newQuestXp - quest.xpEarned;
    final oldLevel = levelFromXp(player.totalXp);
    final newTotalXp = (player.totalXp + delta).clamp(0.0, 999999999.0);
    final newLevel = levelFromXp(newTotalXp);

    quest.xpEarned = newQuestXp;
    quest.isCompleted = quest.overallProgress >= 1.0;
    player.totalXp = newTotalXp;

    // Only advance (or credit) the streak when the entire quest is complete.
    // Logging partial reps does not count.
    _updateStreak(player, questCompleted: quest.isCompleted);
    final newPRs = _updatePersonalRecords(quest);

    await _storage.savePlayer(player);
    await _storage.saveQuest(quest);

    return (
      totalXp: newTotalXp,
      leveledUp: newLevel > oldLevel,
      newLevel: newLevel,
      newPersonalRecords: newPRs,
    );
  }

  /// Checks on app startup whether the player's streak has lapsed since their
  /// last workout and resets it to 0 if so.
  ///
  /// Returns `true` if the streak was reset (caller is responsible for saving
  /// the player). This must be called separately from [awardQuestXp] because
  /// [awardQuestXp] is only triggered when the user logs progress — meaning a
  /// stale streak would otherwise remain displayed until the next workout.
  bool breakStreakIfStale(Player player) {
    if (player.lastCompletedDate == null || player.streakDays == 0)
      return false;
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(player.lastCompletedDate!);
    final diff = today.difference(last).inDays;
    if (diff <= 1) return false; // worked out today or yesterday — still valid
    if (diff == 2) {
      // One day gap: streak survives only if the day after the last workout
      // was marked as a rest day.
      final dayAfterLast = last.add(const Duration(days: 1));
      final bridgeQuest = _storage.getQuest(dayAfterLast);
      if (bridgeQuest?.isRestDay == true) return false;
    }
    // diff >= 3, or diff == 2 with no rest day — streak is broken
    player.streakDays = 0;
    return true;
  }

  void _updateStreak(Player player, {required bool questCompleted}) {
    // Streak only advances when the whole quest is fully done.
    // We still need to run this on every XP update so that decrementing
    // reps (which can drop isCompleted back to false) doesn't leave
    // lastCompletedDate pointing to a day that was only partially done.
    // The strategy: only update lastCompletedDate and streakDays when
    // questCompleted is true. When it's false we leave everything unchanged
    // (breakStreakIfStale handles the stale-streak case on next launch).
    if (!questCompleted) return;

    final today = _dateOnly(DateTime.now());
    if (player.lastCompletedDate == null) {
      player.streakDays = 1;
    } else {
      final last = _dateOnly(player.lastCompletedDate!);
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        // Already credited today — no change.
      } else if (diff == 1) {
        player.streakDays += 1;
      } else if (diff == 2) {
        // One day gap: streak continues only if the day after the last workout
        // was marked as a rest day.
        final dayAfterLast = last.add(const Duration(days: 1));
        final bridgeQuest = _storage.getQuest(dayAfterLast);
        if (bridgeQuest?.isRestDay == true) {
          player.streakDays += 1;
        } else {
          player.streakDays = 1;
        }
      } else {
        player.streakDays = 1; // gap too large — reset
      }
    }
    // Track all-time longest streak.
    if (player.streakDays > player.longestStreak) {
      player.longestStreak = player.streakDays;
    }
    player.lastCompletedDate = today;
  }

  List<String> _updatePersonalRecords(DailyQuest quest) {
    final newPRs = <String>[];
    for (final item in quest.items) {
      if (item.completedAmount <= 0) continue;
      final currentBest = _storage.getPersonalBest(item.exerciseId);
      if (item.completedAmount > currentBest) {
        _storage.setPersonalBest(item.exerciseId, item.completedAmount);
        newPRs.add(item.exerciseId);
      }
    }
    return newPRs;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ---------------------------------------------------------------------------
  // Shadow Trial (Weekly Challenge)
  // ---------------------------------------------------------------------------

  /// Awards 5× XP for challenge progress and, on first completion this week,
  /// credits bonus volume directly to the challenge exercise so it counts
  /// toward the real unlock threshold.
  ///
  /// Bonus = 50% of the required unlock volume for [challenge.exerciseId],
  /// calculated from the adjacent D-1 prereq with the highest defaultTarget.
  /// Stored in [Player.exerciseBonusVolume] keyed by the challenge exercise ID,
  /// so it accumulates across future weeks if the same exercise recurs.
  ///
  /// Returns `(totalXp, leveledUp, newLevel, bonusVolumeAwarded)`.
  Future<
      ({
        double totalXp,
        bool leveledUp,
        int newLevel,
        double bonusVolumeAwarded
      })> awardChallengeXp(
    Player player,
    WeeklyChallenge challenge,
  ) async {
    final xpu = xpPerUnitFor(challenge.exerciseId);
    // 5× multiplier for attempting a locked, harder exercise
    final rawXp = challenge.completedAmount * xpu * 5.0;
    final delta = rawXp - challenge.xpEarned;

    final oldLevel = levelFromXp(player.totalXp);
    final newTotalXp = (player.totalXp + delta).clamp(0.0, 999999999.0);
    final newLevel = levelFromXp(newTotalXp);

    challenge.xpEarned = rawXp;
    challenge.isCompleted = challenge.completedAmount >= challenge.targetAmount;
    player.totalXp = newTotalXp;

    // On first full completion this week: award 50% of unlock volume as bonus
    // stored against the challenge exercise itself (not its prereqs).
    double totalBonus = 0;
    if (challenge.isCompleted && !challenge.bonusVolumeAwarded) {
      final def = exerciseById(challenge.exerciseId);
      if (def != null && def.difficulty >= 3) {
        final unlockMultiplier = def.difficulty == 3
            ? kUnlockMultiplierD3
            : def.difficulty == 4
                ? kUnlockMultiplierD4
                : kUnlockMultiplierD5;
        // Only D-1 prereqs determine the threshold for this exercise.
        final d1Prereqs = kExerciseLibrary
            .where((e) =>
                e.muscleGroup == def.muscleGroup &&
                e.difficulty == def.difficulty - 1)
            .toList();
        if (d1Prereqs.isNotEmpty) {
          // Use the highest defaultTarget among D-1 prereqs (most generous).
          final maxTarget = d1Prereqs
              .map((e) => e.defaultTarget)
              .reduce((a, b) => a > b ? a : b);
          // 50% of the required volume for this exercise.
          totalBonus = 0.5 * unlockMultiplier * maxTarget;
          player.exerciseBonusVolume = Map<String, double>.from(
            player.exerciseBonusVolume,
          )..[def.id] = (player.exerciseBonusVolume[def.id] ?? 0) + totalBonus;
        }
        challenge.bonusVolumeAwarded = true;
      }
    }

    await _storage.savePlayer(player);
    await _storage.saveWeeklyChallenge(challenge);

    return (
      totalXp: newTotalXp,
      leveledUp: newLevel > oldLevel,
      newLevel: newLevel,
      bonusVolumeAwarded: totalBonus,
    );
  }
}
