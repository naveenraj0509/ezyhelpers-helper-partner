import 'package:shared_preferences/shared_preferences.dart';

import '../models/job.dart';

/// Remembers the auth token, the helper, and the chosen backend address.
class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _helperIdKey = 'helper_id';
  static const _helperUsernameKey = 'helper_username';
  static const _helperNameKey = 'helper_full_name';
  static const _baseUrlKey = 'base_url';

  /// Hosted demo backend (Render free tier). For a local server use
  /// http://10.0.2.2:8000 on the emulator, or your machine's LAN IP on a phone.
  static const defaultBaseUrl = 'https://ezyhelpers-helper-api.onrender.com';

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Helper?> readHelper() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_helperIdKey);
    final username = prefs.getString(_helperUsernameKey);
    if (id == null || username == null) return null;
    return Helper(
      id: id,
      username: username,
      fullName: prefs.getString(_helperNameKey) ?? username,
    );
  }

  Future<String> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> writeBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
  }

  Future<void> saveSession({required String token, required Helper helper}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_helperIdKey, helper.id);
    await prefs.setString(_helperUsernameKey, helper.username);
    await prefs.setString(_helperNameKey, helper.fullName);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // The base URL deliberately survives sign-out so the next login is easier.
    await prefs.remove(_tokenKey);
    await prefs.remove(_helperIdKey);
    await prefs.remove(_helperUsernameKey);
    await prefs.remove(_helperNameKey);
  }
}
