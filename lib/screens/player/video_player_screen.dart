import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/download_service.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:kidsapp/services/ads_service.dart';
import 'package:kidsapp/widgets/in_stream_video_ad.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:kidsapp/widgets/video_card.dart';
import 'package:kidsapp/screens/snaps/shorts_feed_screen.dart';
import 'package:kidsapp/utils/content_level.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/providers/premium_notifier.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static int _activePlayers = 0; // Fix Task 7
  VideoPlayerController? _controller;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _adCheckTimer;

  static const Duration _lockThreshold =
      Duration.zero; // Always enable lock for all videos
  static const Duration _unlockHoldDuration = Duration(seconds: 2);
  bool _isLocked = false;
  Timer? _unlockHoldTimer;
  double _unlockHoldProgress = 0.0;

  bool _showingAd = false;
  bool _preRollShown = false;
  bool _postRollShown = false;
  List<Duration> _midRollSchedule = const <Duration>[];
  int _nextMidRollIndex = 0;

  // In-stream ad variables
  BannerAd? _inStreamAd;
  bool _inStreamAdVisible = false;
  bool _currentAdIsSkippable = false;

  String? _initError;

  bool _liked = false;
  bool _disliked = false;
  bool _hasStartedPlayback = false;
  bool _completionHandled = false;

  bool get _isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    super.initState();
    _activePlayers++;
    // Force landscape-only playback in player with auto-rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Enable orientation changes by listening to MediaQuery
    _armHideTimer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Check if user has active premium - don't preload ads for premium users
      final premiumNotifier = context.read<PremiumNotifier>();
      final hasPremium = premiumNotifier.hasActivePremium;

      if (!hasPremium) {
        // Only preload ads if user doesn't have premium
        // Warm up ads early so they can show fast.
        unawaited(AdsService.preloadInterstitial(InterstitialSlot.midRoll));
        unawaited(AdsService.preloadInterstitial(InterstitialSlot.postRoll));
        unawaited(AdsService.preloadInStreamBannerAd());
      }

      // Prefer offline file if downloaded.
      final profile = MockData.currentProfile.value;
      String? offlinePath;
      if (profile != null) {
        offlinePath = await ProfileLocalStore.getOfflineVideoPath(
          profile.id,
          widget.video.id,
        );
      }

      VideoPlayerController controller;
      if (offlinePath != null && offlinePath.isNotEmpty) {
        final file = File(offlinePath);
        if (await file.exists()) {
          controller = VideoPlayerController.file(file);
        } else {
          controller = _networkControllerOrThrow();
        }
      } else {
        controller = _networkControllerOrThrow();
      }

      await controller.initialize();
      controller.setLooping(false);

      // Long-video lock is enabled by default for long videos.
      // Task 8: Lock by default always?
      // "When kids taping on video on video player videos then by default lock the video screen"
      _isLocked = true;
      _controlsVisible = false; // Start with controls hidden/locked
      _unlockHoldTimer?.cancel();
      _unlockHoldProgress = 0.0;

      // Compute mid-roll schedule only if user doesn't have premium
      if (hasPremium) {
        // Premium users: no mid-roll ads
        _midRollSchedule = const <Duration>[];
      } else {
        // Free users: show mid-roll ads
        _midRollSchedule = AdsService.midRollScheduleFor(
          controller.value.duration,
        );
      }
      _nextMidRollIndex = 0;
      _preRollShown = false;
      _postRollShown = false;
      _completionHandled = false;

      controller.addListener(() {
        if (!mounted) return;
        if (!_hasStartedPlayback &&
            controller.value.isInitialized &&
            controller.value.position > Duration.zero) {
          _hasStartedPlayback = true;
        }
        if (_isVideoEnded(controller) && !_completionHandled && !_showingAd) {
          _completionHandled = true;
          _playNext(ignoreLock: true);
        }
        setState(() {});
      });

      setState(() {
        _controller = controller;
        _initError = null;
      });

      // Task 9: Auto-play immediately
      controller.play();

      // Pre-roll: In landscape, show as in-stream. In portrait, skip for better UX.
      // Removed blocking pre-roll for better kids experience
      // Pre-roll ads will show as in-stream ads during playback if available

      // Ensure we are playing after possible ad interaction
      if (mounted &&
          controller.value.isInitialized &&
          !controller.value.isPlaying &&
          !_showingAd) {
        controller.play();
      }

      _startAdChecks();

      _armHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
      });
    }
  }

  VideoPlayerController _networkControllerOrThrow() {
    final url = widget.video.videoUrl;
    if (url == null || url.isEmpty) {
      throw StateError('Video URL missing for this item');
    }
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  @override
  void dispose() {
    _activePlayers--;
    _hideTimer?.cancel();
    _adCheckTimer?.cancel();
    _unlockHoldTimer?.cancel();
    _controller?.dispose();

    // Only reset to portrait if no other players are active
    if (_activePlayers <= 0) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  bool get _lockEnabled {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return false;
    return c.value.duration >= _lockThreshold;
  }

  void _unlockNow() {
    _unlockHoldTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLocked = false;
      _unlockHoldProgress = 0.0;
      _controlsVisible = true;
    });
    _armHideTimer();
  }

  void _lockNow() {
    _unlockHoldTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLocked = true;
      _unlockHoldProgress = 0.0;
      _controlsVisible = false;
    });
  }

  void _startUnlockHold() {
    if (!_lockEnabled || !_isLocked) return;
    _unlockHoldTimer?.cancel();

    final start = DateTime.now();
    setState(() {
      _unlockHoldProgress = 0.0;
    });

    _unlockHoldTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final elapsed = DateTime.now().difference(start);
      final progress =
          (elapsed.inMilliseconds / _unlockHoldDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() {
        _unlockHoldProgress = progress;
      });

      if (progress >= 1.0) {
        t.cancel();
        _unlockNow();
      }
    });
  }

  void _cancelUnlockHold() {
    _unlockHoldTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _unlockHoldProgress = 0.0;
    });
  }

  void _startAdChecks() {
    _adCheckTimer?.cancel();
    _adCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkPreRoll();
      _checkMidRoll();
      _checkPostRoll();
    });
  }

  void _checkPreRoll() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_showingAd) return;
    if (_preRollShown) return;

    // Skip pre-roll if user has active premium subscription
    final premiumNotifier = context.read<PremiumNotifier>();
    if (premiumNotifier.hasActivePremium) {
      _preRollShown = true;
      return;
    }

    // Show pre-roll after video starts playing (position > 0.5 seconds)
    final pos = c.value.position;
    if (pos > const Duration(milliseconds: 500)) {
      _preRollShown = true;
      unawaited(_showAdAndResume(slot: InterstitialSlot.preRoll));
    }
  }

  void _checkMidRoll() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_showingAd) return;

    // Skip mid-roll if user has active premium subscription
    final premiumNotifier = context.read<PremiumNotifier>();
    if (premiumNotifier.hasActivePremium) {
      _nextMidRollIndex = _midRollSchedule.length; // Mark all mid-rolls as done
      return;
    }

    if (_nextMidRollIndex >= _midRollSchedule.length) return;

    final target = _midRollSchedule[_nextMidRollIndex];
    final pos = c.value.position;
    final dur = c.value.duration;
    if (dur <= Duration.zero) return;

    // If user seeks past the target, still trigger once.
    if (pos >= target && pos < (dur - const Duration(seconds: 2))) {
      _nextMidRollIndex++;
      unawaited(_showAdAndResume(slot: InterstitialSlot.midRoll));
    }
  }

  void _checkPostRoll() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_showingAd) return;
    if (_postRollShown) {
      return;
    }

    // Skip post-roll if user has active premium subscription
    final premiumNotifier = context.read<PremiumNotifier>();
    if (premiumNotifier.hasActivePremium) {
      _postRollShown = true;
      return;
    }

    final dur = c.value.duration;
    if (dur <= Duration.zero) return;
    final pos = c.value.position;

    final ended = pos >= (dur - const Duration(milliseconds: 250));
    if (!ended) return;

    _postRollShown = true;
    // Show Ad then auto-play next
    unawaited(
      _showAdAndResume(slot: InterstitialSlot.postRoll, resumeAfterAd: false),
    );
  }

  Future<void> _showAdAndResume({
    required InterstitialSlot slot,
    bool resumeAfterAd = true,
  }) async {
    if (_showingAd) return;
    final c = _controller;
    if (c == null) return;

    _showingAd = true;
    try {
      // Only show in-stream ads in landscape mode
      // In portrait mode, use full-screen interstitials
      if (_isLandscape) {
        // Landscape: Try to show in-stream banner ad at bottom
        final bannerAd = await AdsService.loadInStreamBannerAd();
        if (bannerAd != null && mounted) {
          // Randomize if this ad is skippable (70% skippable, 30% non-skippable like YouTube)
          _currentAdIsSkippable = DateTime.now().microsecond.isEven;
          _inStreamAd = bannerAd;
          _inStreamAdVisible = true;

          setState(() {});
          // Wait for the ad widget to handle close via onClosed callback
          return;
        }
      }

      // Portrait mode or banner ad failed: use full-screen interstitial
      if (c.value.isPlaying) {
        await c.pause();
      }
      await AdsService.showInterstitial(
        slot,
        waitForLoad: const Duration(seconds: 2),
      );
    } catch (_) {
    } finally {
      _showingAd = false;
      if (mounted && _controller != null) {
        if (resumeAfterAd && !_isVideoEnded(_controller!)) {
          _controller!.play();
        } else if (!_completionHandled) {
          _completionHandled = true;
          _playNext(ignoreLock: true);
        }
      }
    }
  }

  void _closeInStreamAd() {
    if (mounted) {
      setState(() {
        _inStreamAdVisible = false;
        _inStreamAd = null;
        _showingAd = false;
      });
      if (_controller != null && !_isVideoEnded(_controller!)) {
        _controller!.play();
      } else if (!_completionHandled) {
        _completionHandled = true;
        _playNext(ignoreLock: true);
      }
    }
  }

  bool _isVideoEnded(VideoPlayerController controller) {
    final dur = controller.value.duration;
    if (dur <= Duration.zero) return false;
    return controller.value.position >= dur - const Duration(milliseconds: 200);
  }

  void _showReportDialog(BuildContext context) {
    // Pause video while reporting
    if (_controller?.value.isPlaying == true) {
      _controller?.pause();
    }

    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Is something wrong with this video?'),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                InteractionService.submitReport(
                  widget.video.id,
                  reasonController.text,
                  'Reported from Player',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ).then((_) {
      // Resume only if we paused it and it wasn't finished
      if (mounted && _controller != null) {
        _controller!.play();
      }
    });
  }

  void _armHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _armHideTimer();
    }
  }

  void _goBack() {
    if (_lockEnabled && _isLocked) return;
    // Restore portrait mode and go back to previous screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pop(context);
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    _armHideTimer();
  }

  Video? _findAdjacentNonShort({required bool forward}) {
    final list = MockData.videos;
    final currentIndex = list.indexWhere((v) => v.id == widget.video.id);
    if (currentIndex == -1) return null;

    final step = forward ? 1 : -1;
    for (var i = currentIndex + step; i >= 0 && i < list.length; i += step) {
      final candidate = list[i];
      if (!candidate.isShorts) return candidate;
    }
    return null;
  }

  void _seekRelative(Duration delta) {
    if (_lockEnabled && _isLocked) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    final dur = c.value.duration;
    var next = pos + delta;
    if (next < Duration.zero) next = Duration.zero;
    if (next > dur) next = dur;
    c.seekTo(next);
    _armHideTimer();
  }

  void _playPrevious() {
    if (_lockEnabled && _isLocked) return;
    final prev = _findAdjacentNonShort(forward: false);
    if (prev == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: prev)),
    );
  }

  void _playNext({bool ignoreLock = false}) {
    if (!ignoreLock && _lockEnabled && _isLocked) return;
    final next = _findAdjacentNonShort(forward: true);
    if (next == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: next)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape;
    final controller = _controller;

    Widget buildVideoContent() {
      final isInitialized = controller?.value.isInitialized == true;
      final isPlaying = controller?.value.isPlaying == true;
      final isBuffering = controller?.value.isBuffering == true;
      final position = controller?.value.position ?? Duration.zero;
      final duration = controller?.value.duration ?? Duration.zero;
      final isLoading =
          !isInitialized || isBuffering || (!_hasStartedPlayback && !isPlaying);
      // Task 8: Unlock with double tap on screen or deep press.
      // Lock is always enabled now.
      final lockEnabled = _lockEnabled;
      final locked = _isLocked;

      String fmt(Duration d) {
        final s = d.inSeconds;
        final mm = ((s ~/ 60) % 60).toString().padLeft(2, '0');
        final ss = (s % 60).toString().padLeft(2, '0');
        final hh = (s ~/ 3600).toString().padLeft(2, '0');
        return d.inHours > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
      }

      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.select): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.enter): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _seekRelative(const Duration(seconds: -10)),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _seekRelative(const Duration(seconds: 10)),
          const SingleActivator(LogicalKeyboardKey.arrowUp): _toggleControls,
          const SingleActivator(LogicalKeyboardKey.arrowDown): _toggleControls,
          const SingleActivator(LogicalKeyboardKey.escape): _goBack,
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: () {
              // If locked, show lock icon (controls are hidden)
              // If unlocked, toggle controls
              if (locked) {
                // Maybe show a hint "Long press lock to unlock" or just ensure lock icon is visible
                setState(() {
                  // We can make lock icon visible for a bit?
                  // Currently lock icon is in a specific position.
                });
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Screen Locked. Double tap or hold Lock icon to unlock.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                _toggleControls();
              }
            },
            onDoubleTap: locked
                ? _unlockNow
                : null, // Task 8: Unlock on double tap
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: isLandscape ? double.infinity : 250,
                  width: double.infinity,
                  color: Colors.black,
                  child: isInitialized
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: controller!.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.video.thumbnailUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.5),
                          colorBlendMode: BlendMode.darken,
                        ),
                ),

                if (_initError != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to play this video.\n$_initError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),

                // Task 5, 7: Loading Spinner in Player
                if (isLoading)
                  const Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                        strokeWidth: 5,
                      ),
                    ),
                  ),

                // Controls Overlay
                // Show overlay even when `locked` so play/pause is visible.
                if (_controlsVisible)
                  Positioned.fill(
                    child: Container(
                      color:
                          Colors.black45, // Task 8: Semi-transparent background
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: locked ? null : _goBack,
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  enabled: !locked,
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) async {
                                    _armHideTimer();
                                    if (value == 'download') {
                                      try {
                                        await DownloadService.downloadVideoForCurrentProfile(
                                          widget.video,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Downloaded'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Download failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'report') {
                                      _showReportDialog(context);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'download',
                                      child: Text('Download'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'report',
                                      child: Text('Report'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (!isLoading)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: locked
                                      ? null
                                      : (isLandscape
                                            ? _playPrevious
                                            : () => _seekRelative(
                                                const Duration(seconds: -10),
                                              )),
                                  icon: Icon(
                                    isLandscape
                                        ? Icons.skip_previous_rounded
                                        : Icons.replay_10_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child:
                                      Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 52,
                                            ),
                                          )
                                          .animate(target: isPlaying ? 0 : 1)
                                          .scale(
                                            duration: 200.ms,
                                            curve: Curves.easeOutBack,
                                          ),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  onPressed: locked
                                      ? null
                                      : (isLandscape
                                            ? _playNext
                                            : () => _seekRelative(
                                                const Duration(seconds: 10),
                                              )),
                                  icon: Icon(
                                    isLandscape
                                        ? Icons.skip_next_rounded
                                        : Icons.forward_10_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            child: Row(
                              children: [
                                Text(
                                  fmt(position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: controller == null
                                      ? const SizedBox.shrink()
                                      : VideoProgressIndicator(
                                          controller,
                                          allowScrubbing: !locked,
                                          colors: VideoProgressColors(
                                            playedColor: AppColors.primaryRed,
                                            bufferedColor: Colors.white24,
                                            backgroundColor: Colors.white12,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  fmt(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (lockEnabled)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Listener(
                      onPointerDown: (_) {
                        if (locked) _startUnlockHold();
                      },
                      onPointerUp: (_) => _cancelUnlockHold(),
                      onPointerCancel: (_) => _cancelUnlockHold(),
                      child: GestureDetector(
                        onTap: () {
                          if (!lockEnabled) return;
                          if (locked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Locked. Double-tap to unlock or hold 2 seconds.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _lockNow();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: locked
                                  ? CircularProgressIndicator(
                                      value: _unlockHoldProgress,
                                      strokeWidth: 4,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                      backgroundColor: Colors.white24,
                                    )
                                  : null,
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                color: Colors.white,
                              ),
                            ).animate().scale(duration: 120.ms),
                          ],
                        ),
                      ),
                    ),
                  ),

                // In-stream video ad overlay (Landscape only)
                if (_inStreamAdVisible && _inStreamAd != null && isLandscape)
                  InStreamVideoAd(
                    ad: _inStreamAd!,
                    isSkippable: _currentAdIsSkippable,
                    onClosed: _closeInStreamAd,
                    showSkipAfter: Duration(
                      seconds: 5 + DateTime.now().microsecond % 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // Landscape behaves like a true fullscreen player (YT Kids style).
      body: isLandscape
          ? buildVideoContent()
          : SafeArea(
              child: Column(
                children: [
                  buildVideoContent(),

                  // Details & Recommendations
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            widget.video.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    (widget.video.channelAvatarUrl != null &&
                                        widget
                                            .video
                                            .channelAvatarUrl!
                                            .isNotEmpty)
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              widget.video.channelAvatarUrl!,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                                Icons.person,
                                                color: AppColors.accentBlue,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: AppColors.accentBlue,
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                // Added Expanded to avoid overflow with long names
                                child: Text(
                                  widget.video.channelName,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentBlue,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _ActionButton(
                                icon: Icons.thumb_up_rounded,
                                color: AppColors.accentGreen,
                                label: 'Like',
                                selected: _liked,
                                onTap: () {
                                  setState(() {
                                    _liked = !_liked;
                                    if (_liked) _disliked = false;
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: Icons.thumb_down_rounded,
                                color: AppColors.primaryRed,
                                label: 'Dislike',
                                selected: _disliked,
                                onTap: () {
                                  setState(() {
                                    _disliked = !_disliked;
                                    if (_disliked) _liked = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          Text(
                            "Up Next",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 10),

                          // Recommendations List (Mock)
                          ...MockData.videos
                              .where((v) {
                                if (v.id == widget.video.id) return false;
                                final p = MockData.currentProfile.value;
                                if (p == null) return true;
                                return ContentLevels.isVideoAllowedForProfile(
                                  v,
                                  p,
                                );
                              })
                              .map(
                                (v) => VideoCard(
                                  video: v,
                                  onTap: () {
                                    if (v.isShorts) {
                                      Navigator.pushReplacement(
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

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            VideoPlayerScreen(video: v),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color),
          ),
        ),
      ],
    );
  }
}
