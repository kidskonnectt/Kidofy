import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/widgets/video_card.dart';
import 'package:kidsapp/widgets/channel_card.dart';
import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:kidsapp/screens/home/channel_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:kidsapp/models/channel_list_item.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];

  Set<String> _blockedVideoIds = {};
  Set<String> _blockedChannelNames = {};

  @override
  void initState() {
    super.initState();
    _loadBlocked();
    MockData.currentProfile.addListener(_loadBlocked);
  }

  @override
  void dispose() {
    MockData.currentProfile.removeListener(_loadBlocked);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBlocked() async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return;

    final blocked = await SupabaseService.getBlockedContent(profile.id);
    if (!mounted) return;

    setState(() {
      _blockedVideoIds = blocked.videoIds;
      _blockedChannelNames = blocked.channelNames;
    });

    if (_controller.text.isNotEmpty) {
      _onSearchChanged(_controller.text);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final currentProfile = MockData.currentProfile.value;
    if (currentProfile == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final matchingVideos = MockData.videos.where((v) {
      if (_blockedVideoIds.contains(v.id)) return false;
      if (_blockedChannelNames.contains(v.channelName)) return false;
      if (!ContentLevels.isVideoAllowedForProfile(v, currentProfile)) {
        return false;
      }
      return v.title.toLowerCase().contains(lowerQuery);
    });

    final matchingChannels = MockData.videos
        .where((v) => ContentLevels.isVideoAllowedForProfile(v, currentProfile))
        .map((v) => v.channelName)
        .toSet()
        .where((name) {
          if (_blockedChannelNames.contains(name)) return false;
          return name.toLowerCase().contains(lowerQuery);
        });

    String? avatarUrlForChannel(String name) {
      for (final v in MockData.videos) {
        if (v.channelName != name) continue;
        final url = (v.channelAvatarUrl ?? '').trim();
        if (url.isNotEmpty) return url;
      }
      return null;
    }

    // Interleave or section results
    final results = [
      ...matchingChannels.map(
        (n) => ChannelListItem(
          channelName: n,
          channelAvatarUrl: avatarUrlForChannel(n),
        ),
      ),
      ...matchingVideos,
    ];

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textDark,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true, // Keyboard pops up immediately
          style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "Type a letter...",
            hintStyle: GoogleFonts.fredoka(
              color: Colors.grey[300],
              fontSize: 24,
            ),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _searchResults.isEmpty
          ? (_controller.text.isNotEmpty
                ? Center(
                    child: Text(
                      "No results found!",
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.search,
                      size: 100,
                      color: Colors.grey[200],
                    ),
                  ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                if (item is ChannelListItem) {
                  final channelName = item.channelName;
                  return ChannelCard(
                    channelName: channelName,
                    channelAvatarUrl: item.channelAvatarUrl,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChannelScreen(channelName: channelName),
                        ),
                      );
                    },
                    onBlock: () async {
                      final profile = MockData.currentProfile.value;
                      if (profile == null) return;
                      await SupabaseService.blockChannel(
                        profileId: profile.id,
                        channelName: channelName,
                      );
                      await _loadBlocked();
                    },
                  );
                } else if (item is Video) {
                  return VideoCard(
                    video: item,
                    onTap: () {
                      final profile = MockData.currentProfile.value;
                      if (profile != null) {
                        ProfileLocalStore.recordWatchedVideo(
                          profile.id,
                          item.id,
                        );
                      }

                      if (item.isShorts) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShortsFeedScreen(
                              shorts: MockData.snaps,
                              initialVideoId: item.id,
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(video: item),
                        ),
                      );
                    },
                    onBlock: () async {
                      final profile = MockData.currentProfile.value;
                      if (profile == null) return;
                      await SupabaseService.blockVideo(
                        profileId: profile.id,
                        videoId: item.id,
                      );
                      await _loadBlocked();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}
