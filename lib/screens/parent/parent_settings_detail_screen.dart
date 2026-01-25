import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/theme/app_theme.dart';

class ParentSettingsDetailScreen extends StatefulWidget {
  const ParentSettingsDetailScreen({super.key});

  @override
  State<ParentSettingsDetailScreen> createState() =>
      _ParentSettingsDetailScreenState();
}

class _ParentSettingsDetailScreenState
    extends State<ParentSettingsDetailScreen> {
  bool _isSigningOut = false;

  Future<void> _removeKid(Profile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Kid'),
        content: Text('Remove ${profile.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await SupabaseService.deleteProfile(profile.id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kid removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _addKid() async {
    final didAdd = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddKidScreen(goToHomeOnComplete: false),
      ),
    );

    if (didAdd == true) {
      // AddKidScreen should update the backend; refresh local list.
      await SupabaseService.initializeData();
      if (!mounted) return;
      setState(() {});
    }
  }

  void _showPasscodeSettings() {
    showDialog(
      context: context,
      builder: (c) {
        final passController = TextEditingController();
        return AlertDialog(
          title: const Text('Parent Passcode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MockData.parentPasscode == null
                    ? 'Set a passcode to replace math problems.'
                    : 'Update or remove your passcode.',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                ),
              ),
            ],
          ),
          actions: [
            if (MockData.parentPasscode != null)
              TextButton(
                onPressed: () {
                  setState(() => MockData.parentPasscode = null);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passcode Removed')),
                  );
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () {
                if (passController.text.length == 4) {
                  setState(() => MockData.parentPasscode = passController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Passcode Set')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await SupabaseService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = MockData.profiles;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'Settings',
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showPasscodeSettings,
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Passcode Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kids',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addKid,
                icon: const Icon(Icons.add),
                label: const Text('Add Kid'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profiles.isEmpty)
            Text('No kids yet.', style: GoogleFonts.fredoka(color: Colors.grey))
          else
            ...profiles.map(
              (p) => Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p.avatarUrl.isEmpty
                        ? null
                        : NetworkImage(p.avatarUrl),
                    child: p.avatarUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    p.name,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Age ${p.age} • ${p.contentType}',
                    style: GoogleFonts.fredoka(fontSize: 13),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeKid(p),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSigningOut ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(_isSigningOut ? 'Signing out...' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}
