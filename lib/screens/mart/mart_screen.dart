import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kidsapp/models/mock_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidsapp/services/supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:kidsapp/services/video_playback_bus.dart';

class MartScreen extends StatefulWidget {
  const MartScreen({super.key});

  @override
  State<MartScreen> createState() => _MartScreenState();
}

class _MartScreenState extends State<MartScreen> {
  final PageController _pageController = PageController();

  List<MartVideo> _martVideos = [];
  bool _isLoading = true;
  String? _error;

  // Key is the feed index
  final Map<int, VideoPlayerController> _controllers = {};
  int _focusedIndex = 0; // The currently visible feed index

  bool _showControls = false;
  Timer? _hideTimer;
  late final VoidCallback _pauseListener;

  @override
  void initState() {
    super.initState();
    _pauseListener = _pauseAllControllers;
    VideoPlaybackBus.pauseSignal.addListener(_pauseListener);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final videos = await SupabaseService.getMartVideos();
      if (mounted) {
        setState(() {
          // Task 2: Arrange randomly
          _martVideos = List.of(videos)..shuffle();
          _isLoading = false;
        });
        if (_martVideos.isNotEmpty) {
          // Task 3: Load 1-2 videos slowly on background
          _initializeControllerAtIndex(0);
          _initializeControllerAtIndex(1);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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

  Future<void> _initializeControllerAtIndex(int feedIndex) async {
    if (_controllers.containsKey(feedIndex)) return;

    if (feedIndex >= _martVideos.length) return;

    final video = _martVideos[feedIndex];

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl),
      );
      _controllers[feedIndex] = controller;
      await controller.initialize();
      await controller.setLooping(true); // Task 4: Play in loop

      if (mounted) {
        setState(() {}); // specific update?
        // Task 4: Auto play if this is the focused index
        if (_focusedIndex == feedIndex && _isRouteActive()) {
          controller.play();
        }
      }
    } catch (e) {
      _controllers.remove(feedIndex);
      // print("Error initializing video $feedIndex: $e");
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _focusedIndex = index;
      _showControls = true; // Briefly show controls
      _startHideTimer();
    });

    // Pause previous
    final prevController = _controllers[index - 1];
    prevController?.pause();
    final nextController = _controllers[index + 1];
    nextController
        ?.pause(); // Pause adjacents? Usually we just pause everything else or reliance on auto-play of current

    // Play current
    final currentController = _controllers[index];
    if (currentController != null &&
        currentController.value.isInitialized &&
        _isRouteActive()) {
      currentController.play();
    } else {
      _initializeControllerAtIndex(index);
    }

    // Cleanup old controllers to save memory (keep +/- 2)
    // Fix Duplicate: Explicitly remove controllers that are too far away.
    // Also ensure we don't accidentally dispose current/next ones.
    final keysToRemove = _controllers.keys
        .where((k) => (k - index).abs() > 3)
        .toList();
    for (final k in keysToRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }

    // Task 3: Preload next 2
    _initializeControllerAtIndex(index + 1);
    _initializeControllerAtIndex(index + 2);
  }

  void _focusPlayback() {
    final controller = _controllers[_focusedIndex];
    if (controller != null &&
        controller.value.isInitialized &&
        _isRouteActive()) {
      controller.play();
    } else {
      _initializeControllerAtIndex(_focusedIndex);
    }
    if (mounted) {
      setState(() {
        _showControls = false;
      });
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

  bool _isRouteActive() {
    final route = ModalRoute.of(context);
    if (route == null) return true;
    return route.isCurrent;
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

  Future<void> _openProductLink(String url, String martVideoId) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    try {
      await SupabaseService.trackMartClick(martVideoId);
    } catch (_) {}
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Task 3: Load 1 2 videos slowly on the background
      // This loading state is for the list fetch.
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (_martVideos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No items", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        // Task 1, 6: Infinity scroll (null itemCount)
        itemBuilder: (context, index) {
          if (index >= _martVideos.length) return null; // Stop scrolling

          final video = _martVideos[index];
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
                // Video Layer
                if (controller != null && controller.value.isInitialized)
                  VideoPlayer(controller)
                else
                  _buildThumbnail(video),

                // Controls Layer
                // Task 8: Semi transparent bg when controls shown
                if (_showControls) Container(color: Colors.black45),

                // Task 5, 10: Play/Pause ALWAYS show on tap
                if (_showControls && !isLoading && controller.value.isPlaying)
                  const Center(
                    child: Icon(
                      Icons.pause_circle_filled,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),

                // Task 7: Loading Spinner
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

                // Product Link (Always visible or toggled? Usually always visible in Mart)
                _buildProductInfo(video),
              ],
            ),
          );
        },
        onPageChanged: _onPageChanged,
      ),
    );
  }

  Widget _buildThumbnail(MartVideo video) {
    final thumbUrl = video.thumbnailUrl.trim();
    if (thumbUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.black),
        errorWidget: (context, url, err) => Container(color: Colors.grey[900]),
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildProductInfo(MartVideo video) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              video.shopName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openProductLink(video.productLink, video.id),
                icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                label: const Text(
                  'SHOP NOW',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
