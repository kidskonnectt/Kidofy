import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/widgets/category_selector.dart';
import 'package:kidsapp/widgets/video_card.dart';
import 'package:kidsapp/widgets/channel_card.dart';
import 'package:kidsapp/widgets/kid_app_bar.dart';
import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:kidsapp/screens/home/channel_screen.dart';
import 'package:kidsapp/screens/search/search_screen.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:kidsapp/models/channel_list_item.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/providers/premium_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use Explore (id 0) by default
  String selectedCategoryId = '0';

  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 12;
  int _visibleCount = _pageSize;
  int _shuffleNonce = 0;
  String _lastShuffleSignature = '';
  List<String> _shuffledVideoIds = <String>[];

  Future<({Set<String> videoIds, Set<String> channelNames})>? _blockedFuture;

  @override
  void initState() {
    super.initState();
    MockData.currentProfile.addListener(_onProfileChanged);
    _onProfileChanged();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    MockData.currentProfile.removeListener(_onProfileChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;

    // Load more when close to bottom.
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      setState(() {
        _visibleCount = _visibleCount + _pageSize;
      });
    }
  }

  void _onProfileChanged() {
    final profile = MockData.currentProfile.value;
    if (profile == null) {
      _blockedFuture = null;
      return;
    }
    setState(() {
      _blockedFuture = SupabaseService.getBlockedContent(profile.id);
      _visibleCount = _pageSize;
      _shuffleNonce++;
    });
  }

  Future<void> _refresh() async {
    try {
      await SupabaseService.initializeData();
    } catch (_) {
      // Ignore refresh errors; still reset UI.
    }
    if (!mounted) return;

    final profile = MockData.currentProfile.value;
    if (profile == null) return;

    setState(() {
      _visibleCount = _pageSize;
      _shuffleNonce++;
      _blockedFuture = SupabaseService.getBlockedContent(profile.id);
    });
  }

  Future<void> _blockVideo(String videoId) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return;
    await SupabaseService.blockVideo(profileId: profile.id, videoId: videoId);
    _onProfileChanged();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video Blocked")));
    }
  }

  Future<void> _blockChannel(String channelName) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return;
    await SupabaseService.blockChannel(
      profileId: profile.id,
      channelName: channelName,
    );
    _onProfileChanged();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Channel Blocked")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = MockData.currentProfile.value;

    if (currentProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile_select',
          (_) => false,
        );
      });
      return const SizedBox.shrink();
    }

    final blockedFuture = _blockedFuture;
    if (blockedFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: blockedFuture,
      builder: (context, snapshot) {
        final blocked =
            snapshot.data ?? (videoIds: <String>{}, channelNames: <String>{});

        // Filter videos based on selection and blocked status
        final displayVideos = MockData.videos.where((v) {
          // Never show shorts on Home.
          if (v.isShorts) return false;
          if (blocked.videoIds.contains(v.id)) return false;
          if (blocked.channelNames.contains(v.channelName)) return false;
          if (!ContentLevels.isVideoAllowedForProfile(v, currentProfile)) {
            return false;
          }

          // Explore (0) shows all
          return selectedCategoryId == '0' ||
              v.categoryId == selectedCategoryId;
        }).toList();

        // Randomize order (stable until refresh / profile / category change)
        final byId = {for (final v in displayVideos) v.id: v};
        final signature =
            '${currentProfile.id}|$selectedCategoryId|${byId.length}|${blocked.videoIds.length}|${blocked.channelNames.length}|$_shuffleNonce';

        if (_lastShuffleSignature != signature) {
          final ids = byId.keys.toList();
          ids.shuffle(Random());
          _shuffledVideoIds = ids;
          _lastShuffleSignature = signature;
          _visibleCount = _pageSize;
        }

        final shuffledVideos = _shuffledVideoIds
            .map((id) => byId[id])
            .whereType<Video>()
            .toList();

        final visibleVideos = shuffledVideos.take(_visibleCount).toList();

        final List<dynamic> listItems = [];
        int counter = 0;
        for (var video in visibleVideos) {
          listItems.add(video);
          counter++;
          if (counter % 4 == 0) {
            listItems.add(
              ChannelListItem(
                channelName: video.channelName,
                channelAvatarUrl: video.channelAvatarUrl,
              ),
            );
          }
        }

        return Consumer<PremiumNotifier>(
          builder: (context, premiumNotifier, _) {
            return Scaffold(
              extendBodyBehindAppBar: false,
              appBar: KidAppBar(
                onProfileTap: () {
                  // Navigate to profile/settings
                  Navigator.pushNamed(context, '/settings');
                },
                onSearchTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                onPremiumTap: () {
                  Navigator.pushNamed(context, '/premium');
                },
                isPremium: premiumNotifier.hasActivePremium,
                daysRemaining: premiumNotifier.daysRemaining,
              ),
              body: Column(
                children: [
                  const SizedBox(height: 20),
                  CategorySelector(
                    selectedCategoryId: selectedCategoryId,
                    onCategorySelected: (id) {
                      setState(() {
                        selectedCategoryId = id;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primaryRed,
                      child: listItems.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'No videos found in this category.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: listItems.length,
                              itemBuilder: (context, index) {
                                final item = listItems[index];

                                if (item is ChannelListItem) {
                                  final channelName = item.channelName;
                                  // Check if channel blocked
                                  if (blocked.channelNames.contains(
                                    channelName,
                                  )) {
                                    return const SizedBox.shrink();
                                  }

                                  return ChannelCard(
                                    channelName: channelName,
                                    channelAvatarUrl: item.channelAvatarUrl,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChannelScreen(
                                            channelName: channelName,
                                          ),
                                        ),
                                      );
                                    },
                                    onBlock: () => _blockChannel(channelName),
                                  );
                                }

                                final video = item as Video;
                                return VideoCard(
                                      video: video,
                                      onBlock: () => _blockVideo(video.id),
                                      onTap: () {
                                        final profile =
                                            MockData.currentProfile.value;
                                        if (profile != null) {
                                          ProfileLocalStore.recordWatchedVideo(
                                            profile.id,
                                            video.id,
                                          );
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                VideoPlayerScreen(video: video),
                                          ),
                                        );
                                      },
                                    )
                                    .animate()
                                    .fade(duration: 400.ms)
                                    .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      curve: Curves.easeOutQuad,
                                      delay: Duration(milliseconds: 100),
                                    );
                              },
                            ),
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
}
