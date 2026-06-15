import 'package:shared_preferences/shared_preferences.dart';

class LookupSettings {
  static const _kGoogleBooksKey = 'googleBooksApiKey';

  static Future<String?> getGoogleBooksKey() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kGoogleBooksKey)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setGoogleBooksKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = key?.trim() ?? '';
    if (clean.isEmpty) {
      await prefs.remove(_kGoogleBooksKey);
    } else {
      await prefs.setString(_kGoogleBooksKey, clean);
    }
  }
}
