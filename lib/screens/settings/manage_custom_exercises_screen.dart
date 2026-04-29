import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/exercises.dart';
import '../../models/custom_exercise.dart';
import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import 'add_custom_exercise_screen.dart';

/// Lists all user-created custom exercises. From here the user can:
///   - Create a new custom exercise
///   - Edit an existing one
///   - Delete one
class ManageCustomExercisesScreen extends ConsumerWidget {
  const ManageCustomExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customs = ref.watch(customExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CUSTOM EXERCISES')),
      body: customs.isEmpty
          ? _buildEmpty(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _CustomExerciseCard(exercise: customs[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_custom_exercise'),
        backgroundColor: context.slColors.accent,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text(
          'CREATE',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No custom exercises yet.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap CREATE to build your own workout.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomExerciseCard extends ConsumerWidget {
  final CustomExercise exercise;
  const _CustomExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ExerciseMuscleGroup.values[exercise.muscleGroupIndex
        .clamp(0, ExerciseMuscleGroup.values.length - 1)];
    final type = ExerciseType
        .values[exercise.typeIndex.clamp(0, ExerciseType.values.length - 1)];
    final typeLabel = switch (type) {
      ExerciseType.reps => 'Reps',
      ExerciseType.duration => 'Duration',
      ExerciseType.distance => 'Distance',
    };

    return Container(
      decoration: goldCardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          // Emoji
          Text(exercise.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      muscleGroupEmoji(group),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      muscleGroupLabel(group),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.slColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· $typeLabel · ${exercise.defaultTarget} ${exercise.unit}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  difficultyStars(exercise.difficulty),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textMuted),
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddCustomExerciseScreen(existing: exercise),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.textMuted),
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Exercise?'),
        content: Text(
          'Delete "${exercise.name}"? It will also be removed from your daily quest.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(customExercisesProvider.notifier).delete(exercise.id);
      // Also remove from active configs if present
      final configs = ref.read(exerciseConfigsProvider);
      if (configs.any((c) => c.exerciseId == exercise.id)) {
        final updated =
            configs.where((c) => c.exerciseId != exercise.id).toList();
        await ref.read(exerciseConfigsProvider.notifier).saveAll(updated);
        await ref.read(dailyQuestProvider.notifier).syncToConfigs();
      }
    }
  }
}
