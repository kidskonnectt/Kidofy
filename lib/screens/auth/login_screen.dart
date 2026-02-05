import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/deep_link_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidsapp/screens/auth/signup_screen.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/screens/root_screen.dart';
import 'package:kidsapp/screens/home/channel_screen.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late final StreamSubscription<AuthState> _authSub;
  bool _handledSignedIn = false;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session == null) return;
      if (_handledSignedIn) return;
      _handledSignedIn = true;
      _onSignedIn();
    });
  }

  Future<void> _onSignedIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.initializeData();

      if (!mounted) return;
      if (MockData.profiles.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AddKidScreen(goToHomeOnComplete: true),
          ),
        );
      } else {
        final pending = DeepLinkService.consumePendingContentUri();
        final nav = Navigator.of(context);

        if (pending != null && pending.scheme == 'https') {
          final segs = pending.pathSegments;
          if (segs.isNotEmpty && segs.first == 'channel') {
            // Home tab as the base.
            nav.pushReplacement(
              MaterialPageRoute(
                builder: (_) => const RootScreen(initialIndex: 0),
              ),
            );

            final nameFromPath = segs.length >= 2
                ? Uri.decodeComponent(segs[1])
                : null;
            final nameFromQuery = pending.queryParameters['name'];
            final channelName = (nameFromPath ?? nameFromQuery)?.trim();

            if (channelName != null && channelName.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                nav.push(
                  MaterialPageRoute(
                    builder: (_) => ChannelScreen(channelName: channelName),
                  ),
                );
              });

              if (segs.isNotEmpty && segs.first == 'snaps') {
                final idFromPath = segs.length >= 2
                    ? Uri.decodeComponent(segs[1])
                    : null;
                final idFromQuery =
                    pending.queryParameters['videoId'] ??
                    pending.queryParameters['v'];
                final videoId = (idFromPath ?? idFromQuery)?.trim();

                // Snaps tab as the base.
                nav.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const RootScreen(initialIndex: 1),
                  ),
                );

                if (videoId != null && videoId.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
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
        } else {
          nav.pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Signed in, but failed to load data: $e';
        _handledSignedIn = false;
      });
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await SupabaseService.signIn(email, password);
      // Tell the OS that the login flow completed so it can offer to save
      // credentials (Android/iOS password manager).
      TextInput.finishAutofillContext();
      // Navigation happens via auth state listener.
    } on SocketException {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error: unable to reach the server. Check internet/DNS and try again.';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔐 LoginScreen: Starting Google Sign-In...');
      final sessionReady = await SupabaseService.signInWithGoogle();

      if (!sessionReady) {
        if (mounted) {
          debugPrint('⚠️ LoginScreen: Web flow - waiting for browser redirect');
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Complete Google sign-in in the browser, then return to the app.';
          });
        }
        return;
      }

      debugPrint('✅ LoginScreen: Google Sign-In session ready');
      // Navigation happens via auth state listener.
    } on SocketException catch (e) {
      if (mounted) {
        debugPrint('❌ LoginScreen: SocketException - ${e.message}');
        setState(() {
          _errorMessage =
              'Network error: unable to reach the server. Check internet/DNS and try again.';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        debugPrint('❌ LoginScreen: AuthException - ${e.message}');
        setState(() {
          final msg = e.message.toLowerCase();

          // Handle specific errors with helpful messages
          if (msg.contains('apierception: 10')) {
            _errorMessage =
                'Google Sign-In not configured. Add SHA-1 and SHA-256 fingerprints in Firebase Console (Settings > Signing Certificate).';
          } else if (msg.contains('canceled') || msg.contains('cancelled')) {
            _errorMessage = null; // User cancelled, not an error
          } else if (msg.contains('configuration') ||
              msg.contains('firebase')) {
            _errorMessage =
                'Firebase/Google Sign-In configuration error. Verify google-services.json is present and package name matches Firebase.';
          } else if (msg.contains('package') || msg.contains('com.kidofy')) {
            _errorMessage =
                'Package name mismatch. Ensure com.kidofy.kidsapp is registered in Firebase.';
          } else if (msg.contains('timeout')) {
            _errorMessage =
                'Google Sign-In timed out. Check your internet connection and try again.';
          } else {
            _errorMessage = "Google Sign In: ${e.message}";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ LoginScreen: Unexpected error - $e');
        setState(() {
          final msg = e.toString().toLowerCase();
          if (msg.contains('apierception: 10')) {
            _errorMessage =
                'SHA-1/SHA-256 certificate fingerprint mismatch in Firebase.';
          } else if (msg.contains('configuration')) {
            _errorMessage =
                'Google Sign-In misconfigured. Check Firebase Console.';
          } else if (msg.contains('timeout')) {
            _errorMessage =
                'Request timed out. Please check your internet and try again.';
          } else {
            _errorMessage = "Google Sign In failed: $e";
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 130,
                  height: 130,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.play_circle_filled_rounded,
                    size: 110,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Kidofy",
                textAlign: TextAlign.center,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 48,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 40),

              Text(
                "Welcome Parents!",
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Log in to manage profiles and settings.",
                style: GoogleFonts.fredoka(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              AutofillGroup(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onEditingComplete: _isLoading ? null : _login,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Log In"),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _loginWithGoogle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata, size: 30),
                label: _isLoading
                    ? const Text("Signing in...")
                    : const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(
                    color: _isLoading ? Colors.grey[300]! : Colors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  disabledForegroundColor: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New here? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "By continuing, you agree to our Terms of Service and Privacy Policy for Kids.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
