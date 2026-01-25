import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum InterstitialSlot { preRoll, midRoll, postRoll }

class AdsService {
  static const String _adMobAppIdAndroid =
      'ca-app-pub-2428967748052842~1409514429';

  static const String _preRollAndroid =
      'ca-app-pub-2428967748052842/7085169479';
  static const String _midRollAndroid =
      'ca-app-pub-2428967748052842/4737357672';
  static const String _postRollAndroid =
      'ca-app-pub-2428967748052842/3317314856';

  static const String _nativeSnapsAndroid =
      'ca-app-pub-2428967748052842/8457960892';

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

  static String get androidAppId => _adMobAppIdAndroid;
  static String get nativeSnapsUnitIdAndroid => _nativeSnapsAndroid;

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

    final completer = Completer<InterstitialAd?>();
    _loadingInterstitial[slot] = completer;

    final unitId = _interstitialUnitId(slot);
    if (unitId.isEmpty) {
      _loadingInterstitial.remove(slot);
      completer.complete(null);
      return null;
    }

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cachedInterstitial[slot] = ad;
          _loadingInterstitial.remove(slot);
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load ($slot): $error');
          _loadingInterstitial.remove(slot);
          completer.complete(null);
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
    if (!_supportsAds) return false;

    InterstitialAd? ad = _cachedInterstitial[slot];
    if (ad == null) {
      try {
        ad = await preloadInterstitial(slot).timeout(waitForLoad);
      } catch (_) {
        ad = null;
      }
    }

    if (ad == null) return false;

    final dismissed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _cachedInterstitial[slot] = null;
        // Start loading the next one ASAP.
        unawaited(preloadInterstitial(slot));
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show ($slot): $error');
        ad.dispose();
        _cachedInterstitial[slot] = null;
        unawaited(preloadInterstitial(slot));
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      ad.show();
      await dismissed.future;
      return true;
    } catch (e) {
      debugPrint('Interstitial show exception ($slot): $e');
      try {
        ad.dispose();
      } catch (_) {
        // ignore
      }
      _cachedInterstitial[slot] = null;
      unawaited(preloadInterstitial(slot));
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
    final style = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: const Color(0xFF111111),
    );

    return NativeAd(
      adUnitId: _nativeSnapsAndroid,
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
}
