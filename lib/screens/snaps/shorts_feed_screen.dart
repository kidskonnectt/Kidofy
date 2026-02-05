import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kidsapp/models/mock_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kidsapp/services/ads_service.dart';
import 'package:kidsapp/services/download_service.dart';
import 'package:video_player/video_player.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/services/video_playback_bus.dart';

/// Replica of Snaps screen for playing Shorts (isShorts=true)
/// from Search/Library/Channel/etc without using the landscape VideoPlayer.
class ShortsFeedScreen extends StatefulWidget {
  final List<Video> shorts;
  final String? initialVideoId;

  const ShortsFeedScreen({
    super.key,
    required this.shorts,
    this.initialVideoId,
  });

  @override
  State<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends State<ShortsFeedScreen> {
  late final PageController _pageController;

  List<Video> _snaps = [];

  final Map<int, VideoPlayerController> _controllers = {};
  int _focusedIndex = 0;
  bool _showControls = false;
  Timer? _hideTimer;
  late final VoidCallback _pauseListener;

  static const int _adEveryA = 4;
  static const int _adEveryB = 5;

  @override
  void initState() {
    super.initState();
    _pauseListener = _pauseAllControllers;
    VideoPlaybackBus.pauseSignal.addListener(_pauseListener);

    final profile = MockData.currentProfile.value;
    final raw = widget.shorts.where((v) => v.isShorts).toList();
    final filtered = profile == null
        ? raw
        : raw
              .where((v) => ContentLevels.isVideoAllowedForProfile(v, profile))
              .toList();

    // Keep same behavior as Snaps (shuffle), but ensure tapped short is focused.
    final snaps = List.of(filtered)..shuffle();

    int initialVideoIndex = 0;
    if (widget.initialVideoId != null) {
      final idx = snaps.indexWhere((v) => v.id == widget.initialVideoId);
      if (idx != -1) initialVideoIndex = idx;
    }

    final initialFeedIndex = _feedIndexForVideoIndex(initialVideoIndex);
    _focusedIndex = initialFeedIndex;
    _snaps = snaps;
    _pageController = PageController(initialPage: initialFeedIndex);

    if (_snaps.isNotEmpty) {
      _initializeControllerAtIndex(initialFeedIndex);
      _initializeControllerAtIndex(initialFeedIndex + 1);
    }
  }

  @override
  void deactivate() {
    for (final c in _controllers.values) {
      c.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    VideoPlaybackBus.pauseSignal.removeListener(_pauseListener);
    _pageController.dispose();
    for (var controller in _controllers.values) {
      if (controller.value.isPlaying) controller.pause();
      controller.dispose();
    }
    super.dispose();
  }

  int _feedIndexForVideoIndex(int videoIndex) {
    if (videoIndex <= 0) return 0;

    var feed = 0;
    var video = 0;
    var block = _adEveryA;
    while (true) {
      final adPos = feed + block;
      // video indices covered in this block are [video, video+block)
      if (videoIndex < video + block) {
        return feed + (videoIndex - video);
      }
      video += block;
      feed = adPos + 1;
      block = (block == _adEveryA) ? _adEveryB : _adEveryA;

      // Safety.
      if (feed > 1000000) return videoIndex;
    }
  }

  Future<void> _initializeControllerAtIndex(int feedIndex) async {
    if (_isAdIndex(feedIndex)) return;
    if (_controllers.containsKey(feedIndex)) return;

    final videoIndex = _videoIndexForFeedIndex(feedIndex);
    if (videoIndex >= _snaps.length) return;

    final video = _snaps[videoIndex];

    try {
      if (video.videoUrl == null) return;
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl!),
      );
      _controllers[feedIndex] = controller;
      await controller.initialize();
      await controller.setLooping(true);

      if (mounted) {
        setState(() {});
        if (_focusedIndex == feedIndex) {
          controller.play();
        }
      }
    } catch (e) {
      _controllers.remove(feedIndex);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _focusedIndex = index;
      _showControls = false;
    });

    _controllers[index - 1]?.pause();
    _controllers[index + 1]?.pause();

    final current = _controllers[index];
    if (current != null && current.value.isInitialized) {
      current.play();
    } else {
      _initializeControllerAtIndex(index);
    }

    _initializeControllerAtIndex(index + 1);
    _initializeControllerAtIndex(index + 2);

    _controllers.keys.where((k) => (k - index).abs() > 3).toList().forEach((k) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    });
  }

  void _focusPlayback() {
    final controller = _controllers[_focusedIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
        if (mounted) {
          setState(() {
            _showControls = true;
          });
          _startHideTimer();
        }
      } else {
        controller.play();
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      }
    } else {
      _initializeControllerAtIndex(_focusedIndex);
    }
  }

  void _pauseAllControllers() {
    for (final c in _controllers.values) {
      if (c.value.isPlaying) {
        c.pause();
      }
    }
    if (mounted) {
      setState(() {
        _showControls = false;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  bool _isAdIndex(int index) {
    var pos = 0;
    var block = _adEveryA;
    while (true) {
      final adPos = pos + block;
      if (index == adPos) return true;
      if (index < adPos) return false;
      pos = adPos + 1;
      block = (block == _adEveryA) ? _adEveryB : _adEveryA;
    }
  }

  int _videoIndexForFeedIndex(int index) {
    var feed = 0;
    var video = 0;
    var block = _adEveryA;
    while (true) {
      final adPos = feed + block;
      if (index < adPos) {
        return video + (index - feed);
      }
      video += block;
      feed = adPos + 1;
      if (index == adPos) return video;
      block = (block == _adEveryA) ? _adEveryB : _adEveryA;
    }
  }

  Future<void> _toggleLike(Video video) async {
    final oldStatus = _likes[video.id] ?? false;
    setState(() {
      _likes[video.id] = !oldStatus;
    });
    try {
      await InteractionService.toggleLike(video.id, !oldStatus);
    } catch (_) {
      setState(() {
        _likes[video.id] = oldStatus;
      });
    }
  }

  // Track likes locally
  final Map<String, bool> _likes = {};

  String _buildShareText(Video video) {
    final url = 'https://kidofy.in/watch?v=${Uri.encodeComponent(video.id)}';
    final title = video.title.trim();
    if (title.isEmpty) return 'Watch on Kidofy: $url';
    return 'Watch "$title" on Kidofy: $url';
  }

  Future<void> _shareVideo(Video video) async {
    await SharePlus.instance.share(ShareParams(text: _buildShareText(video)));
  }

  @override
  Widget build(BuildContext context) {
    if (_snaps.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No shorts', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (_isAdIndex(index)) {
            return const _SnapsNativeAdPage();
          }

          final videoIndex = _videoIndexForFeedIndex(index);
          if (videoIndex >= _snaps.length) return null;

          final video = _snaps[videoIndex];
          final controller = _controllers[index];
          final isLoading =
              controller == null ||
              !controller.value.isInitialized ||
              controller.value.isBuffering;

          return GestureDetector(
            onTap: _focusPlayback,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null && controller.value.isInitialized)
                  VideoPlayer(controller)
                else
                  _buildThumbnail(video),

                if (_showControls) Container(color: Colors.black45),

                if (_showControls && !isLoading && controller.value.isPlaying)
                  const Center(
                    child: Icon(
                      Icons.pause_circle_filled,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),

                if (isLoading)
                  const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                        strokeWidth: 4,
                      ),
                    ),
                  ),

                Positioned(
                  left: 16,
                  bottom: 30,
                  right: 80,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow.withValues(
                                  alpha: 0.25,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  video.channelAvatarUrl != null &&
                                      video.channelAvatarUrl!.trim().isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: video.channelAvatarUrl!
                                            .trim(),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox.shrink(),
                                        errorWidget: (context, url, error) =>
                                            Center(
                                              child: Text(
                                                video.channelName.isEmpty
                                                    ? '?'
                                                    : video.channelName[0],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        video.channelName.isEmpty
                                            ? '?'
                                            : video.channelName[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                video.channelName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 50,
                  child: Column(
                    children: [
                      _ActionButton(
                        icon: (_likes[video.id] == true)
                            ? Icons.thumb_up
                            : Icons.thumb_up_off_alt,
                        label: 'Like',
                        color: (_likes[video.id] == true)
                            ? AppColors.primaryRed
                            : Colors.white,
                        onTap: () => _toggleLike(video),
                      ),
                      const SizedBox(height: 20),
                      _ActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () => _shareVideo(video),
                      ),
                      const SizedBox(height: 20),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 30,
                        ),
                        onSelected: (value) async {
                          if (value == 'download') {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Downloading...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              await DownloadService.downloadVideoForCurrentProfile(
                                video,
                              );
                            } catch (_) {
                              // ignore
                            }
                            return;
                          }

                          if (value == 'report') {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final controller = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Report Video'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Reason',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (controller.text.isNotEmpty) {
                                          InteractionService.submitReport(
                                            video.id,
                                            controller.text,
                                            'Reported from Shorts',
                                          );
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Report submitted.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Download'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(Video video) {
    if (video.thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: video.thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox(),
      );
    }
    return const SizedBox();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SnapsNativeAdPage extends StatefulWidget {
  const _SnapsNativeAdPage();

  @override
  State<_SnapsNativeAdPage> createState() => _SnapsNativeAdPageState();
}

class _SnapsNativeAdPageState extends State<_SnapsNativeAdPage> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = AdsService.createNativeSnapsAd(
      onLoaded: () {
        if (!mounted) return;
        setState(() {
          _loaded = true;
        });
      },
      onFailed: (_) {
        if (!mounted) return;
        setState(() {
          _loaded = false;
        });
      },
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_loaded && _ad != null)
            SizedBox(
              width: double.infinity,
              height: 340,
              child: AdWidget(ad: _ad!),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 16),
          const Text(
            'Sponsored',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
