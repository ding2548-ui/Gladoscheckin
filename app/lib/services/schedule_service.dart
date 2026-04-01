import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';
import 'storage_service.dart';

class ScheduleService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _checkinNotificationId = 1001;
  static bool _scheduled = false;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      'glados_checkin',
      'GLaDOS 签到',
      description: 'GLaDOS 自动签到通知',
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleDaily(int hour, int minute) async {
    try {
      await _plugin.zonedSchedule(
        _checkinNotificationId,
        'GLaDOS 签到',
        '每日签到即将执行...',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'glados_checkin',
            'GLaDOS 签到',
            channelDescription: 'GLaDOS 自动签到通知',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'checkin',
      );
      _scheduled = true;
    } catch (e) {
      _scheduled = false;
      rethrow;
    }
  }

  static Future<void> cancelSchedule() async {
    try {
      await _plugin.cancel(_checkinNotificationId);
    } catch (e) {
      // 忽略 cancel 时的 Missing type parameter 错误
    }
    _scheduled = false;
  }

  static Future<bool> isScheduled() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((n) => n.id == _checkinNotificationId);
    } catch (_) {
      return _scheduled;
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload == 'checkin') {
      await _runCheckin();
    }
  }

  static Future<String> runCheckin() async {
    return await _runCheckin();
  }

  static Future<String> _runCheckin() async {
    final cookies = await StorageService.getCookies();
    final pushToken = await StorageService.getPushToken();

    if (cookies.isEmpty) return '未添加 Cookie';

    final results = <String>[];
    for (final cookie in cookies) {
      if (cookie.trim().isEmpty) continue;
      final result = await ApiService.checkin(cookie.trim());
      results.add('${result.email}: ${result.message}');
    }

    final content = results.join('\n');

    if (pushToken.isNotEmpty) {
      await ApiService.pushNotification(pushToken, 'GLaDOS 签到结果', content.replaceAll('\n', '<br>'));
    }

    return content;
  }
}
