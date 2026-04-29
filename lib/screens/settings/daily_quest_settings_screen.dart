import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/exercises.dart';
import '../../models/custom_exercise.dart';
import '../../models/exercise_config.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_config_tile.dart';
import '../../widgets/exercise_picker.dart';
import '../../widgets/scaling_slider.dart';
import 'add_custom_exercise_screen.dart';

/// Lets the user configure their daily quest:
///   - Add / remove exercises (built-in or custom)
///   - Adjust target amounts and weekly scaling per exercise
///   - Toggle imperial / metric display
class DailyQuestSettingsScreen extends ConsumerStatefulWidget {
  const DailyQuestSettingsScreen({super.key});

  @override
  ConsumerState<DailyQuestSettingsScreen> createState() =>
      _DailyQuestSettingsScreenState();
}

class _DailyQuestSettingsScreenState
    extends ConsumerState<DailyQuestSettingsScreen> {
  late List<ExerciseConfig> _configs;
  late bool _useImperial;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _useImperial = ref.read(playerProvider)?.useImperial ?? false;
  }

  void _reload() {
    _configs =
        List.from(ref.read(exerciseConfigsProvider).map((c) => ExerciseConfig(
              exerciseId: c.exerciseId,
              targetAmount: c.targetAmount,
              scalingPct: c.scalingPct.clamp(kScalingMin, kScalingMax),
            )));
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final storage = ref.read(storageServiceProvider);
    await ref.read(exerciseConfigsProvider.notifier).saveAll(_configs);

    final player = ref.read(playerProvider);
    if (player != null) {
      player.useImperial = _useImperial;
      await storage.savePlayer(player);
      ref.read(playerProvider.notifier).reload();
    }

    await ref.read(dailyQuestProvider.notifier).syncToConfigs();

    setState(() {
      _dirty = false;
      _saving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily quest updated.')),
      );
    }
  }

  Future<void> _openEditCustomExercise(CustomExercise c) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCustomExerciseScreen(existing: c)),
    );
    if (edited == true && mounted) {
      setState(() {
        _reload();
        _dirty = true;
      });
    }
  }

  Future<void> _openCreateCustomExercise() async {
    final created = await Navigator.pushNamed(context, '/add_custom_exercise');
    if (created == true && mounted) {
      setState(() {
        _reload();
        _dirty = true;
      });
    }
  }

  Future<void> _showAddExerciseDialog() async {
    final already = _configs.map((c) => c.exerciseId).toSet();
    final available =
        kExerciseLibrary.where((d) => !already.contains(d.id)).toList();
    final dialogCustom = ref
        .read(customExercisesProvider)
        .where((c) => !already.contains(c.id))
        .toList();

    if (available.isEmpty && dialogCustom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All exercises already added.')));
      return;
    }

    final player = ref.read(playerProvider);
    final lifetimeTotals = ref.read(lifetimeExerciseTotalsProvider);
    // Read directly from the player object (already kept fresh by
    // playerProvider.notifier.reload()) rather than exerciseBonusVolumeProvider,
    // which can hold a stale cached value until the provider is re-evaluated.
    final bonusVolume = player?.exerciseBonusVolume ?? {};

    final chosen = await showDialog<ExerciseDefinition>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Exercise'),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: ExercisePicker(
              available: available,
              customExercises: dialogCustom,
              onSelect: (def) => Navigator.pop(ctx, def),
              onEditCustom: (c) {
                Navigator.pop(ctx);
                _openEditCustomExercise(c);
              },
              onDeleteCustom: (c) async {
                setDialogState(() => dialogCustom.remove(c));
                await ref.read(customExercisesProvider.notifier).delete(c.id);
                if (_configs.any((cfg) => cfg.exerciseId == c.id)) {
                  setState(() {
                    _configs.removeWhere((cfg) => cfg.exerciseId == c.id);
                    _dirty = true;
                  });
                }
              },
              checkUnlocked: (d) {
                // If the player ability-locked this exercise during onboarding,
                // apply the volume-based unlock gate against the D-1 prerequisite.
                final getVolume = (String id) => lifetimeTotals[id] ?? 0.0;
                final getBonusVolume = (String id) => bonusVolume[id] ?? 0.0;
                if (player != null && player.abilityLocked.contains(d.id)) {
                  return isAbilityExerciseUnlocked(d, getVolume);
                }
                return isExerciseUnlocked(d, getVolume,
                    getBonusVolume: getBonusVolume);
              },
              getLockedDescription: (d) {
                if (player != null && player.abilityLocked.contains(d.id)) {
                  return exerciseAbilityLockedDescription(d);
                }
                return exerciseUnlockDescription(d);
              },
              getVolume: (id) => lifetimeTotals[id] ?? 0.0,
              getBonusVolume: (id) => bonusVolume[id] ?? 0.0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );

    if (chosen != null) {
      setState(() {
        _configs.add(ExerciseConfig(
          exerciseId: chosen.id,
          targetAmount: chosen.defaultTarget.toDouble(),
        ));
        _dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY QUEST'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.slColors.accent),
                    )
                  : Text(
                      'SAVE',
                      style: TextStyle(
                        color: context.slColors.accent,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Imperial toggle
          Container(
            decoration: goldCardDecoration(),
            child: SwitchListTile(
              title: const Text('Use Miles (Imperial)'),
              subtitle:
                  const Text('Show running & cycling distances in miles.'),
              value: _useImperial,
              activeThumbColor: context.slColors.accent,
              activeTrackColor: context.slColors.accentDark,
              onChanged: (v) => setState(() {
                _useImperial = v;
                _dirty = true;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Active exercises
          if (_configs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No exercises yet. Add one below.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._configs.asMap().entries.map((entry) {
              final idx = entry.key;
              final cfg = entry.value;
              final isCustom = cfg.exerciseId.startsWith('custom_');
              return ExerciseConfigTile(
                config: cfg,
                useImperial: _useImperial,
                onChanged: (updated) => setState(() {
                  _configs[idx] = updated;
                  _dirty = true;
                }),
                onRemove: () => setState(() {
                  _configs.removeAt(idx);
                  _dirty = true;
                }),
                onEdit: isCustom
                    ? () {
                        final custom = ref
                            .read(customExercisesProvider)
                            .firstWhere((c) => c.id == cfg.exerciseId);
                        _openEditCustomExercise(custom);
                      }
                    : null,
              );
            }),

          // Add buttons
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddExerciseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD EXERCISE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCreateCustomExercise,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('CREATE CUSTOM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.slColors.accent,
                    side: BorderSide(color: context.slColors.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
