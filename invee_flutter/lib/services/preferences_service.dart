import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _serverUrlKey = 'server_url';
  static const _shortHostKey = 'short_host';
  static const _canonicalBaseUrlKey = 'canonical_base_url';

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
    await prefs.remove(_shortHostKey);
    await prefs.remove(_canonicalBaseUrlKey);
  }

  /// Persists the short-link configuration reported by the server's health
  /// endpoint so incoming `invee://` links can be recognized and resolved.
  static Future<void> setShortLinkConfig({
    required String shortHost,
    required String canonicalBaseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shortHostKey, shortHost);
    await prefs.setString(_canonicalBaseUrlKey, canonicalBaseUrl);
  }

  static Future<String?> getShortHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shortHostKey);
  }

  static Future<String?> getCanonicalBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_canonicalBaseUrlKey);
  }
}
