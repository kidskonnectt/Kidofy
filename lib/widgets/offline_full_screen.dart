import 'package:flutter/material.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/theme/app_theme.dart';

class OfflineFullScreen extends StatelessWidget {
  const OfflineFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              // Title
              const Text(
                "You're offline",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                "Turn on mobile data or Wi-Fi to connect.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              // Retry / Spinner
              // Note: The prompt says "show like this 1st img ... with the same loading spinner"
              // The image likely has a retry button or a spinner.
              // Usually offline screens have a "Retry" button.
              // If the user clicks retry and it's still offline, we show spinner then back to this.
              // I'll implement a Retry button that spins when clicked.
              _RetryButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _loading = false;

  Future<void> _retry() async {
    setState(() {
      _loading = true;
    });
    // Wait a bit to simulate check or let the connectivity service update
    await Future.delayed(const Duration(seconds: 1));
    await SupabaseService.initializeData();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.primaryRed,
          strokeWidth: 2,
        ),
      );
    }

    return TextButton(
      onPressed: _retry,
      child: const Text(
        "RETRY",
        style: TextStyle(
          color: AppColors.primaryRed,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
