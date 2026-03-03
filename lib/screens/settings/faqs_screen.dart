import 'package:flutter/material.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is Kidofy?',
      'answer':
          'Kidofy is a safe, kid-friendly video streaming platform designed specifically for children. It offers a curated collection of educational and entertainment content with parental controls to ensure a safe viewing experience.',
    },
    {
      'question': 'Is Kidofy safe for my children?',
      'answer':
          'Yes! Kidofy is designed with child safety as our top priority. All content is carefully curated and age-appropriate. Parents can set strict parental controls, choose content categories, and monitor viewing history. We comply with COPPA and other child protection regulations.',
    },
    {
      'question': 'How do I create an account?',
      'answer':
          'Simply open the Kidofy app and click "Sign Up". You can sign up using your email, Google account, or Apple ID. Follow the prompts to create your profile and add kid profiles.',
    },
    {
      'question': 'How do I add a kid profile?',
      'answer':
          'Go to Settings → Add Kid. Enter your child\'s name, age, and content preferences (Toddler, Preschool, Kids, Teens). You can create multiple profiles for different children.',
    },
    {
      'question': 'What are the age categories?',
      'answer':
          '• Toddler (2-4 years): Very basic, simple content\n• Preschool (4-6 years): Educational and fun content\n• Kids (6-12 years): Educational, adventure, and entertainment content\n• Teens (13+ years): More mature content with guidance',
    },
    {
      'question': 'How do I download videos to watch offline?',
      'answer':
          'Open any video and tap the Download icon. The video will be saved to your device and available in the Library even without internet. Downloaded videos are linked to individual kid profiles.',
    },
    {
      'question': 'How do parental controls work?',
      'answer':
          'Parents can set a PIN code to access parent settings. Control content by age category, set watch time limits, view watch history, create custom content playlists, and manage screen time for each child.',
    },
    {
      'question': 'How do I set a parent PIN?',
      'answer':
          'Go to Settings → Parent Settings → Security. Set a 4-digit PIN. This PIN is required to access parent controls and change settings. Keep it safe and don\'t share it with kids!',
    },
    {
      'question': 'Why can\'t I access parent settings?',
      'answer':
          'You may need to enter your parent PIN. If you forgot your PIN, use the "Forgot PIN?" option to reset it through your registered email. You\'ll need to verify your identity.',
    },
    {
      'question': 'How do I check my child\'s viewing history?',
      'answer':
          'Go to Settings → Parent Settings → View History. Select the kid profile to see what they\'ve watched, when they watched it, and how long they watched.',
    },
    {
      'question': 'Can I set screen time limits?',
      'answer':
          'Yes! Go to Settings → Parent Settings → Screen Time. Set daily watch limits, and the app will notify kids when time is running out. After the limit, they\'ll need to ask for more time.',
    },
    {
      'question': 'What internet speed do I need?',
      'answer':
          '• For HD (720p): 5 Mbps minimum\n• For Full HD (1080p): 10 Mbps recommended\n• For offline downloads: 3 Mbps minimum\nWifi connection is recommended for downloads.',
    },
    {
      'question': 'Can I watch on multiple devices?',
      'answer':
          'Yes! You can watch on phones, tablets, and Kindle Fire devices. Sign in with the same account on each device. Premium plans allow simultaneous streaming on multiple devices.',
    },
    {
      'question': 'How do I report inappropriate content?',
      'answer':
          'Tap the three-dot menu on any video and select "Report Problem". Choose the reason and provide details. Our team reviews all reports within 24 hours.',
    },
    {
      'question': 'How do I update my payment method?',
      'answer':
          'Go to Settings → Account → Payment Method. Update your card, PayPal, or other payment details. Changes apply to your next billing cycle.',
    },
    {
      'question': 'How do I cancel my subscription?',
      'answer':
          'Go to Settings → Account → Subscription. Tap "Cancel Subscription". You\'ll have access until your billing cycle ends. No refunds for partial months.',
    },
    {
      'question': 'What happens if I delete a kid profile?',
      'answer':
          'All viewing history, watch list, and downloaded content for that profile will be permanently deleted. This cannot be undone. Be sure before confirming.',
    },
    {
      'question': 'How do I share videos with friends?',
      'answer':
          'Open a video and tap the Share icon. You can share the video link via WhatsApp, Email, or other messaging apps. Friends can open the link in Kidofy or your website.',
    },
    {
      'question': 'Does Kidofy have ads?',
      'answer':
          'Yes, our free plan includes ads. Premium subscribers enjoy an ad-free experience. Ads shown are always kid-safe and appropriate.',
    },
    {
      'question': 'Why am I seeing different content on web vs. app?',
      'answer':
          'The app and web may have slightly different libraries due to licensing. Both are regularly updated. Make sure you\'re signed into the same account.',
    },
    {
      'question': 'How often is new content added?',
      'answer':
          'We add new content weekly! Check the "New & Popular" section to see the latest additions. You\'ll also get notifications for new content in your favorite categories.',
    },
    {
      'question': 'Can I rename a kid profile?',
      'answer':
          'Yes! Go to Settings → Manage Kids → Edit Profile. Change the name, age, or content category. This won\'t affect their viewing history.',
    },
    {
      'question': 'What should I do if the app crashes?',
      'answer':
          '1. Force close the app\n2. Clear the app cache (Settings → Apps → Kidofy → Storage → Clear Cache)\n3. Restart your device\n4. Reinstall the app if issue persists\nContact support if problems continue.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onExpansionChanged: (_) {},
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    faq['answer']!,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
