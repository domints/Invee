import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _serverUrlKey = 'server_url';

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trimRight().replaceAll(RegExp(r'/+$'), ''));
  }

  static Future<void> clearServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverUrlKey);
  }
}
