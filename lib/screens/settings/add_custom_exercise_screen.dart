import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/exercises.dart';
import '../../constants/xp_config.dart';
import '../../models/custom_exercise.dart';
import '../../models/exercise_config.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';

class AddCustomExerciseScreen extends ConsumerStatefulWidget {
  final CustomExercise? existing;
  const AddCustomExerciseScreen({super.key, this.existing});

  @override
  ConsumerState<AddCustomExerciseScreen> createState() =>
      _AddCustomExerciseScreenState();
}

class _AddCustomExerciseScreenState
    extends ConsumerState<AddCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '10');
  final _unitCtrl = TextEditingController();

  ExerciseType _type = ExerciseType.reps;
  ExerciseMuscleGroup _muscleGroup = ExerciseMuscleGroup.push;
  String _durationUnit = 'minutes';
  bool _addToTodaysQuest = true;
  int _difficulty = 1;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _nameCtrl.text = ex.name;
      _emojiCtrl.text = ex.emoji;
      _targetCtrl.text = ex.defaultTarget.toString();
      _type = ExerciseType
          .values[ex.typeIndex.clamp(0, ExerciseType.values.length - 1)];
      _muscleGroup = ExerciseMuscleGroup.values[
          ex.muscleGroupIndex.clamp(0, ExerciseMuscleGroup.values.length - 1)];
      _difficulty = ex.difficulty.clamp(1, 5);
      if (_type == ExerciseType.duration) _durationUnit = ex.unit;
    }
  }

  /// Auto-determine step size from target: >30 → 5, ≥15 → 2, else → 1
  static int _stepFromTarget(int target) {
    if (target > 30) return 5;
    if (target >= 15) return 2;
    return 1;
  }

  int get _currentTarget => int.tryParse(_targetCtrl.text.trim()) ?? 10;
  int get _autoStep => _stepFromTarget(_currentTarget);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  String get _resolvedUnit {
    switch (_type) {
      case ExerciseType.reps:
        return 'reps';
      case ExerciseType.duration:
        return _durationUnit;
      case ExerciseType.distance:
        return 'km';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final emoji = _emojiCtrl.text.trim().isEmpty
        ? muscleGroupEmoji(_muscleGroup)
        : _emojiCtrl.text.trim();
    final target = _currentTarget;
    final step = _autoStep;
    final resolvedUnit = _resolvedUnit;
    final xpPerUnit = computeCustomXpPerUnit(
      type: _type.name,
      unit: resolvedUnit,
      difficulty: _difficulty,
    );

    if (widget.existing != null) {
      // ── Edit existing ────────────────────────────────────────────────────
      final ex = widget.existing!;
      ex.name = _nameCtrl.text.trim();
      ex.emoji = emoji;
      ex.typeIndex = ExerciseType.values.indexOf(_type);
      ex.unit = resolvedUnit;
      ex.muscleGroupIndex = ExerciseMuscleGroup.values.indexOf(_muscleGroup);
      ex.defaultTarget = target;
      ex.stepSize = step;
      ex.difficulty = _difficulty;
      ex.xpPerUnit = xpPerUnit;

      await ref.read(customExercisesProvider.notifier).update(ex);

      // Update linked ExerciseConfig target (important when type/unit changed).
      final configs = ref.read(exerciseConfigsProvider);
      final idx = configs.indexWhere((c) => c.exerciseId == ex.id);
      if (idx != -1) {
        final updated = List<ExerciseConfig>.from(configs);
        updated[idx] = ExerciseConfig(
          exerciseId: ex.id,
          targetAmount: target.toDouble(),
          scalingPct: configs[idx].scalingPct,
        );
        await ref.read(exerciseConfigsProvider.notifier).saveAll(updated);
      }
      await ref.read(dailyQuestProvider.notifier).syncToConfigs();
    } else {
      // ── Create new ───────────────────────────────────────────────────────
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final custom = CustomExercise(
        id: id,
        name: _nameCtrl.text.trim(),
        emoji: emoji,
        typeIndex: ExerciseType.values.indexOf(_type),
        unit: resolvedUnit,
        muscleGroupIndex: ExerciseMuscleGroup.values.indexOf(_muscleGroup),
        defaultTarget: target,
        stepSize: step,
        difficulty: _difficulty,
        xpPerUnit: xpPerUnit,
      );

      await ref.read(customExercisesProvider.notifier).add(custom);

      if (_addToTodaysQuest) {
        final configs = ref.read(exerciseConfigsProvider);
        final alreadyActive = configs.any((c) => c.exerciseId == id);
        if (!alreadyActive) {
          final updated = [
            ...configs,
            ExerciseConfig(exerciseId: id, targetAmount: target.toDouble()),
          ];
          await ref.read(exerciseConfigsProvider.notifier).saveAll(updated);
          ref.read(dailyQuestProvider.notifier).refresh();
        }
      }
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existing != null ? 'EDIT EXERCISE' : 'CREATE EXERCISE'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold),
                  )
                : Text(
                    widget.existing != null ? 'SAVE' : 'CREATE',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name & Emoji row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji
                SizedBox(
                  width: 72,
                  child: _FieldCard(
                    child: TextFormField(
                      controller: _emojiCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28),
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: muscleGroupEmoji(_muscleGroup),
                        hintStyle: const TextStyle(fontSize: 28),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: _FieldCard(
                    child: TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Exercise name',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name required';
                        }
                        if (v.trim().length > 40) return 'Too long (max 40)';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Type selector
            _Label(text: 'TYPE'),
            const SizedBox(height: 8),
            Row(
              children: ExerciseType.values.map((t) {
                final selected = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.slColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? context.slColors.accent
                              : AppColors.cardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _typeLabel(t),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1,
                          color: selected
                              ? context.slColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Duration unit sub-selector
            if (_type == ExerciseType.duration) ...[
              const SizedBox(height: 12),
              _Label(text: 'UNIT'),
              const SizedBox(height: 8),
              Row(
                children: ['minutes', 'seconds'].map((u) {
                  final selected = _durationUnit == u;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _durationUnit = u),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? context.slColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? context.slColors.accent
                                : AppColors.cardBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          u.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1,
                            color: selected
                                ? context.slColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Muscle group
            _Label(text: 'MUSCLE GROUP'),
            const SizedBox(height: 8),
            _FieldCard(
              child: DropdownButtonFormField<ExerciseMuscleGroup>(
                initialValue: _muscleGroup,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: ExerciseMuscleGroup.values.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Row(
                      children: [
                        Text(muscleGroupEmoji(g),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(muscleGroupLabel(g)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _muscleGroup = v);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Difficulty
            _Label(text: 'DIFFICULTY'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final level = i + 1;
                final selected = _difficulty == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _difficulty = level),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.slColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? context.slColors.accent
                              : AppColors.cardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '⭐' * level,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: level > 3 ? 9 : 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _difficultyLabel(level),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: selected
                                  ? context.slColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Target field
            _Label(text: 'DAILY TARGET'),
            const SizedBox(height: 8),
            _FieldCard(
              child: TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}), // refresh step preview
                decoration: InputDecoration(
                  hintText: '10',
                  suffixText: _resolvedUnit,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Enter a number ≥ 1';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.auto_fix_high,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Step size: $_autoStep ${_resolvedUnit}  '
                  '(auto — target ${_currentTarget > 30 ? ">30" : _currentTarget >= 15 ? "15–30" : "<15"})',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Add to today's quest toggle (create mode only)
            if (widget.existing == null) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: SwitchListTile(
                  title: const Text('Add to Today\'s Quest'),
                  subtitle: const Text(
                    'Start tracking this exercise immediately.',
                  ),
                  value: _addToTodaysQuest,
                  activeThumbColor: context.slColors.accent,
                  activeTrackColor: context.slColors.accentDark,
                  onChanged: (v) => setState(() => _addToTodaysQuest = v),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _typeLabel(ExerciseType t) {
    switch (t) {
      case ExerciseType.reps:
        return 'REPS';
      case ExerciseType.duration:
        return 'DURATION';
      case ExerciseType.distance:
        return 'DISTANCE';
    }
  }

  String _difficultyLabel(int level) {
    switch (level) {
      case 1:
        return 'EASY';
      case 2:
        return 'NORMAL';
      case 3:
        return 'HARD';
      case 4:
        return 'BRUTAL';
      case 5:
        return 'EXTREME';
      default:
        return '';
    }
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.slColors.accent,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
