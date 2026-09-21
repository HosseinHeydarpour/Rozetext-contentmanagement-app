import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/post.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Request Android 13+ permission
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }
  }

  /// Schedule a local notification for an upcoming post
  static Future<void> schedulePostReminder(Post post) async {
    if (post.isPosted) return;
    if (post.scheduledDate.isBefore(DateTime.now())) return;

    final id = post.id.hashCode;

    final scheduledTz = tz.TZDateTime.from(post.scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'post_reminders_channel',
      'یادآور پست‌های اینستاگرام',
      channelDescription: 'اعلان زمان انتشار پست‌های برنامه‌ریزی شده',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        '⏰ زمان انتشار در اینستاگرام',
        'پست: ${post.title} (برای کپی کپشن و دریافت ویدیو کلیک کنید)',
        scheduledTz,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Fallback if exact alarm permissions not allowed
    }
  }

  /// Cancel reminder for a post
  static Future<void> cancelReminder(Post post) async {
    await _plugin.cancel(post.id.hashCode);
  }
}
