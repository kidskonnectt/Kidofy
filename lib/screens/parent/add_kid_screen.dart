import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/screens/parent/content_selection_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/utils/content_level.dart';

class AddKidScreen extends StatefulWidget {
  final bool goToHomeOnComplete;

  const AddKidScreen({super.key, required this.goToHomeOnComplete});

  @override
  State<AddKidScreen> createState() => _AddKidScreenState();
}

class _AddKidScreenState extends State<AddKidScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAge;
  int? _selectedBirthMonth;
  bool _isSaving = false;

  final List<String> _ages = List.generate(10, (index) => "${index + 3}");
  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add Kid",
          style: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Let's set up a profile",
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Child's Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: InputDecoration(
                labelText: "Age",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAge,
                  isExpanded: true,
                  hint: const Text("Select Age"),
                  items: _ages
                      .map(
                        (age) => DropdownMenuItem(value: age, child: Text(age)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAge = val),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: InputDecoration(
                labelText: "Birth Month",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedBirthMonth,
                  isExpanded: true,
                  hint: const Text("Select Birth Month"),
                  items: List.generate(12, (index) {
                    final monthNumber = index + 1;
                    return DropdownMenuItem(
                      value: monthNumber,
                      child: Text(_monthNames[index]),
                    );
                  }),
                  onChanged: (val) => setState(() => _selectedBirthMonth = val),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_nameController.text.isEmpty ||
                            _selectedAge == null ||
                            _selectedBirthMonth == null) {
                          return;
                        }

                        setState(() => _isSaving = true);
                        try {
                          final name = _nameController.text.trim();
                          final age = int.parse(_selectedAge!);
                          final contentType = ContentLevels.fromAge(age);
                          final avatarUrl =
                              'https://robohash.org/$name?set=set4';

                          final created = await SupabaseService.createProfile(
                            name: name,
                            age: age,
                            avatarPath: avatarUrl,
                            contentType: contentType,
                            birthMonth: _selectedBirthMonth,
                          );

                          MockData.profiles.add(created);
                          MockData.currentProfile.value = created;

                          if (!context.mounted) return;

                          final finished = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContentSelectionScreen(profile: created),
                            ),
                          );

                          if (finished == true) {
                            if (!context.mounted) return;
                            if (widget.goToHomeOnComplete) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (_) => false,
                              );
                            } else {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile Created!'),
                                ),
                              );
                            }
                          }
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
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
