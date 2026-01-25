import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/utils/content_level.dart';

class ContentSelectionScreen extends StatefulWidget {
  final Profile profile;

  const ContentSelectionScreen({super.key, required this.profile});

  @override
  State<ContentSelectionScreen> createState() => _ContentSelectionScreenState();
}

class _ContentSelectionScreenState extends State<ContentSelectionScreen> {
  String _selectedLevel = 'Preschool';
  bool _isSaving = false;

  final List<Map<String, String>> _levels = [
    {'title': 'Preschool', 'desc': 'Ages 4 and under', 'icon': '🧸'},
    {'title': 'Younger', 'desc': 'Ages 5+ (includes Preschool)', 'icon': '🚗'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLevel = ContentLevels.normalize(
      widget.profile.contentType,
      fallbackAge: widget.profile.age,
      fallbackBirthMonth: widget.profile.birthMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Content Level",
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "What should ${widget.profile.name} watch?",
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemCount: _levels.length,
                separatorBuilder: (c, i) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  final isSelected = _selectedLevel == level['title'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLevel = level['title']!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentBlue.withValues(alpha: 0.1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentBlue
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            level['icon']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level['title']!,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  level['desc']!,
                                  style: GoogleFonts.fredoka(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.accentBlue,
                              size: 30,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        try {
                          await SupabaseService.updateProfileContentType(
                            profileId: widget.profile.id,
                            contentType: _selectedLevel,
                          );

                          final idx = MockData.profiles.indexWhere(
                            (p) => p.id == widget.profile.id,
                          );
                          if (idx != -1) {
                            final p = MockData.profiles[idx];
                            MockData.profiles[idx] = Profile(
                              id: p.id,
                              name: p.name,
                              avatarUrl: p.avatarUrl,
                              age: p.age,
                              contentType: _selectedLevel,
                              birthMonth: p.birthMonth,
                            );
                            MockData.currentProfile.value =
                                MockData.profiles[idx];
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: const Text("Finish Setup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
