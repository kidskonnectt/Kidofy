import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UsageTracker {
  static String _key(String profileId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'usage_${profileId}_$today';
  }

  static Future<void> addMinute(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(profileId)) ?? 0;
    await prefs.setInt(_key(profileId), current + 1);
  }

  static Future<int> getTodayMinutes(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(profileId)) ?? 0;
  }

  static Future<void> resetUsage(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(profileId));
  }
}
