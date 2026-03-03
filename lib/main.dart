import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/ads_service.dart';
import 'package:kidsapp/services/connectivity_service.dart';
import 'package:kidsapp/services/push_notifications_service.dart';
import 'package:kidsapp/services/snaps_preload_service.dart';
import 'package:kidsapp/screens/parent/parent_gate_screen.dart';
import 'package:kidsapp/screens/parent/settings_screen.dart';
import 'package:kidsapp/screens/profile/profile_selection_screen.dart';
import 'package:kidsapp/screens/auth/login_screen.dart';
import 'package:kidsapp/screens/auth/onboarding_screen.dart';
import 'package:kidsapp/screens/splash_screen.dart';
import 'package:kidsapp/screens/root_screen.dart';
import 'package:kidsapp/services/deep_link_service.dart';
import 'package:kidsapp/screens/contacts_screen.dart';
import 'package:kidsapp/screens/premium/premium_screen.dart';
import 'package:kidsapp/providers/premium_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Messaging only makes sense on Android/iOS.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      await PushNotificationsService.initialize();
    } catch (e) {
      // Non-fatal: app should still run even if Firebase isn't configured.
    }
  }

  await AdsService.initialize();

  await Supabase.initialize(
    url: 'https://dbutdmopzqgvkuzpwqbb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRidXRkbW9wenFndmt1enB3cWJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMzI0MzYsImV4cCI6MjA4MzgwODQzNn0.KFUKvZw4fQNNzWzBbhcpHN1piw9sjmMpum4J05WRMYo',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Web OAuth: Supabase redirects back with ?code=... (PKCE).
  // Exchange it here so `currentUser` is available before routing/data loads.
  if (kIsWeb) {
    final code = Uri.base.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      } catch (_) {
        // Non-fatal: UI will show login if session couldn't be created.
      }
    }
  }

  await SupabaseService.initializeData();

  // Start background preloading of first snaps videos
  SnapsPreloadService.startBackgroundPreload();

  runApp(const KidsApp());
}

class KidsApp extends StatelessWidget {
  const KidsApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  Widget build(BuildContext context) {
    // Start deep-link handling once the widget tree exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.start(navigatorKey);
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => ContactsSyncProvider()),
        ChangeNotifierProvider(create: (_) => PremiumNotifier()),
      ],
      child: MaterialApp(
        title: 'Kidofy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(), // Changed key for clarity
          '/profile_select': (context) => const ProfileSelectionScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const RootScreen(),
          '/settings': (context) => const ParentGateScreen(),
          '/parent_settings': (context) => const SettingsScreen(),
          '/premium': (context) => const PremiumScreen(),
        },
      ),
    );
  }
}
