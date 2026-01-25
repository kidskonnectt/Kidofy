import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/screens/auth/login_screen.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/screens/root_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _subtextController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoGlow;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtextFade;

  @override
  void initState() {
    super.initState();

    // Logo animation: Smooth scale with rotation and glow effect
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotate = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Main text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
        );

    // Subtext animation
    _subtextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _subtextFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _subtextController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _logoController.forward();
    _textController.forward();
    _subtextController.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for animations to complete + min display time
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final user = SupabaseService.currentUser;
    if (user == null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      await SupabaseService.initializeData();

      if (!mounted) return;

      if (MockData.profiles.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AddKidScreen(goToHomeOnComplete: true),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RootScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top spacer for centering (flexible)
            Expanded(flex: 1, child: Container()),

            // Logo with modern animation - properly positioned
            ScaleTransition(
              scale: _logoScale,
              child: RotationTransition(
                turns: _logoRotate,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect background
                    ScaleTransition(
                      scale: _logoGlow,
                      child: Container(
                        width: isSmallScreen ? 160 : 180,
                        height: isSmallScreen ? 160 : 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Logo image - centered properly
                    SizedBox(
                      width: isSmallScreen ? 120 : 140,
                      height: isSmallScreen ? 120 : 140,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.videogame_asset_rounded,
                          size: 120,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 32 : 48),

            // Main title with modern typography
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Kidofy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 48 : 56,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Gen Z tagline with modern font
            FadeTransition(
              opacity: _subtextFade,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Entertainment for Every Kid',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 40 : 60),

            // Loading indicator
            FadeTransition(
              opacity: _subtextFade,
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryRed.withOpacity(0.7),
                  ),
                ),
              ),
            ),

            // Bottom spacer for balance
            Expanded(flex: 1, child: Container()),
          ],
        ),
      ),
    );
  }
}
