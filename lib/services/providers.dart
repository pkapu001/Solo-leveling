/// Riverpod providers exposing all services and reactive state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../models/daily_quest.dart';
import '../models/exercise_config.dart';
import '../models/achievement.dart';
import '../models/custom_exercise.dart';
import '../models/weekly_challenge.dart';
import '../constants/exercises.dart';
import '../constants/xp_config.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';
import 'xp_service.dart';
import 'scaling_service.dart';
import 'notification_service.dart';
import 'sound_service.dart';
import 'achievement_service.dart';

// ---------------------------------------------------------------------------
// Service singletons
// ---------------------------------------------------------------------------

final storageServiceProvider =
    Provider<StorageService>((_) => StorageService());

final xpServiceProvider = Provider<XpService>((ref) {
  return XpService(ref.read(storageServiceProvider));
});

final scalingServiceProvider = Provider<ScalingService>((ref) {
  return ScalingService(ref.read(storageServiceProvider));
});

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

final soundServiceProvider = Provider<SoundService>((_) => SoundService());

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(ref.read(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Theme state
// ---------------------------------------------------------------------------

class ThemeNotifier extends StateNotifier<AppThemeType> {
  final StorageService _storage;

  ThemeNotifier(this._storage) : super(_resolveTheme(_storage.getTheme()));

  static AppThemeType _resolveTheme(String? raw) {
    if (raw == null) return AppThemeType.gold;
    try {
      return AppThemeType.values.byName(raw);
    } catch (_) {
      return AppThemeType.gold;
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    await _storage.saveTheme(type.name);
    state = type;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier(ref.read(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Player state
// ---------------------------------------------------------------------------

class PlayerNotifier extends StateNotifier<Player?> {
  final StorageService _storage;

  PlayerNotifier(this._storage) : super(_storage.getPlayer());

  void reload() => state = _storage.getPlayer();

  Future<void> save(Player player) async {
    await _storage.savePlayer(player);
    state = player;
  }

  /// Called once on app startup to break a stale streak (e.g. the user
  /// skipped yesterday without marking it as a rest day). Because
  /// [XpService._updateStreak] only fires when progress is logged, the UI
  /// would otherwise keep showing the old streak count indefinitely.
  Future<void> checkStreak(XpService xpService) async {
    final player = state;
    if (player == null) return;
    final changed = xpService.breakStreakIfStale(player);
    if (changed) {
      await _storage.savePlayer(player);
      state = player;
    }
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, Player?>((ref) {
  return PlayerNotifier(ref.read(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Daily Quest state
// ---------------------------------------------------------------------------

class DailyQuestNotifier extends StateNotifier<DailyQuest?> {
  final StorageService _storage;

  DailyQuestNotifier(this._storage)
      : super(
          _storage.hasPlayer ? _storage.getOrCreateTodaysQuest() : null,
        );

  void refresh() {
    if (_storage.hasPlayer) {
      state = _storage.getOrCreateTodaysQuest();
    }
  }

  /// Syncs today's quest to the current exercise configs (add/remove/update
  /// targets) while preserving any logged progress. Called after saving
  /// settings so the home screen reflects config changes immediately.
  Future<void> syncToConfigs() async {
    if (!_storage.hasPlayer) return;
    state = await _storage.syncTodaysQuestToConfigs();
  }

  Future<void> logProgress(int itemIndex, double amount) async {
    final quest = state;
    if (quest == null || itemIndex >= quest.items.length) return;
    final item = quest.items[itemIndex];
    item.completedAmount =
        (item.completedAmount + amount).clamp(0.0, double.infinity);
    await _storage.saveQuest(quest);
    state = DailyQuest(
      dateKey: quest.dateKey,
      items: quest.items,
      xpEarned: quest.xpEarned,
      isCompleted: quest.isCompleted,
      streakMultiplier: quest.streakMultiplier,
    );
  }
}

final dailyQuestProvider =
    StateNotifierProvider<DailyQuestNotifier, DailyQuest?>((ref) {
  return DailyQuestNotifier(ref.read(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Exercise config list
// ---------------------------------------------------------------------------

final exerciseConfigsProvider =
    StateNotifierProvider<ExerciseConfigsNotifier, List<ExerciseConfig>>((ref) {
  return ExerciseConfigsNotifier(ref.read(storageServiceProvider));
});

class ExerciseConfigsNotifier extends StateNotifier<List<ExerciseConfig>> {
  final StorageService _storage;

  ExerciseConfigsNotifier(this._storage) : super(_storage.getExerciseConfigs());

  void reload() => state = _storage.getExerciseConfigs();

  Future<void> saveAll(List<ExerciseConfig> configs) async {
    await _storage.clearExerciseConfigs();
    await _storage.saveExerciseConfigs(configs);
    state = List.from(configs);
  }
}

// ---------------------------------------------------------------------------
// Quest history
// ---------------------------------------------------------------------------

final questHistoryProvider = Provider<List<DailyQuest>>((ref) {
  // Re-read when quest changes
  ref.watch(dailyQuestProvider);
  return ref.read(storageServiceProvider).getAllQuests();
});

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

final achievementsProvider = Provider<List<Achievement>>((ref) {
  ref.watch(dailyQuestProvider); // refresh when quests change
  return ref.read(storageServiceProvider).getAllAchievements();
});

// ---------------------------------------------------------------------------
// Lifetime exercise totals (for Stats screen — actual logged volume only)
// ---------------------------------------------------------------------------

final lifetimeExerciseTotalsProvider = Provider<Map<String, double>>((ref) {
  final history = ref.watch(questHistoryProvider);
  final totals = <String, double>{};
  for (final quest in history) {
    for (final item in quest.items) {
      totals[item.exerciseId] =
          (totals[item.exerciseId] ?? 0) + item.completedAmount;
    }
  }
  return totals;
});

// ---------------------------------------------------------------------------
// Exercise bonus volume — per target-exercise bonuses from Shadow Trial wins
// ---------------------------------------------------------------------------

/// Bonus volume keyed by the TARGET exercise ID, earned from Shadow Trial
/// completions. Used alongside logged D-1 prereq volume to check unlock status.
final exerciseBonusVolumeProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(playerProvider)?.exerciseBonusVolume ?? {};
});

// ---------------------------------------------------------------------------
// Custom exercises
// ---------------------------------------------------------------------------

class CustomExercisesNotifier extends StateNotifier<List<CustomExercise>> {
  final StorageService _storage;

  CustomExercisesNotifier(this._storage) : super(_storage.getCustomExercises());

  Future<void> add(CustomExercise exercise) async {
    await _storage.saveCustomExercise(exercise);
    registerCustomExercise(exercise.toDefinition());
    registerCustomExerciseXp(exercise.id, exercise.xpPerUnit);
    state = _storage.getCustomExercises();
  }

  Future<void> update(CustomExercise exercise) async {
    await _storage.saveCustomExercise(exercise);
    registerCustomExercise(exercise.toDefinition());
    registerCustomExerciseXp(exercise.id, exercise.xpPerUnit);
    state = _storage.getCustomExercises();
  }

  Future<void> delete(String id) async {
    await _storage.deleteCustomExercise(id);
    unregisterCustomExercise(id);
    unregisterCustomExerciseXp(id);
    state = _storage.getCustomExercises();
  }
}

final customExercisesProvider =
    StateNotifierProvider<CustomExercisesNotifier, List<CustomExercise>>((ref) {
  return CustomExercisesNotifier(ref.read(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Weekly Challenge (Shadow Trial)
// ---------------------------------------------------------------------------

class WeeklyChallengeNotifier extends StateNotifier<WeeklyChallenge?> {
  final StorageService _storage;

  WeeklyChallengeNotifier(this._storage)
      : super(
          _storage.hasPlayer ? _storage.getOrCreateWeeklyChallenge() : null,
        );

  /// Re-checks storage for the current week's challenge (or creates a new one
  /// if the week has rolled over). Called on app startup and after onboarding.
  void reload() {
    if (_storage.hasPlayer) {
      state = _storage.getOrCreateWeeklyChallenge();
    }
  }

  /// Adds [amount] to the challenge's completed amount and persists.
  Future<void> logProgress(double amount) async {
    final challenge = state;
    if (challenge == null || challenge.isCompleted) return;
    challenge.completedAmount =
        (challenge.completedAmount + amount).clamp(0.0, double.infinity);
    await _storage.saveWeeklyChallenge(challenge);
    // Emit a new object to trigger widget rebuilds.
    state = challenge.copyWith(completedAmount: challenge.completedAmount);
  }

  /// Refreshes state from storage (e.g. after XP is awarded externally).
  void refresh() {
    if (_storage.hasPlayer) {
      state = _storage.getOrCreateWeeklyChallenge();
    }
  }
}

final weeklyChallengeProvider =
    StateNotifierProvider<WeeklyChallengeNotifier, WeeklyChallenge?>((ref) {
  return WeeklyChallengeNotifier(ref.read(storageServiceProvider));
});
