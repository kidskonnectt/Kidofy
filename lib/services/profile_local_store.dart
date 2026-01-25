import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileLocalStore {
  static String _timerKey(String profileId) => 'timer_limit_minutes_$profileId';
  static String _historyKey(String profileId) => 'watch_history_$profileId';
  static String _offlineKey(String profileId) => 'offline_videos_$profileId';
  static String _offlinePathKey(String profileId, String videoId) =>
      'offline_video_path_${profileId}_$videoId';

  static Future<int> getTimerLimitMinutes(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timerKey(profileId)) ?? 0;
  }

  static Future<void> setTimerLimitMinutes(
    String profileId,
    int minutes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerKey(profileId), minutes);
  }

  static Future<List<String>> getWatchHistory(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey(profileId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<void> recordWatchedVideo(
    String profileId,
    String videoId, {
    int maxItems = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getWatchHistory(profileId);

    history.remove(videoId);
    history.insert(0, videoId);

    if (history.length > maxItems) {
      history.removeRange(maxItems, history.length);
    }

    await prefs.setString(_historyKey(profileId), jsonEncode(history));
  }

  static Future<void> clearWatchHistory(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey(profileId));
  }

  static Future<List<String>> getOfflineVideoIds(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_offlineKey(profileId)) ?? [];
  }

  static Future<void> setOfflineVideoIds(
    String profileId,
    List<String> videoIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_offlineKey(profileId), videoIds);
  }

  static Future<void> addOfflineVideo(String profileId, String videoId) async {
    final current = await getOfflineVideoIds(profileId);
    if (current.contains(videoId)) return;
    current.add(videoId);
    await setOfflineVideoIds(profileId, current);
  }

  static Future<void> removeOfflineVideo(
    String profileId,
    String videoId,
  ) async {
    final current = await getOfflineVideoIds(profileId);
    current.remove(videoId);
    await setOfflineVideoIds(profileId, current);
  }

  static Future<String?> getOfflineVideoPath(
    String profileId,
    String videoId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_offlinePathKey(profileId, videoId));
  }

  static Future<void> setOfflineVideoPath(
    String profileId,
    String videoId,
    String filePath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlinePathKey(profileId, videoId), filePath);
  }

  static Future<void> removeOfflineVideoPath(
    String profileId,
    String videoId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlinePathKey(profileId, videoId));
  }
}
