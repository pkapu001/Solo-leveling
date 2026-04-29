import '../models/achievement.dart';
import '../models/player.dart';
import '../constants/xp_config.dart';
import '../constants/achievements.dart';
import '../constants/exercises.dart';
import 'storage_service.dart';

/// Checks achievement conditions and unlocks newly earned achievements.
class AchievementService {
  final StorageService _storage;

  AchievementService(this._storage);

  /// Evaluates all locked achievements against the player's current state.
  /// Saves newly unlocked achievements, awards their xpReward to [player],
  /// and returns both the unlocked achievements and total bonus XP granted.
  ({List<Achievement> unlocked, int bonusXp}) checkAndUnlock(Player player) {
    final achievements = _storage.getAllAchievements();
    final locked = achievements.where((a) => !a.isUnlocked).toList();
    if (locked.isEmpty) return (unlocked: [], bonusXp: 0);

    final level = levelFromXp(player.totalXp);
    final quests = _storage.getAllQuests();
    final completedQuestCount = quests.where((q) => q.isCompleted).length;
    final bestStreak = player.longestStreak > player.streakDays
        ? player.longestStreak
        : player.streakDays;

    // Precompute per-exercise stats from quest history once.
    final exerciseQuestCounts = <String, int>{}; // completed quest count
    final exerciseTotals = <String, double>{}; // cumulative completedAmount

    for (final quest in quests) {
      for (final item in quest.items) {
        if (item.isCompleted) {
          exerciseQuestCounts[item.exerciseId] =
              (exerciseQuestCounts[item.exerciseId] ?? 0) + 1;
        }
        exerciseTotals[item.exerciseId] =
            (exerciseTotals[item.exerciseId] ?? 0.0) + item.completedAmount;
      }
    }

    final newlyUnlocked = <Achievement>[];
    for (final a in locked) {
      if (_shouldUnlock(a.id, player, level, completedQuestCount, bestStreak,
          exerciseQuestCounts, exerciseTotals)) {
        a.isUnlocked = true;
        a.unlockedAt = DateTime.now();
        _storage.saveAchievement(a);
        newlyUnlocked.add(a);
      }
    }

    // Award XP for newly unlocked achievements
    int bonusXp = 0;
    for (final a in newlyUnlocked) {
      bonusXp += achievementById(a.id)?.xpReward ?? 0;
    }
    if (bonusXp > 0) {
      player.totalXp = (player.totalXp + bonusXp).clamp(0.0, 999999999.0);
      _storage.savePlayer(player);
    }

    return (unlocked: newlyUnlocked, bonusXp: bonusXp);
  }

  /// Returns progress data for every achievement — useful for showing
  /// progress bars on locked tiles.  Each entry contains [current] (the
  /// player's current value) and [max] (the threshold needed to unlock),
  /// plus a [unit] label for display (e.g. "quests", "day streak", "XP").
  Map<String, ({double current, double max, String unit})> computeProgress(
      Player player) {
    final level = levelFromXp(player.totalXp).toDouble();
    final quests = _storage.getAllQuests();
    final completedQuestCount =
        quests.where((q) => q.isCompleted).length.toDouble();
    final bestStreak = (player.longestStreak > player.streakDays
            ? player.longestStreak
            : player.streakDays)
        .toDouble();

    final exerciseQuestCounts = <String, double>{};
    final exerciseTotals = <String, double>{};
    for (final quest in quests) {
      for (final item in quest.items) {
        if (item.isCompleted) {
          exerciseQuestCounts[item.exerciseId] =
              (exerciseQuestCounts[item.exerciseId] ?? 0) + 1;
        }
        exerciseTotals[item.exerciseId] =
            (exerciseTotals[item.exerciseId] ?? 0.0) + item.completedAmount;
      }
    }

    final result = <String, ({double current, double max, String unit})>{};
    for (final def in kAchievementDefinitions) {
      final p = _progressFor(def.id, player, level, completedQuestCount,
          bestStreak, exerciseQuestCounts, exerciseTotals);
      if (p != null) result[def.id] = p;
    }
    return result;
  }

  ({double current, double max, String unit})? _progressFor(
    String id,
    Player player,
    double level,
    double completedQuestCount,
    double bestStreak,
    Map<String, double> exerciseQuestCounts,
    Map<String, double> exerciseTotals,
  ) {
    switch (id) {
      case 'first_quest':
        return (current: completedQuestCount, max: 1, unit: 'quests');
      case 'quest_10':
        return (current: completedQuestCount, max: 10, unit: 'quests');
      case 'quest_100':
        return (current: completedQuestCount, max: 100, unit: 'quests');
      case 'streak_3':
        return (current: bestStreak, max: 3, unit: 'day streak');
      case 'streak_7':
        return (current: bestStreak, max: 7, unit: 'day streak');
      case 'streak_30':
        return (current: bestStreak, max: 30, unit: 'day streak');
      case 'streak_100':
        return (current: bestStreak, max: 100, unit: 'day streak');
      case 'rank_d':
        return (current: level, max: 11, unit: 'levels');
      case 'rank_c':
        return (current: level, max: 21, unit: 'levels');
      case 'rank_b':
        return (current: level, max: 36, unit: 'levels');
      case 'rank_a':
        return (current: level, max: 51, unit: 'levels');
      case 'rank_s':
        return (current: level, max: 66, unit: 'levels');
      case 'rank_national':
        return (current: level, max: 81, unit: 'levels');
      case 'rank_monarch':
        return (current: level, max: 96, unit: 'levels');
      case 'xp_1000':
        return (current: player.totalXp, max: 1000, unit: 'XP');
      case 'xp_10000':
        return (current: player.totalXp, max: 10000, unit: 'XP');
      case 'xp_100000':
        return (current: player.totalXp, max: 100000, unit: 'XP');
    }
    final questMatch = RegExp(r'^(.+)_quest_(\d+)$').firstMatch(id);
    if (questMatch != null) {
      final exId = questMatch.group(1)!;
      final n = double.parse(questMatch.group(2)!);
      return (
        current: exerciseQuestCounts[exId] ?? 0.0,
        max: n,
        unit: 'quests',
      );
    }
    final totalMatch = RegExp(r'^(.+)_total_(\d+)$').firstMatch(id);
    if (totalMatch != null) {
      final exId = totalMatch.group(1)!;
      final n = double.parse(totalMatch.group(2)!);
      final unit = exerciseById(exId)?.unit ?? 'reps';
      return (
        current: exerciseTotals[exId] ?? 0.0,
        max: n,
        unit: unit,
      );
    }
    return null;
  }

  bool _shouldUnlock(
    String id,
    Player player,
    int level,
    int completedQuestCount,
    int bestStreak,
    Map<String, int> exerciseQuestCounts,
    Map<String, double> exerciseTotals,
  ) {
    switch (id) {
      // --- Quests ---
      case 'first_quest':
        return completedQuestCount >= 1;
      case 'quest_10':
        return completedQuestCount >= 10;
      case 'quest_100':
        return completedQuestCount >= 100;
      // --- Streak ---
      case 'streak_3':
        return bestStreak >= 3;
      case 'streak_7':
        return bestStreak >= 7;
      case 'streak_30':
        return bestStreak >= 30;
      case 'streak_100':
        return bestStreak >= 100;
      // --- Rank ---
      case 'rank_d':
        return level >= 11;
      case 'rank_c':
        return level >= 21;
      case 'rank_b':
        return level >= 36;
      case 'rank_a':
        return level >= 51;
      case 'rank_s':
        return level >= 66;
      case 'rank_national':
        return level >= 81;
      case 'rank_monarch':
        return level >= 96;
      // --- XP ---
      case 'xp_1000':
        return player.totalXp >= 1000;
      case 'xp_10000':
        return player.totalXp >= 10000;
      case 'xp_100000':
        return player.totalXp >= 100000;
    }

    // {exerciseId}_quest_{n}  — per-exercise quest-completion milestones
    final questMatch = RegExp(r'^(.+)_quest_(\d+)$').firstMatch(id);
    if (questMatch != null) {
      final exId = questMatch.group(1)!;
      final n = int.parse(questMatch.group(2)!);
      return (exerciseQuestCounts[exId] ?? 0) >= n;
    }

    // {exerciseId}_total_{n}  — per-exercise cumulative volume milestones
    final totalMatch = RegExp(r'^(.+)_total_(\d+)$').firstMatch(id);
    if (totalMatch != null) {
      final exId = totalMatch.group(1)!;
      final n = int.parse(totalMatch.group(2)!);
      return (exerciseTotals[exId] ?? 0.0) >= n;
    }

    return false;
  }
}
