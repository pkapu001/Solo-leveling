import 'storage_service.dart';
import '../constants/exercises.dart';

class ScalingService {
  final StorageService _storage;

  ScalingService(this._storage);

  /// Call on every app launch. If a new week has passed since last scaling,
  /// apply per-exercise scaling to all configs and update player record.
  Future<bool> applyWeeklyScalingIfDue() async {
    final player = _storage.getPlayer();
    if (player == null) return false;

    final weeksSinceStart = _weeksSince(player.startDate);
    if (weeksSinceStart <= player.lastScaledWeek) return false;

    final configs = _storage.getExerciseConfigs();
    if (configs.isEmpty) return false;

    // Apply scaling for each week that was missed (catch up gracefully)
    for (int w = player.lastScaledWeek + 1; w <= weeksSinceStart; w++) {
      for (final config in configs) {
        final isDistance =
            exerciseById(config.exerciseId)?.type == ExerciseType.distance;
        config.targetAmount = _scaleUp(config.targetAmount, config.scalingPct,
            isDistance: isDistance);
      }
    }

    // Persist updated configs
    await _storage.saveExerciseConfigs(configs);

    // Update player's last scaled week
    player.lastScaledWeek = weeksSinceStart;
    await _storage.savePlayer(player);

    return true; // scaling was applied
  }

  /// Returns number of full weeks elapsed since [start].
  int _weeksSince(DateTime start) {
    final now = DateTime.now();
    final days = now.difference(start).inDays;
    return (days / 7).floor();
  }

  /// Increase target by [pct]%, minimum increment depends on exercise type.
  double _scaleUp(double current, double pct, {bool isDistance = false}) {
    final increased = current * (1 + pct / 100);
    final delta = increased - current;
    if (isDistance) {
      // Distance: keep decimals, minimum +0.1
      if (delta < 0.1 && current >= 1) return current + 0.1;
      return (increased * 10).ceilToDouble() / 10;
    } else {
      // Reps / duration: always whole numbers, minimum +1
      if (delta < 1 && current >= 1) return current + 1;
      return increased.ceilToDouble();
    }
  }
}

/// Utility to compute next-week preview for a target.
double previewNextWeekTarget(double currentTarget, double scalingPct,
    {bool isDistance = false}) {
  final increased = currentTarget * (1 + scalingPct / 100);
  final delta = increased - currentTarget;
  if (isDistance) {
    if (delta < 0.1 && currentTarget >= 1) return currentTarget + 0.1;
    return (increased * 10).ceilToDouble() / 10;
  } else {
    if (delta < 1 && currentTarget >= 1) return currentTarget + 1;
    return increased.ceilToDouble();
  }
}
