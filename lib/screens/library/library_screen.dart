import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:kidsapp/widgets/video_card.dart';

import 'package:kidsapp/screens/player/video_player_screen.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';
import 'package:kidsapp/services/download_bus.dart';
import 'package:kidsapp/services/download_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Future<List<Video>>? _downloadsFuture;
  Future<List<Video>>? _historyFuture;
  Future<List<Video>>? _likedFuture;

  @override
  void initState() {
    super.initState();
    MockData.currentProfile.addListener(_reload);
    DownloadBus().addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    MockData.currentProfile.removeListener(_reload);
    DownloadBus().removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    final profile = MockData.currentProfile.value;
    if (profile == null) return;
    setState(() {
      _downloadsFuture = _loadDownloads(profile.id);
      _historyFuture = _loadHistory(profile.id);
      _likedFuture = _loadLiked();
    });
  }

  Future<List<Video>> _loadDownloads(String profileId) async {
    final ids = await ProfileLocalStore.getOfflineVideoIds(profileId);
    final byId = {for (final v in MockData.videos) v.id: v};
    
    final List<Video> result = [];
    for (final id in ids) {
      final v = byId[id] ?? await ProfileLocalStore.getVideoMetadata(id);
      if (v != null) result.add(v);
    }
    return result;
  }

  Future<List<Video>> _loadHistory(String profileId) async {
    final ids = await ProfileLocalStore.getWatchHistory(profileId);
    final byId = {for (final v in MockData.videos) v.id: v};
    
    final List<Video> result = [];
    for (final id in ids) {
      final v = byId[id] ?? await ProfileLocalStore.getVideoMetadata(id);
      if (v != null) result.add(v);
    }
    return result;
  }

  Future<List<Video>> _loadLiked() async {
    final ids = await InteractionService.getLikedVideoIds();
    final byId = {for (final v in MockData.videos) v.id: v};
    
    final List<Video> result = [];
    for (final id in ids) {
      final v = byId[id] ?? await ProfileLocalStore.getVideoMetadata(id);
      if (v != null) result.add(v);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final profile = MockData.currentProfile.value;

    if (profile == null) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(
            'My Library',
            style: GoogleFonts.fredoka(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryRed,
            indicatorWeight: 4,
            labelStyle: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            tabs: const [
              Tab(text: 'Downloads'),
              Tab(text: 'History'),
              Tab(text: 'Liked Videos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<Video>>(
              future: _downloadsFuture,
              builder: (context, snapshot) {
                return _buildVideoList(
                  context,
                  snapshot.data ?? const <Video>[],
                  'No downloads yet!',
                  isDownloads: true,
                );
              },
            ),
            FutureBuilder<List<Video>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                return _buildVideoList(
                  context,
                  snapshot.data ?? const <Video>[],
                  'No history yet!',
                );
              },
            ),
            FutureBuilder<List<Video>>(
              future: _likedFuture,
              builder: (context, snapshot) {
                return _buildVideoList(
                  context,
                  snapshot.data ?? const <Video>[],
                  'No liked videos yet!',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList(
    BuildContext context,
    List<Video> videos,
    String emptyMessage, {
    bool isDownloads = false,
  }) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.fredoka(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final v = videos[index];
        return VideoCard(
          video: v,
          onRemove:
              isDownloads
                  ? () async {
                    try {
                      await DownloadService.removeDownloadedVideoForCurrentProfile(
                        v.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from downloads'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                  : null,
          onTap: () {
            if (v.isShorts) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShortsFeedScreen(
                    shorts: MockData.snaps,
                    initialVideoId: v.id,
                  ),
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
    );
  }
}
