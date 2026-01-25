import 'package:flutter/material.dart';
import 'package:kidsapp/screens/home/home_screen.dart';
import 'package:kidsapp/screens/snaps/snaps_screen.dart';
import 'package:kidsapp/screens/library/library_screen.dart';
import 'package:kidsapp/screens/mart/mart_screen.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/widgets/offline_full_screen.dart';
import 'package:kidsapp/services/connectivity_service.dart';
import 'package:kidsapp/services/video_playback_bus.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/screens/tv/tv_root_screen.dart';

class RootScreen extends StatefulWidget {
  final int initialIndex;

  const RootScreen({super.key, this.initialIndex = 0});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MockData.currentProfile.value == null &&
          MockData.profiles.isNotEmpty) {
        // Auto-select first profile if none selected
        MockData.currentProfile.value = MockData.profiles.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check for TV / Large Screen (Landscape TV usually > 900)
    // "Optimise... for Android TVs only... Phones and tablets remain unchanged"
    // To distinguish TV from Tablet reliably without plugins is hard.
    // But typically TVs are landscape and wide.
    // User instruction: "phones and tablets remain unchanged".
    // I'll set a high threshold or rely on aspect ratio > 1.5 AND width > 950.
    final size = MediaQuery.of(context).size;
    final isTv = size.width > 950 && size.aspectRatio > 1.3;

    if (isTv) {
      return const TvRootScreen();
    }

    Widget currentPage() {
      switch (_currentIndex) {
        case 0:
          return const HomeScreen();
        case 1:
          return const SnapsScreen();
        case 2:
          return const LibraryScreen();
        case 3:
          return const MartScreen();
        default:
          return const HomeScreen();
      }
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: Consumer<ConnectivityService>(
          builder: (context, connectivity, child) {
            if (!connectivity.isOnline) {
              return const OfflineFullScreen();
            }
            return Column(children: [Expanded(child: currentPage())]);
          },
        ),
        bottomNavigationBar: ValueListenableBuilder<Profile?>(
          valueListenable: MockData.currentProfile,
          builder: (context, profile, _) {
            final name = profile?.name ?? 'Profile';
            final avatarUrl = profile?.avatarUrl;
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                VideoPlaybackBus.pauseAll();
                if (index == 4) {
                  Navigator.pushNamed(context, '/profile_select');
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              selectedItemColor: AppColors.primaryRed,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.video_library_rounded),
                  label: "Snaps",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.folder_special_rounded),
                  label: "Library",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: "Mart",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentIndex == 4
                            ? AppColors.primaryRed
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: avatarUrl == null
                          ? null
                          : NetworkImage(avatarUrl),
                      radius: 12,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                  ),
                  label: name,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
