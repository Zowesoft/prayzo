import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    // Timezone initialization for zoned scheduling (use device default)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    _initialized = true;
  }

  static NotificationDetails _defaultDetails() {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'prayoo_reminders',
      'Reminders',
      channelDescription: 'Session reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const DarwinNotificationDetails ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  /// Schedule a local notification at a specific time.
  /// If [scheduledDate] is in the past, this will show immediately.
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();
    final when = scheduledDate.isAfter(DateTime.now())
        ? scheduledDate
        : DateTime.now().add(const Duration(seconds: 1));
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      _defaultDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}
