import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: must initialize Firebase.
  // On unsupported platforms or missing config, ignore safely.
  try {
    await Firebase.initializeApp();
    debugPrint('📨 Background FCM message received: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
  } catch (e) {
    debugPrint('❌ Background FCM error: $e');
    return;
  }
}

class PushNotificationsService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'kidsapp_high_importance',
        'KidsApp Notifications',
        description: 'High importance notifications from Kidofy',
        importance: Importance.high,
      );

  /// Initialize FCM and local notifications
  static Future<void> initialize() async {
    if (_initialized) return;
    if (!_supported) {
      _initialized = true;
      debugPrint('⚠️ FCM not supported on this platform (Web/Unsupported)');
      return;
    }

    debugPrint('🔄 Initializing Firebase Cloud Messaging...');

    // Initialize local notifications (used to show foreground notifications)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('👆 Notification tapped by user');
      },
    );

    // Android: create notification channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_androidChannel);
      try {
        await androidPlugin.requestNotificationsPermission();
        debugPrint('✅ Android notification permission granted');
      } catch (e) {
        debugPrint('⚠️ Android notification permission denied: $e');
      }
    }

    // iOS: request notification permissions via FCM
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint(
        '✅ iOS notification permission: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('⚠️ iOS notification permission error: $e');
    }

    // iOS: ensure foreground notifications are presented
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App opened from notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔓 App opened from notification: ${message.messageId}');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
    });

    // Get and log token (Very useful for testing campaigns via "Test on device")
    _setupToken();

    // Subscribe to a generic topic for broadcast campaigns
    subscribeTopic('all_users');

    _initialized = true;
    debugPrint('✅ Firebase Cloud Messaging initialized successfully');
  }

  /// Get FCM token and save to Supabase if user is logged in
  static Future<void> _setupToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Token: $token');
        // Copy this token from debug console to Firebase Console "Test on device" 
        // to verify integration immediately.
        
        await _saveTokenToSupabase(token);
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token Refreshed: $newToken');
        _saveTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Save token to the fcm_tokens table in Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    // We use Supabase user since that's where the table is
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    
    if (supabaseUser == null) {
      debugPrint('ℹ️ FCM: No user logged in, skipping token save to DB');
      return;
    }

    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': supabaseUser.id,
        'fcm_token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('💾 FCM token saved to Supabase for user ${supabaseUser.id}');
    } catch (e) {
      debugPrint('❌ FCM: Failed to save token to Supabase - $e');
    }
  }


  /// Display foreground notification using local notifications
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    debugPrint('📬 Foreground notification received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) {
      debugPrint('⚠️ No notification payload in message');
      return;
    }

    debugPrint('   Title: ${notification.title}');
    debugPrint('   Body: ${notification.body}');

    final android = notification.android;

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Kidofy',
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color.fromARGB(255, 255, 69, 69), // Kidofy red
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
      debugPrint('✅ Local notification displayed');
    } catch (e) {
      debugPrint('❌ Error displaying notification: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (!_supported) return false;

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('⚠️ Error checking notification status: $e');
      return false;
    }
  }

  /// Request notification permissions explicitly
  static Future<void> requestNotificationPermissions() async {
    if (!_supported) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('✅ Notification permissions requested');
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  /// Subscribe to a topic (useful for broadcast notifications)
  static Future<void> subscribeTopic(String topic) async {
    if (!_supported) return;

    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('📬 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeTopic(String topic) async {
    if (!_supported) return;

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('📭 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
