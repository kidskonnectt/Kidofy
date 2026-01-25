import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:kidsapp/models/mock_data.dart'; // Ensure this model exists and has data
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';

class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  // We can group videos by Category for "Rows"
  // Or just chunks.

  @override
  Widget build(BuildContext context) {
    final categories = MockData.categories;
    final videos = MockData.videos;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "Featured",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= categories.length) return null;
              final cat = categories[index];
              // Filter videos needed? MockData usually has all.
              // For demo, we just show all videos in every category or shuffle
              final catVideos = (cat.id == '0')
                  ? videos
                  : videos.where((v) => v.categoryId == cat.id).toList();

              if (catVideos.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 16,
                    ),
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 280, // Large row
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: catVideos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 24),
                      itemBuilder: (context, vIndex) {
                        final video = catVideos[vIndex];
                        return _TvVideoCard(video: video);
                      },
                    ),
                  ),
                ],
              );
            }, childCount: categories.length),
          ),
        ],
      ),
    );
  }
}

class _TvVideoCard extends StatefulWidget {
  final Video video;
  const _TvVideoCard({required this.video});

  @override
  State<_TvVideoCard> createState() => _TvVideoCardState();
}

class _TvVideoCardState extends State<_TvVideoCard> {
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
      onFocusChange: (value) {
        setState(() {
          _isFocused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        height: 240, // Aspect ratio
        transform: _isFocused
            ? (Matrix4.identity()..scaleByVector3(Vector3.all(1.1)))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: _isFocused
              ? Border.all(color: AppColors.primaryRed, width: 4)
              : null,
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.video.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (_, __, ___) => Container(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _isFocused ? Colors.white : Colors.white70,
                fontSize: 20, // Enlarged
                fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
