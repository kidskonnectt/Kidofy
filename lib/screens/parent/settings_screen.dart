import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/screens/settings/help_feedback_screen.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/screens/parent/refer_earn_screen.dart';
import 'package:kidsapp/screens/parent/parent_settings_detail_screen.dart';
import 'package:kidsapp/utils/content_level.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Profile? _selectedProfileForConfig;

  @override
  void initState() {
    super.initState();
    _selectedProfileForConfig = MockData.currentProfile.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Parent Dashboard",
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            onPressed: _showPasscodeSettings,
            icon: const Icon(Icons.lock_outline),
            tooltip: "Passcode Settings",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildKidSelector(),
            const SizedBox(height: 20),
            if (_selectedProfileForConfig != null)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _SettingCard(
                      icon: Icons.block,
                      title: "Content",
                      color: AppColors.accentBlue,
                      subtitle: ContentLevels.normalize(
                        _selectedProfileForConfig!.contentType,
                        fallbackAge: _selectedProfileForConfig!.age,
                        fallbackBirthMonth:
                            _selectedProfileForConfig!.birthMonth,
                      ),
                      onTap: _showContentLevelPicker,
                    ),
                    _SettingCard(
                      icon: Icons.history,
                      title: "History",
                      color: AppColors.accentGreen,
                      subtitle: "Full history",
                      onTap: _showWatchHistory,
                    ),
                    _SettingCard(
                      icon: Icons.offline_bolt,
                      title: "Offline",
                      color: AppColors.accentYellow,
                      subtitle: "Manage downloads",
                      onTap: _showOfflineManager,
                    ),
                    _SettingCard(
                      icon: Icons.block_flipped,
                      title: "Blocked",
                      color: Colors.redAccent,
                      subtitle: "Manage blocks",
                      onTap: () => _showBlockedContentManager(),
                    ),
                    _SettingCard(
                      icon: Icons.card_giftcard,
                      title: "Refer & Earn",
                      color: Colors.purpleAccent,
                      subtitle: "Invite Friends",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReferEarnScreen(),
                          ),
                        );
                      },
                    ),
                    _SettingCard(
                      icon: Icons.settings,
                      title: "Settings",
                      color: Colors.blueGrey,
                      subtitle: "Kids & Sign out",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ParentSettingsDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPasscodeSettings() {
    showDialog(
      context: context,
      builder: (c) {
        final passController = TextEditingController();
        return AlertDialog(
          title: const Text("Parent Passcode"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MockData.parentPasscode == null
                    ? "Set a passcode to replace math problems."
                    : "Update or remove your passcode.",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: "Enter 4-digit PIN",
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
                    const SnackBar(content: Text("Passcode Removed")),
                  );
                },
                child: const Text(
                  "Remove",
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
                  ).showSnackBar(const SnackBar(content: Text("Passcode Set")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showContentLevelPicker() async {
    final profile = _selectedProfileForConfig;
    if (profile == null) return;

    final options = ContentLevels.values;
    String selected = ContentLevels.normalize(
      profile.contentType,
      fallbackAge: profile.age,
      fallbackBirthMonth: profile.birthMonth,
    );

    await showModalBottomSheet(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Content Level",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (o) => RadioListTile<String>(
                      value: o,
                      // ignore: deprecated_member_use
                      groupValue: selected,
                      title: Text(o),
                      // ignore: deprecated_member_use
                      onChanged: (v) => setSheetState(() {
                        selected = v ?? selected;
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final sheetContext = context;
                        await SupabaseService.updateProfileContentType(
                          profileId: profile.id,
                          contentType: selected,
                        );
                        if (!mounted) return;
                        setState(() {
                          _selectedProfileForConfig = MockData.profiles
                              .firstWhere((p) => p.id == profile.id);
                        });
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Content level saved')),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWatchHistory() async {
    final profile = _selectedProfileForConfig;
    if (profile == null) return;

    final history = await ProfileLocalStore.getWatchHistory(profile.id);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        final videosById = {for (final v in MockData.videos) v.id: v};
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Watch History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Text('No history yet')
              else
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final id = history[index];
                      final video = videosById[id];
                      return ListTile(
                        title: Text(video?.title ?? 'Video $id'),
                        subtitle: Text(video?.channelName ?? ''),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        await ProfileLocalStore.clearWatchHistory(profile.id);
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('History cleared')),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOfflineManager() async {
    final profile = _selectedProfileForConfig;
    if (profile == null) return;

    var offlineIds = await ProfileLocalStore.getOfflineVideoIds(profile.id);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final videosById = {for (final v in MockData.videos) v.id: v};

            Future<void> refresh() async {
              offlineIds = await ProfileLocalStore.getOfflineVideoIds(
                profile.id,
              );
              if (!mounted) return;
              setSheetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offline',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (offlineIds.isEmpty)
                    const Text('No offline videos yet')
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        itemCount: offlineIds.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final id = offlineIds[index];
                          final video = videosById[id];
                          return ListTile(
                            title: Text(video?.title ?? 'Video $id'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ProfileLocalStore.removeOfflineVideo(
                                  profile.id,
                                  id,
                                );
                                await refresh();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Add Offline Video',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 320,
                                    child: ListView.builder(
                                      itemCount: MockData.videos.length,
                                      itemBuilder: (context, index) {
                                        final v = MockData.videos[index];
                                        final disabled = offlineIds.contains(
                                          v.id,
                                        );
                                        return ListTile(
                                          title: Text(v.title),
                                          subtitle: Text(v.channelName),
                                          trailing: disabled
                                              ? const Icon(Icons.check)
                                              : null,
                                          enabled: !disabled,
                                          onTap: disabled
                                              ? null
                                              : () => Navigator.pop(
                                                  context,
                                                  v.id,
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        if (picked == null) return;
                        await ProfileLocalStore.addOfflineVideo(
                          profile.id,
                          picked,
                        );
                        await refresh();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add video'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockedContentManager() {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        final profile = _selectedProfileForConfig;
        if (profile == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Select a kid first'),
          );
        }

        return FutureBuilder(
          future: SupabaseService.getBlockedContent(profile.id),
          builder: (context, snapshot) {
            final blocked =
                snapshot.data ??
                (videoIds: <String>{}, channelNames: <String>{});

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blocked Content',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('Blocked Channels:'),
                  const SizedBox(height: 6),
                  Wrap(
                    children: blocked.channelNames
                        .map(
                          (name) => Chip(
                            label: Text(name),
                            onDeleted: () async {
                              await SupabaseService.unblockItem(
                                profileId: profile.id,
                                itemId: name,
                                itemType: 'channel',
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showBlockedContentManager();
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text('Blocked Videos (IDs):'),
                  const SizedBox(height: 6),
                  Wrap(
                    children: blocked.videoIds
                        .map(
                          (id) => Chip(
                            label: Text(id),
                            onDeleted: () async {
                              await SupabaseService.unblockItem(
                                profileId: profile.id,
                                itemId: id,
                                itemType: 'video',
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showBlockedContentManager();
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKidSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Kids",
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...MockData.profiles.map((p) {
                  final isSelected = p.id == _selectedProfileForConfig?.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProfileForConfig = p;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentYellow
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(p.avatarUrl),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Stack(
                            children: [
                              if (isSelected)
                                Positioned(
                                  bottom: 2,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 8,
                                    color: AppColors.accentYellow.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddKidScreen(goToHomeOnComplete: false),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.add, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Add Kid",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} // End SettingsScreen

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
