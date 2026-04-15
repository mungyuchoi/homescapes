import 'package:shared_preferences/shared_preferences.dart';

class BottomSheetAdStorage {
  static const String _keyPrefix = 'bottom_sheet_ad_hidden_';

  static Future<void> hideAdForToday(String adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$adId', _todayKey());
    } catch (e) {
      // Ignore storage failures to avoid blocking ad flow.
    }
  }

  static Future<bool> isAdHiddenToday(String adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix$adId') == _todayKey();
    } catch (e) {
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
    } catch (e) {
      // Ignore storage failures.
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
