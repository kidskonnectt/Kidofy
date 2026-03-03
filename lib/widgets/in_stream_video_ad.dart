import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// In-stream banner ad widget for videos - shows ads overlay during playback
/// Similar to YouTube's in-stream ads with skip functionality
class InStreamVideoAd extends StatefulWidget {
  final BannerAd ad;
  final bool isSkippable;
  final VoidCallback onClosed;
  final Duration showSkipAfter;

  const InStreamVideoAd({
    super.key,
    required this.ad,
    required this.isSkippable,
    required this.onClosed,
    this.showSkipAfter = const Duration(seconds: 5),
  });

  @override
  State<InStreamVideoAd> createState() => _InStreamVideoAdState();
}

class _InStreamVideoAdState extends State<InStreamVideoAd> {
  late Timer _skipTimer;
  late Timer _autoDismissTimer;
  int _secondsRemaining = 5;
  bool _canSkip = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSkippable) {
      _startSkipTimer();
    } else {
      // Non-skippable: auto-close after 5-7 seconds
      _startAutoClose();
    }
  }

  void _startSkipTimer() {
    _secondsRemaining = widget.showSkipAfter.inSeconds > 0
        ? widget.showSkipAfter.inSeconds
        : 5;

    _skipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {
          _canSkip = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _startAutoClose() {
    // Non-skippable ads auto-close after 5-7 seconds
    final closeDelay = Duration(seconds: 5 + DateTime.now().microsecond % 3);
    _autoDismissTimer = Timer(closeDelay, () {
      _closeAd();
    });
  }

  void _closeAd() {
    if (_dismissed) return;
    _dismissed = true;
    _skipTimer.cancel();
    _autoDismissTimer.cancel();
    widget.onClosed();
  }

  @override
  void dispose() {
    if (!_dismissed) {
      _skipTimer.cancel();
      _autoDismissTimer.cancel();
    }
    super.dispose();
  }

  /// Build the skip button with countdown or clickable state
  Widget _buildSkipButton() {
    if (_canSkip) {
      // Button is active and clickable
      return GestureDetector(
        onTap: _closeAd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Skip Ad',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      // Button is disabled with countdown
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white30, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Skip in $_secondsRemaining',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ad container
            SizedBox(
              width: double.infinity,
              height: 55,
              child: AdWidget(ad: widget.ad),
            ),
            // Ad info and Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!widget.isSkippable)
                    const Text(
                      'Ad',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.isSkippable)
                    _buildSkipButton()
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
