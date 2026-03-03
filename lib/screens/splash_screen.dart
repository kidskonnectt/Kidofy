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
  late AnimationController _spinnerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoGlow;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtextFade;

  @override
  void initState() {
    super.initState();

    // Spinner rotation - fast
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo animation: Smooth scale with rotation and glow effect
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoGlow = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Main text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    // Subtext animation
    _subtextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _subtextFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _subtextController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations sequentially
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _subtextController.forward();
    });

    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for minimal animations + min display time with extra delay
    await Future.delayed(const Duration(seconds: 2));

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
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Kid-friendly decorative background elements
          Positioned(
            top: -20,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB6C1).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF87CEEB).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF98FB98).withOpacity(0.15),
              ),
            ),
          ),
          // Decorative stars
          Positioned(
            top: 60,
            left: 30,
            child: Text(
              '⭐',
              style: TextStyle(
                fontSize: 28,
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 50,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 24,
                color: Colors.purple.withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 40,
            child: Text(
              '🎨',
              style: TextStyle(
                fontSize: 32,
                color: Colors.red.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 30,
            child: Text(
              '🎭',
              style: TextStyle(
                fontSize: 28,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 60,
            child: Text(
              '🎵',
              style: TextStyle(
                fontSize: 24,
                color: Colors.blue.withOpacity(0.22),
              ),
            ),
          ),

          // Main content
          SafeArea(
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

                // Modern tagline with "Edutainment"
                FadeTransition(
                  opacity: _subtextFade,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Edutainment for Every Kid',
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

                // Modern fast loading spinner
                FadeTransition(
                  opacity: _subtextFade,
                  child: _buildModernSpinner(),
                ),

                // Bottom spacer for balance
                Expanded(flex: 1, child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSpinner() {
    return RotationTransition(
      turns: _spinnerController,
      child: CustomPaint(painter: _SpinnerPainter(), size: const Size(50, 50)),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle - gradient arc
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.primaryRed.withOpacity(0.2),
          AppColors.primaryRed.withOpacity(0.8),
          AppColors.primaryRed.withOpacity(0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw arc from 0 to 270 degrees
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.0, // 240 degrees in radians ≈ 4.2
      false,
      paint,
    );

    // Inner circle - accent dots
    final dotPaint = Paint()
      ..color = AppColors.primaryRed.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx + radius - 6, center.dy), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => false;
}
