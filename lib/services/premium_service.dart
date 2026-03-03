import 'package:flutter/foundation.dart';
import 'package:kidsapp/models/premium_subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  static final client = Supabase.instance.client;

  factory PremiumService() {
    return _instance;
  }

  PremiumService._internal();

  /// Create Razorpay Order in Backend
  Future<String> createRazorpayOrder({
    required String userId,
    required String planName,
    required String amount, // Amount in paise
  }) async {
    try {
      debugPrint(
        '📝 Creating Razorpay order for user: $userId, plan: $planName',
      );

      // Ensure user is authenticated and session is valid
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Refresh session to get fresh JWT token
      try {
        await client.auth.refreshSession();
        debugPrint('✅ Session refreshed successfully');
      } catch (e) {
        debugPrint('⚠️ Session refresh failed: $e');
        // Continue anyway, as the session might still be valid
      }

      // Verify session is valid
      final session = client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final jwtToken = session.accessToken;
      debugPrint('✅ User authenticated: ${currentUser.id}');
      debugPrint('✅ JWT token available, calling edge function');
      debugPrint('🔐 JWT Token: ${jwtToken.substring(0, 50)}...');

      // Get the Supabase project URL from REST endpoint
      final restUrl = client.rest.url;
      final supabaseUrl = restUrl.replaceAll('/rest/v1', '');
      final functionUrl = '$supabaseUrl/functions/v1/create_razorpay_order';

      debugPrint('📍 Function URL: $functionUrl');
      debugPrint('📍 Supabase REST URL: $restUrl');

      // Make direct HTTP request with JWT in Authorization header
      // NOTE: If you get 401 Unauthorized, the edge function needs JWT verification disabled.
      // Deploy with: supabase functions deploy create_razorpay_order --no-verify-jwt
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'plan_name': planName,
        }),
      );

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');
      debugPrint('📨 Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        String errorMessage = 'Unknown error';
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage =
                errorBody['error'] ?? errorBody['message'] ?? 'Unknown error';
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'Empty response';
        }

        throw Exception(
          'Failed to create order: ${response.statusCode} - $errorMessage (JWT: ${jwtToken.substring(0, 20)}...)',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final orderId = data['order_id'] as String?;

      if (orderId == null) {
        throw Exception('Order ID not returned from server');
      }

      debugPrint('✅ Razorpay order created: $orderId');
      return orderId;
    } catch (e) {
      debugPrint('❌ Error creating Razorpay order: $e');
      rethrow;
    }
  }

  /// Save subscription to database
  Future<void> saveSubscription({
    required String userId,
    required String planName,
    required String planDuration,
    required double price,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required int durationInDays,
  }) async {
    try {
      final subscriptionId = const Uuid().v4();
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationInDays));

      debugPrint('💾 Saving subscription: $subscriptionId');

      await client.from('premium_subscriptions').insert({
        'id': subscriptionId,
        'user_id': userId,
        'plan_name': planName,
        'plan_duration': planDuration,
        'price': price,
        'purchase_date': now.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'status': 'active',
      });

      debugPrint('✅ Subscription saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving subscription: $e');
      rethrow;
    }
  }

  /// Get active subscription for user
  Future<PremiumSubscription?> getActiveSubscription(String userId) async {
    try {
      debugPrint('🔍 Fetching subscription for user: $userId');

      final response = await client
          .from('premium_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('purchase_date', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('❌ No active subscription found');
        return null;
      }

      final subscription = PremiumSubscription.fromJson(response[0]);

      // Check if subscription has expired
      if (subscription.isExpired) {
        debugPrint('⏰ Subscription expired, updating status');
        await updateSubscriptionStatus(subscription.id, 'expired');
        return null;
      }

      debugPrint('✅ Active subscription found: ${subscription.planName}');
      return subscription;
    } catch (e) {
      debugPrint('❌ Error fetching subscription: $e');
      return null;
    }
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus(
    String subscriptionId,
    String status,
  ) async {
    try {
      debugPrint('🔄 Updating subscription $subscriptionId status to: $status');

      await client
          .from('premium_subscriptions')
          .update({'status': status})
          .eq('id', subscriptionId);

      debugPrint('✅ Subscription status updated');
    } catch (e) {
      debugPrint('❌ Error updating subscription status: $e');
      rethrow;
    }
  }

  /// Get subscription history for user
  Future<List<PremiumSubscription>> getSubscriptionHistory(
    String userId,
  ) async {
    try {
      debugPrint('📋 Fetching subscription history for user: $userId');

      final response = await client
          .from('premium_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('purchase_date', ascending: false);

      final subscriptions = (response as List)
          .map((json) => PremiumSubscription.fromJson(json))
          .toList();

      debugPrint('✅ Found ${subscriptions.length} subscriptions');
      return subscriptions;
    } catch (e) {
      debugPrint('❌ Error fetching subscription history: $e');
      return [];
    }
  }

  /// Verify payment with Razorpay
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      debugPrint('🔐 Verifying payment: $paymentId');

      // Ensure user is authenticated and session is valid
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Refresh session to get fresh JWT token
      try {
        await client.auth.refreshSession();
        debugPrint('✅ Session refreshed successfully');
      } catch (e) {
        debugPrint('⚠️ Session refresh failed: $e');
        // Continue anyway, as the session might still be valid
      }

      // Verify session is valid
      final session = client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final jwtToken = session.accessToken;
      debugPrint('✅ User authenticated: ${currentUser.id}');
      debugPrint('✅ JWT token available, verifying payment');

      // Get the Supabase project URL from REST endpoint
      final restUrl = client.rest.url;
      final supabaseUrl = restUrl.replaceAll('/rest/v1', '');
      final functionUrl = '$supabaseUrl/functions/v1/verify_razorpay_payment';

      debugPrint('📍 Calling function at: $functionUrl');

      // Make direct HTTP request with JWT in Authorization header
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
        }),
      );

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');
      debugPrint('📨 Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Payment verification failed with status ${response.statusCode}',
        );
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final isValid = data['success'] as bool? ?? false;
      debugPrint(
        isValid ? '✅ Payment verified' : '❌ Payment verification failed',
      );
      return isValid;
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Check if user has active premium
  Future<bool> hasActivePremium(String userId) async {
    final subscription = await getActiveSubscription(userId);
    return subscription != null && subscription.isActive;
  }

  /// Get days remaining in subscription
  Future<int> getDaysRemaining(String userId) async {
    final subscription = await getActiveSubscription(userId);
    if (subscription == null) return 0;
    return subscription.daysRemaining;
  }

  /// Renew subscription
  Future<void> renewSubscription({
    required String userId,
    required String planName,
    required String planDuration,
    required double price,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required int durationInDays,
  }) async {
    try {
      debugPrint('🔄 Renewing subscription for user: $userId');

      // Get existing subscription
      final existingSubscription = await getActiveSubscription(userId);

      // Mark existing as expired
      if (existingSubscription != null) {
        await updateSubscriptionStatus(existingSubscription.id, 'expired');
      }

      // Create new subscription
      await saveSubscription(
        userId: userId,
        planName: planName,
        planDuration: planDuration,
        price: price,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        durationInDays: durationInDays,
      );

      debugPrint('✅ Subscription renewed successfully');
    } catch (e) {
      debugPrint('❌ Error renewing subscription: $e');
      rethrow;
    }
  }
}
