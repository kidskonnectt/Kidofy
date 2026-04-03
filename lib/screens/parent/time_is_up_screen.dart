import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidsapp/screens/parent/parent_gate_screen.dart';

class TimeIsUpScreen extends StatelessWidget {
  const TimeIsUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  color: AppColors.primaryRed,
                  size: 100,
                ),
              ).animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .shake(delay: 600.ms),
              const SizedBox(height: 48),
              Text(
                "Time's Up!",
                style: GoogleFonts.fredoka(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
              const SizedBox(height: 16),
              Text(
                "You've reached your daily screen time limit. It's time to take a break and play outside!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentGateScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Ask Parent for More Time",
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Simply exit the app or go back to profile selection
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  "Exit Now",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
