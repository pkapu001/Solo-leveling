import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/quest_item.dart';
import '../models/daily_quest.dart';
import '../models/exercise_config.dart';
import '../models/achievement.dart';
import '../models/custom_exercise.dart';
import '../models/weekly_challenge.dart';
import '../constants/exercises.dart';
import '../constants/xp_config.dart';
import '../constants/achievements.dart';

class StorageService {
  static const String _playerBoxName = 'player';
  static const String _questBoxName = 'quests';
  static const String _configBoxName = 'exercise_config';
  static const String _achievementsBoxName = 'achievements';
  static const String _personalBestsBoxName = 'personal_bests';
  static const String _customExercisesBoxName = 'custom_exercises';
  static const String _weeklyChallengeBoxName = 'weekly_challenges';
  static const String _settingsBoxName = 'app_settings';
  static const String _playerKey = 'current_player';
  static const String _themeKey = 'active_theme';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Player> _playerBox;
  late Box<DailyQuest> _questBox;
  late Box<ExerciseConfig> _configBox;
  late Box<Achievement> _achievementsBox;
  late Box<double> _personalBestsBox;
  late Box<WeeklyChallenge> _weeklyChallengeBox;
  late Box<CustomExercise> _customExercisesBox;
  late Box<String> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(PlayerAdapter());
    Hive.registerAdapter(QuestItemAdapter());
    Hive.registerAdapter(DailyQuestAdapter());
    Hive.registerAdapter(ExerciseConfigAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(CustomExerciseAdapter());
    Hive.registerAdapter(WeeklyChallengeAdapter());

    _playerBox = await Hive.openBox<Player>(_playerBoxName);
    _questBox = await Hive.openBox<DailyQuest>(_questBoxName);
    _configBox = await Hive.openBox<ExerciseConfig>(_configBoxName);
    _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
    _personalBestsBox = await Hive.openBox<double>(_personalBestsBoxName);
    _customExercisesBox =
        await Hive.openBox<CustomExercise>(_customExercisesBoxName);
    _weeklyChallengeBox =
        await Hive.openBox<WeeklyChallenge>(_weeklyChallengeBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // ---------------------------------------------------------------------------
  // App Settings — theme
  // ---------------------------------------------------------------------------

  String? getTheme() => _settingsBox.get(_themeKey);

  Future<void> saveTheme(String themeTypeName) async {
    await _settingsBox.put(_themeKey, themeTypeName);
  }

  // ---------------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------------

  bool get hasPlayer => _playerBox.containsKey(_playerKey);

  Player? getPlayer() => _playerBox.get(_playerKey);

  Future<void> savePlayer(Player player) async {
    await _playerBox.put(_playerKey, player);
  }

  // ---------------------------------------------------------------------------
  // Exercise Config
  // ---------------------------------------------------------------------------

  List<ExerciseConfig> getExerciseConfigs() {
    final configs = _configBox.values.toList();
    configs.sort((a, b) {
      final defA = exerciseById(a.exerciseId);
      final defB = exerciseById(b.exerciseId);
      // Fall back to custom exercise box for unregistered customs
      final groupA = defA?.muscleGroup.index ??
          (_customExercisesBox.get(a.exerciseId)?.muscleGroupIndex ?? 99);
      final groupB = defB?.muscleGroup.index ??
          (_customExercisesBox.get(b.exerciseId)?.muscleGroupIndex ?? 99);
      if (groupA != groupB) return groupA.compareTo(groupB);
      final diffA = defA?.difficulty ??
          (_customExercisesBox.get(a.exerciseId)?.difficulty ?? 99);
      final diffB = defB?.difficulty ??
          (_customExercisesBox.get(b.exerciseId)?.difficulty ?? 99);
      return diffA.compareTo(diffB);
    });
    return configs;
  }

  ExerciseConfig? getExerciseConfig(String exerciseId) =>
      _configBox.get(exerciseId);

  Future<void> saveExerciseConfig(ExerciseConfig config) async {
    await _configBox.put(config.exerciseId, config);
  }

  Future<void> saveExerciseConfigs(List<ExerciseConfig> configs) async {
    final map = {for (final c in configs) c.exerciseId: c};
    await _configBox.putAll(map);
  }

  Future<void> deleteExerciseConfig(String exerciseId) async {
    await _configBox.delete(exerciseId);
  }

  Future<void> clearExerciseConfigs() async => _configBox.clear();

  // ---------------------------------------------------------------------------
  // Daily Quests
  // ---------------------------------------------------------------------------

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  DailyQuest? getQuest(DateTime date) => _questBox.get(_dateKey(date));

  DailyQuest getOrCreateTodaysQuest() {
    final key = _dateKey(DateTime.now());
    if (_questBox.containsKey(key)) return _questBox.get(key)!;

    // Build fresh quest from current exercise configs
    final configs = getExerciseConfigs();
    final items = configs
        .map((c) => QuestItem(
              exerciseId: c.exerciseId,
              targetAmount: c.targetAmount,
              scalingPct: c.scalingPct,
            ))
        .toList();

    // Capture streak multiplier at quest creation time
    final player = getPlayer();
    final streakDays = player?.streakDays ?? 0;
    final multiplier =
        1.0 + (streakDays * kStreakBonusPerDay).clamp(0.0, kMaxStreakBonusPct);

    final quest = DailyQuest(
      dateKey: key,
      items: items,
      streakMultiplier: multiplier,
    );
    _questBox.put(key, quest);
    return quest;
  }

  Future<void> saveQuest(DailyQuest quest) async {
    await _questBox.put(quest.dateKey, quest);
  }

  /// Syncs today's quest items to match the current exercise configs.
  ///
  /// - Adds items for newly configured exercises (starting at 0 progress).
  /// - Updates target amounts for existing items.
  /// - Removes items for exercises that are no longer in the config.
  /// - Preserves logged progress for items that remain.
  ///
  /// Creates today's quest first if it doesn't exist yet.
  Future<DailyQuest> syncTodaysQuestToConfigs() async {
    final quest = getOrCreateTodaysQuest();
    final configs = getExerciseConfigs();

    // Build a map of existing progress keyed by exerciseId.
    final progressMap = <String, double>{
      for (final item in quest.items) item.exerciseId: item.completedAmount,
    };

    // Rebuild items from configs, preserving progress.
    final updatedItems = configs
        .map((c) => QuestItem(
              exerciseId: c.exerciseId,
              targetAmount: c.targetAmount,
              scalingPct: c.scalingPct,
            ))
        .toList();

    // Restore logged progress.
    for (final item in updatedItems) {
      final logged = progressMap[item.exerciseId];
      if (logged != null && logged > 0) {
        item.completedAmount = logged;
      }
    }

    final updated = DailyQuest(
      dateKey: quest.dateKey,
      items: updatedItems,
      xpEarned: quest.xpEarned,
      isCompleted: quest.isCompleted,
      streakMultiplier: quest.streakMultiplier,
    );
    await saveQuest(updated);
    return updated;
  }

  /// Returns quests sorted descending by date (most recent first).
  List<DailyQuest> getAllQuests() {
    final quests = _questBox.values.toList();
    quests.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return quests;
  }

  /// Returns the total volume logged for [exerciseId] across all quests,
  /// plus any bonus volume awarded from completed Shadow Trial challenges.
  double getExerciseTotalVolume(String exerciseId) {
    final questTotal = _questBox.values.fold(0.0, (sum, q) {
      final items = q.items.where((i) => i.exerciseId == exerciseId);
      return sum + items.fold(0.0, (s, i) => s + i.completedAmount);
    });
    final bonusTotal = getPlayer()?.challengeBonusVolume[exerciseId] ?? 0.0;
    return questTotal + bonusTotal;
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  Future<void> resetAll() async {
    await _playerBox.clear();
    await _questBox.clear();
    await _configBox.clear();
    await _achievementsBox.clear();
    await _personalBestsBox.clear();
    await _customExercisesBox.clear();
    await _weeklyChallengeBox.clear();
  }

  // ---------------------------------------------------------------------------
  // Custom Exercises
  // ---------------------------------------------------------------------------

  List<CustomExercise> getCustomExercises() =>
      _customExercisesBox.values.toList();

  Future<void> saveCustomExercise(CustomExercise exercise) async {
    await _customExercisesBox.put(exercise.id, exercise);
  }

  Future<void> deleteCustomExercise(String id) async {
    await _customExercisesBox.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  /// Populates the achievements box with locked entries for any missing ids.
  Future<void> initAchievements() async {
    for (final def in kAchievementDefinitions) {
      if (!_achievementsBox.containsKey(def.id)) {
        await _achievementsBox.put(def.id, Achievement(id: def.id));
      }
    }
  }

  Achievement? getAchievement(String id) => _achievementsBox.get(id);

  List<Achievement> getAllAchievements() => _achievementsBox.values.toList();

  Future<void> saveAchievement(Achievement achievement) async {
    await _achievementsBox.put(achievement.id, achievement);
  }

  // ---------------------------------------------------------------------------
  // Personal Bests
  // ---------------------------------------------------------------------------

  double getPersonalBest(String exerciseId) =>
      _personalBestsBox.get(exerciseId) ?? 0.0;

  Future<void> setPersonalBest(String exerciseId, double amount) async {
    await _personalBestsBox.put(exerciseId, amount);
  }

  // ---------------------------------------------------------------------------
  // Rest Day helpers
  // ---------------------------------------------------------------------------

  /// Returns true if a rest day has already been taken in the current week
  /// (Mon–Sun) based on the player's [lastRestDayKey].
  bool hasRestDayThisWeek() {
    final player = getPlayer();
    if (player?.lastRestDayKey == null) return false;
    try {
      final restDate = DateFormat('yyyy-MM-dd').parse(player!.lastRestDayKey!);
      final today = DateTime.now();
      final todayMonday =
          DateTime(today.year, today.month, today.day - (today.weekday - 1));
      final restMonday = DateTime(
          restDate.year, restDate.month, restDate.day - (restDate.weekday - 1));
      return todayMonday == restMonday;
    } catch (_) {
      return false;
    }
  }

  /// Marks today as a rest day. Should only be called when no progress has
  /// been logged and no rest day exists this week.
  Future<void> markRestDay() async {
    final today = DateTime.now();
    final key = _dateKey(today);

    // Get or create today's quest and mark it as a rest day
    final quest = getOrCreateTodaysQuest();
    quest.isRestDay = true;
    await saveQuest(quest);

    // Update player's last rest day key
    final player = getPlayer();
    if (player != null) {
      player.lastRestDayKey = key;
      await savePlayer(player);
    }
  }

  // ---------------------------------------------------------------------------
  // Weekly Challenge (Shadow Trial)
  // ---------------------------------------------------------------------------

  /// Returns the current week's Shadow Trial challenge, creating a new one if
  /// this is the first call for the ISO week (keyed by Monday date).
  ///
  /// Returns `null` when no eligible locked exercise was found, or when the
  /// stored entry for this week has [WeeklyChallenge.skippedWeek] == true.
  WeeklyChallenge? getOrCreateWeeklyChallenge() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final weekKey = DateFormat('yyyy-MM-dd').format(monday);

    // Return existing entry for this week (sentinel or real challenge).
    if (_weeklyChallengeBox.containsKey(weekKey)) {
      final existing = _weeklyChallengeBox.get(weekKey)!;
      return existing.skippedWeek ? null : existing;
    }

    // ---- First call this week: roll the challenge ----

    // Compute lifetime totals from quest history + previous challenge bonuses.
    final lifetimeTotals = <String, double>{};
    for (final quest in _questBox.values) {
      for (final item in quest.items) {
        lifetimeTotals[item.exerciseId] =
            (lifetimeTotals[item.exerciseId] ?? 0) + item.completedAmount;
      }
    }
    final player = getPlayer();
    if (player != null) {
      for (final entry in player.challengeBonusVolume.entries) {
        lifetimeTotals[entry.key] =
            (lifetimeTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Player's currently configured exercise IDs (excluded from challenge pool).
    final userExerciseIds =
        getExerciseConfigs().map((c) => c.exerciseId).toList();

    // In debug builds, trigger day = today so the card is always visible during testing.
    final triggerDay =
        kDebugMode ? DateTime.now().weekday : Random().nextInt(7) + 1;

    // Pick a locked exercise one tier above the player's current max.
    final def = pickChallengeExercise(userExerciseIds, lifetimeTotals);
    if (def == null) {
      // No challenge available — store sentinel so we don't re-roll this week.
      _weeklyChallengeBox.put(
        weekKey,
        WeeklyChallenge(
          weekKey: weekKey,
          triggerDay: triggerDay,
          exerciseId: '',
          targetAmount: 0,
          skippedWeek: true,
        ),
      );
      return null;
    }

    // Target = 30 % of default, clamped up to minTarget.
    final rawTarget = (def.defaultTarget * 0.30).ceilToDouble();
    final targetAmount =
        rawTarget.clamp(def.minTarget.toDouble(), double.infinity);

    final challenge = WeeklyChallenge(
      weekKey: weekKey,
      triggerDay: triggerDay,
      exerciseId: def.id,
      targetAmount: targetAmount,
    );
    _weeklyChallengeBox.put(weekKey, challenge);
    return challenge;
  }

  Future<void> saveWeeklyChallenge(WeeklyChallenge challenge) async {
    await _weeklyChallengeBox.put(challenge.weekKey, challenge);
  }

  /// Deletes the stored entry for the current ISO week so the next call to
  /// [getOrCreateWeeklyChallenge] rolls a brand-new challenge.
  /// Only intended for use during development / debug builds.
  Future<void> deleteThisWeeksChallenge() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final weekKey = DateFormat('yyyy-MM-dd').format(monday);
    await _weeklyChallengeBox.delete(weekKey);
  }
}
