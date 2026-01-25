import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAge;
  final List<String> _ages = List.generate(10, (i) => '${i + 3}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Create a Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://robohash.org/NewKid?set=set4',
              ),
            ),
            const SizedBox(height: 10),
            const Text("Pick a look!"),
            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Child's First Name",
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
                  items: _ages
                      .map(
                        (age) => DropdownMenuItem(value: age, child: Text(age)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAge = val),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Save and proceed
                  Navigator.pushReplacementNamed(
                    context,
                    '/profile_select',
                  ); // Or direct to root
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
