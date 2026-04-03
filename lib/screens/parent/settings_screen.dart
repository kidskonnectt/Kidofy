import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/screens/settings/help_feedback_screen.dart';
import 'package:kidsapp/screens/parent/add_kid_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/profile_local_store.dart';

import 'package:kidsapp/screens/parent/parent_settings_detail_screen.dart';
import 'package:kidsapp/screens/premium/premium_screen.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/providers/premium_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Profile? _selectedProfileForConfig;
  int _currentTimeLimit = 0;

  @override
  void initState() {
    super.initState();
    _selectedProfileForConfig = MockData.currentProfile.value;
    _fetchLimit();
  }

  void _fetchLimit() async {
    if (_selectedProfileForConfig != null) {
      final limit = await ProfileLocalStore.getTimerLimitMinutes(
        _selectedProfileForConfig!.id,
      );
      if (mounted) {
        setState(() {
          _currentTimeLimit = limit;
        });
      }
    }
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
                      icon: Icons.timer,
                      title: "Time Limit",
                      color: AppColors.primaryRed,
                      subtitle:
                          _currentTimeLimit == 0
                              ? "Unlimited Time"
                              : "$_currentTimeLimit mins set",
                      onTap: () => _handleTimeLimitTap(context),
                      isLocked: !context.watch<PremiumNotifier>().hasActivePremium,
                    ),
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
                      icon: Icons.workspace_premium,
                      title: "Premium",
                      color: AppColors.primaryRed,
                      subtitle: "Unlock features",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PremiumScreen(),
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
        final answerController = TextEditingController();
        
        return AlertDialog(
          title: const Text("Parent Passcode"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MockData.parentPasscode == null
                      ? "Set a passcode to replace math problems."
                      : "Update or remove your passcode.",
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Enter 4-digit PIN",
                    labelText: "Passcode",
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text(
                  "Security Question (for recovery)",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    MockData.parentSecurityQuestion ?? "What is your child first name?",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    hintText: "Enter your answer",
                    labelText: "Answer",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (MockData.parentPasscode != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    MockData.parentPasscode = null;
                    MockData.parentSecurityAnswer = null;
                  });
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (passController.text.length == 4 && answerController.text.isNotEmpty) {
                  setState(() {
                    MockData.parentPasscode = passController.text;
                    MockData.parentSecurityAnswer = answerController.text.toLowerCase().trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Passcode & Answer Set")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter PIN and answer")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _handleTimeLimitTap(BuildContext context) {
    final premiumNotifier = context.read<PremiumNotifier>();
    if (premiumNotifier.hasActivePremium) {
      _showTimeLimitPicker();
    } else {
      _showPremiumPopup();
    }
  }

  void _showPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: AppColors.primaryRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Premium Feature",
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Time Limit is a premium feature. Upgrade your plan to unlock full parental controls and more!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Explore Plans",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Maybe Later",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTimeLimitPicker() async {
    final profile = _selectedProfileForConfig;
    if (profile == null) return;

    int currentLimit = await ProfileLocalStore.getTimerLimitMinutes(profile.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer,
                          color: AppColors.primaryRed,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Set Time Limit",
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    currentLimit == 0
                        ? "Unlimited Time"
                        : "$currentLimit Minutes",
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Daily usage limit for ${profile.name}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryRed,
                      inactiveTrackColor:
                          AppColors.primaryRed.withValues(alpha: 0.2),
                      trackHeight: 8.0,
                      thumbColor: AppColors.primaryRed,
                      overlayColor: AppColors.primaryRed.withValues(alpha: 0.1),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 15.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 30.0,
                      ),
                    ),
                    child: Slider(
                      value: currentLimit.toDouble(),
                      min: 0,
                      max: 180, // 3 hours
                      divisions: 12, // 15 min steps
                      onChanged: (value) {
                        setSheetState(() {
                          currentLimit = value.toInt();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Minimum",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          "Maximum (3h)",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await ProfileLocalStore.setTimerLimitMinutes(
                          profile.id,
                          currentLimit,
                        );
                        if (!context.mounted) return;
                        _fetchLimit();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              currentLimit == 0
                                  ? "Time limit removed"
                                  : "Time limit set to $currentLimit minutes",
                            ),
                            backgroundColor: AppColors.primaryRed,
                          ),
                        );
                      },
                      child: Text(
                        "Save Limit",
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
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
                        _fetchLimit();
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
  final bool isLocked;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
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
          if (isLocked)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
