import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/bunny_service.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SupabaseService {
  static final client = Supabase.instance.client;

  // Google Sign In Configuration
  // NOTE: Do NOT ship the Google "Client Secret" in the app.
  // The secret is only for Supabase dashboard/provider configuration.
  // This Client ID MUST match the "Client ID" configured under:
  // Supabase Dashboard → Auth → Providers → Google.
  static const String _googleWebClientId =
      '920546448999-t5nla6o5clhpc6ma3k8t2g5ba5cfp34b.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleInitialized = false;

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(serverClientId: _googleWebClientId);
    _googleInitialized = true;
  }

  // Auth
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'kidofy://auth-callback',
    );
  }

  static Future<bool> signInWithGoogle() async {
    debugPrint('🔐 Google Sign-In: Starting flow...');

    // Web: use Supabase OAuth redirect back to the current web origin.
    // The session will be created by exchanging the returned ?code=... on app
    // startup (see main.dart).
    if (kIsWeb) {
      debugPrint('🌐 Google Sign-In: Web platform detected');
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      return false;
    }

    final bool isMobile =
        (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

    // Desktop platforms are not configured for Google Sign-In in this app.
    if (!isMobile) {
      debugPrint('❌ Google Sign-In: Desktop platform not supported');
      throw const AuthException(
        'Google Sign-In is only configured for Android/iOS/Web in this app.',
      );
    }

    debugPrint('📱 Google Sign-In: Mobile platform detected, initializing...');

    // Mobile: native in-app Google account picker (no browser redirect).
    try {
      await _ensureGoogleInitialized();
      debugPrint('✅ Google Sign-In: Initialized');
    } catch (e) {
      debugPrint('❌ Google Sign-In: Initialization failed - $e');
      throw AuthException('Google Sign-In initialization failed: $e');
    }

    try {
      debugPrint('🔄 Google Sign-In: Signing out previous user...');
      // Force the account chooser each time.
      try {
        await _googleSignIn.signOut();
        debugPrint('✅ Google Sign-In: Previous user signed out');
      } catch (e) {
        debugPrint('⚠️ Google Sign-In: Signout warning - $e');
        // ignore - not critical
      }

      debugPrint('📱 Google Sign-In: Showing account picker...');

      // Add timeout to prevent infinite loading
      final googleUser = await _googleSignIn
          .authenticate(scopeHint: const ['email', 'profile'])
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint('⏱️ Google Sign-In: Timeout after 60 seconds');
              throw const AuthException(
                'Google Sign-In timed out. Check your internet connection and try again.',
              );
            },
          );

      // If we reach here, googleUser is not null (authenticate throws instead)
      debugPrint(
        '✅ Google Sign-In: User selected, getting authentication tokens...',
      );

      final auth = googleUser.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('❌ Google Sign-In: No ID token received');
        throw const AuthException(
          'Google Sign-In did not return an ID token. Check Firebase SHA-1/SHA-256, package name, and Supabase Google provider settings.',
        );
      }

      debugPrint('🔐 Google Sign-In: Exchanging ID token with Supabase...');

      final response = await client.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ Google Sign-In: Supabase exchange timeout');
              throw const AuthException(
                'Authentication service timeout. Please check your internet connection.',
              );
            },
          );

      final success = response.session != null;
      if (success) {
        debugPrint('🎉 Google Sign-In: SUCCESS - Session created');
      } else {
        debugPrint('⚠️ Google Sign-In: No session returned');
      }
      return success;
    } on AuthException catch (e) {
      debugPrint('❌ Google Sign-In: AuthException - ${e.message}');
      final msg = e.message.toLowerCase();

      if (msg.contains('canceled') || msg.contains('cancelled')) {
        throw const AuthException('Sign-in cancelled');
      }
      if (msg.contains('apierception: 10')) {
        throw AuthException(
          'Google Sign-In configuration error (ApiException: 10). Add SHA-1 and SHA-256 for your app in Firebase, download a new google-services.json, and ensure the package name matches.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Google Sign-In: Unexpected error - $e');
      final msg = e.toString().toLowerCase();

      if (msg.contains('canceled') || msg.contains('cancelled')) {
        throw const AuthException('Sign-in cancelled');
      }
      if (msg.contains('apierception: 10')) {
        throw AuthException(
          'Google Sign-In configuration error (ApiException: 10). Add SHA-1 and SHA-256 for your app in Firebase, download a new google-services.json, and ensure the package name matches.',
        );
      }
      if (msg.contains('timeout')) {
        throw AuthException('Google Sign-In timed out: $e');
      }

      throw AuthException('Google Sign-In error: $e');
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
  }

  static User? get currentUser => client.auth.currentUser;

  // Data fetching
  // Assuming tables: videos, categories, profiles

  static const String _prefsProfileKey = 'selected_profile';

  static Future<void> saveCurrentProfile(Profile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsProfileKey, jsonEncode(p.toJson()));
  }

  static Future<void> initializeData() async {
    // Attempt to restore profile from cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profileJson = prefs.getString(_prefsProfileKey);
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        MockData.currentProfile.value = Profile.fromJson(profileMap);
      }
    } catch (e) {
      debugPrint('Error restoring profile: $e');
    }

    try {
      final cats = await getCategories();
      MockData.categories = [
        const Category(id: '0', name: 'Explore', color: 0xFFFFD600),
        ...cats,
      ];

      final vids = await getVideos();
      MockData.videos = vids;
      MockData.snaps = vids.where((v) => v.isShorts).toList();

      final user = client.auth.currentUser;
      if (user != null) {
        final profiles = await getProfiles(user.id);
        MockData.profiles = profiles;

        final current = MockData.currentProfile.value;
        if (current == null && profiles.isNotEmpty) {
          final first = profiles.first;
          MockData.currentProfile.value = first;
          await saveCurrentProfile(first);
        } else if (current != null &&
            profiles.isNotEmpty &&
            !profiles.any((p) => p.id == current.id)) {
          // If cached profile is no longer valid/exists on server
          final first = profiles.first;
          MockData.currentProfile.value = first;
          await saveCurrentProfile(first);
        }
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  // Fetch Categories
  static Future<List<Category>> getCategories() async {
    try {
      final response = await client.from('categories').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        int color = 0xFF000000;
        final colorData = json['color'];
        if (colorData is int) {
          color = colorData;
        } else if (colorData is String) {
          color =
              int.tryParse(colorData) ??
              int.tryParse(colorData.replaceAll('#', '0xFF')) ??
              0xFF000000;
        }

        String? iconUrl = json['icon_url'] ?? json['icon_path'];
        if (iconUrl != null &&
            iconUrl.isNotEmpty &&
            !iconUrl.startsWith('http')) {
          iconUrl = BunnyService.getFileUrl(iconUrl);
        }
        return Category(
          id: json['id'].toString(),
          name: json['name'],
          color: color,
          iconUrl: iconUrl,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  // Fetch Videos
  static Future<List<Video>> getVideos() async {
    try {
      // Attempt to fetch channel avatars map to fix missing avatars in video table
      final Map<String, String> channelAvatarMap = {};
      try {
        final channelsResponse = await client
            .from('channels')
            .select('name, avatar_path');
        final List<dynamic> channelsData = channelsResponse as List<dynamic>;
        for (final c in channelsData) {
          final String? name = c['name'];
          final String? path = c['avatar_path'];
          if (name != null && path != null) {
            channelAvatarMap[name] = path;
          }
        }
      } catch (_) {
        // Table might not exist or error, ignore
      }

      final response = await client.from('videos').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        String thumbnail =
            json['thumbnail_path'] ?? json['thumbnail_url'] ?? '';
        if (thumbnail.isNotEmpty && !thumbnail.startsWith('http')) {
          thumbnail = BunnyService.getFileUrl(thumbnail);
        }

        String? channelAvatar =
            json['channel_avatar_path'] ?? json['channel_avatar_url'];

        // Fallback: Check map
        final String cName = json['channel_name'] ?? '';
        if ((channelAvatar == null || channelAvatar.isEmpty) &&
            channelAvatarMap.containsKey(cName)) {
          channelAvatar = channelAvatarMap[cName];
        }

        if (channelAvatar != null &&
            channelAvatar.isNotEmpty &&
            !channelAvatar.startsWith('http')) {
          channelAvatar = BunnyService.getFileUrl(channelAvatar);
        }

        final String? rawVideoPath = json['video_path'] ?? json['video_url'];
        String? videoUrl;
        if (rawVideoPath != null && rawVideoPath.isNotEmpty) {
          videoUrl = rawVideoPath.startsWith('http')
              ? rawVideoPath
              : BunnyService.getFileUrl(rawVideoPath);
        }

        final isShortsRaw = json['is_shorts'];
        final bool isShorts =
            isShortsRaw == true || isShortsRaw?.toString() == 'true';

        final String? contentLevel =
            (json['content_level'] ??
                    json['contentLevel'] ??
                    json['content_type'] ??
                    json['contentType'])
                ?.toString();

        return Video(
          id: json['id'].toString(),
          title: json['title'],
          thumbnailUrl: thumbnail,
          videoUrl: videoUrl,
          duration: json['duration'],
          channelName: json['channel_name'],
          channelAvatarUrl: channelAvatar,
          categoryId: json['category_id'].toString(),
          isShorts: isShorts,
          contentLevel: contentLevel,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      return [];
    }
  }

  // Fetch Profiles
  static Future<List<Profile>> getProfiles(String userId) async {
    try {
      dynamic response;
      try {
        // Prefer explicit filter when schema matches.
        response = await client
            .from('profiles')
            .select()
            .eq('parent_id', userId);
      } on PostgrestException catch (e) {
        final combined = '${e.message} ${(e.details ?? '')} ${(e.hint ?? '')}'
            .toLowerCase();
        if (combined.contains('parent_id') || combined.contains('parentid')) {
          // Back-compat: some schemas use user_id instead of parent_id.
          response = await client
              .from('profiles')
              .select()
              .eq('user_id', userId);
        } else {
          // Fall back to RLS-only select.
          response = await client.from('profiles').select();
        }
      }

      final List<dynamic> data = response as List<dynamic>;
      final profiles = <Profile>[];
      final pendingContentTypeUpdates = <String, String>{};

      for (final row in data) {
        String avatarPath = row['avatar_path'] ?? row['avatar_url'] ?? '';
        if (avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
          avatarPath = BunnyService.getFileUrl(avatarPath);
        }

        final birthMonthRaw = row['birth_month'] ?? row['birthMonth'];
        final int? birthMonth = birthMonthRaw == null
            ? null
            : int.tryParse(birthMonthRaw.toString());

        final int age = row['age'] ?? 0;
        final String storedType = (row['content_type'] ?? '').toString().trim();

        // Auto-transition content levels by age:
        // Preschool (<=4) -> Younger (>4)
        // Legacy "Older" or "Choose for me" will be auto-mapped to "Younger" via normalize.

        final int effectiveAge = ContentLevels.effectiveAge(
          age: age,
          birthMonth: birthMonth,
        );

        final String ageLevel = ContentLevels.fromAge(effectiveAge);
        final String normalizedStored = ContentLevels.normalize(
          storedType,
          fallbackAge: age,
          fallbackBirthMonth: birthMonth,
        );

        String desiredType = normalizedStored;

        // Auto-transfer logic:
        // If age implies Younger (age > 4), but stored is Preschool, upgrade them.
        // Also if stored was legacy (Older/ChooseForMe), normalizedStored is already likely Younger (if age fits)
        // or age based.

        if (ageLevel == ContentLevels.younger &&
            normalizedStored == ContentLevels.preschool) {
          desiredType = ContentLevels.younger;
        }

        if (storedType.isNotEmpty && desiredType != storedType) {
          pendingContentTypeUpdates[row['id'].toString()] = desiredType;
        }

        profiles.add(
          Profile(
            id: row['id'].toString(),
            name: row['name'],
            avatarUrl: avatarPath,
            age: age,
            // ...
            contentType: desiredType.isEmpty ? 'Preschool' : desiredType,
            birthMonth: birthMonth,
          ),
        );
      }

      if (pendingContentTypeUpdates.isNotEmpty) {
        // Best-effort: keep the app responsive even if updates fail.
        try {
          await Future.wait(
            pendingContentTypeUpdates.entries.map(
              (e) => client
                  .from('profiles')
                  .update({'content_type': e.value})
                  .eq('id', e.key),
            ),
          );
        } catch (e) {
          debugPrint('Profile content_type auto-update failed: $e');
        }
      }

      return profiles;
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      return [];
    }
  }

  static Future<Profile> createProfile({
    required String name,
    required int age,
    required String avatarPath,
    required String contentType,
    int? birthMonth,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    Map<String, dynamic> payload = {
      'parent_id': user.id,
      'name': name,
      'avatar_path': avatarPath,
      'age': age,
      'content_type': contentType,
      if (birthMonth != null) 'birth_month': birthMonth,
    };

    dynamic inserted;
    try {
      inserted = await client
          .from('profiles')
          .insert(payload)
          .select()
          .single();
    } on PostgrestException catch (e) {
      final msg = (e.message).toLowerCase();
      final details = (e.details ?? '').toString().toLowerCase();
      final hint = (e.hint ?? '').toString().toLowerCase();
      final combined = '$msg $details $hint';

      // Most common real-world failure: RLS/policy not configured.
      if (combined.contains('row-level security') ||
          combined.contains('new row violates row-level security policy') ||
          combined.contains('permission denied')) {
        throw const AuthException(
          'Backend blocked saving the kid profile (RLS/policy). In Supabase, enable RLS policies for `profiles`: allow SELECT and INSERT where `auth.uid() = parent_id` (or your parent column).',
        );
      }

      // Back-compat if DB column names differ.
      // Retry with alternate column names that appear in older schema variants.
      Map<String, dynamic> alt = Map.of(payload);

      if (combined.contains('birth_month') || combined.contains('birthmonth')) {
        alt.remove('birth_month');
        alt['birthMonth'] = birthMonth;
      }

      if (combined.contains('parent_id') || combined.contains('parentid')) {
        alt.remove('parent_id');
        alt['user_id'] = user.id;
      }

      if (combined.contains('avatar_path') || combined.contains('avatarpath')) {
        alt.remove('avatar_path');
        alt['avatar_url'] = avatarPath;
      }

      if (combined.contains('content_type') ||
          combined.contains('contenttype')) {
        alt.remove('content_type');
        alt['content_level'] = contentType;
      }

      // If we changed anything, retry once.
      if (alt.toString() != payload.toString()) {
        inserted = await client.from('profiles').insert(alt).select().single();
      } else {
        rethrow;
      }
    }

    String avatar = inserted['avatar_path'] ?? '';
    if (avatar.isNotEmpty && !avatar.startsWith('http')) {
      avatar = BunnyService.getFileUrl(avatar);
    }

    final birthMonthRaw = inserted['birth_month'] ?? inserted['birthMonth'];
    final int? createdBirthMonth = birthMonthRaw == null
        ? null
        : int.tryParse(birthMonthRaw.toString());

    return Profile(
      id: inserted['id'].toString(),
      name: inserted['name'],
      avatarUrl: avatar,
      age: inserted['age'],
      contentType: inserted['content_type'] ?? 'Preschool',
      birthMonth: createdBirthMonth,
    );
  }

  static Future<void> updateProfileContentType({
    required String profileId,
    required String contentType,
  }) async {
    await client
        .from('profiles')
        .update({'content_type': contentType})
        .eq('id', profileId);

    final idx = MockData.profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      final p = MockData.profiles[idx];
      MockData.profiles[idx] = Profile(
        id: p.id,
        name: p.name,
        avatarUrl: p.avatarUrl,
        age: p.age,
        contentType: contentType,
        birthMonth: p.birthMonth,
      );

      if (MockData.currentProfile.value?.id == profileId) {
        MockData.currentProfile.value = MockData.profiles[idx];
      }
    }
  }

  static Future<void> deleteProfile(String profileId) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    await client
        .from('profiles')
        .delete()
        .eq('id', profileId)
        .eq('parent_id', user.id);

    MockData.profiles.removeWhere((p) => p.id == profileId);
    if (MockData.currentProfile.value?.id == profileId) {
      MockData.currentProfile.value = MockData.profiles.isNotEmpty
          ? MockData.profiles.first
          : null;
    }
  }

  // Fetch Mart Videos
  static Future<List<MartVideo>> getMartVideos() async {
    try {
      final response = await client
          .from('mart_videos')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        String? thumbnail = json['thumbnail_url'] ?? '';
        if (thumbnail != null &&
            thumbnail.isNotEmpty &&
            !thumbnail.startsWith('http')) {
          thumbnail = BunnyService.getFileUrl(thumbnail);
        }

        String? videoUrl = json['video_url'] ?? '';
        if (videoUrl != null &&
            videoUrl.isNotEmpty &&
            !videoUrl.startsWith('http')) {
          videoUrl = BunnyService.getFileUrl(videoUrl);
        }

        return MartVideo(
          id: json['id'].toString(),
          videoUrl: videoUrl ?? '',
          thumbnailUrl: thumbnail ?? '',
          productLink: json['product_link'] ?? '',
          shopName: json['shop_name'] ?? 'Unknown Shop',
          views: (json['views'] ?? 0) as int,
          clicks: (json['clicks'] ?? 0) as int,
          createdAt:
              DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching mart videos: $e');
      return [];
    }
  }

  static Future<void> trackMartView(String martVideoId) async {
    try {
      await client.rpc(
        'increment_mart_views',
        params: {'p_id': int.parse(martVideoId)},
      );
    } catch (e) {
      debugPrint('Error tracking mart view: $e');
    }
  }

  static Future<void> trackMartClick(String martVideoId) async {
    try {
      await client.rpc(
        'increment_mart_clicks',
        params: {'p_id': int.parse(martVideoId)},
      );
    } catch (e) {
      debugPrint('Error tracking mart click: $e');
    }
  }

  static Future<({Set<String> videoIds, Set<String> channelNames})>
  getBlockedContent(String profileId) async {
    final response = await client
        .from('blocked_content')
        .select()
        .eq('profile_id', profileId);
    final List<dynamic> data = response as List<dynamic>;

    final videoIds = <String>{};
    final channelNames = <String>{};

    for (final row in data) {
      final type = (row['item_type'] ?? '').toString();
      final id = (row['item_id'] ?? '').toString();
      if (id.isEmpty) continue;

      if (type == 'video') {
        videoIds.add(id);
      } else if (type == 'channel') {
        channelNames.add(id);
      }
    }

    return (videoIds: videoIds, channelNames: channelNames);
  }

  static Future<void> blockVideo({
    required String profileId,
    required String videoId,
  }) async {
    await client.from('blocked_content').insert({
      'profile_id': profileId,
      'item_id': videoId,
      'item_type': 'video',
    });
  }

  static Future<void> blockChannel({
    required String profileId,
    required String channelName,
  }) async {
    await client.from('blocked_content').insert({
      'profile_id': profileId,
      'item_id': channelName,
      'item_type': 'channel',
    });
  }

  static Future<void> unblockItem({
    required String profileId,
    required String itemId,
    required String itemType,
  }) async {
    await client
        .from('blocked_content')
        .delete()
        .eq('profile_id', profileId)
        .eq('item_id', itemId)
        .eq('item_type', itemType);
  }
}
