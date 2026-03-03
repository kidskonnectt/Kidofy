import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:kidsapp/models/mock_data.dart';

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  // Math Mode
  late int num1;
  late int num2;
  late int answer;

  // Passcode Mode
  bool get isPasscodeMode => MockData.parentPasscode != null;

  final TextEditingController _controller = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    if (!isPasscodeMode) {
      _generateProblem();
    }
  }

  void _generateProblem() {
    final random = Random();
    num1 = random.nextInt(9) + 1;
    num2 = random.nextInt(9) + 1;
    answer = num1 * num2;
    setState(() {});
  }

  void _checkAnswer() {
    if (isPasscodeMode) {
      if (_controller.text == MockData.parentPasscode) {
        Navigator.pushReplacementNamed(context, '/parent_settings');
      } else {
        setState(() {
           error = "Wrong Passcode!";
           _controller.clear();
        });
      }
    } else {
      if (_controller.text == answer.toString()) {
        Navigator.pushReplacementNamed(context, '/parent_settings');
      } else {
        setState(() {
          error = "Oops! Try again.";
          _controller.clear();
        });
      }
    }
  }

  void _showForgotPasscodeDialog() {
    final answerController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Verify Your Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MockData.parentSecurityQuestion ?? 'What is your child first name?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(
                hintText: 'Enter your answer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final userAnswer = answerController.text.toLowerCase().trim();
              final correctAnswer = MockData.parentSecurityAnswer?.toLowerCase().trim();
              
              if (userAnswer == correctAnswer) {
                Navigator.pop(c);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Your Passcode'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your passcode is:',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            MockData.parentPasscode ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('Wrong answer!')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      appBar: AppBar(
        leading: const CloseButton(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 48,
                color: AppColors.deepPurple,
              ),
              const SizedBox(height: 16),
              Text(
                "For Parents Only",
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPasscodeMode ? "Enter Passcode" : "Please solve this to continue:",
                style: GoogleFonts.fredoka(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (!isPasscodeMode)
                Text(
                  "$num1 x $num2 = ?",
                  style: GoogleFonts.fredoka(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: isPasscodeMode, // Hide text if passcode
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Answer",
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  child: const Text("Submit"),
                ),
              ),              if (isPasscodeMode) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showForgotPasscodeDialog,
                  child: Text(
                    'Forgot Passcode?',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryRed,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],            ],
          ),
        ),
      ),
    );
  }
}
