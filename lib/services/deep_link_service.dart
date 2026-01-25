import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:kidsapp/screens/auth/login_screen.dart';
import 'package:kidsapp/screens/home/channel_screen.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/screens/root_screen.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  static const String scheme = 'kidofy';
  static const String host = 'auth-callback';

  // Web/App Links hosts (HTTPS) for deep-linking into the app.
  static const Set<String> _webHosts = {'kidofy.in', 'www.kidofy.in'};

  // If the user opens a content link while signed-out, we keep it and
  // navigate after login.
  static Uri? _pendingContentUri;

  static Uri? consumePendingContentUri() {
    final uri = _pendingContentUri;
    _pendingContentUri = null;
    return uri;
  }

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    // Handle cold start.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial, navigatorKey);
      }
    } catch (e) {
      debugPrint('DeepLink initialLink error: $e');
    }

    // Handle running app.
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, navigatorKey),
      onError: (e) => debugPrint('DeepLink stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _handleUri(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    // 1) Custom-scheme auth callback used by Supabase (PKCE email confirm).
    if (uri.scheme == scheme && uri.host == host) {
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) return;

      try {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        await SupabaseService.initializeData();

        final nav = navigatorKey.currentState;
        if (nav == null) return;

        // After confirmation, go directly to Add Kid.
        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AddKidScreen(goToHomeOnComplete: true),
          ),
          (_) => false,
        );
      } on AuthException catch (e) {
        debugPrint('DeepLink auth exchange failed: ${e.message}');
      } catch (e) {
        debugPrint('DeepLink handleUri failed: $e');
      }
      return;
    }

    // 2) HTTPS deep links (Android App Links / iOS Universal Links).
    if (uri.scheme == 'https' && _webHosts.contains(uri.host)) {
      await _handleHttpsContentLink(uri, navigatorKey);
    }
  }

  Future<void> _handleHttpsContentLink(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // Require login for in-app content.
    if (SupabaseService.currentUser == null) {
      _pendingContentUri = uri;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    // Ensure local cache is ready before trying to navigate to content.
    try {
      await SupabaseService.initializeData();
    } catch (_) {
      // Non-fatal; we can still navigate and let the UI load what it can.
    }

    // Supported routes:
    // - https://www.kidofy.in/channel/<Channel%20Name>
    // - https://www.kidofy.in/channel?name=<Channel%20Name>
    // - https://www.kidofy.in/snaps
    // - https://www.kidofy.in/snaps/<VideoId>
    // - https://www.kidofy.in/snaps?videoId=<VideoId>
    final segs = uri.pathSegments;
    if (segs.isEmpty) return;

    if (segs.first == 'channel') {
      // Home tab as the base.
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen(initialIndex: 0)),
        (_) => false,
      );

      final nameFromPath = segs.length >= 2
          ? Uri.decodeComponent(segs[1])
          : null;
      final nameFromQuery = uri.queryParameters['name'];
      final channelName = (nameFromPath ?? nameFromQuery)?.trim();

      if (channelName != null && channelName.isNotEmpty) {
        // Push the channel page on top of RootScreen.
        Future.microtask(() {
          nav.push(
            MaterialPageRoute(
              builder: (_) => ChannelScreen(channelName: channelName),
            ),
          );
        });
      }
    }

    if (segs.first == 'snaps') {
      final videoIdFromPath = segs.length >= 2
          ? Uri.decodeComponent(segs[1])
          : null;
      final videoIdFromQuery =
          uri.queryParameters['videoId'] ?? uri.queryParameters['v'];
      final videoId = (videoIdFromPath ?? videoIdFromQuery)?.trim();

      // Open Snaps tab.
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen(initialIndex: 1)),
        (_) => false,
      );

      // If a specific short id is provided, open it.
      if (videoId != null && videoId.isNotEmpty) {
        Future.microtask(() {
          nav.push(
            MaterialPageRoute(
              builder: (_) => ShortsFeedScreen(
                shorts: MockData.snaps,
                initialVideoId: videoId,
              ),
            ),
          );
        });
      }
    }
  }
}
