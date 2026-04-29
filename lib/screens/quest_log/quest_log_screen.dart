import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/exercises.dart';
import '../../models/daily_quest.dart';
import '../../models/quest_item.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';

class QuestLogScreen extends ConsumerStatefulWidget {
  const QuestLogScreen({super.key});

  @override
  ConsumerState<QuestLogScreen> createState() => _QuestLogScreenState();
}

class _QuestLogScreenState extends ConsumerState<QuestLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(questHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUEST LOG'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.slColors.accent,
          labelColor: context.slColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'WEEKLY XP'),
            Tab(text: 'BY EXERCISE'),
          ],
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                'No quest history yet.\nComplete your first daily quest.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1 — Weekly XP + history list
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _WeeklyXpChart(history: history),
                    const SizedBox(height: 24),
                    Text(
                      'HISTORY',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: context.slColors.accent,
                                letterSpacing: 2,
                              ),
                    ),
                    const SizedBox(height: 12),
                    ...history.map((q) => _QuestLogEntry(quest: q)),
                  ],
                ),
                // Tab 2 — Per-exercise chart
                _ExerciseHistoryTab(history: history),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly XP Bar Chart
// ---------------------------------------------------------------------------
class _WeeklyXpChart extends StatelessWidget {
  final List<DailyQuest> history;

  const _WeeklyXpChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Group quests by ISO week number (last 8 weeks)
    final Map<String, int> weeklyXp = {};
    for (final q in history) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(q.dateKey);
        final weekKey = _isoWeekKey(date);
        weeklyXp[weekKey] = (weeklyXp[weekKey] ?? 0) + q.xpEarned.round();
      } catch (_) {}
    }

    final sorted = weeklyXp.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final recent =
        sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;

    if (recent.isEmpty) return const SizedBox.shrink();

    final maxY =
        recent.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP PER WEEK',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.slColors.accent,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: goldCardDecoration(),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              backgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppColors.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= recent.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          recent[idx].key,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: recent.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value.toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          context.slColors.accentDeep,
                          context.slColors.accent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _isoWeekKey(DateTime date) {
    // ISO week: week containing Thursday of the date's week
    final thursday = date.subtract(Duration(days: date.weekday - 4));
    final jan4 = DateTime(thursday.year, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    final weekNum = ((thursday.difference(week1Monday).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Single quest log entry
// ---------------------------------------------------------------------------
class _QuestLogEntry extends StatelessWidget {
  final DailyQuest quest;

  const _QuestLogEntry({required this.quest});

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try {
      date = DateFormat('yyyy-MM-dd').parse(quest.dateKey);
    } catch (_) {}

    final dateStr = date != null
        ? DateFormat('EEE, MMM d yyyy').format(date)
        : quest.dateKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: goldCardDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Icon(
              quest.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: quest.isCompleted
                  ? context.slColors.accent
                  : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(dateStr, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${quest.xpEarned.round()} XP',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              '${quest.completedCount}/${quest.items.length} done',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        iconColor: context.slColors.accent,
        collapsedIconColor: AppColors.textMuted,
        children: quest.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  item.isCompleted ? Icons.check : Icons.close,
                  size: 16,
                  color: item.isCompleted
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.exerciseId,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fmt(item.completedAmount)} / ${_fmt(item.targetAmount)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ---------------------------------------------------------------------------
// Per-Exercise History Tab
// ---------------------------------------------------------------------------
class _ExerciseHistoryTab extends StatefulWidget {
  final List<DailyQuest> history;

  const _ExerciseHistoryTab({required this.history});

  @override
  State<_ExerciseHistoryTab> createState() => _ExerciseHistoryTabState();
}

class _ExerciseHistoryTabState extends State<_ExerciseHistoryTab> {
  String? _selectedExerciseId;

  /// Collect all exercise ids that appear in history.
  List<String> get _exerciseIds {
    final ids = <String>{};
    for (final q in widget.history) {
      for (final item in q.items) {
        ids.add(item.exerciseId);
      }
    }
    return ids.toList()..sort();
  }

  @override
  void didUpdateWidget(_ExerciseHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If history changes and the previously selected exercise is no longer
    // present, reset so the dropdown doesn't hold an invalid value.
    if (oldWidget.history != widget.history) {
      if (_selectedExerciseId != null &&
          !_exerciseIds.contains(_selectedExerciseId)) {
        _selectedExerciseId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = _exerciseIds;
    if (ids.isEmpty) {
      return const Center(child: Text('No exercise data yet.'));
    }

    _selectedExerciseId ??= ids.first;

    // Build last-14-days data for selected exercise
    final dataPoints = _buildDataPoints(_selectedExerciseId!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'BY EXERCISE',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.slColors.accent,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 12),
        // Dropdown
        Container(
          decoration: goldCardDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedExerciseId,
              dropdownColor: AppColors.surface,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textPrimary),
              isExpanded: true,
              items: ids.map((id) {
                final def = exerciseById(id);
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text('${def?.emoji ?? ''}  ${def?.name ?? id}'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedExerciseId = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (dataPoints.isEmpty)
          Container(
            decoration: goldCardDecoration(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No data for this exercise in the last 14 days.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          _ExerciseBarChart(
            dataPoints: dataPoints,
            exerciseId: _selectedExerciseId!,
          ),
      ],
    );
  }

  List<_ExerciseDataPoint> _buildDataPoints(String exerciseId) {
    final today = DateTime.now();
    final result = <_ExerciseDataPoint>[];
    for (int i = 13; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final quest =
          widget.history.firstWhere((q) => q.dateKey == key, orElse: () {
        return DailyQuest(dateKey: key, items: []);
      });
      final item = quest.items.firstWhere(
        (item) => item.exerciseId == exerciseId,
        orElse: () => QuestItem(exerciseId: exerciseId, targetAmount: 0),
      );
      result.add(_ExerciseDataPoint(
        dateKey: key,
        completed: item.completedAmount,
        target: item.targetAmount,
        label: DateFormat('M/d').format(date),
      ));
    }
    // Only keep days where target > 0 (exercise was configured that day)
    return result.where((d) => d.target > 0 || d.completed > 0).toList();
  }
}

class _ExerciseDataPoint {
  final String dateKey;
  final double completed;
  final double target;
  final String label;
  const _ExerciseDataPoint({
    required this.dateKey,
    required this.completed,
    required this.target,
    required this.label,
  });
}

class _ExerciseBarChart extends StatelessWidget {
  final List<_ExerciseDataPoint> dataPoints;
  final String exerciseId;

  const _ExerciseBarChart({
    required this.dataPoints,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context) {
    final def = exerciseById(exerciseId);
    final maxY = dataPoints
        .map((d) => d.target > d.completed ? d.target : d.completed)
        .fold(0.0, (a, b) => a > b ? a : b);
    if (maxY == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST 14 DAYS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: goldCardDecoration(),
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.25,
              backgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppColors.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= dataPoints.length) {
                        return const SizedBox.shrink();
                      }
                      // Only show every other label to avoid crowding
                      if (idx % 2 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          dataPoints[idx].label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: dataPoints.asMap().entries.map((e) {
                final d = e.value;
                final completedRatio = d.target > 0
                    ? (d.completed / d.target).clamp(0.0, 1.5)
                    : 0.0;
                final barColor = completedRatio >= 1.0
                    ? context.slColors.accent
                    : (completedRatio > 0
                        ? context.slColors.accentDark
                        : AppColors.cardBorder);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    // Target bar (background, dimmer)
                    BarChartRodData(
                      toY: d.target,
                      color: context.slColors.accentDeep.withValues(alpha: 0.3),
                      width: 14,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    // Completed bar (foreground)
                    if (d.completed > 0)
                      BarChartRodData(
                        toY: d.completed,
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _LegendDot(color: context.slColors.accentDeep.withValues(alpha: 0.3)),
          const SizedBox(width: 4),
          Text('Target',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 16),
          _LegendDot(color: context.slColors.accent),
          const SizedBox(width: 4),
          Text('Completed (${def?.unit ?? ''})',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
        ]),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
