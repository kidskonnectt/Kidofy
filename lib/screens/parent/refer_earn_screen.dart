import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _contactsGranted = false;
  bool _loadingContacts = false;
  List<Contact> _contacts = <Contact>[];
  List<Contact> _filtered = <Contact>[];

  String get _refCode {
    return SupabaseService.currentUser?.id.substring(0, 6).toUpperCase() ??
        'KIDSAPP';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join Kidofy using my code: $_refCode\nhttps://kidofy.in',
      ),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _refCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied')));
  }

  Future<void> _requestContacts() async {
    setState(() {
      _loadingContacts = true;
    });
    try {
      if (await FlutterContacts.requestPermission()) {
        if (!mounted) return;
        setState(() {
          _contactsGranted = true;
        });
        await _loadContacts();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingContacts = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (granted && mounted) {
      setState(() {
        _contactsGranted = true;
      });
      _loadContacts(); // Auto load if granted
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loadingContacts = true;
    });

    try {
      final all = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      if (!mounted) return;
      setState(() {
        _contacts = all;
        _filtered = _applyFilter(all, _searchController.text);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContacts = false;
        });
      }
    }
  }

  List<Contact> _applyFilter(List<Contact> input, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((c) {
      final name = c.displayName.toLowerCase();
      final phones = c.phones.map((p) => p.number.toLowerCase()).join(' ');
      final emails = c.emails.map((e) => e.address.toLowerCase()).join(' ');
      return name.contains(q) || phones.contains(q) || emails.contains(q);
    }).toList();
  }

  Future<void> _inviteContact(Contact c) async {
    final email = c.emails.isNotEmpty ? c.emails.first.address.trim() : '';
    final phone = c.phones.isNotEmpty ? c.phones.first.number.trim() : '';

    // Best-effort: store the invite (the DB column is named `referred_email`,
    // but we allow storing phone if email is unavailable).
    final key = email.isNotEmpty ? email : phone;
    if (key.isNotEmpty) {
      try {
        await InteractionService.referUser(key);
      } catch (_) {
        // ignore
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Hey ${c.displayName}, join Kidofy using my referral code: $_refCode\nhttps://kidofy.in',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF08365A), Color(0xFF0B4A78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refer friends &\nget rewards',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _share,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Invite friends'),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'How it works',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your referral code: $_refCode',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _step(
            icon: Icons.person_add_alt_rounded,
            title: 'Invite your friends',
            subtitle: 'Share your code with friends and family.',
          ),
          _step(
            icon: Icons.verified_rounded,
            title: 'Friend joins Kidofy',
            subtitle:
                'When they sign up using your code, it counts as a referral.',
          ),
          _step(
            icon: Icons.workspace_premium_rounded,
            title: 'Get rewards',
            subtitle: 'Your referral status updates after verification.',
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refer friends',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_contactsGranted)
                IconButton(
                  onPressed: _loadContacts,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reload contacts',
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (!_contactsGranted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contacts access',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Allow access to show your contacts and invite them easily.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingContacts ? null : _requestContacts,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(
                        _loadingContacts ? 'Requesting…' : 'Allow access',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search contacts',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _filtered = _applyFilter(_contacts, v);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_loadingContacts)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No contacts found.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filtered.length.clamp(0, 50),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        final subtitle = c.phones.isNotEmpty
                            ? c.phones.first.number
                            : (c.emails.isNotEmpty
                                  ? c.emails.first.address
                                  : '');
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryRed.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              (c.displayName.isNotEmpty
                                      ? c.displayName[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            c.displayName.isEmpty ? 'Unknown' : c.displayName,
                          ),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          trailing: TextButton(
                            onPressed: () => _inviteContact(c),
                            child: const Text('Invite'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _step({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
