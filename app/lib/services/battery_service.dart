import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryService {
  static const _channel = MethodChannel('glados/battery');
  static const String _key = 'battery_opt_requested';

  /// 请求忽略电池优化
  static Future<String> requestIgnore() async {
    try {
      final result = await _channel.invokeMethod<String>('requestIgnoreBatteryOpt');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      return result ?? '已请求';
    } on PlatformException catch (e) {
      return '请求失败: ${e.message}';
    }
  }

  /// 检查是否已忽略
  static Future<bool> isIgnoring() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOpt');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 是否已请求过
  static Future<bool> hasRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}
