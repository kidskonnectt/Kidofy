import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  late Razorpay _razorpay;

  // API Keys
  static const String apiKey = 'rzp_live_SMOkShIYcMBuLb';

  // Callbacks
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  factory RazorpayService() {
    return _instance;
  }

  RazorpayService._internal() {
    _razorpay = Razorpay();
    _setupListeners();
  }

  void _setupListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment Successful: ${response.paymentId}');
    _onPaymentSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    _onPaymentError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('💳 External Wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  void setCallbacks({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    _onExternalWallet = onExternalWallet;
  }

  void openCheckout({
    required String orderId,
    required String amount, // Amount in paise (e.g., 9900 for ₹99)
    required String description,
    required String userEmail,
    required String userName,
    required String userPhone,
  }) {
    var options = {
      'key': apiKey,
      'order_id': orderId,
      'amount': amount,
      'name': 'Kidofy Premium',
      'description': description,
      'prefill': {'contact': userPhone, 'email': userEmail, 'name': userName},
      'theme': {
        'color': '#FF6B6B', // Kidofy red color
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening checkout: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
