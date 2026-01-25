import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidsapp/screens/tv/tv_home_screen.dart';
import 'package:kidsapp/screens/tv/tv_library_screen.dart';
import 'package:kidsapp/theme/app_theme.dart';

class TvRootScreen extends StatefulWidget {
  const TvRootScreen({super.key});

  @override
  State<TvRootScreen> createState() => _TvRootScreenState();
}

class _TvRootScreenState extends State<TvRootScreen> {
  int _selectedIndex = 0;
  final FocusNode _navRailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure landscape for TV
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _navRailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TV Theme Override
    return Theme(
      data: AppTheme.lightTheme.copyWith(
        textTheme: AppTheme.lightTheme.textTheme
            .apply(
              fontSizeFactor: 1.5, // Enlarge fonts
            )
            .copyWith(
              bodyMedium: const TextStyle(fontSize: 24, color: Colors.white),
              titleLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        scaffoldBackgroundColor: const Color(
          0xFF1a1a1a,
        ), // Darker high contrast background
        iconTheme: const IconThemeData(size: 40, color: Colors.white),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF121212),
          selectedIconTheme: IconThemeData(
            color: AppColors.primaryRed,
            size: 48,
          ),
          unselectedIconTheme: IconThemeData(color: Colors.grey, size: 40),
          selectedLabelTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          unselectedLabelTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ),
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              groupAlignment: 0.0,
              onDestinationSelected: (int index) {
                if (index == 3) {
                  Navigator.pushNamed(
                    context,
                    '/profile_select',
                  ); // Or TV specific profile
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_library_rounded),
                  label: Text('Shorts'), // Snaps adapted?
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_special_rounded),
                  label: Text('Library'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: Colors.white12,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  TvHomeScreen(),
                  Center(
                    child: Text("Shorts on TV (Use Remote Arrows)"),
                  ), // TODO: Adapt Snaps
                  TvLibraryScreen(),
                  SizedBox(), // Profile handled by nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
