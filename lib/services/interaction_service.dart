import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionService {
  static final client = Supabase.instance.client;

  // Likes
  static Future<void> toggleLike(String videoId, bool isLike) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      // Check if exists
      final existing = await client
          .from('video_likes')
          .select()
          .eq('user_id', user.id)
          .eq('video_id', videoId)
          .maybeSingle();

      if (existing != null) {
        final currentLike = existing['is_like'] as bool;
        if (currentLike == isLike) {
          // Remove if toggling same state (Undo like/dislike)
          await client
              .from('video_likes')
              .delete()
              .eq('user_id', user.id)
              .eq('video_id', videoId);
        } else {
          // Update
          await client
              .from('video_likes')
              .update({'is_like': isLike})
              .eq('user_id', user.id)
              .eq('video_id', videoId);
        }
      } else {
        // Insert
        await client.from('video_likes').insert({
          'user_id': user.id,
          'video_id': videoId,
          'is_like': isLike,
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  static Future<bool?> getLikeStatus(String videoId) async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await client
          .from('video_likes')
          .select('is_like')
          .eq('user_id', user.id)
          .eq('video_id', videoId)
          .maybeSingle();

      if (res != null) {
        return res['is_like'] as bool;
      }
    } catch (e) {
      debugPrint('Error getting like status: $e');
    }
    return null; // No interaction
  }

  static Future<List<String>> getLikedVideoIds() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await client
          .from('video_likes')
          .select('video_id')
          .eq('user_id', user.id)
          .eq('is_like', true);

      return (res as List).map((e) => e['video_id'].toString()).toList();
    } catch (e) {
      debugPrint('Error fetching liked videos: $e');
      return [];
    }
  }

  // Reports
  static Future<void> submitReport(
    String? videoId,
    String reason,
    String description,
  ) async {
    final user = client.auth.currentUser;
    // User can be anonymous or null, but table allows null user_id?
    // Schema says user_id can be null.

    await client.from('reports').insert({
      'user_id': user?.id,
      'video_id': videoId == null ? null : int.tryParse(videoId) ?? videoId,
      'reason': reason,
      'description': description,
    });
  }

  static Future<List<Map<String, dynamic>>> getMyReports() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    final res = await client
        .from('reports')
        .select('id, reason, description, status, response, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<Map<String, dynamic>?> getReportById(int reportId) async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final res = await client
        .from('reports')
        .select(
          'id, user_id, reason, description, status, response, created_at',
        )
        .eq('id', reportId)
        .maybeSingle();

    if (res == null) return null;
    // Extra guard even if RLS is correct.
    if (res['user_id']?.toString() != user.id) return null;
    return Map<String, dynamic>.from(res);
  }

  // Referrals
  static Future<void> referUser(String email) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("Must be logged in");

    await client.from('referrals').insert({
      'referrer_id': user.id,
      'referred_email': email,
    });
  }
}
