import 'package:shared_preferences/shared_preferences.dart';

class DialogAdStorage {
  static const String _keyPrefix = 'dialog_ad_hidden_';

  static Future<void> hideAdForToday(String adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$adId', _todayKey());
    } catch (_) {}
  }

  static Future<bool> isAdHiddenToday(String adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix$adId') == _todayKey();
    } catch (_) {
      return false;
    }
  }

  static Future<void> resetAllHiddenAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
