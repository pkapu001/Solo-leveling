import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../theme/app_theme.dart';
import 'daily_quest_settings_screen.dart';
import 'manage_custom_exercises_screen.dart';
import 'theme_picker_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final morningTime = TimeOfDay(
      hour: player?.notificationHour ?? 7,
      minute: player?.notificationMinute ?? 0,
    );
    final eveningTime = TimeOfDay(
      hour: player?.eveningNotifHour ?? 20,
      minute: player?.eveningNotifMinute ?? 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── NOTIFICATION ─────────────────────────────────────────────────
          const _SectionHeader(title: 'NOTIFICATION'),
          Container(
            decoration: goldCardDecoration(),
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Morning Reminder'),
              subtitle: Text(
                morningTime.format(context),
                style: TextStyle(color: context.slColors.accent),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: morningTime,
                );
                if (picked != null) {
                  await _saveNotification(
                      ref: ref, isMorning: true, time: picked);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: goldCardDecoration(),
            child: ListTile(
              leading: const Icon(Icons.nights_stay_outlined),
              title: const Text('Evening Reminder'),
              subtitle: Text(
                eveningTime.format(context),
                style: TextStyle(color: context.slColors.accent),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: eveningTime,
                );
                if (picked != null) {
                  await _saveNotification(
                      ref: ref, isMorning: false, time: picked);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── WORKOUT ───────────────────────────────────────────────────────
          const _SectionHeader(title: 'WORKOUT'),
          _NavTile(
            icon: Icons.checklist_rounded,
            title: 'Edit Daily Quest',
            subtitle: 'Manage active exercises, targets & scaling',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DailyQuestSettingsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.fitness_center_outlined,
            title: 'Custom Exercises',
            subtitle: 'Create, edit or delete custom workouts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManageCustomExercisesScreen()),
            ),
          ),
          const SizedBox(height: 24),

          // ── APPEARANCE ────────────────────────────────────────────────────
          const _SectionHeader(title: 'APPEARANCE'),
          _NavTile(
            icon: Icons.palette_outlined,
            title: 'Themes',
            subtitle: 'Change the look of your system',
            comingSoon: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
            ),
          ),
          const SizedBox(height: 32),

          // ── DEBUG (visible only in debug builds) ──────────────────────────
          if (kDebugMode) ..._DebugShadowTrialTile(context: context, ref: ref),

          // ── DANGER ZONE ───────────────────────────────────────────────────
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'DANGER ZONE', color: AppColors.error),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.delete_forever_outlined,
                color: AppColors.error),
            label: const Text('RESET ALL PROGRESS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _saveNotification({
    required WidgetRef ref,
    required bool isMorning,
    required TimeOfDay time,
  }) async {
    final player = ref.read(playerProvider);
    if (player == null) return;
    if (isMorning) {
      player.notificationHour = time.hour;
      player.notificationMinute = time.minute;
    } else {
      player.eveningNotifHour = time.hour;
      player.eveningNotifMinute = time.minute;
    }
    await ref.read(storageServiceProvider).savePlayer(player);
    ref.read(playerProvider.notifier).reload();
    final notifService = ref.read(notificationServiceProvider);
    if (isMorning) {
      await notifService.scheduleDailyReminder(
          hour: time.hour, minute: time.minute);
    } else {
      await notifService.scheduleEveningReminder(
          hour: time.hour, minute: time.minute);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will delete all your XP, levels, quest history, and configuration. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(storageServiceProvider).resetAll();
      await ref.read(notificationServiceProvider).cancelAll();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color ?? context.slColors.accent,
              letterSpacing: 2,
            ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: comingSoon ? 0.45 : 1.0,
      child: Container(
        decoration: goldCardDecoration(),
        child: ListTile(
          leading: Icon(icon, color: context.slColors.accent),
          title: Row(
            children: [
              Text(title),
              if (comingSoon) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.slColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: context.slColors.accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: context.slColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ── Debug-only Shadow Trial helper ───────────────────────────────────────────

/// Shown only in `kDebugMode`. Lets you delete this week's stored challenge so
/// the next [WeeklyChallengeNotifier.reload()] re-rolls a fresh one.
List<Widget> _DebugShadowTrialTile({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return [
    const Divider(color: AppColors.cardBorder),
    const SizedBox(height: 12),
    Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A1A5A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛠  DEBUG — Shadow Trial',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFCE93D8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(storageServiceProvider)
                    .deleteThisWeeksChallenge();
                ref.read(weeklyChallengeProvider.notifier).reload();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '⚔️ Shadow Trial re-rolled — go back to Home to see it.'),
                      backgroundColor: Color(0xFF2A1A3A),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const Text('Re-roll Shadow Trial'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCE93D8),
                side: const BorderSide(color: Color(0xFF9C27B0)),
              ),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
  ];
}
