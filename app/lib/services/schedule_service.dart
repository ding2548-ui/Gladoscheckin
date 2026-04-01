import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ScheduleService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const int _alarmId = 9090;
  static bool _enabled = false;

  static Future<void> init() async {
    // 初始化通知（仅用于手动推送，不用来调度）
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);

    // 创建通知渠道
    const channel = AndroidNotificationChannel(
      'glados_checkin',
      'GLaDOS 签到',
      description: 'GLaDOS 自动签到通知',
      importance: Importance.low,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 检查是否已启用
    _enabled = await AndroidAlarmManager.isScheduled(_alarmId);
  }

  static Future<void> scheduleDaily(int hour, int minute) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await AndroidAlarmManager.oneShotAt(
      scheduledDate,
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
    );
    _enabled = true;
  }

  static Future<void> cancelSchedule() async {
    try {
      await AndroidAlarmManager.cancel(_alarmId);
    } catch (_) {}
    _enabled = false;
  }

  static Future<bool> isScheduled() async {
    try {
      return await AndroidAlarmManager.isScheduled(_alarmId);
    } catch (_) {
      return _enabled;
    }
  }

  static Future<String> runCheckin() async {
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

// 回调函数（必须在顶层）
Future<void> _alarmCallback() async {
  final cookies = await StorageService.getCookies();
  final pushToken = await StorageService.getPushToken();

  if (cookies.isEmpty) return;

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
}
