import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPoliciesScreen extends StatelessWidget {
  final String title;
  final String content;

  const AppPoliciesScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.fredoka(color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
      ),
    );
  }
}

class PolicyContent {
  static const String privacyPolicy = """
Privacy Policy for KidsKonnect

Last updated: January 2026

1. Who this policy applies to
KidsKonnect is designed for children to use under parent/guardian supervision. Parents/guardians create and manage accounts.

2. Data we collect
- Parent account information (e.g., email) for login and support
- Child profile information you provide (e.g., nickname, age range) to personalize content
- Basic usage data (e.g., viewed videos) to improve recommendations and safety

3. How we use data
- To provide the app’s core features (profiles, recommendations, downloads)
- To keep the experience safe (blocking, reporting, moderation)
- To maintain and improve the service

4. Sharing
We do not sell children’s personal data. We may share limited data with service providers only as needed to run the app.

5. Contact
Contact us at contact@kidofy.in for privacy questions.
""";

  static const String termsOfService = """
Terms of Service

1. Acceptance
By using KidsKonnect, you agree to these terms.

2. Usage
This app is for children under parental supervision.

3. Content
We strive to filter content but cannot guarantee 100% accuracy. Parents should monitor usage.

4. Termination
We reserve the right to ban accounts violating our policies.
""";

  static const String childSafety = """
Child Safety Measures

1. Curated Content
All videos are pre-screened or come from safe channels.

2. Parental Controls
Parents can block videos/channels and view watch history.

3. Ad-Free
We strive to keep the environment free of inappropriate ads.

4. Reporting
Please use the report button if you see unsafe content.
""";
}
