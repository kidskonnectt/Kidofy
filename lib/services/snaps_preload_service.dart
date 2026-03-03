import 'package:video_player/video_player.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'dart:async';

/// Service to preload the first 1-2 snaps videos in background at app startup
/// This ensures smooth playback when user opens snaps page
class SnapsPreloadService {
  static final Map<String, VideoPlayerController> _preloadedControllers = {};
  static bool _isPreloading = false;
  static Timer? _preloadTimer;

  /// Start background preloading of first 2 snaps videos
  /// Uses slow/staggered initialization to minimize bandwidth usage
  static void startBackgroundPreload() {
    if (_isPreloading) return;
    if (MockData.snaps.isEmpty) return;

    _isPreloading = true;

    // Preload first video after a short delay (2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      _preloadVideoAtIndex(0);
    });

    // Preload second video after longer delay (5 seconds)
    if (MockData.snaps.length > 1) {
      Future.delayed(const Duration(seconds: 5), () {
        _preloadVideoAtIndex(1);
      });
    }
  }

  /// Preload a single video
  static Future<void> _preloadVideoAtIndex(int index) async {
    if (index >= MockData.snaps.length) return;

    final video = MockData.snaps[index];
    if (video.videoUrl == null) return;

    // Don't preload if already preloaded
    if (_preloadedControllers.containsKey(video.id)) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl!),
      );

      // Initialize with low buffer size to reduce bandwidth
      await controller.initialize();

      // Don't start playback, just buffer
      _preloadedControllers[video.id] = controller;

      // Dispose after 5 minutes if not used
      _startAutoDisposeTimer(video.id);
    } catch (e) {
      // Silently fail - preload is not critical
    }
  }

  /// Get a preloaded controller if available, otherwise return null
  static VideoPlayerController? getPreloadedController(String videoId) {
    final controller = _preloadedControllers.remove(videoId);
    if (controller != null) {
      _preloadTimer?.cancel();
    }
    return controller;
  }

  /// Auto-dispose preloaded controller if not used within timeout
  static void _startAutoDisposeTimer(String videoId) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(minutes: 5), () {
      final controller = _preloadedControllers.remove(videoId);
      controller?.dispose();
    });
  }

  /// Clear all preloaded controllers
  static void clearCache() {
    _preloadTimer?.cancel();
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    _isPreloading = false;
  }
}
