import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../nest/nest_logic.dart';

class NestNotify {
  NestNotify._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static var enabled = false;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    _useDeviceOffset();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    enabled = true;
  }

  static void _useDeviceOffset() {
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }

  static Future<void> sync(List<NestItem> items) async {
    if (!enabled) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    var id = 1;
    for (final item in items) {
      id = await _schedule(id, item.name, 'Time to check ${item.name}.', item.maintainOn, now);
      if (id > 40) return;
      id = await _schedule(id, item.name, 'Warranty ends for ${item.name}.', item.warrantyUntil, now);
      if (id > 40) return;
    }
  }

  static Future<int> _schedule(int id, String title, String body, DateTime? when, DateTime now) async {
    if (when == null) return id;
    final morning = DateTime(when.year, when.month, when.day, 9);
    if (!morning.isAfter(now)) return id;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(morning, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care',
          'Care reminders',
          channelDescription: 'A reminder to maintain or replace an item',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    return id + 1;
  }
}
