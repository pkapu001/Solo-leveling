import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/flavor_text.dart';

class NotificationService {
  static const int _dailyQuestNotifId = 1001;
  static const int _eveningNotifId = 1002;
  static const String _channelId = 'daily_quest';
  static const String _channelName = 'Daily Quest';
  static const String _channelDesc = 'Daily quest reminders from the System.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);
  }

  /// Always returns the device's current timezone, even after the user travels.
  Future<tz.Location> _currentLocation() async {
    final tzName = await FlutterTimezone.getLocalTimezone();
    return tz.getLocation(tzName);
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule (or re-schedule) the daily quest notification.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_dailyQuestNotifId);

    final location = await _currentLocation();
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's time already passed, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    try {
      await _plugin.zonedSchedule(
        _dailyQuestNotifId,
        'Daily Quest',
        randomMorningNotification(),
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException {
      // Exact alarm permission not granted on Android 12+; use inexact fallback.
      await _plugin.zonedSchedule(
        _dailyQuestNotifId,
        'Daily Quest',
        randomMorningNotification(),
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Schedule (or re-schedule) the evening incomplete-quest notification.
  /// Pass [skipToday] = true when the user just completed all quests for today.
  Future<void> scheduleEveningReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {
    await _plugin.cancel(_eveningNotifId);

    final location = await _currentLocation();
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now) || skipToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    try {
      await _plugin.zonedSchedule(
        _eveningNotifId,
        'Quests Incomplete, Hunter',
        randomEveningNotification(),
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException {
      // Exact alarm permission not granted on Android 12+; use inexact fallback.
      await _plugin.zonedSchedule(
        _eveningNotifId,
        'Quests Incomplete, Hunter',
        randomEveningNotification(),
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelEveningReminder() async => _plugin.cancel(_eveningNotifId);

  Future<void> cancelAll() async => _plugin.cancelAll();
}
