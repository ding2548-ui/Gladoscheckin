import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _cookiesKey = 'glados_cookies';
  static const String _pushTokenKey = 'pushplus_token';

  static Future<List<String>> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cookiesKey) ?? [];
  }

  static Future<void> setCookies(List<String> cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cookiesKey, cookies);
  }

  static Future<void> addCookie(String cookie) async {
    final cookies = await getCookies();
    if (!cookies.contains(cookie.trim())) {
      cookies.add(cookie.trim());
      await setCookies(cookies);
    }
  }

  static Future<void> removeCookie(int index) async {
    final cookies = await getCookies();
    if (index >= 0 && index < cookies.length) {
      cookies.removeAt(index);
      await setCookies(cookies);
    }
  }

  static Future<String> getPushToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pushTokenKey) ?? '';
  }

  static Future<void> setPushToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pushTokenKey, token);
  }
}
