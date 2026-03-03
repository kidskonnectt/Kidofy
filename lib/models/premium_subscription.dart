class PremiumSubscription {
  final String id;
  final String userId;
  final String planName; // "1 Month", "3 Months", "6 Months", "1 Year"
  final String planDuration; // Duration in days or months
  final double price;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String status; // "active", "expired", "cancelled"

  PremiumSubscription({
    required this.id,
    required this.userId,
    required this.planName,
    required this.planDuration,
    required this.price,
    required this.purchaseDate,
    required this.expiryDate,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.status,
  });

  bool get isActive =>
      status == 'active' && DateTime.now().isBefore(expiryDate);

  bool get isExpired =>
      DateTime.now().isAfter(expiryDate) && status == 'active';

  int get daysRemaining {
    if (!isActive) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_name': planName,
      'plan_duration': planDuration,
      'price': price,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'status': status,
    };
  }

  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planName: json['plan_name'] as String,
      planDuration: json['plan_duration'] as String,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      razorpayOrderId: json['razorpay_order_id'] as String,
      razorpayPaymentId: json['razorpay_payment_id'] as String,
      status: json['status'] as String,
    );
  }

  PremiumSubscription copyWith({
    String? id,
    String? userId,
    String? planName,
    String? planDuration,
    double? price,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? status,
  }) {
    return PremiumSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      planDuration: planDuration ?? this.planDuration,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      status: status ?? this.status,
    );
  }
}

class PremiumPlan {
  final String name;
  final String price;
  final String durationText;
  final String icon;
  final bool isPopular;
  final String? saving;
  final List<String> benefits;
  final int durationInDays;

  const PremiumPlan({
    required this.name,
    required this.price,
    required this.durationText,
    required this.icon,
    required this.isPopular,
    this.saving,
    required this.benefits,
    required this.durationInDays,
  });

  static List<PremiumPlan> getAllPlans() => [
    PremiumPlan(
      name: '1 Month',
      price: '99',
      durationText: 'per month',
      icon: '📅',
      isPopular: false,
      benefits: ['Unlimited Videos', 'Ad-Free Experience', 'HD Quality'],
      durationInDays: 30,
    ),
    PremiumPlan(
      name: '3 Months',
      price: '249',
      durationText: '₹83/month',
      icon: '⏰',
      isPopular: false,
      saving: 'Save ₹48',
      benefits: [
        'Unlimited Videos',
        'Ad-Free Experience',
        'HD Quality',
        'Offline Access',
      ],
      durationInDays: 90,
    ),
    PremiumPlan(
      name: '6 Months',
      price: '399',
      durationText: '₹67/month',
      icon: '🏆',
      isPopular: false,
      saving: 'Save ₹195',
      benefits: [
        'Unlimited Videos',
        'Ad-Free Experience',
        'HD Quality',
        'Offline Access',
        'Priority Support',
      ],
      durationInDays: 180,
    ),
    PremiumPlan(
      name: '1 Year',
      price: '699',
      durationText: '₹58/month',
      icon: '👑',
      isPopular: true,
      saving: 'Save ₹489',
      benefits: [
        'Unlimited Videos',
        'Ad-Free Experience',
        'HD Quality',
        'Offline Access',
        'Premium Support 24/7',
      ],
      durationInDays: 365,
    ),
  ];
}
