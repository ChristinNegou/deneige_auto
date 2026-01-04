import 'package:equatable/equatable.dart';

enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final CardBrand brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final DateTime createdAt;
  final String? billingName;
  final String? stripePaymentMethodId;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
    required this.createdAt,
    this.billingName,
    this.stripePaymentMethodId,
  });

  // Business logic
  bool get isExpired {
    final now = DateTime.now();
    return expYear < now.year || (expYear == now.year && expMonth < now.month);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final expiryDate = DateTime(expYear, expMonth);
    final monthsUntilExpiry = expiryDate.difference(now).inDays ~/ 30;
    return monthsUntilExpiry <= 2 && monthsUntilExpiry >= 0;
  }

  String get displayNumber {
    return '•••• $last4';
  }

  String get expiryDisplay {
    return '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    CardBrand? brand,
    String? last4,
    int? expMonth,
    int? expYear,
    bool? isDefault,
    DateTime? createdAt,
    String? billingName,
    String? stripePaymentMethodId,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      billingName: billingName ?? this.billingName,
      stripePaymentMethodId:
          stripePaymentMethodId ?? this.stripePaymentMethodId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        brand,
        last4,
        expMonth,
        expYear,
        isDefault,
        createdAt,
        billingName,
        stripePaymentMethodId,
      ];
}

extension CardBrandExtension on CardBrand {
  String get displayName {
    switch (this) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.unknown:
        return 'Carte';
    }
  }
}
