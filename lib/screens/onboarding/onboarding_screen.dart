import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/exercises.dart';
import '../../models/exercise_config.dart';
import '../../models/player.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_picker.dart';
import '../../widgets/scaling_slider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  // Page 0: name
  final _nameCtrl = TextEditingController();

  // Page 1: fitness check
  bool _canDoPushup = false;
  bool _canDoPullup = false;

  /// Exercise IDs ability-locked based on the fitness check answers.
  Set<String> get _abilityLocked {
    final locked = <String>{};
    if (!_canDoPushup) locked.addAll(['pushups', 'wide_pushups']);
    if (!_canDoPullup) locked.add('pullups');
    return locked;
  }

  // Page 2: selected exercises + configs
  final Map<String, _ExerciseDraft> _drafts = {};

  // Page 4: notification times
  TimeOfDay _notifTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningNotifTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your hunter name to proceed.')),
      );
      return;
    }
    // Page 1 is the fitness check — always valid (yes/no question, no empty state).
    if (_page == 2 && _drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise to track.')),
      );
      return;
    }
    if (_page < 4) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _finishOnboarding();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page--);
    }
  }

  Future<void> _finishOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    final notifService = ref.read(notificationServiceProvider);

    // Save player
    final player = Player(
      name: _nameCtrl.text.trim(),
      startDate: DateTime.now(),
      notificationHour: _notifTime.hour,
      notificationMinute: _notifTime.minute,
      eveningNotifHour: _eveningNotifTime.hour,
      eveningNotifMinute: _eveningNotifTime.minute,
      abilityLocked: _abilityLocked.toList(),
    );
    await storage.savePlayer(player);

    // Save exercise configs
    final configs = _drafts.values
        .map((d) => ExerciseConfig(
              exerciseId: d.exerciseId,
              targetAmount: d.target,
              scalingPct: d.scalingPct,
            ))
        .toList();
    await storage.saveExerciseConfigs(configs);

    // Schedule notifications
    await notifService.requestPermission();
    await notifService.scheduleDailyReminder(
      hour: _notifTime.hour,
      minute: _notifTime.minute,
    );
    await notifService.scheduleEveningReminder(
      hour: _eveningNotifTime.hour,
      minute: _eveningNotifTime.minute,
    );

    // Reload providers
    ref.read(playerProvider.notifier).reload();
    ref.read(dailyQuestProvider.notifier).refresh();
    ref.read(exerciseConfigsProvider.notifier).reload();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NamePage(controller: _nameCtrl),
                  _FitnessCheckPage(
                    canDoPushup: _canDoPushup,
                    canDoPullup: _canDoPullup,
                    onChanged: (pushup, pullup) => setState(() {
                      _canDoPushup = pushup;
                      _canDoPullup = pullup;
                      // Remove any now-locked exercises from the drafts so they
                      // don't silently carry over if the user changes their answer.
                      for (final id in _abilityLocked) {
                        _drafts.remove(id);
                      }
                    }),
                  ),
                  _ExercisePage(
                    drafts: _drafts,
                    abilityLocked: _abilityLocked,
                    onChanged: () => setState(() {}),
                  ),
                  _ConfigPage(
                    drafts: _drafts,
                    onChanged: () => setState(() {}),
                  ),
                  _NotifPage(
                    morningTime: _notifTime,
                    eveningTime: _eveningNotifTime,
                    onMorningChanged: (t) => setState(() => _notifTime = t),
                    onEveningChanged: (t) =>
                        setState(() => _eveningNotifTime = t),
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titles = [
      'Your Identity',
      'Fitness Check',
      'Choose Exercises',
      'Set Targets',
      'Notification Time'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM INITIALIZATION',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.slColors.accent,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            titles[_page],
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          // Step indicators
          Row(
            children: List.generate(5, (i) {
              final active = i == _page;
              final done = i < _page;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: done
                        ? context.slColors.accentDark
                        : active
                            ? context.slColors.accent
                            : AppColors.cardBorder,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: context.slColors.accentGlow,
                                blurRadius: 8)
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_page > 0) ...[
                OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: const Text('BACK'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_page == 4 ? 'BEGIN YOUR JOURNEY' : 'NEXT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Name
// ---------------------------------------------------------------------------
class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your name, Hunter?',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Hunter Name',
              prefixIcon:
                  Icon(Icons.person_outline, color: context.slColors.accent),
            ),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"Everyone who crossed through the Gate came back as a Hunter."\n— The System',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Fitness check
// ---------------------------------------------------------------------------
class _FitnessCheckPage extends StatelessWidget {
  final bool canDoPushup;
  final bool canDoPullup;
  final void Function(bool pushup, bool pullup) onChanged;

  const _FitnessCheckPage({
    required this.canDoPushup,
    required this.canDoPullup,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Be honest — the System adapts to your level.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        _AbilityCard(
          emoji: '💪',
          question: 'Can you do a push-up?',
          hint: 'A full push-up from the floor with good form.',
          value: canDoPushup,
          onChanged: (v) => onChanged(v, canDoPullup),
        ),
        const SizedBox(height: 16),
        _AbilityCard(
          emoji: '🏋️',
          question: 'Can you do a pull-up?',
          hint: 'Hanging from a bar and pulling your chin above it.',
          value: canDoPullup,
          onChanged: (v) => onChanged(canDoPushup, v),
        ),
        const SizedBox(height: 24),
        Text(
          'Exercises you cannot do yet will unlock automatically once you\'ve built enough strength with the beginner alternatives.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _AbilityCard extends StatelessWidget {
  final String emoji;
  final String question;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AbilityCard({
    required this.emoji,
    required this.question,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: value
          ? goldGlowDecoration(context, borderRadius: 12)
          : goldCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'Yes',
                  selected: value,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceChip(
                  label: 'No',
                  selected: !value,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? context.slColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? context.slColors.accent : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color:
                  selected ? context.slColors.accent : AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Exercise selection
// ---------------------------------------------------------------------------
class _ExerciseDraft {
  final String exerciseId;
  double target;
  double scalingPct = 5.0;

  _ExerciseDraft({
    required this.exerciseId,
    required this.target,
  });
}

class _ExercisePage extends StatelessWidget {
  final Map<String, _ExerciseDraft> drafts;
  final Set<String> abilityLocked;
  final VoidCallback onChanged;

  const _ExercisePage({
    required this.drafts,
    required this.abilityLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            'Choose the exercises you want to track each day.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ExercisePicker(
            available: kExerciseLibrary,
            selectedIds: drafts.keys.toSet(),
            onToggle: (def) {
              if (drafts.containsKey(def.id)) {
                drafts.remove(def.id);
              } else {
                drafts[def.id] = _ExerciseDraft(
                  exerciseId: def.id,
                  target: def.defaultTarget.toDouble(),
                );
              }
              onChanged();
            },
            checkUnlocked: (d) =>
                !abilityLocked.contains(d.id) &&
                isExerciseUnlocked(d, (_) => 0.0),
            getLockedDescription: (d) => abilityLocked.contains(d.id)
                ? exerciseAbilityLockedDescription(d)
                : exerciseUnlockDescription(d),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Configure targets for selected exercises
// ---------------------------------------------------------------------------
class _ConfigPage extends StatelessWidget {
  final Map<String, _ExerciseDraft> drafts;
  final VoidCallback onChanged;

  const _ConfigPage({required this.drafts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected =
        kExerciseLibrary.where((d) => drafts.containsKey(d.id)).toList();
    if (selected.isEmpty) {
      return Center(
        child: Text(
          'No exercises selected.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          'Set your starting target and weekly growth rate for each exercise.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...selected.map((def) {
          final draft = drafts[def.id]!;
          return _ConfigTile(
            def: def,
            draft: draft,
            onTargetChanged: (val) {
              draft.target = val;
              onChanged();
            },
            onScalingChanged: (val) {
              draft.scalingPct = val;
              onChanged();
            },
          );
        }),
      ],
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final ExerciseDefinition def;
  final _ExerciseDraft draft;
  final ValueChanged<double> onTargetChanged;
  final ValueChanged<double> onScalingChanged;

  const _ConfigTile({
    required this.def,
    required this.draft,
    required this.onTargetChanged,
    required this.onScalingChanged,
  });

  /// Preview how many units will be added next week.
  String _nextIncrementPreview(
      double target, double scalingPct, ExerciseDefinition def) {
    final isDistance = def.type == ExerciseType.distance;
    final delta = target * scalingPct / 100;
    double inc;
    if (isDistance) {
      inc =
          (delta < 0.1 && target >= 1) ? 0.1 : (delta * 10).ceilToDouble() / 10;
    } else {
      inc = (delta < 1 && target >= 1) ? 1.0 : delta.ceilToDouble();
    }
    return (isDistance && inc != inc.truncateToDouble())
        ? inc.toStringAsFixed(1)
        : inc.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: goldCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(def.name, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Daily Target',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              _DistanceTargetInput(
                value: draft.target,
                unit: def.unit,
                min: def.minTarget.toDouble(),
                max: def.maxTarget.toDouble(),
                allowDecimal:
                    def.type == ExerciseType.distance || def.unit == 'minutes',
                onChanged: onTargetChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 8),
          ScalingSlider(
            value: draft.scalingPct,
            suffixText:
                '(+${_nextIncrementPreview(draft.target, draft.scalingPct, def)} ${def.unit})',
            onChanged: onScalingChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline distance target input (decimal text field)
// ---------------------------------------------------------------------------
class _DistanceTargetInput extends StatefulWidget {
  final double value;
  final String unit;
  final double min;
  final double? max;
  final bool allowDecimal;
  final ValueChanged<double> onChanged;

  const _DistanceTargetInput({
    required this.value,
    required this.unit,
    required this.min,
    this.max,
    this.allowDecimal = true,
    required this.onChanged,
  });

  @override
  State<_DistanceTargetInput> createState() => _DistanceTargetInputState();
}

class _DistanceTargetInputState extends State<_DistanceTargetInput> {
  late final TextEditingController _ctrl;

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(_DistanceTargetInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the controller text when the value is changed programmatically
    // (e.g. parent resets or clamps the value externally).
    if (oldWidget.value != widget.value) {
      final formatted = _fmt(widget.value);
      if (_ctrl.text != formatted) {
        _ctrl.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: widget.allowDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: [
                widget.allowDecimal
                    ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    : FilteringTextInputFormatter.digitsOnly,
              ],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.slColors.accent,
                    fontFamily: 'Rajdhani',
                  ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: context.slColors.accent),
                ),
              ),
              onChanged: (s) {
                final v = double.tryParse(s);
                if (v == null) return;
                if (v < widget.min) return;
                if (widget.max != null && v > widget.max!) return;
                widget.onChanged(v);
              },
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.unit,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Notification time
// ---------------------------------------------------------------------------
class _NotifPage extends StatelessWidget {
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;
  final ValueChanged<TimeOfDay> onMorningChanged;
  final ValueChanged<TimeOfDay> onEveningChanged;

  const _NotifPage({
    required this.morningTime,
    required this.eveningTime,
    required this.onMorningChanged,
    required this.onEveningChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Set the times the System will contact you.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        // Morning
        Text(
          'MORNING SUMMONS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.slColors.accent,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: morningTime,
                builder: (ctx, child) =>
                    Theme(data: Theme.of(ctx), child: child!),
              );
              if (picked != null) onMorningChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: goldGlowDecoration(context, borderRadius: 16),
              child: Column(
                children: [
                  Text(
                    morningTime.format(context),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: context.slColors.accent),
                  ),
                  const SizedBox(height: 6),
                  Text('Tap to change',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Evening
        Text(
          'EVENING ALERT',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.slColors.accent,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fires if you still have incomplete quests.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: eveningTime,
                builder: (ctx, child) =>
                    Theme(data: Theme.of(ctx), child: child!),
              );
              if (picked != null) onEveningChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: goldCardDecoration(),
              child: Column(
                children: [
                  Text(
                    eveningTime.format(context),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text('Tap to change',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '"Arise." — The System will summon you at the morning time, and warn you in the evening if quests remain.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }
}
