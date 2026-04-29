import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/achievements.dart';
import '../../models/achievement.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import 'dart:math' show min;

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final total = kAchievementDefinitions.length;

    // Build a map for quick lookup
    final achievementMap = {for (final a in achievements) a.id: a};

    // Compute progress for locked achievements
    final player = ref.watch(playerProvider);
    final progressMap = player != null
        ? ref.read(achievementServiceProvider).computeProgress(player)
        : <String, ({double current, double max, String unit})>{};

    return Scaffold(
      appBar: AppBar(title: const Text('ACHIEVEMENTS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, unlockedCount, total),
          const SizedBox(height: 24),
          ...AchievementCategory.values.map((cat) {
            final defs = kAchievementDefinitions
                .where((d) => d.category == cat)
                .toList();
            return _CategorySection(
              category: cat,
              definitions: defs,
              achievementMap: achievementMap,
              progressMap: progressMap,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final pct = total > 0 ? unlocked / total : 0.0;
    return Container(
      decoration: goldGlowDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '◆  HUNTER ACHIEVEMENTS',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: context.slColors.accent,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              context.slColors.accentDeep,
                              context.slColors.accent
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: context.slColors.accentGlow,
                                blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$unlocked / $total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.slColors.accent,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementDefinition> definitions;
  final Map<String, Achievement?> achievementMap;
  final Map<String, ({double current, double max, String unit})> progressMap;

  const _CategorySection({
    required this.category,
    required this.definitions,
    required this.achievementMap,
    required this.progressMap,
  });

  String _categoryLabel(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.quests:
        return 'QUESTS';
      case AchievementCategory.streak:
        return 'STREAK';
      case AchievementCategory.rank:
        return 'RANK';
      case AchievementCategory.xp:
        return 'XP';
      case AchievementCategory.exercise:
        return 'EXERCISE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _categoryLabel(category),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.slColors.accent,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 8),
        if (category == AchievementCategory.exercise)
          ..._buildExerciseGroups(context)
        else
          ...definitions.map((def) {
            final achievement = achievementMap[def.id];
            final unlocked = achievement?.isUnlocked ?? false;
            return _AchievementTile(
              def: def,
              unlocked: unlocked,
              unlockedAt: achievement?.unlockedAt,
              progress: unlocked ? null : progressMap[def.id],
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildExerciseGroups(BuildContext context) {
    // Group definitions by exerciseId, preserving insertion order.
    final groups = <String, List<AchievementDefinition>>{};
    for (final def in definitions) {
      (groups[def.exerciseId ?? ''] ??= []).add(def);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final first = entry.value.first;
      // Sub-header per exercise
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Row(children: [
          Text(first.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            _formatExerciseId(entry.key),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
          ),
        ]),
      ));
      for (final def in entry.value) {
        final achievement = achievementMap[def.id];
        final unlocked = achievement?.isUnlocked ?? false;
        widgets.add(_AchievementTile(
          def: def,
          unlocked: unlocked,
          unlockedAt: achievement?.unlockedAt,
          progress: unlocked ? null : progressMap[def.id],
        ));
      }
    }
    return widgets;
  }

  String _formatExerciseId(String id) => id
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _AchievementTile extends StatelessWidget {
  final AchievementDefinition def;
  final bool unlocked;
  final DateTime? unlockedAt;
  final ({double current, double max, String unit})? progress;

  const _AchievementTile({
    required this.def,
    required this.unlocked,
    this.unlockedAt,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: unlocked ? goldGlowDecoration(context) : goldCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Emoji — hidden (?) when locked
          Text(
            unlocked ? def.emoji : '?',
            style: TextStyle(
              fontSize: 28,
              color: unlocked ? null : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked ? def.title : '???',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                ),
                Text(
                  // Always show the condition so players know what to aim for
                  def.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: unlocked ? null : FontStyle.italic,
                      ),
                ),
                if (!unlocked && progress != null) ...[
                  const SizedBox(height: 6),
                  _buildProgressBar(context, progress!)
                ],
                if (unlocked && unlockedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unlocked ${DateFormat('MMM d, yyyy').format(unlockedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.slColors.accent,
                          fontSize: 10,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.check_circle,
                    color: context.slColors.accent, size: 22),
                if (def.xpReward > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${def.xpReward} XP',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.slColors.accent,
                    ),
                  ),
                ],
              ],
            )
          else if (def.xpReward > 0)
            Text(
              '+${def.xpReward} XP',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, ({double current, double max, String unit}) p) {
    final fraction = p.max > 0 ? (p.current / p.max).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).round();

    String fmtNum(double v) {
      if (v >= 1000) return NumberFormat('#,##0', 'en_US').format(v.round());
      if (v == v.truncateToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      context.slColors.accentDeep.withValues(alpha: 0.7),
                      context.slColors.accent.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${fmtNum(min(p.current, p.max))} / ${fmtNum(p.max)} ${p.unit}  ($pct%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
