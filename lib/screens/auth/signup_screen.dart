import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _errorMessage;

  void _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_acceptTerms) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please accept Terms of Service and Privacy Policy";
          _isLoading = false;
        });
      }
      return;
    }

    if (phone.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please enter your phone number";
          _isLoading = false;
        });
      }
      return;
    }

    if (phone.length < 10) {
      if (mounted) {
        setState(() {
          _errorMessage = "Phone number must be at least 10 digits";
          _isLoading = false;
        });
      }
      return;
    }

    if (password != confirmPassword) {
      if (mounted) {
        setState(() {
          _errorMessage = "Passwords do not match";
          _isLoading = false;
        });
      }
      return;
    }

    if (password.length < 6) {
      if (mounted) {
        setState(() {
          _errorMessage = "Password must be at least 6 characters";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final response = await SupabaseService.signUp(email, password);

      // Check if session is established (Auto confirm disabled?) or if user needs to confirm email
      if (response.session != null) {
        // Save phone number to users table
        await SupabaseService.client
            .from('users')
            .update({'phone_number': phone})
            .eq('id', response.user!.id);

        await SupabaseService.initializeData();
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AddKidScreen(goToHomeOnComplete: true),
          ),
        );
      } else {
        if (!mounted) return;
        // User created but needs email confirmation
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Account created! Please check your email to confirm.",
            ),
          ),
        );
        navigator.pop(); // Go back to login
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 36,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "10 digit number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "I accept Terms of Service and Privacy Policy",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
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
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
