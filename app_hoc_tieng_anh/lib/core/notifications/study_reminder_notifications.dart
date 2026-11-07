import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class StudyReminderSchedule {
  const StudyReminderSchedule({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
  });

  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> weekdays;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get daysLabel {
    if (weekdays.length == 7) return 'mỗi ngày';
    if (weekdays.length == 5 && weekdays.containsAll({1, 2, 3, 4, 5})) {
      return 'thứ 2–thứ 6';
    }
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdays.map((day) => labels[day - 1]).join(', ');
  }
}

class StudyReminderNotifications {
  StudyReminderNotifications._();

  static final instance = StudyReminderNotifications._();
  static const _enabledKey = 'study_reminder_enabled';
  static const _hourKey = 'study_reminder_hour';
  static const _minuteKey = 'study_reminder_minute';
  static const _weekdaysKey = 'study_reminder_weekdays';
  static const _notificationIdBase = 7300;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 4),
      );
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        )
        .timeout(const Duration(seconds: 6));
  }

  Future<StudyReminderSchedule> loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyReminderSchedule(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 20,
      minute: prefs.getInt(_minuteKey) ?? 0,
      weekdays:
          (prefs.getStringList(_weekdaysKey) ??
                  const ['1', '2', '3', '4', '5', '6', '7'])
              .map(int.parse)
              .toSet(),
    );
  }

  Future<bool> saveSchedule(StudyReminderSchedule schedule) async {
    await initialize();
    if (schedule.enabled && !await _requestPermission()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, schedule.enabled);
    await prefs.setInt(_hourKey, schedule.hour);
    await prefs.setInt(_minuteKey, schedule.minute);
    await prefs.setStringList(
      _weekdaysKey,
      schedule.weekdays.map((day) => day.toString()).toList()..sort(),
    );

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final id = _notificationIdBase + weekday;
      await _plugin.cancel(id: id);
      if (!schedule.enabled || !schedule.weekdays.contains(weekday)) continue;

      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      );
      while (next.weekday != weekday || !next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: id,
        title: 'Đến giờ học rồi!',
        body: 'Dành một chút thời gian luyện tiếng Anh cùng LingoUp nhé.',
        scheduledDate: next,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminder_channel',
            'Nhắc nhở học tập',
            channelDescription: 'Nhắc bạn học tiếng Anh theo lịch đã đặt.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    return true;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    int id = 7399,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminder_channel',
          'Nhắc nhở học tập',
          channelDescription: 'Thông báo đẩy từ máy chủ FCM hoặc lịch học.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<bool> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return true;
  }
}
