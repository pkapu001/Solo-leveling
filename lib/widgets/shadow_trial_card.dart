import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/weekly_challenge.dart';
import '../constants/exercises.dart';

/// Accent colour used throughout the Shadow Trial card UI.
const Color _trialColor = Color(0xFF9C27B0); // purple — "forbidden" palette
const Color _trialColorLight = Color(0xFFCE93D8);
const Color _trialGlow = Color(0x449C27B0);

BoxDecoration _trialCardDecoration({bool active = false}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? _trialColor : const Color(0xFF3A1A4A),
        width: active ? 1.5 : 1.0,
      ),
      boxShadow: active
          ? const [
              BoxShadow(
                color: _trialGlow,
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
          : null,
    );

/// The Shadow Trial card shown above daily quests when the weekly challenge is
/// active. Handles its own log dialog for large targets (mirroring QuestItemCard).
class ShadowTrialCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  final bool useImperial;

  /// Called with the amount to add (in the exercise's native unit).
  final void Function(double amount) onLog;

  /// Called to undo one step.
  final VoidCallback onUndo;

  /// Called to log the remaining amount and mark the trial complete in one tap.
  final VoidCallback? onComplete;

  const ShadowTrialCard({
    super.key,
    required this.challenge,
    required this.onLog,
    required this.onUndo,
    this.onComplete,
    this.useImperial = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = exerciseById(challenge.exerciseId);
    if (def == null) return const SizedBox.shrink();

    final isComplete = challenge.isCompleted;
    final progress = challenge.progress;
    final isDistance = def.type == ExerciseType.distance;

    final displayCompleted = (isDistance && useImperial)
        ? kmToMi(challenge.completedAmount)
        : challenge.completedAmount;
    final displayTarget = (isDistance && useImperial)
        ? kmToMi(challenge.targetAmount)
        : challenge.targetAmount;
    final displayUnit = (isDistance && useImperial) ? 'mi' : def.unit;

    final daysLeft = challenge.daysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _trialCardDecoration(active: !isComplete),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _trialColor.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF3A1A4A)),
              ),
            ),
            child: Row(
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'SHADOW TRIAL',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _trialColorLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        fontSize: 12,
                      ),
                ),
                const Spacer(),
                if (isComplete)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _trialColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: _trialColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      '✓  COMPLETE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _trialColorLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                    ),
                  )
                else
                  Text(
                    daysLeft == 0
                        ? 'Last chance today'
                        : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flavor text
                Text(
                  isComplete
                      ? 'Trial mastered. The System acknowledges your power.'
                      : 'A forbidden technique has emerged from the shadows.\nProve yourself worthy, Hunter.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 14),

                // Exercise row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  def.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: isComplete
                                            ? _trialColorLight
                                            : AppColors.textPrimary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // LOCKED badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _trialColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color:
                                          _trialColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  '🔒 LOCKED',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _trialColorLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(displayCompleted)} / ${_fmt(displayTarget)} $displayUnit  •  Challenge Mode',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          // Difficulty stars
                          Text(
                            difficultyStars(def.difficulty),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Buttons
                    if (!isComplete) ...[
                      if (challenge.completedAmount > 0)
                        IconButton(
                          onPressed: onUndo,
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.textMuted, size: 22),
                          tooltip: 'Undo',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onComplete != null)
                        IconButton(
                          onPressed: onComplete,
                          icon: const Icon(Icons.check_circle_outline,
                              color: _trialColor, size: 22),
                          tooltip: 'Mark complete',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _handleLog(context, def),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _trialColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.check_circle,
                          color: _trialColor, size: 28),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: isComplete
                                ? [
                                    _trialColor.withValues(alpha: 0.7),
                                    _trialColorLight,
                                  ]
                                : [
                                    const Color(0xFF6A0080),
                                    _trialColor,
                                  ],
                          ),
                          boxShadow: isComplete
                              ? const [
                                  BoxShadow(
                                    color: _trialGlow,
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Reward line
                Row(
                  children: [
                    const Text('✦',
                        style:
                            TextStyle(color: _trialColorLight, fontSize: 12)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isComplete
                            ? 'Bonus XP earned  •  Unlock progress granted'
                            : 'Reward: 5× XP  •  Unlock progress on completion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isComplete
                                  ? _trialColorLight
                                  : AppColors.textMuted,
                              fontSize: 11,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  void _handleLog(BuildContext context, ExerciseDefinition def) {
    onLog(dynamicStepFor(challenge.targetAmount, def));
  }
}
