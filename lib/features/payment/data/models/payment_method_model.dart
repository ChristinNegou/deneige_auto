import '../../domain/entities/payment_method.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.userId,
    required super.brand,
    required super.last4,
    required super.expMonth,
    required super.expYear,
    super.isDefault = false,
    required super.createdAt,
    super.billingName,
    super.stripePaymentMethodId,
  });

  /// Create from Stripe API response
  factory PaymentMethodModel.fromStripeJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>;

    return PaymentMethodModel(
      id: json['id'],
      userId: '', // Set from context
      brand: _parseCardBrand(card['brand']),
      last4: card['last4'],
      expMonth: card['exp_month'],
      expYear: card['exp_year'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000),
      billingName: json['billing_details']?['name'],
      stripePaymentMethodId: json['id'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  static CardBrand _parseCardBrand(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'amex':
        return CardBrand.amex;
      case 'discover':
        return CardBrand.discover;
      default:
        return CardBrand.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'brand': brand.name,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'isDefault': isDefault,
      'billingName': billingName,
      'stripePaymentMethodId': stripePaymentMethodId,
    };
  }
}
