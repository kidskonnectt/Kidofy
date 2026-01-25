import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';

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
      backgroundColor: AppColors.accentBlue, // Fun background color
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.play_circle_filled_rounded,
                      size: 50,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Kidofy",
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 40,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(
              begin: -0.5,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

            const Spacer(flex: 1),

            // Profiles List
            Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 30,
                children: [
                  ...MockData.profiles.map(
                    (profile) => _ProfileAvatar(profile: profile),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Parent Button
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.lock, color: Colors.white70),
                label: Text(
                  "Parent Settings",
                  style: GoogleFonts.fredoka(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Profile profile;
  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MockData.currentProfile.value = profile;
        SupabaseService.saveCurrentProfile(profile);
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(profile.avatarUrl),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 10),
          Text(
            profile.name,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
