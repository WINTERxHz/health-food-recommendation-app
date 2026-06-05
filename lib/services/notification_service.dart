import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification IDs
  static const int _breakfastId = 1;
  static const int _lunchId = 2;
  static const int _dinnerId = 3;
  static const int _waterId = 4;

  // ✅ INIT
  Future<void> init() async {
    tz.initializeTimeZones();

    // 🔥 ต้องเพิ่มตรงนี้
    final location = tz.getLocation('Asia/Bangkok');
    tz.setLocalLocation(location);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    await requestPermission();
  }

  // ✅ ขอ permission (สำคัญมาก Android 13+)
  Future<void> requestPermission() async {
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  // ── ตั้ง reminder ทุกวัน ─────────────────────
  Future<void> scheduleMealReminders() async {
    await _scheduleDailyNotification(
      id: _breakfastId,
      title: "🌅 Breakfast time!",
      body: "Don't forget to log your breakfast.",
      hour: 8,
      minute: 0,
    );

    await _scheduleDailyNotification(
      id: _lunchId,
      title: "☀️ Lunch time!",
      body: "Log your lunch to track your nutrition.",
      hour: 12,
      minute: 0,
    );

    await _scheduleDailyNotification(
      id: _dinnerId,
      title: "🌙 Dinner time!",
      body: "Log your dinner before the day ends.",
      hour: 18,
      minute: 30,
    );

    await _scheduleDailyNotification(
      id: _waterId,
      title: "💧 Stay hydrated!",
      body: "Remember to drink water.",
      hour: 17,
      minute: 15,
    );
  }

  // ── Core Scheduler ─────────────────────
  // ── Core Scheduler ─────────────────────
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // ถ้าเวลาวันนี้ผ่านแล้ว → ไปวันพรุ่งนี้
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_channel',
          'Meal Reminder',
          channelDescription: 'Daily meal reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // เหลือแค่นี้พอครับ (ลบ uiLocalNotificationDateInterpretation ทิ้งไปเลย)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// ❌ ยกเลิกทั้งหมด
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  /// 🔥 ยิง notification ทันที (เอาไว้ test)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Instant Notification',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
