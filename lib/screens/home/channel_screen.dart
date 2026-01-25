import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/widgets/video_card.dart';
import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';

class ChannelScreen extends StatelessWidget {
  final String channelName;

  const ChannelScreen({super.key, required this.channelName});

  @override
  Widget build(BuildContext context) {
    final profile = MockData.currentProfile.value;

    // Filter videos by channel
    final videos = MockData.videos.where((v) {
      if (v.channelName != channelName) return false;
      if (profile == null) return true;
      return ContentLevels.isVideoAllowedForProfile(v, profile);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoCard(
            video: videos[index],
            onTap: () {
              final profile = MockData.currentProfile.value;
              if (profile != null) {
                ProfileLocalStore.recordWatchedVideo(
                  profile.id,
                  videos[index].id,
                );
              }

              final v = videos[index];
              if (v.isShorts) {
                final shorts = videos.where((x) => x.isShorts).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ShortsFeedScreen(shorts: shorts, initialVideoId: v.id),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
              );
            },
          );
        },
      ),
    );
  }
}
