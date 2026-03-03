import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'dart:math';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MockData.profiles.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AddKidScreen(goToHomeOnComplete: true),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Beautiful gradient background - light, bright, and colorful
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF0F9FF), // Very light blue
                  const Color(0xFFE0F7FF), // Light sky blue
                  const Color(0xFFE8F4FD), // Soft blue
                ],
              ),
            ),
          ),

          // Add soft colored overlay shapes for visual interest
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentYellow.withValues(alpha: 0.05),
              ),
            ),
          ),

          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Decorative 2D painting elements in background
          ..._buildDecorativePaintings(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Title with creative styling
                Text(
                  "Select Your Profile",
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 42,
                    color: AppColors.textDark,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ).animate().slideY(
                  begin: -0.5,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

                const SizedBox(height: 10),

                // Decorative line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 800.ms),

                const SizedBox(height: 30),

                // Profiles Grid
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 25,
                        runSpacing: 40,
                        alignment: WrapAlignment.center,
                        children: [
                          ...MockData.profiles.asMap().entries.map(
                            (entry) => _ProfileAvatar(
                              profile: entry.value,
                              index: entry.key,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Parent Settings Button with creative styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppColors.primaryRed.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Parent Settings",
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().slideY(
                  begin: 0.5,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build decorative 2D painting elements
  List<Widget> _buildDecorativePaintings() {
    return [
      // Top left: Curved paint strokes
      Positioned(
        top: 30,
        left: 10,
        child: CustomPaint(
          size: const Size(120, 120),
          painter: PaintStrokePainter(
            color: AppColors.accentBlue.withValues(alpha: 0.25),
          ),
        ).animate().fadeIn(duration: 1000.ms),
      ),

      // Top right: Circle and lines
      Positioned(
        top: 50,
        right: 15,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.accentYellow.withValues(alpha: 0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 1200.ms),
      ),

      // Bottom left: Paint splatter style
      Positioned(
        bottom: 100,
        left: 20,
        child: CustomPaint(
          size: const Size(100, 100),
          painter: SplatterPainter(
            color: AppColors.accentGreen.withValues(alpha: 0.25),
          ),
        ).animate().fadeIn(duration: 1400.ms),
      ),

      // Bottom right: Wavy lines
      Positioned(
        bottom: 80,
        right: 20,
        child: CustomPaint(
          size: const Size(120, 80),
          painter: WavePainter(
            color: AppColors.accentBlue.withValues(alpha: 0.25),
          ),
        ).animate().fadeIn(duration: 1600.ms),
      ),

      // Center left: small dots pattern with multiple colors
      Positioned(
        top: 250,
        left: 15,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildColorDot(AppColors.accentBlue, 0.3),
            _buildColorDot(AppColors.accentYellow, 0.35),
            _buildColorDot(AppColors.accentGreen, 0.3),
            _buildColorDot(AppColors.primaryRed, 0.25),
            _buildColorDot(AppColors.accentBlue, 0.28),
            _buildColorDot(AppColors.accentYellow, 0.32),
          ],
        ).animate().fadeIn(duration: Duration(milliseconds: 800)),
      ),
    ];
  }

  Widget _buildColorDot(Color color, double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final Profile profile;
  final int index;
  const _ProfileAvatar({required this.profile, required this.index});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MockData.currentProfile.value = widget.profile;
        SupabaseService.saveCurrentProfile(widget.profile);
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: Column(
          children: [
            // Profile Avatar Container with decorative elements
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow circle
                if (_isHovered)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOut),

                // Main avatar circle with border
                Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accentBlue.withValues(alpha: 0.9),
                            AppColors.accentGreen.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(
                              alpha: _isHovered ? 0.4 : 0.2,
                            ),
                            blurRadius: _isHovered ? 30 : 20,
                            spreadRadius: _isHovered ? 5 : 0,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(widget.profile.avatarUrl),
                      ),
                    )
                    .animate()
                    .scale(
                      delay: Duration(milliseconds: widget.index * 100),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .animate(
                      onPlay: _isHovered
                          ? (controller) => controller.repeat()
                          : null,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),

                // Decorative stars around avatar
                if (_isHovered) _buildDecorativeStar(0, 30),
                if (_isHovered) _buildDecorativeStar(90, 30),
                if (_isHovered) _buildDecorativeStar(180, 30),
                if (_isHovered) _buildDecorativeStar(270, 30),
              ],
            ),

            const SizedBox(height: 16),

            // Profile name with creative styling
            Text(
                  widget.profile.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: widget.index * 100 + 300),
                  duration: 400.ms,
                )
                .animate(
                  onPlay: _isHovered
                      ? (controller) => controller.repeat()
                      : null,
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ),

            // Tap indicator
            if (!_isHovered)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child:
                    Text(
                          "Tap to play",
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: AppColors.primaryRed.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 1000.ms)
                        .then()
                        .fadeOut(duration: 1000.ms),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeStar(double angle, double distance) {
    final radian = angle * (3.14159 / 180);
    final offsetX = distance * cos(radian);
    final offsetY = distance * sin(radian);

    return Positioned(
      left: 64 + offsetX,
      top: 64 + offsetY,
      child: Text('⭐', style: const TextStyle(fontSize: 24))
          .animate()
          .scale(duration: 400.ms, curve: Curves.easeOut)
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(begin: 0, end: 6.28, duration: 3000.ms, curve: Curves.linear),
    );
  }
}

// Custom painter for paint stroke effect
class PaintStrokePainter extends CustomPainter {
  final Color color;
  PaintStrokePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Curved stroke
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.3,
      0,
      size.width * 0.6,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.6,
      size.width,
      size.height * 0.8,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PaintStrokePainter oldDelegate) => false;
}

// Custom painter for splatter effect
class SplatterPainter extends CustomPainter {
  final Color color;
  SplatterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final random = Random(42);

    // Draw splatter dots
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 6.28;
      final distance = random.nextDouble() * 40;
      final radius = random.nextDouble() * 3 + 1;

      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(SplatterPainter oldDelegate) => false;
}

// Custom painter for wave effect
class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const waveHeight = 20.0;
    const waveFrequency = 0.1;

    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height * 0.5 + waveHeight * sin((x * waveFrequency));
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}
