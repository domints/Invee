import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const _jwtKey = 'jwt_token';
  static const _storage = FlutterSecureStorage();

  static String? _jwtToken;

  /// Load the persisted JWT from secure storage. Call once at app start.
  static Future<void> init() async {
    _jwtToken = await _storage.read(key: _jwtKey);
  }

  static String? get jwtToken => _jwtToken;

  static bool get isAuthenticated => _jwtToken != null;

  static Future<void> setJwtToken(String token) async {
    _jwtToken = token;
    await _storage.write(key: _jwtKey, value: token);
  }

  static Future<void> clearSession() async {
    _jwtToken = null;
    await _storage.delete(key: _jwtKey);
  }

  /// Calls `/api/auth/mobile-token` using the short-lived session [cookieHeader]
  /// (e.g. `.AspNetCore.Cookies=abc123...`) to obtain a long-lived JWT.
  /// Stores the JWT on success and returns true; returns false on failure.
  static Future<bool> exchangeCookieForJwt(
      String baseUrl, String cookieHeader) async {
    final url =
        Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/auth/mobile-token');
    try {
      final response = await http
          .get(url, headers: {'Cookie': cookieHeader})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await setJwtToken(token);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
