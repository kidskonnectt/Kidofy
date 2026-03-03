import 'package:flutter/foundation.dart';
import 'package:kidsapp/models/premium_subscription.dart';
import 'package:kidsapp/services/premium_service.dart';

class PremiumNotifier extends ChangeNotifier {
  final PremiumService _premiumService = PremiumService();

  PremiumSubscription? _subscription;
  bool _isLoading = false;
  String? _error;

  PremiumSubscription? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActivePremium => _subscription?.isActive ?? false;
  int get daysRemaining => _subscription?.daysRemaining ?? 0;
  String get subscriptionStatus =>
      _subscription?.planName ?? 'No Active Subscription';

  /// Initialize premium status for user
  Future<void> initializePremium(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Initializing premium for user: $userId');
      _subscription = await _premiumService.getActiveSubscription(userId);
      debugPrint(
        '✅ Premium initialized: ${_subscription?.planName ?? 'No subscription'}',
      );
    } catch (e) {
      _error = 'Failed to load premium status: $e';
      debugPrint('❌ Error initializing premium: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create order and process payment
  Future<Map<String, dynamic>> purchasePlan({
    required String userId,
    required PremiumPlan plan,
    required String userEmail,
    required String userName,
    required String userPhone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('💳 Processing purchase for plan: ${plan.name}');

      // Create Razorpay order
      final orderId = await _premiumService.createRazorpayOrder(
        userId: userId,
        planName: plan.name,
        amount: (int.parse(plan.price) * 100).toString(), // Convert to paise
      );

      debugPrint('✅ Order created: $orderId');

      return {
        'success': true,
        'orderId': orderId,
        'plan': plan,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userPhone': userPhone,
      };
    } catch (e) {
      _error = 'Failed to create order: $e';
      debugPrint('❌ Error creating order: $e');
      return {'success': false, 'error': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save subscription after successful payment
  Future<bool> saveSubscriptionAfterPayment({
    required String userId,
    required PremiumPlan plan,
    required String razorpayOrderId,
    required String razorpayPaymentId,
  }) async {
    try {
      debugPrint(
        '💾 Saving subscription after payment for user: $userId, plan: ${plan.name}',
      );

      await _premiumService.saveSubscription(
        userId: userId,
        planName: plan.name,
        planDuration: plan.durationText,
        price: double.parse(plan.price),
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        durationInDays: plan.durationInDays,
      );

      // Refresh subscription data
      await initializePremium(userId);
      debugPrint('✅ Subscription saved successfully');
      return true;
    } catch (e) {
      _error = 'Failed to save subscription: $e';
      debugPrint('❌ Error saving subscription: $e');
      notifyListeners();
      return false;
    }
  }

  /// Verify payment
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      debugPrint('🔐 Verifying payment: $paymentId');
      return await _premiumService.verifyPayment(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      );
    } catch (e) {
      _error = 'Payment verification failed: $e';
      debugPrint('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Refresh subscription status
  Future<void> refreshSubscription(String userId) async {
    try {
      _subscription = await _premiumService.getActiveSubscription(userId);
      notifyListeners();
      debugPrint('✅ Subscription refreshed: ${_subscription?.planName}');
    } catch (e) {
      _error = 'Failed to refresh subscription: $e';
      debugPrint('❌ Error refreshing subscription: $e');
      notifyListeners();
    }
  }

  /// Check if subscription has expired and update status
  Future<void> checkSubscriptionExpiry(String userId) async {
    try {
      if (_subscription == null) return;

      if (_subscription!.isExpired) {
        debugPrint('⏰ Subscription has expired, updating status');
        await _premiumService.updateSubscriptionStatus(
          _subscription!.id,
          'expired',
        );
        _subscription = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error checking subscription expiry: $e');
    }
  }

  /// Clear premium data
  void clearPremium() {
    _subscription = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
