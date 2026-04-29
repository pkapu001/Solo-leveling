import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/providers.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'constants/exercises.dart';
import 'constants/xp_config.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/quest_log/quest_log_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/add_custom_exercise_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/stats/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  final storage = StorageService();
  await storage.init();
  await storage.initAchievements();

  // Populate custom exercise registry so exerciseById resolves custom IDs
  for (final custom in storage.getCustomExercises()) {
    registerCustomExercise(custom.toDefinition());
    registerCustomExerciseXp(custom.id, custom.xpPerUnit);
  }

  // Initialize notifications
  final notifService = NotificationService();
  await notifService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const SoloLevelingApp(),
    ),
  );

  // Pre-load sounds AFTER runApp so the Flutter engine is fully started.
  // AudioPlayer / Android audio HAL initialisation can deadlock when called
  // before the engine is ready, causing the app to hang on the splash screen
  // in release builds on some devices (Samsung Exynos, MediaTek, etc.).
  // SoundService._play() already guards against null players, so the app
  // works fine if a sound fires before init completes.
  unawaited(SoundService().init());
}

class SoloLevelingApp extends ConsumerStatefulWidget {
  const SoloLevelingApp({super.key});

  @override
  ConsumerState<SoloLevelingApp> createState() => _SoloLevelingAppState();
}

class _SoloLevelingAppState extends ConsumerState<SoloLevelingApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Apply weekly scaling on app launch (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scalingService = ref.read(scalingServiceProvider);
      final applied = await scalingService.applyWeeklyScalingIfDue();
      if (applied) {
        // Reload configs and refresh today's quest with new targets
        ref.read(exerciseConfigsProvider.notifier).reload();
        ref.read(dailyQuestProvider.notifier).refresh();
      }

      // Schedule (or re-schedule) notifications based on player preferences
      final player = ref.read(playerProvider);
      if (player != null) {
        final notifService = ref.read(notificationServiceProvider);
        await notifService.scheduleDailyReminder(
          hour: player.notificationHour,
          minute: player.notificationMinute,
        );
        await notifService.scheduleEveningReminder(
          hour: player.eveningNotifHour,
          minute: player.eveningNotifMinute,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-schedule notifications whenever the app returns to the foreground so
  /// that timezone changes (e.g. the user travelling) are picked up.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final player = ref.read(playerProvider);
      if (player != null) {
        final notifService = ref.read(notificationServiceProvider);
        notifService.scheduleDailyReminder(
          hour: player.notificationHour,
          minute: player.notificationMinute,
        );
        notifService.scheduleEveningReminder(
          hour: player.eveningNotifHour,
          minute: player.eveningNotifMinute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayer = ref.read(storageServiceProvider).hasPlayer;
    final themeType = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Solo Leveling Fitness',
      theme: AppTheme.forType(themeType),
      debugShowCheckedModeBanner: false,
      // Use onGenerateInitialRoutes so only ONE route is pushed on startup.
      // Using initialRoute: '/home' causes Flutter to push both '/' AND '/home',
      // which would place the OnboardingScreen below HomeScreen in the stack.
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute(
          builder: (_) =>
              hasPlayer ? const HomeScreen() : const OnboardingScreen(),
        ),
      ],
      routes: {
        '/': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
        '/quest_log': (_) => const QuestLogScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/add_custom_exercise': (_) => const AddCustomExerciseScreen(),
        '/achievements': (_) => const AchievementsScreen(),
        '/stats': (_) => const StatsScreen(),
      },
    );
  }
}
