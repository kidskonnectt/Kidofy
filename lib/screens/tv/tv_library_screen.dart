import 'package:flutter/material.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';

class TvLibraryScreen extends StatelessWidget {
  const TvLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming Library shows "All Videos" or "Favorites" (MockData isn't explicit on user favorites locally in this context, using all for demo).
    final videos = MockData.videos;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Library",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 cols for TV
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 32,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return _TvLibraryCard(video: videos[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvLibraryCard extends StatefulWidget {
  final Video video;
  const _TvLibraryCard({required this.video});

  @override
  State<_TvLibraryCard> createState() => _TvLibraryCardState();
}

class _TvLibraryCardState extends State<_TvLibraryCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.video.isShorts) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShortsFeedScreen(
                shorts: MockData.snaps,
                initialVideoId: widget.video.id,
              ),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(video: widget.video),
          ),
        );
      },
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: _isFocused
              ? Border.all(color: AppColors.primaryRed, width: 4)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.video.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: _isFocused ? Colors.grey[800] : Colors.transparent,
              child: Text(
                widget.video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
