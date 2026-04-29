/// Achievement definitions for the Solo Leveling Fitness app.
library;

enum AchievementCategory { quests, streak, rank, xp, exercise }

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;

  /// Non-null for exercise achievements — used for sub-grouping in the UI.
  final String? exerciseId;

  /// Bonus XP awarded to the player when this achievement is first unlocked.
  final int xpReward;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.exerciseId,
    this.xpReward = 0,
  });
}

// ---------------------------------------------------------------------------
// Static achievements (quests / streak / rank / xp)
// ---------------------------------------------------------------------------

const List<AchievementDefinition> _kStaticAchievements = [
  // --- Quests ---
  AchievementDefinition(
    id: 'first_quest',
    title: 'First Step',
    description: 'Complete your first daily quest.',
    emoji: '⚔️',
    category: AchievementCategory.quests,
    xpReward: 50,
  ),
  AchievementDefinition(
    id: 'quest_10',
    title: 'Persistent Hunter',
    description: 'Complete 10 daily quests.',
    emoji: '📜',
    category: AchievementCategory.quests,
    xpReward: 150,
  ),
  AchievementDefinition(
    id: 'quest_100',
    title: 'Century Hunter',
    description: 'Complete 100 daily quests.',
    emoji: '💯',
    category: AchievementCategory.quests,
    xpReward: 600,
  ),

  // --- Streak ---
  AchievementDefinition(
    id: 'streak_3',
    title: 'Awakening',
    description: 'Maintain a 3-day training streak.',
    emoji: '🔥',
    category: AchievementCategory.streak,
    xpReward: 75,
  ),
  AchievementDefinition(
    id: 'streak_7',
    title: 'Iron Will',
    description: 'Maintain a 7-day training streak.',
    emoji: '⚡',
    category: AchievementCategory.streak,
    xpReward: 200,
  ),
  AchievementDefinition(
    id: 'streak_30',
    title: 'Shadow Disciple',
    description: 'Maintain a 30-day training streak.',
    emoji: '🌑',
    category: AchievementCategory.streak,
    xpReward: 750,
  ),
  AchievementDefinition(
    id: 'streak_100',
    title: 'Immortal Hunter',
    description: 'Maintain a 100-day training streak.',
    emoji: '👑',
    category: AchievementCategory.streak,
    xpReward: 2000,
  ),

  // --- Rank ---
  AchievementDefinition(
    id: 'rank_d',
    title: 'D-Class Ascension',
    description: 'Reach level 11 and attain D-Class rank.',
    emoji: '🟢',
    category: AchievementCategory.rank,
    xpReward: 250,
  ),
  AchievementDefinition(
    id: 'rank_c',
    title: 'C-Class Ascension',
    description: 'Reach level 21 and attain C-Class rank.',
    emoji: '🔵',
    category: AchievementCategory.rank,
    xpReward: 500,
  ),
  AchievementDefinition(
    id: 'rank_b',
    title: 'B-Class Ascension',
    description: 'Reach level 36 and attain B-Class rank.',
    emoji: '🟣',
    category: AchievementCategory.rank,
    xpReward: 1000,
  ),
  AchievementDefinition(
    id: 'rank_a',
    title: 'A-Class Ascension',
    description: 'Reach level 51 and attain A-Class rank.',
    emoji: '🟠',
    category: AchievementCategory.rank,
    xpReward: 1500,
  ),
  AchievementDefinition(
    id: 'rank_s',
    title: 'S-Class Ascension',
    description: 'Reach level 66 and attain S-Class rank.',
    emoji: '⭐',
    category: AchievementCategory.rank,
    xpReward: 2500,
  ),
  AchievementDefinition(
    id: 'rank_national',
    title: 'National Level Hunter',
    description: 'Reach level 81 and become a National Level Hunter.',
    emoji: '🌟',
    category: AchievementCategory.rank,
    xpReward: 4000,
  ),
  AchievementDefinition(
    id: 'rank_monarch',
    title: 'Shadow Monarch',
    description: 'Reach level 96. You stand alone at the top.',
    emoji: '🌑',
    category: AchievementCategory.rank,
    xpReward: 7500,
  ),

  // --- XP ---
  AchievementDefinition(
    id: 'xp_1000',
    title: 'Rookie Hunter',
    description: 'Earn a total of 1,000 XP.',
    emoji: '✨',
    category: AchievementCategory.xp,
    xpReward: 100,
  ),
  AchievementDefinition(
    id: 'xp_10000',
    title: 'Veteran Hunter',
    description: 'Earn a total of 10,000 XP.',
    emoji: '💎',
    category: AchievementCategory.xp,
    xpReward: 400,
  ),
  AchievementDefinition(
    id: 'xp_100000',
    title: 'Legend of Hunters',
    description: 'Earn a total of 100,000 XP.',
    emoji: '🏆',
    category: AchievementCategory.xp,
    xpReward: 1500,
  ),
];

// ---------------------------------------------------------------------------
// Exercise achievement generators
// ---------------------------------------------------------------------------

// (exerciseId, emoji, display name)
const _kExerciseMeta = [
  // Original exercises
  ('pushups', '💪', 'Push-ups'),
  ('pullups', '🏋️', 'Pull-ups'),
  ('situps', '🧘', 'Sit-ups'),
  ('squats', '🦵', 'Squats'),
  ('running', '🏃', 'Running'),
  ('plank', '🧱', 'Plank'),
  ('dips', '🔱', 'Dips'),
  ('burpees', '🔥', 'Burpees'),
  ('jumping_jacks', '⚡', 'Jumping Jacks'),
  ('cycling', '🚴', 'Cycling'),
  ('jump_rope', '🪢', 'Jump Rope'),
  // New exercises
  ('wide_pushups', '🤲', 'Wide Push-ups'),
  ('diamond_pushups', '💎', 'Diamond Push-ups'),
  ('pike_pushups', '🔻', 'Pike Push-ups'),
  ('archer_pushups', '🏹', 'Archer Push-ups'),
  ('lunges', '🚶', 'Lunges'),
  ('bulgarian_squats', '🎯', 'Bulgarian Split Squats'),
  ('russian_twists', '🌀', 'Russian Twists'),
  ('spiderman_plank', '🕷️', 'Spider-Man Plank'),
  ('stretching', '🤸', 'Stretching'),
];

// Quest-completion milestones — same for every exercise. '{}' → exercise name.
const _kQuestMilestones = [
  (1, 'First {}'),
  (10, '{} Initiate'),
  (25, '{} Adept'),
  (50, '{} Veteran'),
  (100, '{} Master'),
];

/// XP rewarded for each quest-count milestone (index matches _kQuestMilestones).
const _kQuestMilestoneXp = [50, 150, 350, 700, 1500];

/// XP rewarded for volume milestones by tier position (0 = first milestone).
const _kVolumeMilestoneXp = [100, 250, 500, 1000, 1500, 2500, 4000];

// Volume milestones per exercise: (amount, title, description).
// Units are the exercise's native unit (reps / km / seconds / minutes).
const _kVolumeMilestones = {
  'pushups': [
    (50, 'Iron Arms Initiate', '50 total push-ups logged.'),
    (100, 'Push-up Centurion', '100 push-ups crushed.'),
    (200, 'Pressing Force', '200 push-ups completed.'),
    (500, 'Push-up Veteran', '500 push-ups in the books.'),
    (1000, 'Arm of Steel', '1,000 push-ups completed.'),
    (2000, 'Relentless Presser', '2,000 push-ups conquered.'),
    (5000, 'Shadow Presser', '5,000 push-ups — you are unstoppable.'),
  ],
  'pullups': [
    (10, 'First Pull', 'Log your first 10 pull-ups.'),
    (50, 'Rising Hunter', '50 total pull-ups achieved.'),
    (100, 'Iron Grip', '100 pull-ups completed.'),
    (250, 'Ceiling Climber', '250 pull-ups conquered.'),
    (500, 'Pull-up Monarch', '500 pull-ups — sheer dominance.'),
  ],
  'situps': [
    (100, 'Core Awakened', '100 sit-ups completed.'),
    (250, 'Iron Core', '250 sit-ups in the books.'),
    (500, 'Core Veteran', '500 sit-ups achieved.'),
    (1000, 'Abdominal Legend', '1,000 sit-ups completed.'),
    (2500, 'Core of Steel', '2,500 sit-ups — unbreakable.'),
  ],
  'squats': [
    (100, 'Leg Day Initiate', '100 squats completed.'),
    (250, 'Quad Runner', '250 squats conquered.'),
    (500, 'Iron Thighs', '500 squats in the books.'),
    (1000, 'Squat Legend', '1,000 squats achieved.'),
    (2500, 'Squat Sovereign', '2,500 squats — legs of iron.'),
  ],
  'running': [
    (1, 'First Kilometer', 'Run your first kilometer.'),
    (10, 'Road Runner', '10 km of total running.'),
    (25, 'Trail Blazer', '25 km on the road.'),
    (50, 'Marathon Spirit', '50 km of total running.'),
    (100, 'Century Sprinter', '100 km run in total.'),
    (250, 'Boundless Road', '250 km of total running.'),
    (500, "Hunter's Marathon", '500 km run — extraordinary.'),
  ],
  'plank': [
    (300, '5-Minute Hold', 'Hold a total of 5 minutes of plank (300 s).'),
    (600, 'Iron Plank', '10 total minutes in plank position (600 s).'),
    (1800, 'Stone Wall', '30 total minutes of plank endured (1,800 s).'),
    (3600, '1-Hour Sentinel', '1 hour of total plank time (3,600 s).'),
    (7200, 'Colossus', '2 hours of total plank — unshakeable (7,200 s).'),
  ],
  'dips': [
    (50, 'Dip Initiate', '50 total dips completed.'),
    (100, 'Tricep Hunter', '100 dips logged.'),
    (250, 'Iron Triceps', '250 dips conquered.'),
    (500, 'Dip Veteran', '500 dips in the books.'),
    (1000, 'Parallel Bar Monarch', '1,000 dips — total dominance.'),
  ],
  'burpees': [
    (50, 'Burst Initiate', '50 total burpees completed.'),
    (100, 'Burpee Centurion', '100 burpees logged.'),
    (250, 'Endurance Seeker', '250 burpees conquered.'),
    (500, 'Conditioning Legend', '500 burpees achieved.'),
    (1000, 'Shadow Burpee', '1,000 burpees — iron will.'),
  ],
  'jumping_jacks': [
    (100, 'Jack Initiate', '100 jumping jacks completed.'),
    (250, 'Jack of All Trades', '250 jumping jacks logged.'),
    (500, 'Jump Veteran', '500 jumping jacks achieved.'),
    (1000, 'Endless Energy', '1,000 jumping jacks crushed.'),
    (2500, 'Lightning Jumper', '2,500 jumping jacks — electric.'),
  ],
  'cycling': [
    (10, 'First Ride', '10 km cycled.'),
    (50, 'Road Cyclist', '50 km of cycling completed.'),
    (100, 'Century Rider', '100 km cycled.'),
    (250, 'Iron Pedals', '250 km on the bike.'),
    (500, 'Velocity Hunter', '500 km cycled — relentless.'),
  ],
  'jump_rope': [
    (30, 'Rope Initiate', '30 total minutes of jump rope.'),
    (60, 'Jump Rope Runner', '60 minutes of jump rope completed.'),
    (120, 'Double Under', '120 minutes of jump rope logged.'),
    (300, 'Rope Veteran', '300 minutes on the rope.'),
    (600, 'Shadow Jumper', '600 minutes of jump rope — relentless.'),
  ],
  // New exercises
  'wide_pushups': [
    (50, 'Wide Initiate', '50 wide push-ups completed.'),
    (100, 'Broad Presser', '100 wide push-ups logged.'),
    (250, 'Chest Expander', '250 wide push-ups conquered.'),
    (500, 'Wide Veteran', '500 wide push-ups in the books.'),
    (1000, 'Pec Sovereign', '1,000 wide push-ups — raw chest power.'),
  ],
  'diamond_pushups': [
    (50, 'Diamond Initiate', '50 diamond push-ups completed.'),
    (100, 'Tricep Sculptor', '100 diamond push-ups logged.'),
    (250, 'Diamond Veteran', '250 diamond push-ups conquered.'),
    (500, 'Diamond Sovereign', '500 diamond push-ups — chiseled arms.'),
  ],
  'pike_pushups': [
    (50, 'Pike Initiate', '50 pike push-ups completed.'),
    (100, 'Shoulder Builder', '100 pike push-ups logged.'),
    (250, 'Pike Veteran', '250 pike push-ups conquered.'),
    (500, 'Pike Sovereign', '500 pike push-ups — shoulder of steel.'),
  ],
  'archer_pushups': [
    (25, 'Archer Initiate', '25 archer push-ups completed.'),
    (50, 'One-Arm Approach', '50 archer push-ups logged.'),
    (100, 'Archer Veteran', '100 archer push-ups conquered.'),
    (250, 'Archer Sovereign', '250 archer push-ups — near one-arm level.'),
  ],
  'lunges': [
    (50, 'Lunge Initiate', '50 total lunges completed.'),
    (100, 'Strider', '100 lunges logged.'),
    (250, 'Lunge Veteran', '250 lunges conquered.'),
    (500, 'Quad Crusher', '500 lunges in the books.'),
    (1000, 'Lunge Sovereign', '1,000 lunges — unstoppable legs.'),
  ],
  'bulgarian_squats': [
    (25, 'Split Initiate', '25 Bulgarian split squats completed.'),
    (50, 'Balance Seeker', '50 Bulgarian split squats logged.'),
    (100, 'Split Veteran', '100 Bulgarian split squats conquered.'),
    (250, 'Single-Leg Legend', '250 Bulgarian split squats: elite legs.'),
    (500, 'Split Sovereign', '500 Bulgarian split squats — iron quads.'),
  ],
  'russian_twists': [
    (50, 'Twist Initiate', '50 Russian twists completed.'),
    (100, 'Core Rotator', '100 Russian twists logged.'),
    (250, 'Twist Veteran', '250 Russian twists conquered.'),
    (500, 'Oblique Crusher', '500 Russian twists in the books.'),
    (1000, 'Twist Sovereign', '1,000 Russian twists — obliques of iron.'),
  ],
  'spiderman_plank': [
    (25, 'Spider Initiate', '25 Spider-Man planks completed.'),
    (50, 'Web Crawler', '50 Spider-Man planks logged.'),
    (100, 'Spider Veteran', '100 Spider-Man planks conquered.'),
    (250, 'Spider Sovereign', '250 Spider-Man planks — wall-crawling core.'),
  ],
  'stretching': [
    (60, 'First Stretch', '60 total minutes of stretching.'),
    (120, 'Flexibility Seeker', '120 minutes of stretching logged.'),
    (300, 'Stretch Veteran', '300 minutes of stretching completed.'),
    (600, 'Mobility Master', '600 minutes of stretching — elite flexibility.'),
    (1200, 'Shadow Yogi', '1,200 minutes of stretching — body like water.'),
  ],
};

List<AchievementDefinition> _generateExerciseAchievements() {
  final result = <AchievementDefinition>[];
  for (final (id, emoji, name) in _kExerciseMeta) {
    // Quest-completion milestones
    for (int i = 0; i < _kQuestMilestones.length; i++) {
      final (count, titleTemplate) = _kQuestMilestones[i];
      result.add(AchievementDefinition(
        id: '${id}_quest_$count',
        title: titleTemplate.replaceAll('{}', name),
        description: count == 1
            ? 'Complete your first $name quest.'
            : 'Complete $count $name quests.',
        emoji: emoji,
        category: AchievementCategory.exercise,
        exerciseId: id,
        xpReward: _kQuestMilestoneXp[i],
      ));
    }
    // Lifetime volume milestones
    final milestones = (_kVolumeMilestones[id] as List<dynamic>?) ?? [];
    for (int i = 0; i < milestones.length; i++) {
      final entry = milestones[i];
      final amount = entry.$1 as int;
      final title = entry.$2 as String;
      final desc = entry.$3 as String;
      result.add(AchievementDefinition(
        id: '${id}_total_$amount',
        title: title,
        description: desc,
        emoji: emoji,
        category: AchievementCategory.exercise,
        exerciseId: id,
        xpReward:
            i < _kVolumeMilestoneXp.length ? _kVolumeMilestoneXp[i] : 4000,
      ));
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Combined list — used everywhere (storage seeding, screens, service)
// ---------------------------------------------------------------------------

final List<AchievementDefinition> kAchievementDefinitions = [
  ..._kStaticAchievements,
  ..._generateExerciseAchievements(),
];

AchievementDefinition? achievementById(String id) {
  try {
    return kAchievementDefinitions.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
}
