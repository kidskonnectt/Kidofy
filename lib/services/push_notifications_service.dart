import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: must initialize Firebase.
  // On unsupported platforms or missing config, ignore safely.
  try {
    await Firebase.initializeApp();
  } catch (_) {
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
        description: 'General notifications',
        importance: Importance.high,
      );

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!_supported) {
      _initialized = true;
      return;
    }

    // Initialize local notifications (used to show foreground notifications).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('Notification tapped: ${resp.payload}');
      },
    );

    // Android: create channel.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_androidChannel);
      // Android 13+: runtime notification permission.
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS: ask permission via FCM.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: ensure foreground notifications are presented.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages: display a local notification.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App opened from notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Opened from notification: ${message.messageId}');
    });

    // Token (useful for testing; you can store it in DB later).
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }

    _initialized = true;
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: android?.smallIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
