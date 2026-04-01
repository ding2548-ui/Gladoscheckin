import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account_model.dart';

class ApiService {
  static const String _checkinUrl = 'https://glados.cloud/api/user/checkin';
  static const String _statusUrl = 'https://glados.cloud/api/user/status';
  static const String _referer = 'https://glados.cloud/console/checkin';
  static const String _origin = 'https://glados.cloud';
  static const String _ua = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36';

  static Map<String, String> _headers(String cookie) => {
    'cookie': cookie,
    'referer': _referer,
    'origin': _origin,
    'user-agent': _ua,
    'content-type': 'application/json;charset=UTF-8',
  };

  static Future<CheckinResult> checkin(String cookie) async {
    try {
      final resp = await http.post(
        Uri.parse(_checkinUrl),
        headers: _headers(cookie),
        body: jsonEncode({'token': 'glados.cloud'}),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        return CheckinResult.error('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      final msg = data['message'] ?? '';
      final points = data['points'] ?? 0;

      final status = await _getStatus(cookie);
      final email = status['email'] ?? '';
      final leftDays = status['leftDays'] ?? 0;

      if (msg.contains('Checkin! Got')) {
        return CheckinResult.success(email, points, leftDays, msg);
      } else if (msg.contains('Checkin Repeats!')) {
        return CheckinResult.repeat(email, leftDays);
      } else {
        return CheckinResult.fail(email, msg);
      }
    } catch (e) {
      return CheckinResult.error(e.toString());
    }
  }

  static Future<Map<String, dynamic>> _getStatus(String cookie) async {
    try {
      final resp = await http.get(
        Uri.parse(_statusUrl),
        headers: {
          'cookie': cookie,
          'referer': _referer,
          'origin': _origin,
          'user-agent': _ua,
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final d = data['data'] ?? {};
        return {
          'email': d['email'] ?? '',
          'leftDays': (d['leftDays'] is num) ? (d['leftDays'] as num).toInt() : 0,
        };
      }
    } catch (_) {}
    return {'email': '', 'leftDays': 0};
  }

  static Future<void> pushNotification(String token, String title, String content) async {
    if (token.isEmpty) return;
    try {
      final url = 'https://www.pushplus.plus/send?token=$token&title=${Uri.encodeComponent(title)}&content=${Uri.encodeComponent(content)}&template=html';
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }
}
