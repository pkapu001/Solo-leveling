import 'package:flutter/material.dart';
import 'dart:math' show max;
import '../constants/exercises.dart';
import '../models/custom_exercise.dart';
import '../theme/app_theme.dart';

/// Shared exercise picker used in the settings "Add Exercise" dialog and the
/// onboarding selection page.
///
/// Features:
///  - Search bar filters across all groups; matching groups auto-expand.
///  - Collapsible muscle-group sections (all collapsed by default).
///  - **Single-select** mode: provide [onSelect]; tapping a row calls it.
///  - **Multi-select** mode: provide [selectedIds] + [onToggle]; rows get checkboxes.
///  - Custom exercises show a CUSTOM badge plus optional edit / delete icons.
///
/// The widget must be placed inside a parent with **bounded height** so that
/// the internal [ListView] can scroll (e.g. [Expanded] or [SizedBox] with height).
class ExercisePicker extends StatefulWidget {
  /// Built-in exercises to show (already filtered by the caller if needed).
  final List<ExerciseDefinition> available;

  /// Custom exercises shown first in each group with a CUSTOM badge.
  final List<CustomExercise> customExercises;

  // ── Multi-select ──────────────────────────────────────────────────────────
  /// Currently selected IDs. Non-null switches the UI to checkbox / multi mode.
  final Set<String>? selectedIds;

  /// Called when the user taps a row in multi-select mode.
  final void Function(ExerciseDefinition)? onToggle;

  // ── Single-select ─────────────────────────────────────────────────────────
  /// Called when the user taps a row in single-select (dialog) mode.
  final void Function(ExerciseDefinition)? onSelect;

  // ── Custom exercise management ─────────────────────────────────────────────
  final void Function(CustomExercise)? onEditCustom;
  final void Function(CustomExercise)? onDeleteCustom;

  // ── Unlock check ──────────────────────────────────────────────────────────
  /// Return false to render a locked, non-tappable tile.
  /// When null, all exercises are treated as unlocked.
  final bool Function(ExerciseDefinition)? checkUnlocked;

  /// Override the subtitle text shown on a locked tile.
  /// When null, falls back to [exerciseUnlockDescription].
  final String Function(ExerciseDefinition)? getLockedDescription;

  /// Returns the player's cumulative logged volume for a given exercise id.
  /// When provided, locked tiles show a progress bar toward the unlock threshold.
  final double Function(String exerciseId)? getVolume;

  /// Returns the bonus volume earned via Shadow Trial for a given exercise id.
  /// Keyed by TARGET exercise ID. When provided, bonus is included in the
  /// progress bar and unlock check via [exerciseUnlockProgress].
  final double Function(String exerciseId)? getBonusVolume;

  const ExercisePicker({
    super.key,
    required this.available,
    this.customExercises = const [],
    this.selectedIds,
    this.onToggle,
    this.onSelect,
    this.onEditCustom,
    this.onDeleteCustom,
    this.checkUnlocked,
    this.getLockedDescription,
    this.getVolume,
    this.getBonusVolume,
  });

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  // Explicitly expanded groups; when searching, all matching groups expand
  // automatically regardless of this set.
  final Set<ExerciseMuscleGroup> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase().trim();

    // Build per-group data, filtered by the search query.
    final groups = <_GroupData>[];
    for (final group in ExerciseMuscleGroup.values) {
      final builtIn = widget.available.where((d) {
        if (d.muscleGroup != group) return false;
        return q.isEmpty || d.name.toLowerCase().contains(q);
      }).toList()
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

      final custom = widget.customExercises.where((c) {
        final g = ExerciseMuscleGroup.values[
            c.muscleGroupIndex.clamp(0, ExerciseMuscleGroup.values.length - 1)];
        if (g != group) return false;
        return q.isEmpty || c.name.toLowerCase().contains(q);
      }).toList();

      if (builtIn.isNotEmpty || custom.isNotEmpty) {
        groups.add(_GroupData(group: group, builtIn: builtIn, custom: custom));
      }
    }

    // When there is a search query, auto-expand every group that has results.
    final effectiveExpanded =
        q.isNotEmpty ? groups.map((g) => g.group).toSet() : _expanded;

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search exercises…',
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // ── Group list ─────────────────────────────────────────────────────
        if (groups.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No exercises found.',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (_, i) => _buildGroup(
                context,
                groups[i],
                effectiveExpanded.contains(groups[i].group),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroup(BuildContext context, _GroupData g, bool isExpanded) {
    final selectedInGroup = widget.selectedIds == null
        ? 0
        : [...g.builtIn.map((d) => d.id), ...g.custom.map((c) => c.id)]
            .where((id) => widget.selectedIds!.contains(id))
            .length;
    final total = g.builtIn.length + g.custom.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header — tap to expand / collapse
        InkWell(
          onTap: () => setState(() {
            if (_expanded.contains(g.group)) {
              _expanded.remove(g.group);
            } else {
              _expanded.add(g.group);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(muscleGroupEmoji(g.group),
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  muscleGroupLabel(g.group),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.slColors.accent,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.selectedIds != null
                      ? '($selectedInGroup / $total)'
                      : '($total)',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.cardBorder, height: 1, indent: 16),
        if (isExpanded) ...[
          // Custom exercises first
          ...g.custom.map((c) => _buildCustomTile(c)),
          // Built-in exercises
          ...g.builtIn.map((d) => _buildBuiltInTile(d)),
        ],
      ],
    );
  }

  Widget _buildCustomTile(CustomExercise c) {
    final def = c.toDefinition();
    final isSelected = widget.selectedIds?.contains(def.id) ?? false;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: Text(def.emoji, style: const TextStyle(fontSize: 20)),
      title: Row(
        children: [
          Flexible(child: Text(def.name)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: context.slColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: context.slColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              'CUSTOM',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.slColors.accent,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${def.defaultTarget} ${def.unit}  ·  ${difficultyStars(def.difficulty)}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.selectedIds != null)
            Checkbox(
              value: isSelected,
              onChanged: (_) => widget.onToggle?.call(def),
              activeColor: context.slColors.accent,
            ),
          if (widget.onEditCustom != null)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onEditCustom?.call(c),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.edit_outlined,
                    size: 15, color: AppColors.textMuted),
              ),
            ),
          if (widget.onDeleteCustom != null)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onDeleteCustom?.call(c),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, size: 15, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
      onTap: () => widget.selectedIds != null
          ? widget.onToggle?.call(def)
          : widget.onSelect?.call(def),
    );
  }

  Widget _buildBuiltInTile(ExerciseDefinition d) {
    final unlocked = widget.checkUnlocked == null || widget.checkUnlocked!(d);

    if (!unlocked) {
      final desc =
          widget.getLockedDescription?.call(d) ?? exerciseUnlockDescription(d);
      // Compute unlock progress when getVolume is provided
      final progress = widget.getVolume != null
          ? exerciseUnlockProgress(d, widget.getVolume!,
              getBonusVolume: widget.getBonusVolume)
          : null;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Text('🔒', style: TextStyle(fontSize: 20)),
            title: Text(d.name,
                style: const TextStyle(color: AppColors.textMuted)),
            subtitle: Text(
              desc.isEmpty
                  ? difficultyStars(d.difficulty)
                  : '${difficultyStars(d.difficulty)}  ·  $desc',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            enabled: false,
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
              child: _UnlockProgressBar(
                fraction: progress.fraction,
                current: progress.current,
                needed: progress.needed,
                prereq: progress.prereq,
              ),
            ),
        ],
      );
    }

    final isSelected = widget.selectedIds?.contains(d.id) ?? false;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Text(d.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(d.name),
      subtitle: Text(difficultyStars(d.difficulty),
          style: const TextStyle(fontSize: 11)),
      trailing: widget.selectedIds != null
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => widget.onToggle?.call(d),
              activeColor: context.slColors.accent,
            )
          : null,
      onTap: () => widget.selectedIds != null
          ? widget.onToggle?.call(d)
          : widget.onSelect?.call(d),
    );
  }
}

class _GroupData {
  final ExerciseMuscleGroup group;
  final List<ExerciseDefinition> builtIn;
  final List<CustomExercise> custom;
  _GroupData(
      {required this.group, required this.builtIn, required this.custom});
}

/// Small progress bar shown below a locked exercise tile.
class _UnlockProgressBar extends StatelessWidget {
  final double fraction; // 0.0–1.0
  final double current;
  final double needed;
  final ExerciseDefinition prereq;

  const _UnlockProgressBar({
    required this.fraction,
    required this.current,
    required this.needed,
    required this.prereq,
  });

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).round();
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
              widthFactor: max(0.0, fraction),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      context.slColors.accentDeep.withValues(alpha: 0.6),
                      context.slColors.accent.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${_fmt(current.clamp(0, needed))} / ${_fmt(needed)} ${prereq.unit} of ${prereq.name}  ($pct%)',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }
}
