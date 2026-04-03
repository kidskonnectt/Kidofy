import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidsapp/screens/settings/app_policies_screen.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/providers/premium_notifier.dart';
import 'package:kidsapp/models/premium_subscription.dart';
import 'package:kidsapp/services/razorpay_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? selectedPlan;
  late ScrollController _reviewScrollController;
  late RazorpayService _razorpayService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _reviewScrollController = ScrollController();
    _razorpayService = RazorpayService();

    // Set up Razorpay callbacks
    _razorpayService.setCallbacks(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _reviewScrollController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment successful: ${response.paymentId}');

    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      final premiumNotifier = context.read<PremiumNotifier>();
      final selectedPlanObj = PremiumPlan.getAllPlans().firstWhere(
        (p) => p.name == selectedPlan,
      );

      // Save subscription to database
      final success = await premiumNotifier.saveSubscriptionAfterPayment(
        userId: currentUser.id,
        plan: selectedPlanObj,
        razorpayOrderId: response.data?['order_id'] ?? 'N/A',
        razorpayPaymentId: response.paymentId ?? 'N/A',
      );

      if (success) {
        _showSuccess(
          'Congratulations! 🎉\n\nYou now have premium access for ${selectedPlanObj.name}!\n\nEnjoy unlimited videos and ad-free experience!',
        );

        // Pop back to home after a delay
        Future.delayed(Duration(seconds: 3)).then((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showError('Failed to save subscription. Please contact support.');
      }
    } catch (e) {
      _showError('Error processing subscription: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment failed: ${response.code} - ${response.message}');
    _showError('Payment failed: ${response.message ?? 'Unknown error'}');
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('💳 External wallet selected: ${response.walletName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${response.walletName}...'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success! 🎉'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (selectedPlan == null) {
      _showError('Please select a plan');
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      final premiumNotifier = context.read<PremiumNotifier>();
      final selectedPlanObj = PremiumPlan.getAllPlans().firstWhere(
        (p) => p.name == selectedPlan,
      );

      // Get user email and name
      final userEmail = currentUser.email ?? 'user@kidofy.app';
      final userName =
          currentUser.userMetadata?['name'] as String? ?? 'Kidofy User';
      final userPhone =
          currentUser.userMetadata?['phone'] as String? ?? '+91 9000000000';

      // Create order
      final orderResult = await premiumNotifier.purchasePlan(
        userId: currentUser.id,
        plan: selectedPlanObj,
        userEmail: userEmail,
        userName: userName,
        userPhone: userPhone,
      );

      if (!orderResult['success']) {
        _showError(orderResult['error'] ?? 'Failed to create order');
        return;
      }

      final orderId = orderResult['orderId'] as String;

      // Open Razorpay checkout
      _razorpayService.openCheckout(
        orderId: orderId,
        amount: (int.parse(selectedPlanObj.price) * 100).toString(),
        description: 'Kidofy Premium - ${selectedPlanObj.name}',
        userEmail: userEmail,
        userName: userName,
        userPhone: userPhone,
      );
    } catch (e) {
      _showError('Error initiating payment: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _startAutoScroll() {
    if (!_reviewScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
      return;
    }

    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!mounted) return;
      if (_reviewScrollController.hasClients) {
        final maxScroll = _reviewScrollController.position.maxScrollExtent;
        _reviewScrollController
            .animateTo(
              maxScroll,
              duration: Duration(seconds: (maxScroll / 100).toInt()),
              curve: Curves.linear,
            )
            .then((_) {
              if (mounted) {
                _reviewScrollController.jumpTo(0);
                _startAutoScroll();
              }
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumNotifier>(
      builder: (context, premiumNotifier, _) {
        // If premium is active, show active subscription page
        if (premiumNotifier.hasActivePremium) {
          return _buildActivePremiumPage(premiumNotifier);
        }

        // Otherwise show purchase page
        return _buildPurchasePage();
      },
    );
  }

  Widget _buildActivePremiumPage(PremiumNotifier premiumNotifier) {
    final subscription = premiumNotifier.subscription;
    if (subscription == null) {
      return _buildPurchasePage();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Premium',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Active Plan Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withOpacity(0.15),
                      Colors.orange.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '🎉 Active Subscription 🎉',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subscription.planName,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${subscription.price.toStringAsFixed(0)}',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 30),

              // Countdown Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Days Remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${subscription.daysRemaining}',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expires: ${subscription.expiryDate.toString().split(' ')[0]}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),

              const SizedBox(height: 30),

              // Active Plan Features
              Text(
                'Your Premium Features',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildActivePlanFeatures(subscription),

              const SizedBox(height: 40),

              // Subscription Info
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Details',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Plan', subscription.planName),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Purchase Date',
                      subscription.purchaseDate.toString().split(' ')[0],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Expiry Date',
                      subscription.expiryDate.toString().split(' ')[0],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Status',
                      subscription.status.toUpperCase(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Cancel Premium Info
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  'To cancel your subscription, please email us at contact@kidofy.in. No hidden charges!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.amber.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlanFeatures(PremiumSubscription subscription) {
    final planFeatures = _getFeaturesByPlan(subscription.planName);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: planFeatures.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryRed.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: Text(
              planFeatures[index],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ).animate().fadeIn(
          duration: 500.ms,
          delay: Duration(milliseconds: 100 * index),
        );
      },
    );
  }

  List<String> _getFeaturesByPlan(String planName) {
    const commonFeatures = [
      '🎥 Unlimited Videos',
      '📺 Ad-Free',
      '⭐ Exclusive Content',
      '📚 All Resources',
    ];

    if (planName == '1 Month') {
      return commonFeatures;
    } else if (planName == '3 Months') {
      return [...commonFeatures, '🎬 HD Quality', '⏱️ Extended Access'];
    } else if (planName == '6 Months') {
      return [
        ...commonFeatures,
        '🎬 HD Quality',
        '🌍 Offline Access',
        '⏱️ Extended Access',
        '💬 Priority Support',
      ];
    } else if (planName == '1 Year') {
      return [
        ...commonFeatures,
        '🎬 HD Quality',
        '🌍 Offline Access',
        '⏱️ Extended Access',
        '💬 24/7 Support',
        '🎁 Bonus Features',
        '👨‍👩‍👧‍👦 Family Friendly',
      ];
    }
    return commonFeatures;
  }

  Widget _buildPurchasePage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kidofy Premium',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Premium Header Section
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withOpacity(0.1),
                      Colors.yellow.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '✨ Unlock Premium Kidofy ✨',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
                    const SizedBox(height: 16),
                    Text(
                      'Unlimited access to all our amazing educational content, ad-free experience, and exclusive features!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 30),

              // Premium Features
              Text(
                'Premium Features',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeaturesList(),
              const SizedBox(height: 30),

              // Pricing Plans
              Text(
                'Choose Your Plan',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildPricingPlans(),
              const SizedBox(height: 30),

              const SizedBox(height: 20),
              const SizedBox(height: 40),

              // FAQs Section
              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQs(),
              const SizedBox(height: 40),

              // Reviews Section
              Text(
                'What Parents Say',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildReviews(),
              const SizedBox(height: 40),

              // Terms and Auto-Pay Note
              _buildTermsAndAutoPayNote(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      '🎥 Unlimited Video Access',
      '📺 Ad-Free Experience',
      '⭐ Exclusive Premium Content',
      '� Educational Resources',
      '🎬 HD Quality Streaming',
      '🌍 Offline Content Access',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryRed.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(
                child: Text(
                  features[index],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: Duration(milliseconds: 100 * index),
            )
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 500.ms,
              delay: Duration(milliseconds: 100 * index),
            );
      },
    );
  }

  Widget _buildPricingPlans() {
    final plans = PremiumPlan.getAllPlans();

    return Column(
      children: List.generate(plans.length, (index) {
        final plan = plans[index];
        final isSelected = selectedPlan == plan.name;
        final isPopular = plan.isPopular;

        return GestureDetector(
              onTap: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        selectedPlan = plan.name;
                      });
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (index == 0
                                ? Colors.blue
                                : index == 1
                                ? Colors.purple
                                : index == 2
                                ? AppColors.primaryRed
                                : Colors.green)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? (index == 0
                              ? Colors.blue
                              : index == 1
                              ? Colors.purple
                              : index == 2
                              ? AppColors.primaryRed
                              : Colors.green)
                        : Colors.grey.withOpacity(0.2),
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: isPopular || isSelected
                      ? [
                          BoxShadow(
                            color:
                                (index == 0
                                        ? Colors.blue
                                        : index == 1
                                        ? Colors.purple
                                        : index == 2
                                        ? AppColors.primaryRed
                                        : Colors.green)
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Popular Badge
                    if (isPopular)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'BEST VALUE 🌟',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Content
                    Column(
                      children: [
                        Row(
                          children: [
                            // Icon
                            Text(
                              plan.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 16),

                            // Plan Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Benefits
                                  ...plan.benefits.map((benefit) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '✓ $benefit',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : (index == 0
                                                  ? Colors.blue
                                                  : index == 1
                                                      ? Colors.purple
                                                      : index == 2
                                                          ? AppColors
                                                              .primaryRed
                                                          : Colors.green),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  if (plan.saving != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.4)
                                              : Colors.green.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        plan.saving!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.green.shade700,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Price
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${plan.price}',
                                  style: GoogleFonts.bubblegumSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : (index == 0
                                            ? Colors.blue
                                            : index == 1
                                                ? Colors.purple
                                                : index == 2
                                                    ? AppColors
                                                        .primaryRed
                                                    : Colors.green),
                                  ),
                                ),
                                Text(
                                  plan.durationText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            // Checkbox
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: (index == 0
                                          ? Colors.blue
                                          : index == 1
                                              ? Colors.purple
                                              : index == 2
                                                  ? AppColors.primaryRed
                                                  : Colors.green),
                                      size: 16,
                                    )
                                  : const SizedBox(width: 16, height: 16),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: (index == 0
                                    ? Colors.blue
                                    : index == 1
                                        ? Colors.purple
                                        : index == 2
                                            ? AppColors.primaryRed
                                            : Colors.green),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  _isProcessing ? null : _initiatePayment,
                              child: _isProcessing
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          (index == 0
                                              ? Colors.blue
                                              : index == 1
                                                  ? Colors.purple
                                                  : index == 2
                                                      ? AppColors.primaryRed
                                                      : Colors.green),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Subscribe Now',
                                      style: GoogleFonts.bubblegumSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ).animate().scale(
                                duration: 300.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: Duration(milliseconds: 150 * index),
            )
            .slideX(
              begin: -0.3,
              end: 0,
              duration: 500.ms,
              delay: Duration(milliseconds: 150 * index),
            );
      }),
    );
  }

  Widget _buildFAQs() {
    final faqs = [
      {
        'question': 'Can I cancel my subscription anytime?',
        'answer':
            'Yes! You can cancel anytime by emailing us at contact@kidofy.in with your request. We\'ll process it immediately. No hidden charges or cancellation fees.',
      },
      {
        'question': 'What payment methods do you accept?',
        'answer':
            'We accept all major credit/debit cards, UPI, and digital wallets like Google Pay and Apple Pay.',
      },
      {
        'question': 'What if I don\'t want to pay?',
        'answer':
            'We have a free version of Kidofy with ads. Premium removes all ads and gives access to exclusive content!',
      },
      {
        'question': 'Is there an annual discount?',
        'answer':
            '1 Year plan gives you 41% discount compared to monthly billing. That\'s the best value! ⭐',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return ExpansionTile(
              title: Text(
                faq['question'] as String,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    faq['answer'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 100 * index),
            )
            .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildReviews() {
    final reviews = [
      {
        'name': 'Priya Sharma',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'rating': 5,
        'review':
            'Best content for kids! My children love it and it\'s completely safe.',
        'avatar': '👩',
      },
      {
        'name': 'Rajesh Kumar',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'rating': 5,
        'review':
            'Worth every penny! Ad-free and unlimited content keeps my kids engaged.',
        'avatar': '👨',
      },
      {
        'name': 'Neha Patel',
        'city': 'Delhi',
        'state': 'Delhi',
        'rating': 5,
        'review':
            'Education + Entertainment combined perfectly. Highly recommended!',
        'avatar': '👩',
      },
      {
        'name': 'Arun Singh',
        'city': 'Pune',
        'state': 'Maharashtra',
        'rating': 5,
        'review':
            'My kids are learning so much through fun videos. Great platform!',
        'avatar': '👨',
      },
      {
        'name': 'Meera Gupta',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'rating': 5,
        'review':
            'Clean, safe, and entertaining. Exactly what we needed for our family.',
        'avatar': '👩',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _reviewScrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: List.generate(reviews.length, (index) {
          final review = reviews[index];
          return Container(
                width: 280,
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating Stars
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Review Text
                    Text(
                      review['review'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // User Info
                    Row(
                      children: [
                        Text(
                          review['avatar'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['name'] as String,
                                style: GoogleFonts.bubblegumSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${review['city']}, ${review['state']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 150 * index),
              )
              .slideY(begin: 0.3, end: 0);
        }),
      ),
    );
  }

  Widget _buildTermsAndAutoPayNote() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AppPoliciesScreen(
              title: 'Terms of Service',
              content: PolicyContent.termsOfService,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          'By subscribing, you are accepting our Terms of Service',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.amber.shade700,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }
}
