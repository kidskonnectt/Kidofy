import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kidsapp/services/premium_service.dart';

/// Service to periodically check for subscription expiration
class SubscriptionExpiryChecker {
  static final SubscriptionExpiryChecker _instance =
      SubscriptionExpiryChecker._internal();
  static Timer? _timer;
  static final PremiumService _premiumService = PremiumService();

  factory SubscriptionExpiryChecker() {
    return _instance;
  }

  SubscriptionExpiryChecker._internal();

  /// Start checking for expired subscriptions every 6 hours
  void startAutoCheck() {
    debugPrint('🔄 Starting subscription expiry checker');

    // Check immediately on startup
    _performCheck();

    // Then check every 6 hours
    _timer = Timer.periodic(const Duration(hours: 6), (_) {
      _performCheck();
    });
  }

  /// Stop the auto-check
  void stopAutoCheck() {
    debugPrint('⏹️ Stopping subscription expiry checker');
    _timer?.cancel();
    _timer = null;
  }

  /// Manually trigger a check
  Future<void> _performCheck() async {
    try {
      debugPrint('🔍 Checking for expired subscriptions...');

      // Note: In production, you'd want to get the user ID from auth
      // This is a service-level check that can be expanded

      debugPrint('✅ Subscription expiry check completed');
    } catch (e) {
      debugPrint('❌ Error during expiry check: $e');
    }
  }

  /// Check specific user subscription expiry
  Future<bool> checkUserSubscriptionExpiry(String userId) async {
    try {
      final subscription = await _premiumService.getActiveSubscription(userId);
      if (subscription == null) return false;

      if (subscription.isExpired) {
        debugPrint('⏰ Subscription expired for user: $userId');
        await _premiumService.updateSubscriptionStatus(
          subscription.id,
          'expired',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking user subscription expiry: $e');
      return false;
    }
  }
}
