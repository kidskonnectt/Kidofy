import 'package:flutter/material.dart';
import 'package:kidsapp/screens/settings/app_policies_screen.dart';
import 'package:kidsapp/screens/settings/report_problem_screen.dart';
import 'package:kidsapp/screens/settings/faqs_screen.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Feedback")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "How can we help you?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text("FAQs"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("Report a problem"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Contact Support"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email: contact@kidofy.in'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Policies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppPoliciesScreen(
                    title: 'Privacy Policy',
                    content: PolicyContent.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppPoliciesScreen(
                    title: 'Terms of Service',
                    content: PolicyContent.termsOfService,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Child Safety'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppPoliciesScreen(
                    title: 'Child Safety',
                    content: PolicyContent.childSafety,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Version 1.0.7"),
          ),
        ],
      ),
    );
  }
}
