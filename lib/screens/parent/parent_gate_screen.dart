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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
