import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum InterstitialSlot { preRoll, midRoll, postRoll }

class AdsService {
  // ============ PRODUCTION AD UNIT IDs ============
  static const String _adMobAppIdAndroid =
      'ca-app-pub-9631152544509905~3488703613';

  static const String _preRollAndroid =
      'ca-app-pub-9631152544509905/3272681816';
  static const String _midRollAndroid =
      'ca-app-pub-9631152544509905/1465949585';
  static const String _postRollAndroid =
      'ca-app-pub-9631152544509905/3025269801';

  static const String _nativeSnapsAndroid =
      'ca-app-pub-9631152544509905/3026443266';

  static const String _bannerAndroid =
      'ca-app-pub-9631152544509905/3025269801'; // Reusing postRoll for banner ads

  // ============ GOOGLE TEST AD UNIT IDs (for debugging) ============
  // These never show real ads, only test ads, and never block any requests
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeAndroid =
      'ca-app-pub-3940256099942544/2247696110';

  // Toggle to true to use Google test ads (for debugging)
  static const bool _useTestAds = false;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static bool get _supportsAds =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static final Map<InterstitialSlot, InterstitialAd?> _cachedInterstitial =
      <InterstitialSlot, InterstitialAd?>{};
  static final Map<InterstitialSlot, Completer<InterstitialAd?>>
  _loadingInterstitial = <InterstitialSlot, Completer<InterstitialAd?>>{};
  static final Map<InterstitialSlot, DateTime> _lastPreloadTime =
      <InterstitialSlot, DateTime>{};

  static BannerAd? _cachedBannerAd;
  static Completer<BannerAd?>? _loadingBannerAd;

  static String get androidAppId => _adMobAppIdAndroid;
  static String get nativeSnapsUnitIdAndroid => _nativeSnapsAndroid;

  /// Check if user has active premium subscription
  /// Premium users should not see any ads
  static bool shouldDisableAds() {
    try {
      // Import happens here to avoid circular dependency
      // This uses Provider to check if user has active premium
      // If this returns true, all ads should be skipped
      // The actual check will be done from video_player_screen using Provider
      return false; // Default: show ads
    } catch (_) {
      return false; // Default: show ads if error
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!_supportsAds) {
      _initialized = true;
      return;
    }

    await MobileAds.instance.initialize();

    // Kids content: request safer ads. (You can tune this in future.)
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );

    _initialized = true;
  }

  static String _interstitialUnitId(InterstitialSlot slot) {
    if (!_supportsAds) return '';

    if (_useTestAds) {
      debugPrint('Using TEST interstitial ad unit');
      return _testInterstitialAndroid;
    }

    return switch (slot) {
      InterstitialSlot.preRoll => _preRollAndroid,
      InterstitialSlot.midRoll => _midRollAndroid,
      InterstitialSlot.postRoll => _postRollAndroid,
    };
  }

  static Future<InterstitialAd?> preloadInterstitial(
    InterstitialSlot slot,
  ) async {
    await initialize();
    if (!_supportsAds) return null;

    final existing = _cachedInterstitial[slot];
    if (existing != null) return existing;

    final existingLoad = _loadingInterstitial[slot];
    if (existingLoad != null) return existingLoad.future;

    _lastPreloadTime[slot] = DateTime.now();

    final completer = Completer<InterstitialAd?>();
    _loadingInterstitial[slot] = completer;

    final unitId = _interstitialUnitId(slot);
    if (unitId.isEmpty) {
      _loadingInterstitial.remove(slot);
      completer.complete(null);
      debugPrint('Empty unit ID for $slot');
      return null;
    }

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial loaded ($slot)');
          _cachedInterstitial[slot] = ad;
          _loadingInterstitial.remove(slot);
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load ($slot): $error');
          _loadingInterstitial.remove(slot);
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  static Future<bool> showInterstitial(
    InterstitialSlot slot, {
    Duration waitForLoad = const Duration(seconds: 2),
  }) async {
    await initialize();
    if (!_supportsAds) {
      debugPrint('Ads not supported on this platform');
      return false;
    }

    InterstitialAd? ad = _cachedInterstitial[slot];
    if (ad == null) {
      try {
        debugPrint('Preloading interstitial ($slot)...');
        ad = await preloadInterstitial(slot).timeout(waitForLoad);
        debugPrint('Interstitial loaded: ${ad != null}');
      } catch (e) {
        debugPrint('Timeout/error loading interstitial ($slot): $e');
        ad = null;
      }
    } else {
      debugPrint('Using cached interstitial ($slot)');
    }

    if (ad == null) {
      debugPrint('No ad available to show ($slot)');
      return false;
    }

    final dismissed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial dismissed ($slot)');
        ad.dispose();
        _cachedInterstitial[slot] = null;
        // Schedule next preload with a small delay to avoid deep request chains
        Future.delayed(const Duration(milliseconds: 500), () {
          unawaited(preloadInterstitial(slot));
        });
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show ($slot): $error');
        ad.dispose();
        _cachedInterstitial[slot] = null;
        // Schedule next preload with a small delay to avoid deep request chains
        Future.delayed(const Duration(milliseconds: 500), () {
          unawaited(preloadInterstitial(slot));
        });
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      debugPrint('Showing interstitial ($slot)...');
      ad.show();
      await dismissed.future;
      debugPrint('Interstitial shown and dismissed ($slot)');
      return true;
    } catch (e) {
      debugPrint('Interstitial show exception ($slot): $e');
      try {
        ad.dispose();
      } catch (_) {
        // ignore
      }
      _cachedInterstitial[slot] = null;
      // Schedule next preload with a small delay to avoid deep request chains
      Future.delayed(const Duration(milliseconds: 500), () {
        unawaited(preloadInterstitial(slot));
      });
      return false;
    }
  }

  static List<Duration> midRollScheduleFor(Duration videoDuration) {
    // Only allowed if video >= 8 minutes.
    if (videoDuration.inMinutes < 8) return const <Duration>[];

    final totalMinutes = videoDuration.inMinutes;

    // 8–15 min => 1 mid-roll around 5–7 minutes.
    if (totalMinutes < 16) {
      final targetMinutes = (totalMinutes / 2).round().clamp(5, 7);
      return <Duration>[Duration(minutes: targetMinutes)];
    }

    // >= 16 min => max 2 mid-rolls around 7 and 14 minutes.
    final schedule = <Duration>[
      const Duration(minutes: 7),
      const Duration(minutes: 14),
    ];

    // Ensure we don't schedule past the end.
    final latestAllowed = videoDuration - const Duration(minutes: 1);
    return schedule.where((d) => d < latestAllowed).toList(growable: false);
  }

  static NativeAd createNativeSnapsAd({
    required void Function() onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    // Use small template which doesn't have a close button
    // Native ads in feed contexts shouldn't have close buttons
    final style = NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: const Color(0xFF111111),
    );

    final adUnitId = _useTestAds ? _testNativeAndroid : _nativeSnapsAndroid;
    if (_useTestAds) {
      debugPrint('Using TEST native ad unit');
    }

    return NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: style,
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );
  }

  /// Load a banner ad for in-stream video display
  /// Returns a Completer that completes with the loaded ad when ready
  static Future<BannerAd?> loadInStreamBannerAd() async {
    await initialize();
    if (!_supportsAds) return null;

    final existing = _cachedBannerAd;
    if (existing != null) {
      debugPrint('Banner ad already cached');
      return existing;
    }

    final existingLoad = _loadingBannerAd;
    if (existingLoad != null) {
      debugPrint('Banner ad already loading...');
      return existingLoad.future;
    }

    final completer = Completer<BannerAd?>();
    _loadingBannerAd = completer;

    final adUnitId = _useTestAds ? _testBannerAndroid : _bannerAndroid;
    if (_useTestAds) {
      debugPrint('Using TEST banner ad unit');
    }

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully');
          _cachedBannerAd = ad as BannerAd;
          _loadingBannerAd = null;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _loadingBannerAd = null;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      debugPrint('Loading banner ad...');
      await bannerAd.load();
      debugPrint('Banner ad load called, waiting for callback...');
    } catch (e) {
      debugPrint('Banner ad load exception: $e');
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }

  /// Preload an in-stream banner ad
  static Future<void> preloadInStreamBannerAd() async {
    unawaited(loadInStreamBannerAd());
  }

  /// Get the current cached banner ad
  static BannerAd? getCachedBannerAd() {
    return _cachedBannerAd;
  }

  /// Dispose the current banner ad and clear cache
  static void disposeBannerAd() {
    _cachedBannerAd?.dispose();
    _cachedBannerAd = null;
  }

  /// Check if a banner ad is available and loaded
  static bool isBannerAdAvailable() {
    return _cachedBannerAd != null;
  }
}
