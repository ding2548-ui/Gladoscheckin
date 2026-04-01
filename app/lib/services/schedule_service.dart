import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ScheduleService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static Timer? _timer;
  static bool _enabled = false;
  static int _hour = 8;
  static int _minute = 0;
  static bool _checkedToday = false;

  static Future<void> init() async {
    // 初始化通知（仅用于 show，不用 zonedSchedule）
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      'glados_checkin',
      '签到助手',
      description: '签到结果通知',
      importance: Importance.defaultImportance,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('schedule_enabled') ?? false;
    _hour = prefs.getInt('schedule_hour') ?? 8;
    _minute = prefs.getInt('schedule_minute') ?? 0;
    if (_enabled) _startTimer();
  }

  static Future<void> scheduleDaily(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    _enabled = true;
    _checkedToday = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', true);
    await prefs.setInt('schedule_hour', hour);
    await prefs.setInt('schedule_minute', minute);
    _startTimer();
  }

  static Future<void> cancelSchedule() async {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', false);
  }

  static Future<bool> isScheduled() async => _enabled;

  static void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  static Future<void> _check() async {
    if (!_enabled) return;
    final now = DateTime.now();
    if (now.hour == _hour && now.minute == _minute && !_checkedToday) {
      _checkedToday = true;
      await runCheckin();
    }
    if (now.hour == 0 && now.minute == 0) {
      _checkedToday = false;
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    try {
      await _notifications.show(
        1001,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'glados_checkin',
            '签到助手',
            channelDescription: '签到结果通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<String> runCheckin() async {
    final cookies = await StorageService.getCookies();
    final pushToken = await StorageService.getPushToken();
    if (cookies.isEmpty) {
      await _showNotification('签到助手', '未添加 Cookie');
      return '未添加 Cookie';
    }

    final results = <String>[];
    for (final cookie in cookies) {
      if (cookie.trim().isEmpty) continue;
      final result = await ApiService.checkin(cookie.trim());
      results.add('${result.email}: ${result.message}');
    }

    final content = results.join('\n');

    // 显示系统通知
    final hasSuccess = content.contains('签到成功');
    await _showNotification(
      hasSuccess ? '签到成功 ✅' : '签到结果',
      content.length > 50 ? '${content.substring(0, 50)}...' : content,
    );

    // PushPlus 推送
    if (pushToken.isNotEmpty) {
      await ApiService.pushNotification(pushToken, '签到助手', content.replaceAll('\n', '<br>'));
    }
    return content;
  }
}
