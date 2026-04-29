/// Standard exercise library — users pick from these during onboarding / settings.
library;

import 'dart:math';

enum ExerciseType { reps, distance, duration }

/// Muscle group / movement category — used for grouping pickers in the UI.
enum ExerciseMuscleGroup { push, pull, core, legs, cardio, flexibility }

class ExerciseDefinition {
  final String id;
  final String name;
  final ExerciseType type;
  final String unit; // "reps", "km", "seconds", "minutes"
  final String emoji;
  final int defaultTarget;
  final int minTarget;
  final int maxTarget;
  final int stepSize; // stepper increment on the onboarding picker

  /// Movement category — used for grouping in the UI only (not persisted).
  final ExerciseMuscleGroup muscleGroup;

  /// Relative difficulty 1 (easiest) – 5 (hardest) within the library.
  final int difficulty;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.emoji,
    required this.defaultTarget,
    required this.minTarget,
    required this.maxTarget,
    required this.stepSize,
    required this.muscleGroup,
    required this.difficulty,
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String muscleGroupLabel(ExerciseMuscleGroup g) {
  switch (g) {
    case ExerciseMuscleGroup.push:
      return 'PUSH';
    case ExerciseMuscleGroup.pull:
      return 'PULL';
    case ExerciseMuscleGroup.core:
      return 'CORE';
    case ExerciseMuscleGroup.legs:
      return 'LEGS';
    case ExerciseMuscleGroup.cardio:
      return 'CARDIO';
    case ExerciseMuscleGroup.flexibility:
      return 'FLEXIBILITY & RECOVERY';
  }
}

String muscleGroupEmoji(ExerciseMuscleGroup g) {
  switch (g) {
    case ExerciseMuscleGroup.push:
      return '💪';
    case ExerciseMuscleGroup.pull:
      return '🏋️';
    case ExerciseMuscleGroup.core:
      return '🧘';
    case ExerciseMuscleGroup.legs:
      return '🦵';
    case ExerciseMuscleGroup.cardio:
      return '🏃';
    case ExerciseMuscleGroup.flexibility:
      return '🤸';
  }
}

/// Returns a string of filled/empty stars representing difficulty.
String difficultyStars(int difficulty) {
  final filled = '⭐' * difficulty.clamp(1, 5);
  return filled;
}

/// Computes a sensible log-step based on *today's* target amount so the
/// increment grows automatically as weekly scaling pushes targets higher.
///
/// Reps:     ≤14→1  15-30→2  31-50→5  >50→10
/// Seconds:  ≤29→5  30-60→10  61-120→15  >120→30
/// Minutes:  ≤9→1  10-30→2  31-60→5  >60→10
/// Distance: ≤2→0.1  3-10→0.5  >10→1.0  (km; used for undo only)
double dynamicStepFor(double targetAmount, ExerciseDefinition def) {
  switch (def.type) {
    case ExerciseType.reps:
      if (targetAmount > 50) return 10;
      if (targetAmount > 30) return 5;
      if (targetAmount >= 15) return 2;
      return 1;
    case ExerciseType.duration:
      if (def.unit == 'seconds') {
        if (targetAmount > 120) return 30;
        if (targetAmount > 60) return 15;
        if (targetAmount >= 30) return 10;
        return 5;
      }
      // minutes
      if (targetAmount > 60) return 10;
      if (targetAmount > 30) return 5;
      if (targetAmount >= 10) return 2;
      return 1;
    case ExerciseType.distance:
      // Distance exercises use a free-text dialog — step only matters for undo.
      if (targetAmount > 10) return 1.0;
      if (targetAmount >= 3) return 0.5;
      return 0.1;
  }
}

// ---------------------------------------------------------------------------
// Library — sorted by group (push→pull→core→legs→cardio→flexibility)
//           then ascending difficulty within each group.
// ---------------------------------------------------------------------------

const List<ExerciseDefinition> kExerciseLibrary = [
  // ── PUSH ──────────────────────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'wall_pushups',
    name: 'Wall Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🧱',
    defaultTarget: 20,
    minTarget: 5,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'pushups',
    name: 'Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '💪',
    defaultTarget: 20,
    minTarget: 5,
    maxTarget: 500,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'wide_pushups',
    name: 'Wide Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🤲',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 300,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'diamond_pushups',
    name: 'Diamond Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '💎',
    defaultTarget: 10,
    minTarget: 3,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'dips',
    name: 'Dips',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🔱',
    defaultTarget: 15,
    minTarget: 1,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'pike_pushups',
    name: 'Pike Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🔻',
    defaultTarget: 10,
    minTarget: 3,
    maxTarget: 150,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'decline_pushups',
    name: 'Decline Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '📐',
    defaultTarget: 12,
    minTarget: 3,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'archer_pushups',
    name: 'Archer Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🏹',
    defaultTarget: 8,
    minTarget: 2,
    maxTarget: 100,
    stepSize: 2,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 4,
  ),
  ExerciseDefinition(
    id: 'handstand_pushups',
    name: 'Handstand Push-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🙃',
    defaultTarget: 5,
    minTarget: 1,
    maxTarget: 50,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.push,
    difficulty: 5,
  ),

  // ── PULL ──────────────────────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'inverted_rows',
    name: 'Inverted Rows',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🔄',
    defaultTarget: 15,
    minTarget: 3,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.pull,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'pullups',
    name: 'Pull-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🏋️',
    defaultTarget: 10,
    minTarget: 1,
    maxTarget: 200,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.pull,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'chinups',
    name: 'Chin-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🤜',
    defaultTarget: 10,
    minTarget: 1,
    maxTarget: 200,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.pull,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'commando_pullups',
    name: 'Commando Pull-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '⚔️',
    defaultTarget: 6,
    minTarget: 1,
    maxTarget: 100,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.pull,
    difficulty: 4,
  ),
  ExerciseDefinition(
    id: 'muscle_ups',
    name: 'Muscle-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '👑',
    defaultTarget: 3,
    minTarget: 1,
    maxTarget: 50,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.pull,
    difficulty: 5,
  ),

  // ── CORE ──────────────────────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'situps',
    name: 'Sit-ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🧘',
    defaultTarget: 30,
    minTarget: 5,
    maxTarget: 500,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'leg_raises',
    name: 'Leg Raises',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🦵',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'flutter_kicks',
    name: 'Flutter Kicks',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🌊',
    defaultTarget: 30,
    minTarget: 10,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'russian_twists',
    name: 'Russian Twists',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🌀',
    defaultTarget: 20,
    minTarget: 10,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'side_plank',
    name: 'Side Plank',
    type: ExerciseType.duration,
    unit: 'seconds',
    emoji: '↔️',
    defaultTarget: 30,
    minTarget: 10,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'plank',
    name: 'Plank',
    type: ExerciseType.duration,
    unit: 'seconds',
    emoji: '🧱',
    defaultTarget: 60,
    minTarget: 10,
    maxTarget: 600,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'hollow_body_hold',
    name: 'Hollow Body Hold',
    type: ExerciseType.duration,
    unit: 'seconds',
    emoji: '🍌',
    defaultTarget: 30,
    minTarget: 5,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'v_ups',
    name: 'V-Ups',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '✌️',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'spiderman_plank',
    name: 'Spider-Man Plank',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🕷️',
    defaultTarget: 10,
    minTarget: 5,
    maxTarget: 100,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'ab_wheel_rollouts',
    name: 'Ab Wheel Rollouts',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '☸️',
    defaultTarget: 10,
    minTarget: 3,
    maxTarget: 100,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.core,
    difficulty: 4,
  ),

  // ── LEGS ──────────────────────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'calf_raises',
    name: 'Calf Raises',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🦶',
    defaultTarget: 30,
    minTarget: 10,
    maxTarget: 500,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'glute_bridges',
    name: 'Glute Bridges',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🌉',
    defaultTarget: 20,
    minTarget: 5,
    maxTarget: 300,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'squats',
    name: 'Squats',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🦵',
    defaultTarget: 30,
    minTarget: 5,
    maxTarget: 500,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'wall_sit',
    name: 'Wall Sit',
    type: ExerciseType.duration,
    unit: 'seconds',
    emoji: '🧱',
    defaultTarget: 60,
    minTarget: 10,
    maxTarget: 600,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'lunges',
    name: 'Lunges',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🚶',
    defaultTarget: 20,
    minTarget: 5,
    maxTarget: 300,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'jump_squats',
    name: 'Jump Squats',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🚀',
    defaultTarget: 20,
    minTarget: 5,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'bulgarian_squats',
    name: 'Bulgarian Split Squats',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🎯',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'nordic_curls',
    name: 'Nordic Curls',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '❄️',
    defaultTarget: 5,
    minTarget: 1,
    maxTarget: 50,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 4,
  ),
  ExerciseDefinition(
    id: 'pistol_squats',
    name: 'Pistol Squats',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🔫',
    defaultTarget: 5,
    minTarget: 1,
    maxTarget: 50,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.legs,
    difficulty: 4,
  ),

  // ── CARDIO ────────────────────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'walking',
    name: 'Walking',
    type: ExerciseType.distance,
    unit: 'km',
    emoji: '🚶',
    defaultTarget: 3,
    minTarget: 1,
    maxTarget: 30,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'high_knees',
    name: 'High Knees',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🏃',
    defaultTarget: 50,
    minTarget: 10,
    maxTarget: 500,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'jumping_jacks',
    name: 'Jumping Jacks',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '⚡',
    defaultTarget: 50,
    minTarget: 10,
    maxTarget: 500,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'jump_rope',
    name: 'Jump Rope',
    type: ExerciseType.duration,
    unit: 'minutes',
    emoji: '🪢',
    defaultTarget: 10,
    minTarget: 1,
    maxTarget: 60,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'cycling',
    name: 'Cycling',
    type: ExerciseType.distance,
    unit: 'km',
    emoji: '🚴',
    defaultTarget: 10,
    minTarget: 1,
    maxTarget: 100,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'running',
    name: 'Running',
    type: ExerciseType.distance,
    unit: 'km',
    emoji: '🏃',
    defaultTarget: 3,
    minTarget: 1,
    maxTarget: 42,
    stepSize: 1,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'mountain_climbers',
    name: 'Mountain Climbers',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '⛰️',
    defaultTarget: 30,
    minTarget: 10,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 2,
  ),
  ExerciseDefinition(
    id: 'burpees',
    name: 'Burpees',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '🔥',
    defaultTarget: 10,
    minTarget: 1,
    maxTarget: 200,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 3,
  ),
  ExerciseDefinition(
    id: 'box_jumps',
    name: 'Box Jumps',
    type: ExerciseType.reps,
    unit: 'reps',
    emoji: '📦',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 100,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.cardio,
    difficulty: 3,
  ),

  // ── FLEXIBILITY & RECOVERY ────────────────────────────────────────────────
  ExerciseDefinition(
    id: 'stretching',
    name: 'Stretching',
    type: ExerciseType.duration,
    unit: 'minutes',
    emoji: '🤸',
    defaultTarget: 10,
    minTarget: 5,
    maxTarget: 60,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.flexibility,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'yoga',
    name: 'Yoga',
    type: ExerciseType.duration,
    unit: 'minutes',
    emoji: '🧘',
    defaultTarget: 15,
    minTarget: 5,
    maxTarget: 120,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.flexibility,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'foam_rolling',
    name: 'Foam Rolling',
    type: ExerciseType.duration,
    unit: 'minutes',
    emoji: '🫸',
    defaultTarget: 10,
    minTarget: 5,
    maxTarget: 30,
    stepSize: 5,
    muscleGroup: ExerciseMuscleGroup.flexibility,
    difficulty: 1,
  ),
  ExerciseDefinition(
    id: 'deep_squat_hold',
    name: 'Deep Squat Hold',
    type: ExerciseType.duration,
    unit: 'seconds',
    emoji: '🐸',
    defaultTarget: 60,
    minTarget: 10,
    maxTarget: 300,
    stepSize: 10,
    muscleGroup: ExerciseMuscleGroup.flexibility,
    difficulty: 2,
  ),
];

// ---------------------------------------------------------------------------
// Lookup helpers
// ---------------------------------------------------------------------------

ExerciseDefinition? exerciseById(String id) {
  try {
    return kExerciseLibrary.firstWhere((e) => e.id == id);
  } catch (_) {
    return _customRegistry[id];
  }
}

// ---------------------------------------------------------------------------
// Custom exercise registry (populated at runtime from Hive)
// ---------------------------------------------------------------------------

final Map<String, ExerciseDefinition> _customRegistry = {};

List<ExerciseDefinition> get customExercises =>
    List.unmodifiable(_customRegistry.values);

void registerCustomExercise(ExerciseDefinition def) {
  _customRegistry[def.id] = def;
}

void unregisterCustomExercise(String id) {
  _customRegistry.remove(id);
}

/// Returns all exercises for a given muscle group, sorted by difficulty.
List<ExerciseDefinition> exercisesByGroup(ExerciseMuscleGroup group) =>
    kExerciseLibrary.where((e) => e.muscleGroup == group).toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

/// Returns true if the exercise measures distance (running, cycling).
bool isDistanceExercise(String exerciseId) =>
    exerciseById(exerciseId)?.type == ExerciseType.distance;

/// Kilometres → Miles
double kmToMi(double km) => km * 0.621371;

/// Miles → Kilometres
double miToKm(double mi) => mi / 0.621371;

/// Format a distance value nicely (1 decimal place, strip trailing .0).
String fmtDistance(double value) {
  final s = value.toStringAsFixed(1);
  return s.endsWith('.0') ? value.toInt().toString() : s;
}

// ---------------------------------------------------------------------------
// Progression unlock helpers
// ---------------------------------------------------------------------------

/// Multipliers for volume-based unlock thresholds.
/// Threshold = multiplier × prereq.defaultTarget, so a harder default target
/// requires proportionally more total reps/km/secs logged.
/// Made public so xp_service and ability-gate helpers can share the same thresholds.
const double kUnlockMultiplierD3 = 15.0; // e.g. 15 × 20 pushups = 300 reps
const double kUnlockMultiplierD4 = 30.0; // e.g. 30 × 20 pushups = 600 reps
const double kUnlockMultiplierD5 = 60.0; // e.g. 60 × 10 pull-ups = 600 reps

/// Returns true when [def] is available to the user.
/// d1/d2 exercises are always available.
/// d3 unlocks when cumulative volume of any same-group d2 prerequisite
/// reaches [kUnlockMultiplierD3 × prereq.defaultTarget].
/// d4 uses [kUnlockMultiplierD4] against d3 prereqs only.
/// d5 uses [kUnlockMultiplierD5] against d4 prereqs only.
/// Only the immediately-adjacent lower tier (difficulty - 1) qualifies.
/// [getVolume] should return the total logged units for a given exercise id.
/// [getBonusVolume] optionally returns extra bonus volume keyed to [def.id]
/// earned via Shadow Trial completions; added on top of logged volume.
bool isExerciseUnlocked(
  ExerciseDefinition def,
  double Function(String id) getVolume, {
  double Function(String id)? getBonusVolume,
}) {
  if (def.difficulty <= 2) return true;
  final multiplier = def.difficulty == 3
      ? kUnlockMultiplierD3
      : def.difficulty == 4
          ? kUnlockMultiplierD4
          : kUnlockMultiplierD5;
  final prereqs = kExerciseLibrary
      .where((e) =>
          e.muscleGroup == def.muscleGroup &&
          e.difficulty == def.difficulty - 1)
      .toList();
  // No prerequisites defined — unlock by default (e.g. pullups is alone in PULL)
  if (prereqs.isEmpty) return true;
  final bonus = getBonusVolume?.call(def.id) ?? 0.0;
  return prereqs
      .any((e) => getVolume(e.id) + bonus >= multiplier * e.defaultTarget);
}

/// Human-readable unlock requirement string for display in the UI.
/// Shows the exact volume threshold needed for the adjacent-tier prerequisite.
/// Returns empty string for d1/d2 exercises or when no prerequisites exist.
String exerciseUnlockDescription(ExerciseDefinition def) {
  if (def.difficulty <= 2) return '';
  final multiplier = def.difficulty == 3
      ? kUnlockMultiplierD3
      : def.difficulty == 4
          ? kUnlockMultiplierD4
          : kUnlockMultiplierD5;
  final prereqs = kExerciseLibrary
      .where((e) =>
          e.muscleGroup == def.muscleGroup &&
          e.difficulty == def.difficulty - 1)
      .toList();
  if (prereqs.isEmpty) return '';
  final parts = prereqs.map((e) {
    final needed = (multiplier * e.defaultTarget).round();
    return '$needed ${e.unit} of ${e.name}';
  }).join(' or ');
  return 'Log $parts to unlock.';
}

// ---------------------------------------------------------------------------
// Ability-gate helpers (for onboarding fitness screening)
// ---------------------------------------------------------------------------

/// Returns true when a D2 exercise that was ability-locked during onboarding
/// has been unlocked by the player logging enough volume of a same-group D1
/// prerequisite. Uses [kUnlockMultiplierD3] as the threshold.
/// [getVolume] should return the total logged units for a given exercise id.
bool isAbilityExerciseUnlocked(
  ExerciseDefinition def,
  double Function(String id) getVolume,
) {
  final prereqs = kExerciseLibrary
      .where((e) =>
          e.muscleGroup == def.muscleGroup &&
          e.difficulty == def.difficulty - 1)
      .toList();
  if (prereqs.isEmpty) return true;
  return prereqs
      .any((e) => getVolume(e.id) >= kUnlockMultiplierD3 * e.defaultTarget);
}

/// Human-readable unlock requirement for an ability-locked exercise.
/// e.g. "Complete 300 reps of Inverted Rows to unlock."
String exerciseAbilityLockedDescription(ExerciseDefinition def) {
  final prereqs = kExerciseLibrary
      .where((e) =>
          e.muscleGroup == def.muscleGroup &&
          e.difficulty == def.difficulty - 1)
      .toList();
  if (prereqs.isEmpty) return '';
  final parts = prereqs.map((e) {
    final needed = (kUnlockMultiplierD3 * e.defaultTarget).round();
    return '$needed ${e.unit} of ${e.name}';
  }).join(' or ');
  return 'Complete $parts to unlock.';
}

// ---------------------------------------------------------------------------
// Unlock progress helper
// ---------------------------------------------------------------------------

/// Returns progress toward unlocking [def] via cumulative logged volume.
///
/// Only the immediately-adjacent lower tier (difficulty - 1) is considered.
/// Finds the prerequisite with the highest fraction and returns:
/// - [fraction]  0.0–1.0 (clamped) — percentage toward threshold
/// - [current]   logged volume of the best prereq plus any bonus
/// - [needed]    volume threshold required for unlock
/// - [prereq]    the prerequisite exercise with the best progress
///
/// [getBonusVolume] optionally returns bonus volume keyed to [def.id] from
/// Shadow Trial completions; added to [current] and reflected in [fraction].
///
/// Returns null for d1/d2 exercises (always unlocked) or when no prerequisites
/// exist (exercise is unlocked by default).
({
  double fraction,
  double current,
  double needed,
  ExerciseDefinition prereq,
})? exerciseUnlockProgress(
  ExerciseDefinition def,
  double Function(String id) getVolume, {
  double Function(String id)? getBonusVolume,
}) {
  if (def.difficulty <= 2) return null;
  final multiplier = def.difficulty == 3
      ? kUnlockMultiplierD3
      : def.difficulty == 4
          ? kUnlockMultiplierD4
          : kUnlockMultiplierD5;
  final prereqs = kExerciseLibrary
      .where((e) =>
          e.muscleGroup == def.muscleGroup &&
          e.difficulty == def.difficulty - 1)
      .toList();
  if (prereqs.isEmpty) return null;

  final bonus = getBonusVolume?.call(def.id) ?? 0.0;

  ({
    double fraction,
    double current,
    double needed,
    ExerciseDefinition prereq,
  })? best;
  for (final prereq in prereqs) {
    final needed = multiplier * prereq.defaultTarget;
    final current = getVolume(prereq.id) + bonus;
    final fraction = needed > 0 ? (current / needed).clamp(0.0, 1.0) : 0.0;
    if (best == null || fraction > best.fraction) {
      best = (
        fraction: fraction,
        current: current,
        needed: needed,
        prereq: prereq,
      );
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Shadow Trial — challenge exercise picker
// ---------------------------------------------------------------------------

/// Picks a random exercise that the player has NOT yet unlocked, at the next
/// difficulty tier above their current maximum unlocked difficulty.
///
/// [userExerciseIds] — IDs already configured in the player's daily quest
///   (excluded so the challenge is always something new to try).
/// [lifetimeTotals] — total logged volume per exercise ID, used by
///   [isExerciseUnlocked] to check volume-based unlock thresholds.
///
/// Returns `null` when every exercise in the library is already available
/// (nothing left to challenge the player with).
ExerciseDefinition? pickChallengeExercise(
  List<String> userExerciseIds,
  Map<String, double> lifetimeTotals,
) {
  final getVolume = (String id) => lifetimeTotals[id] ?? 0.0;

  // Find the highest difficulty the player has currently unlocked.
  int maxUnlockedDiff = 1;
  for (final def in kExerciseLibrary) {
    if (isExerciseUnlocked(def, getVolume)) {
      if (def.difficulty > maxUnlockedDiff) maxUnlockedDiff = def.difficulty;
    }
  }

  // Target one tier beyond their current ceiling, capped at D5.
  final targetDiff = (maxUnlockedDiff + 1).clamp(1, 5);

  // Build the eligible pool: locked exercises at the target difficulty,
  // excluding any already in the player's daily config.
  var pool = kExerciseLibrary
      .where((def) =>
          def.difficulty == targetDiff &&
          !isExerciseUnlocked(def, getVolume) &&
          !userExerciseIds.contains(def.id))
      .toList();

  // Fallback: any locked exercise above the player's current max.
  if (pool.isEmpty) {
    pool = kExerciseLibrary
        .where((def) =>
            def.difficulty > maxUnlockedDiff &&
            !isExerciseUnlocked(def, getVolume) &&
            !userExerciseIds.contains(def.id))
        .toList();
  }

  if (pool.isEmpty) return null;

  return pool[Random().nextInt(pool.length)];
}
