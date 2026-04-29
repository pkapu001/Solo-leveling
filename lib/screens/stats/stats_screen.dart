import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/xp_config.dart';
import '../../constants/exercises.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/level_badge.dart';
import '../../widgets/rank_title.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    if (player == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final history = ref.watch(questHistoryProvider);
    final lifetimeTotals = ref.watch(lifetimeExerciseTotalsProvider);
    final achievements = ref.watch(achievementsProvider);
    final level = levelFromXp(player.totalXp);
    final rank = rankForLevel(level);

    final daysActive = history.length;
    final daysSinceStart =
        DateTime.now().difference(player.startDate).inDays + 1;
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('HUNTER STATS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rank-colored hero header
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: rank.color.withValues(alpha: 0.6), width: 1),
              color: rank.color.withValues(alpha: 0.07),
              boxShadow: [
                BoxShadow(
                    color: rank.color.withValues(alpha: 0.25), blurRadius: 20),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                LevelBadge(level: level, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(overflow: TextOverflow.ellipsis),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      RankTitle(level: level),
                      const SizedBox(height: 4),
                      Text(
                        'Hunter since ${DateFormat('MMM d, yyyy').format(player.startDate)}',
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
          ),
          const SizedBox(height: 24),

          // Core stats grid
          _SectionLabel(title: 'OVERVIEW'),
          const SizedBox(height: 8),
          _StatsGrid(stats: [
            _StatItem(label: 'Level', value: level.toString(), icon: '⚡'),
            _StatItem(
                label: 'Total XP',
                value: _fmtInt(player.totalXp.round()),
                icon: '✨'),
            _StatItem(
                label: 'Current Streak',
                value: '${player.streakDays}d',
                icon: '🔥'),
            _StatItem(
                label: 'Longest Streak',
                value: '${player.longestStreak}d',
                icon: '🏅'),
            _StatItem(
                label: 'Days Active', value: daysActive.toString(), icon: '📅'),
            _StatItem(
                label: 'Days Since Start',
                value: daysSinceStart.toString(),
                icon: '🗓️'),
            _StatItem(
                label: 'Achievements',
                value: '$unlockedAchievements / ${achievements.length}',
                icon: '🏆'),
            _StatItem(
                label: 'XP to Next Level',
                value: _fmtInt(xpNeededForNextLevel(level) -
                    xpInCurrentLevel(player.totalXp)),
                icon: '📈'),
          ]),
          const SizedBox(height: 24),

          // Lifetime exercise totals
          if (lifetimeTotals.isNotEmpty) ...[
            _SectionLabel(title: 'LIFETIME TOTALS'),
            const SizedBox(height: 8),
            ...lifetimeTotals.entries.map((entry) {
              final def = exerciseById(entry.key);
              if (def == null) return const SizedBox.shrink();
              final displayValue =
                  (def.type == ExerciseType.distance && player.useImperial)
                      ? kmToMi(entry.value)
                      : entry.value;
              final unit =
                  (def.type == ExerciseType.distance && player.useImperial)
                      ? 'mi'
                      : def.unit;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: goldCardDecoration(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(def.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(def.name,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Text(
                      '${_fmtDouble(displayValue)} $unit',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: context.slColors.accent),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String _fmtInt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  static String _fmtDouble(double v) {
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.slColors.accent,
            letterSpacing: 2,
          ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust aspect ratio for narrow screens (< 360 dp)
        final ratio = constraints.maxWidth < 360 ? 1.8 : 2.2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) {
            final s = stats[i];
            return Container(
              decoration: goldCardDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(s.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.label,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.slColors.accent,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
