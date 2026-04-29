/// XP thresholds, rank titles and level-up configuration.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// XP needed to reach [level] from level [level-1].
/// Formula: 105·n + 3·n^1.5 — hybrid linear + power-law.
/// Calibrated for: D ~1 month, C ~3 months, B ~6-7 months, A ~1 year,
/// S ~1.5-2 years, Shadow Monarch ~3 years of consistent training.
/// The n^1.5 term ensures each level feels progressively harder while
/// keeping endgame reachable as players add more exercises and reps.
int xpToLevel(int level) {
  if (level <= 1) return 0;
  return (105 * level + 3 * level * sqrt(level.toDouble())).round();
}

/// Cumulative XP needed to be at the start of [level].
int cumulativeXpForLevel(int level) {
  int total = 0;
  for (int i = 2; i <= level; i++) {
    total += xpToLevel(i);
  }
  return total;
}

/// Current level given total XP.
int levelFromXp(num totalXp) {
  int level = 1;
  int cumulative = 0;
  while (true) {
    int needed = xpToLevel(level + 1);
    if (cumulative + needed > totalXp) break;
    cumulative += needed;
    level++;
    if (level >= 200) break; // safety cap
  }
  return level;
}

/// XP progress within current level (0 to xpNeededForNextLevel).
int xpInCurrentLevel(num totalXp) {
  int level = levelFromXp(totalXp);
  int cumulative = cumulativeXpForLevel(level);
  return (totalXp - cumulative).toInt();
}

/// XP needed to complete current level (to level up).
int xpNeededForNextLevel(int level) => xpToLevel(level + 1);

// ---------------------------------------------------------------------------
// Rank titles & colors
// ---------------------------------------------------------------------------

class RankInfo {
  final String title;
  final String shortTitle;
  final Color color;
  final int minLevel;
  final int maxLevel;

  const RankInfo({
    required this.title,
    required this.shortTitle,
    required this.color,
    required this.minLevel,
    required this.maxLevel,
  });
}

const List<RankInfo> kRanks = [
  RankInfo(
    title: 'E-Class Hunter',
    shortTitle: 'E',
    color: AppColors.rankE,
    minLevel: 1,
    maxLevel: 10,
  ),
  RankInfo(
    title: 'D-Class Hunter',
    shortTitle: 'D',
    color: AppColors.rankD,
    minLevel: 11,
    maxLevel: 20,
  ),
  RankInfo(
    title: 'C-Class Hunter',
    shortTitle: 'C',
    color: AppColors.rankC,
    minLevel: 21,
    maxLevel: 35,
  ),
  RankInfo(
    title: 'B-Class Hunter',
    shortTitle: 'B',
    color: AppColors.rankB,
    minLevel: 36,
    maxLevel: 50,
  ),
  RankInfo(
    title: 'A-Class Hunter',
    shortTitle: 'A',
    color: AppColors.rankA,
    minLevel: 51,
    maxLevel: 65,
  ),
  RankInfo(
    title: 'S-Class Hunter',
    shortTitle: 'S',
    color: AppColors.rankS,
    minLevel: 66,
    maxLevel: 80,
  ),
  RankInfo(
    title: 'National Level Hunter',
    shortTitle: 'N',
    color: AppColors.rankNational,
    minLevel: 81,
    maxLevel: 95,
  ),
  RankInfo(
    title: 'Shadow Monarch',
    shortTitle: '★',
    color: AppColors.rankMonarch,
    minLevel: 96,
    maxLevel: 999,
  ),
];

RankInfo rankForLevel(int level) {
  for (final rank in kRanks.reversed) {
    if (level >= rank.minLevel) return rank;
  }
  return kRanks.first;
}

/// XP earned purely by volume (reps / km / seconds / minutes).
/// Formula:
///   - Below goal : completedAmount × xpPerUnit
///   - At/above goal: completedAmount × xpPerUnit × 1.2  (completion bonus)
///
/// Returns a [double] so callers accumulate precise fractional XP before
/// rounding to an integer only when updating player.totalXp.
double calculateExerciseXp({
  required double completedAmount,
  required double targetAmount,
  required double xpPerUnit,
}) {
  if (completedAmount <= 0 || xpPerUnit <= 0) return 0;
  final base = completedAmount * xpPerUnit;
  final multiplier =
      (targetAmount > 0 && completedAmount >= targetAmount) ? 1.2 : 1.0;
  return base * multiplier;
}

/// XP earned per unit (rep / km / second / minute) for each exercise.
/// Calibrated so hitting the default target gives ~the same XP as before,
/// but now volume scales the reward naturally.
const Map<String, double> kXpPerUnit = {
  // ── Original ────────────────────────────────────────────────────────────
  'pushups': 2.0, // per rep   (default 20 → 48 XP at goal)
  'pullups': 5.0, // per rep   (default 10 → 60 XP)
  'situps': 1.0, // per rep   (default 30 → 36 XP)
  'squats': 1.0, // per rep   (default 30 → 36 XP)
  'running': 25.0, // per km    (default  3 → 90 XP)
  'plank': 1.0, // per second(default 60 → 72 XP)
  'dips': 3.0, // per rep   (default 15 → 54 XP)
  'burpees': 6.0, // per rep   (default 10 → 72 XP)
  'jumping_jacks': 1.0, // per rep   (default 50 → 60 XP)
  'cycling': 7.0, // per km    (default 10 → 84 XP)
  'jump_rope': 5.0, // per minute(default 10 → 60 XP)
  // ── New exercises (difficulty-scaled) ───────────────────────────────────
  'wide_pushups': 2.0, // per rep   (d2, default 15 → 36 XP)
  'diamond_pushups': 5.0, // per rep   (d3, default 10 → 60 XP)
  'pike_pushups': 5.0, // per rep   (d3, default 10 → 60 XP)
  'archer_pushups': 9.0, // per rep   (d4, default  8 → 86 XP)
  'lunges': 2.0, // per rep   (d2, default 20 → 48 XP)
  'bulgarian_squats': 4.0, // per rep   (d3, default 15 → 72 XP)
  'russian_twists': 1.0, // per rep   (d2, default 20 → 24 XP)
  'spiderman_plank': 5.0, // per rep   (d3, default 10 → 60 XP)
  'stretching': 2.0, // per minute(d1, default 10 → 24 XP)
};

double xpPerUnitFor(String exerciseId) =>
    _customXpRegistry[exerciseId] ?? kXpPerUnit[exerciseId] ?? 2.0;

// ---------------------------------------------------------------------------
// Custom exercise XP registry (populated at runtime)
// ---------------------------------------------------------------------------

final Map<String, double> _customXpRegistry = {};

void registerCustomExerciseXp(String id, double xpPerUnit) {
  _customXpRegistry[id] = xpPerUnit;
}

void unregisterCustomExerciseXp(String id) {
  _customXpRegistry.remove(id);
}

/// Compute the XP-per-unit for a custom exercise from its type, unit and
/// difficulty level (1–5).
///
/// Tables agreed on 2026-04-19:
///   Reps:      D1=0.75  D2=1.5   D3=3.0   D4=5.5   D5=9.0
///   Minutes:   D1=2.0   D2=5.0   D3=9.0   D4=14.0  D5=20.0
///   Seconds:   D1=0.35  D2=0.70  D3=1.50  D4=2.50  D5=4.00
///   Km:        D1=5.0   D2=12.0  D3=25.0  D4=40.0  D5=60.0
double computeCustomXpPerUnit({
  required String type, // 'reps' | 'distance' | 'duration'
  required String unit, // 'reps' | 'km' | 'minutes' | 'seconds'
  required int difficulty,
}) {
  final d = difficulty.clamp(1, 5) - 1; // 0-based index

  const repsTable = [1.0, 2.0, 3.0, 6.0, 9.0];
  const minutesTable = [2.0, 5.0, 9.0, 14.0, 20.0];
  const secondsTable = [1.0, 1.0, 2.0, 3.0, 4.0];
  const kmTable = [5.0, 12.0, 25.0, 40.0, 60.0];

  if (type == 'distance') return kmTable[d];
  if (type == 'duration') {
    return unit == 'seconds' ? secondsTable[d] : minutesTable[d];
  }
  // reps (default)
  return repsTable[d];
}

// ---------------------------------------------------------------------------
// Bonus XP configuration
// ---------------------------------------------------------------------------

/// Flat XP bonus awarded when ALL daily exercises are fully completed.
const int kQuestCompletionBonus = 100;

/// XP multiplier increase per streak day (e.g. 0.01 = +1% per day).
const double kStreakBonusPerDay = 0.01;

/// Maximum streak XP multiplier bonus (0.50 = +50% cap).
const double kMaxStreakBonusPct = 0.50;
