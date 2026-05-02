import 'package:shared_preferences/shared_preferences.dart';

class LocalSettings {
  static const _keyWebAppUrl = 'sheet_webapp_url';
  static const _keyAdminUsername = 'sheet_admin_username';
  static const _keyAdminPassword = 'sheet_admin_password';
  static const _keyCachedSymptoms = 'cached_symptoms_json';

  // URL default — dipakai jika belum dikonfigurasi manual
  static const kDefaultWebAppUrl =
      'https://script.google.com/macros/s/AKfycbwninR39omIKiTrktRlIvdaFM2A0s_v8IakhULgcYNjLOglz1afJCt6ftfRvqIFEPXs/exec';

  Future<String> getWebAppUrl() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_keyWebAppUrl);
    if (v != null && v.trim().isNotEmpty) return v.trim();
    return kDefaultWebAppUrl;
  }

  Future<void> setWebAppUrl(String? url) async {
    final p = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await p.remove(_keyWebAppUrl);
    } else {
      await p.setString(_keyWebAppUrl, url.trim());
    }
  }

  Future<String?> getAdminUsername() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyAdminUsername);
  }

  Future<void> setAdminUsername(String? v) async {
    final p = await SharedPreferences.getInstance();
    if (v == null || v.isEmpty) {
      await p.remove(_keyAdminUsername);
    } else {
      await p.setString(_keyAdminUsername, v);
    }
  }

  Future<String?> getAdminPassword() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyAdminPassword);
  }

  Future<void> setAdminPassword(String? v) async {
    final p = await SharedPreferences.getInstance();
    if (v == null || v.isEmpty) {
      await p.remove(_keyAdminPassword);
    } else {
      await p.setString(_keyAdminPassword, v);
    }
  }

  Future<String?> getCachedSymptomsJson() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyCachedSymptoms);
  }

  Future<void> setCachedSymptomsJson(String? json) async {
    final p = await SharedPreferences.getInstance();
    if (json == null || json.isEmpty) {
      await p.remove(_keyCachedSymptoms);
    } else {
      await p.setString(_keyCachedSymptoms, json);
    }
  }
}
