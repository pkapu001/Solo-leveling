import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/xp_config.dart';
import '../../constants/flavor_text.dart';
import '../../constants/exercises.dart';
import '../../constants/achievements.dart';
import '../../models/daily_quest.dart';
import '../../models/player.dart';
import '../../models/quest_item.dart';
import '../../models/weekly_challenge.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_bar.dart';
import '../../widgets/level_badge.dart';
import '../../widgets/rank_title.dart';
import '../../widgets/quest_item_card.dart';
import '../../widgets/level_up_overlay.dart';
import '../../widgets/achievement_unlocked_overlay.dart';
import '../../widgets/xp_gain_popup.dart';
import '../../widgets/shadow_trial_card.dart';
import '../../widgets/shadow_trial_complete_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _levelUpTo;
  // Queue of achievements to display one at a time
  final List<AchievementDefinition> _pendingAchievements = [];
  // XP gain popup state
  int? _xpPopupGained;
  bool _xpPopupAllComplete = false;
  // Shadow Trial completion overlay state
  String? _shadowTrialCompleteExercise;
  double? _shadowTrialBonusVolume;
  // Exercises that hit a personal record this session
  final Set<String> _prExercisesToday = {};

  @override
  void initState() {
    super.initState();
    // Retroactively unlock any achievements the player already qualifies for.
    // This handles data that existed before the achievement system was active.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkAchievementsOnStartup());
  }

  Future<void> _checkAchievementsOnStartup() async {
    // Break a stale streak first (it is only updated during progress logging,
    // so opening the app after a missed day would otherwise keep the old count).
    await ref
        .read(playerProvider.notifier)
        .checkStreak(ref.read(xpServiceProvider));

    // Ensure the weekly challenge is loaded / created for this week.
    ref.read(weeklyChallengeProvider.notifier).reload();

    final player = ref.read(playerProvider);
    if (player == null) return;
    final (:unlocked, :bonusXp) =
        ref.read(achievementServiceProvider).checkAndUnlock(player);
    if (unlocked.isEmpty) return;
    final defs = unlocked
        .map((a) => achievementById(a.id))
        .whereType<AchievementDefinition>()
        .toList();
    if (defs.isNotEmpty && mounted) {
      setState(() => _pendingAchievements.addAll(defs));
    }
    ref.invalidate(achievementsProvider);
    if (bonusXp > 0) {
      ref.read(playerProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final quest = ref.watch(dailyQuestProvider);
    final challenge = ref.watch(weeklyChallengeProvider);

    if (player == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final level = levelFromXp(player.totalXp);

    return PopScope(
      canPop: false, // Home is the root screen — block back navigation
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('SYSTEM'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: 'Stats',
              onPressed: () => Navigator.pushNamed(context, '/stats'),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Achievements',
              onPressed: () => Navigator.pushNamed(context, '/achievements'),
            ),
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Quest Log',
              onPressed: () => Navigator.pushNamed(context, '/quest_log'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Fixed header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _PlayerCard(player: player, level: level),
                ),
                const SizedBox(height: 4),
                // ── Scrollable quest board ────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: context.slColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      ref.read(dailyQuestProvider.notifier).refresh();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _StreakCard(streak: player.streakDays),
                        const SizedBox(height: 12),
                        // ── Shadow Trial (weekly challenge) ────────────────
                        if (challenge != null &&
                            challenge.isActive &&
                            !challenge.isExpired)
                          ShadowTrialCard(
                            challenge: challenge,
                            useImperial: player.useImperial,
                            onLog: (amount) => _logChallengeProgress(
                                amount, player, challenge),
                            onUndo: () =>
                                _undoChallengeProgress(player, challenge),
                            onComplete: challenge.isCompleted
                                ? null
                                : () {
                                    final remaining = challenge.targetAmount -
                                        challenge.completedAmount;
                                    if (remaining > 0) {
                                      _logChallengeProgress(
                                          remaining, player, challenge);
                                    }
                                  },
                          ),
                        _DailyQuestBoard(
                          quest: quest,
                          useImperial: player.useImperial,
                          prExercises: _prExercisesToday,
                          onLog: (itemIdx, amount) =>
                              _logProgress(itemIdx, amount, player, quest),
                          onUndo: (itemIdx, amount) =>
                              _undoProgress(itemIdx, amount, player, quest),
                          onRestDay: () => _takeRestDay(player),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Level-up overlay
            if (_levelUpTo != null)
              LevelUpOverlay(
                newLevel: _levelUpTo!,
                onDismiss: () => setState(() => _levelUpTo = null),
              ),
            // XP gain popup (auto-dismisses) — behind the Shadow Trial overlay
            if (_xpPopupGained != null)
              XpGainPopup(
                xpGained: _xpPopupGained!,
                allComplete: _xpPopupAllComplete,
                onDone: () => setState(() {
                  _xpPopupGained = null;
                  _xpPopupAllComplete = false;
                }),
              ),
            // Shadow Trial completion overlay — rendered above the XP popup
            if (_shadowTrialCompleteExercise != null && _levelUpTo == null)
              ShadowTrialCompleteOverlay(
                exerciseName: _shadowTrialCompleteExercise!,
                bonusVolume: _shadowTrialBonusVolume,
                onDismiss: () => setState(() {
                  _shadowTrialCompleteExercise = null;
                  _shadowTrialBonusVolume = null;
                }),
              ),
            // Achievement unlocked overlay (shown after level-up is dismissed)
            if (_pendingAchievements.isNotEmpty && _levelUpTo == null)
              AchievementUnlockedOverlay(
                def: _pendingAchievements.first,
                onDismiss: () =>
                    setState(() => _pendingAchievements.removeAt(0)),
              ),
          ],
        ),
      ), // Scaffold
    ); // PopScope
  }

  Future<void> _logProgress(
    int itemIdx,
    double amount,
    Player player,
    DailyQuest? quest,
  ) async {
    if (quest == null) return;

    // Capture pre-log state for sound detection
    final prevItemCompleted = quest.items[itemIdx].isCompleted;

    await ref.read(dailyQuestProvider.notifier).logProgress(itemIdx, amount);

    // Re-read updated quest
    final updatedQuest = ref.read(dailyQuestProvider);
    if (updatedQuest == null) return;

    // Award XP
    final xpService = ref.read(xpServiceProvider);
    final totalXpBefore = player.totalXp; // capture before mutation
    final result = await xpService.awardQuestXp(player, updatedQuest);
    final allNowComplete = updatedQuest.isCompleted;
    // Compute display gain from the actual player.totalXp change (consistent
    // regardless of whether reps were logged one-at-a-time or in bulk).
    final xpGainedDisplay = (player.totalXp - totalXpBefore).round();
    if (xpGainedDisplay > 0 && mounted) {
      setState(() {
        // Accumulate so rapid taps update the displayed number
        _xpPopupGained = (_xpPopupGained ?? 0) + xpGainedDisplay;
        _xpPopupAllComplete = allNowComplete;
      });
    }

    // Track personal records this session
    if (result.newPersonalRecords.isNotEmpty) {
      setState(() {
        _prExercisesToday.addAll(result.newPersonalRecords);
      });
    }

    ref.read(playerProvider.notifier).reload();
    ref.read(dailyQuestProvider.notifier).refresh();

    // Check achievements
    final latestPlayer = ref.read(playerProvider);
    if (latestPlayer != null) {
      final levelBefore = levelFromXp(latestPlayer.totalXp);
      final (:unlocked, :bonusXp) =
          ref.read(achievementServiceProvider).checkAndUnlock(latestPlayer);
      if (unlocked.isNotEmpty) {
        final defs = unlocked
            .map((a) => achievementById(a.id))
            .whereType<AchievementDefinition>()
            .toList();
        if (defs.isNotEmpty && mounted) {
          setState(() => _pendingAchievements.addAll(defs));
        }
        ref.invalidate(achievementsProvider);
      }
      // If achievement XP caused a level-up, show the overlay
      if (bonusXp > 0) {
        ref.read(playerProvider.notifier).reload();
        final updatedPlayer = ref.read(playerProvider);
        if (updatedPlayer != null && mounted) {
          final levelAfter = levelFromXp(updatedPlayer.totalXp);
          if (levelAfter > levelBefore && _levelUpTo == null) {
            setState(() => _levelUpTo = levelAfter);
          }
        }
      }
    }

    // Play the most significant sound
    final sound = ref.read(soundServiceProvider);
    if (result.leveledUp) {
      unawaited(sound.playLevelUp());
    } else if (!prevItemCompleted && updatedQuest.items[itemIdx].isCompleted) {
      unawaited(sound.playQuestComplete());
    } else {
      unawaited(sound.playIncrement());
    }

    // If all quests are now done, skip tonight's evening notification
    if (updatedQuest.isCompleted) {
      final p = ref.read(playerProvider);
      if (p != null) {
        await ref.read(notificationServiceProvider).scheduleEveningReminder(
              hour: p.eveningNotifHour,
              minute: p.eveningNotifMinute,
              skipToday: true,
            );
      }
    }

    if (result.leveledUp) {
      setState(() => _levelUpTo = result.newLevel);
    }
  }

  Future<void> _takeRestDay(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Take Rest Day?'),
        content: const Text(
          'Mark today as a rest day. Your streak will be protected.\nYou can take 1 rest day per week.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REST DAY'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(storageServiceProvider).markRestDay();
      ref.read(playerProvider.notifier).reload();
      ref.read(dailyQuestProvider.notifier).refresh();
    }
  }

  Future<void> _undoProgress(
    int itemIdx,
    double amount,
    Player player,
    DailyQuest? quest,
  ) async {
    if (quest == null || itemIdx >= quest.items.length) return;
    final item = quest.items[itemIdx];
    final def = exerciseById(item.exerciseId);
    if (def == null) return;
    // Undo one step
    final step = dynamicStepFor(item.targetAmount, def);
    final undo = item.completedAmount >= step ? step : item.completedAmount;
    await ref.read(dailyQuestProvider.notifier).logProgress(itemIdx, -undo);
    unawaited(ref.read(soundServiceProvider).playUndo());

    // Recalculate XP so the decrement is reflected
    final updatedQuest = ref.read(dailyQuestProvider);
    if (updatedQuest == null) return;
    final xpService = ref.read(xpServiceProvider);
    await xpService.awardQuestXp(player, updatedQuest);
    ref.read(playerProvider.notifier).reload();
    ref.read(dailyQuestProvider.notifier).refresh();
  }

  // ---------------------------------------------------------------------------
  // Shadow Trial handlers
  // ---------------------------------------------------------------------------

  Future<void> _logChallengeProgress(
    double amount,
    Player player,
    WeeklyChallenge challenge,
  ) async {
    final wasCompleted = challenge.isCompleted;

    await ref.read(weeklyChallengeProvider.notifier).logProgress(amount);

    // Re-read the updated challenge from the notifier
    final updated = ref.read(weeklyChallengeProvider);
    if (updated == null) return;

    // Award XP (handles delta tracking and bonus volume on completion)
    final xpService = ref.read(xpServiceProvider);
    final totalXpBefore = player.totalXp;
    final result = await xpService.awardChallengeXp(player, updated);

    final xpGainedDisplay = (player.totalXp - totalXpBefore).round();
    if (xpGainedDisplay > 0 && mounted) {
      setState(() {
        _xpPopupGained = (_xpPopupGained ?? 0) + xpGainedDisplay;
        _xpPopupAllComplete = updated.isCompleted;
      });
    }

    ref.read(playerProvider.notifier).reload();
    ref.invalidate(exerciseBonusVolumeProvider);
    ref.read(weeklyChallengeProvider.notifier).refresh();

    // Play sound
    final sound = ref.read(soundServiceProvider);
    if (result.leveledUp) {
      unawaited(sound.playLevelUp());
    } else if (!wasCompleted && updated.isCompleted) {
      unawaited(sound.playQuestComplete());
    } else {
      unawaited(sound.playIncrement());
    }

    // Show Shadow Trial completion overlay on first completion
    if (!wasCompleted && updated.isCompleted && mounted) {
      final def = exerciseById(updated.exerciseId);
      setState(() {
        _shadowTrialCompleteExercise = def?.name ?? updated.exerciseId;
        _shadowTrialBonusVolume =
            result.bonusVolumeAwarded > 0 ? result.bonusVolumeAwarded : null;
      });
    }

    if (result.leveledUp) {
      setState(() => _levelUpTo = result.newLevel);
    }
  }

  Future<void> _undoChallengeProgress(
    Player player,
    WeeklyChallenge challenge,
  ) async {
    if (challenge.completedAmount <= 0) return;
    final def = exerciseById(challenge.exerciseId);
    if (def == null) return;
    final step = dynamicStepFor(challenge.targetAmount, def);
    final undo =
        challenge.completedAmount >= step ? step : challenge.completedAmount;
    await ref.read(weeklyChallengeProvider.notifier).logProgress(-undo);
    unawaited(ref.read(soundServiceProvider).playUndo());

    // Recalculate XP (handles negative delta correctly)
    final updated = ref.read(weeklyChallengeProvider);
    if (updated == null) return;
    final xpService = ref.read(xpServiceProvider);
    await xpService.awardChallengeXp(player, updated);
    ref.read(playerProvider.notifier).reload();
    ref.read(weeklyChallengeProvider.notifier).refresh();
  }
}

// ---------------------------------------------------------------------------
// Player Card
// ---------------------------------------------------------------------------
class _PlayerCard extends StatelessWidget {
  final Player player;
  final int level;

  const _PlayerCard({required this.player, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: goldGlowDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelBadge(level: level, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    RankTitle(level: level),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          XpBar(totalXp: player.totalXp),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Quest Board
// ---------------------------------------------------------------------------
class _DailyQuestBoard extends ConsumerWidget {
  final DailyQuest? quest;
  final void Function(int idx, double amount) onLog;
  final void Function(int idx, double amount) onUndo;
  final VoidCallback onRestDay;
  final bool useImperial;
  final Set<String> prExercises;

  const _DailyQuestBoard({
    required this.quest,
    required this.onLog,
    required this.onUndo,
    required this.onRestDay,
    required this.useImperial,
    required this.prExercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (quest == null || quest!.items.isEmpty) {
      return Container(
        decoration: goldCardDecoration(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No exercises configured.\nVisit Settings to set up your quest.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Show rest-day card if today is marked as rest
    if (quest!.isRestDay) {
      return Container(
        decoration: goldCardDecoration(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🛌', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'REST DAY',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.slColors.accent,
                    letterSpacing: 3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recovery is part of the grind. Your streak is safe.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final q = quest!;
    final completed = q.completedCount;
    final total = q.items.length;
    final allDone = completed == total;
    final noProgress = q.items.every((i) => i.completedAmount == 0);
    final storage = ref.read(storageServiceProvider);
    final canRestToday = noProgress && !storage.hasRestDayThisWeek();

    // Streak multiplier badge text
    final multiplierPct = ((q.streakMultiplier - 1.0) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '◆  DAILY QUEST',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.slColors.accent,
                    letterSpacing: 2,
                  ),
            ),
            const Spacer(),
            if (multiplierPct > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.slColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: context.slColors.accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '+$multiplierPct% XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.slColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '$completed / $total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!allDone) const _QuestCountdownTimer(),
        if (allDone) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: context.slColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: context.slColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              kQuestCompleteMessages[DateTime.now().millisecondsSinceEpoch %
                  kQuestCompleteMessages.length],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.slColors.accent,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Group quest items by muscle group
        ...() {
          // Build ordered list of (group, [(idx, item)]) pairs
          final grouped = <ExerciseMuscleGroup,
              List<({int idx, QuestItem item, double step})>>{};
          for (var i = 0; i < q.items.length; i++) {
            final item = q.items[i];
            final def = exerciseById(item.exerciseId);
            final group = def?.muscleGroup ?? ExerciseMuscleGroup.cardio;
            final step = def?.stepSize.toDouble() ?? 1.0;
            (grouped[group] ??= []).add((idx: i, item: item, step: step));
          }
          final widgets = <Widget>[];
          for (final group in ExerciseMuscleGroup.values) {
            final entries = grouped[group];
            if (entries == null || entries.isEmpty) continue;
            widgets.add(_QuestGroupHeader(group: group));
            for (final e in entries) {
              widgets.add(QuestItemCard(
                item: e.item,
                useImperial: useImperial,
                isPersonalRecord: prExercises.contains(e.item.exerciseId),
                onLog: (amount) => onLog(e.idx, amount),
                onUndo: () => onUndo(e.idx, e.step),
                onComplete: e.item.isCompleted
                    ? null
                    : () {
                        final remaining =
                            e.item.targetAmount - e.item.completedAmount;
                        if (remaining > 0) onLog(e.idx, remaining);
                      },
              ));
            }
          }
          return widgets;
        }(),
        // Rest Day button — visible only when no progress & no rest day this week
        if (canRestToday) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRestDay,
              icon: const Text('🛌', style: TextStyle(fontSize: 16)),
              label: const Text('TAKE REST DAY'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quest Group Header
// ---------------------------------------------------------------------------
class _QuestGroupHeader extends StatelessWidget {
  final ExerciseMuscleGroup group;
  const _QuestGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Text(muscleGroupEmoji(group), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            muscleGroupLabel(group),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.slColors.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          const Expanded(
              child: Divider(color: AppColors.cardBorder, height: 1)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quest Countdown Timer
// ---------------------------------------------------------------------------
class _QuestCountdownTimer extends StatefulWidget {
  const _QuestCountdownTimer();

  @override
  State<_QuestCountdownTimer> createState() => _QuestCountdownTimerState();
}

class _QuestCountdownTimerState extends State<_QuestCountdownTimer>
    with SingleTickerProviderStateMixin {
  late Duration _remaining;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Thresholds
  static const _criticalHours = 4;
  static const _urgentHours = 10;

  Duration _calcRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calcRemaining());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    final hours = _remaining.inHours;
    if (hours < _criticalHours) return const Color(0xFFFF1744); // red
    if (hours < _urgentHours) return const Color(0xFFFF6D00); // orange
    return const Color(0xFF4CAF50); // green
  }

  String get _label {
    final hours = _remaining.inHours;
    if (hours < _criticalHours) return '⚠  QUEST EXPIRES IN — ACT NOW';
    if (hours < _urgentHours) return '⚠  QUEST EXPIRES IN';
    return 'QUEST EXPIRES IN';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final h = _remaining.inHours.toString().padLeft(2, '0');
        final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
        final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
        final critical = _remaining.inHours < _criticalHours;
        final color = _accentColor;

        // pulse: opacity swings 0.80 → 1.0, scale swings 0.97 → 1.03
        final opacity = 0.80 + _pulseAnim.value * 0.20;
        final scale = 0.97 + _pulseAnim.value * 0.06;
        final glowBlur = critical
            ? 10.0 + _pulseAnim.value * 30.0
            : 6.0 + _pulseAnim.value * 18.0;

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    '$h:$m:$s',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      fontFeatures: [const FontFeature.tabularFigures()],
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.9),
                          blurRadius: glowBlur,
                        ),
                        Shadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: glowBlur * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Streak Card
// ---------------------------------------------------------------------------
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) {
      return Container(
        decoration: goldCardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Begin Your Journey',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Complete today\'s quest to start your streak.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bonusPct =
        ((streak * kStreakBonusPerDay).clamp(0.0, kMaxStreakBonusPct) * 100)
            .round();

    return Container(
      decoration: goldCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  streakMessage(streak),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (bonusPct > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+$bonusPct% XP bonus active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.slColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
