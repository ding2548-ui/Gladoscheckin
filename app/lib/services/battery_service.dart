import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BatteryService {
  static const String _key = 'battery_opt_requested';

  /// 请求忽略电池优化（避免后台被杀）
  static Future<String> requestIgnoreBatteryOpt() async {
    try {
      // 通过 platform channel 调用原生代码
      const channel = MethodChannel('glados/battery');
      final result = await channel.invokeMethod('requestIgnoreBatteryOpt');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      return result ?? '已请求';
    } catch (e) {
      return '请求失败: $e';
    }
  }

  /// 检查是否已忽略电池优化
  static Future<bool> isIgnoringBatteryOpt() async {
    try {
      const channel = MethodChannel('glados/battery');
      final result = await channel.invokeMethod('isIgnoringBatteryOpt');
      return result == true;
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

// 需要 import 'package:flutter/services.dart';
