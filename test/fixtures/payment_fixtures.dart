import 'package:deneige_auto/features/payment/domain/entities/payment.dart';
import 'package:deneige_auto/features/payment/domain/entities/payment_method.dart';
import 'package:deneige_auto/features/payment/domain/entities/refund.dart';

/// Fixtures pour les tests de paiement
class PaymentFixtures {
  static final DateTime _now = DateTime(2024, 1, 15, 10, 0);

  /// Cree un paiement reussi
  static Payment createSucceeded({
    String? id,
    String? userId,
    String? reservationId,
    double? amount,
    String? last4,
    String? cardBrand,
  }) {
    return Payment(
      id: id ?? 'payment-123',
      userId: userId ?? 'user-123',
      reservationId: reservationId ?? 'reservation-123',
      amount: amount ?? 25.0,
      status: PaymentStatus.succeeded,
      methodType: PaymentMethodType.card,
      last4: last4 ?? '4242',
      cardBrand: cardBrand ?? 'Visa',
      createdAt: _now,
      paidAt: _now,
      vehicleMake: 'Honda',
      vehicleModel: 'Civic',
      parkingSpotNumber: 'A-15',
    );
  }

  /// Cree un paiement en attente
  static Payment createPending({
    String? id,
    double? amount,
  }) {
    return Payment(
      id: id ?? 'payment-pending-123',
      userId: 'user-123',
      reservationId: 'reservation-123',
      amount: amount ?? 25.0,
      status: PaymentStatus.pending,
      methodType: PaymentMethodType.card,
      createdAt: _now,
    );
  }

  /// Cree un paiement echoue
  static Payment createFailed({
    String? id,
    String? failureMessage,
  }) {
    return Payment(
      id: id ?? 'payment-failed-123',
      userId: 'user-123',
      reservationId: 'reservation-123',
      amount: 25.0,
      status: PaymentStatus.failed,
      methodType: PaymentMethodType.card,
      createdAt: _now,
      failureMessage: failureMessage ?? 'Carte refusee',
    );
  }

  /// Cree un paiement rembourse
  static Payment createRefunded({
    String? id,
    double? amount,
    double? refundedAmount,
  }) {
    return Payment(
      id: id ?? 'payment-refunded-123',
      userId: 'user-123',
      reservationId: 'reservation-123',
      amount: amount ?? 25.0,
      refundedAmount: refundedAmount ?? 25.0,
      status: PaymentStatus.refunded,
      methodType: PaymentMethodType.card,
      createdAt: _now,
      paidAt: _now,
      refundedAt: _now.add(const Duration(hours: 2)),
    );
  }

  /// Cree un paiement partiellement rembourse
  static Payment createPartiallyRefunded({
    String? id,
    double amount = 25.0,
    double refundedAmount = 10.0,
  }) {
    return Payment(
      id: id ?? 'payment-partial-123',
      userId: 'user-123',
      reservationId: 'reservation-123',
      amount: amount,
      refundedAmount: refundedAmount,
      status: PaymentStatus.partiallyRefunded,
      methodType: PaymentMethodType.card,
      createdAt: _now,
      paidAt: _now,
      refundedAt: _now.add(const Duration(hours: 1)),
    );
  }

  /// Cree une liste de paiements
  static List<Payment> createList(int count) {
    return List.generate(
      count,
      (index) => createSucceeded(
        id: 'payment-$index',
        amount: 20.0 + index * 5,
      ),
    );
  }

  /// Cree une liste mixte de paiements (succeeded, failed, refunded)
  static List<Payment> createMixedList() {
    return [
      createSucceeded(id: 'payment-1', amount: 25.0),
      createSucceeded(id: 'payment-2', amount: 30.0),
      createFailed(id: 'payment-3'),
      createRefunded(id: 'payment-4', amount: 20.0),
      createPending(id: 'payment-5'),
    ];
  }

  /// Cree une methode de paiement
  static PaymentMethod createPaymentMethod({
    String? id,
    String? userId,
    CardBrand brand = CardBrand.visa,
    String last4 = '4242',
    int expMonth = 12,
    int expYear = 2026,
    bool isDefault = false,
  }) {
    return PaymentMethod(
      id: id ?? 'pm-123',
      userId: userId ?? 'user-123',
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      isDefault: isDefault,
      createdAt: _now,
      stripePaymentMethodId: 'stripe_pm_$id',
    );
  }

  /// Cree une liste de methodes de paiement
  static List<PaymentMethod> createPaymentMethodList(int count,
      {bool withDefault = true}) {
    return List.generate(
      count,
      (index) => createPaymentMethod(
        id: 'pm-$index',
        brand: index.isEven ? CardBrand.visa : CardBrand.mastercard,
        last4: '${4242 + index}',
        isDefault: withDefault && index == 0,
      ),
    );
  }

  /// Cree un remboursement
  static Refund createRefund({
    String? id,
    String? paymentId,
    String? reservationId,
    double? amount,
    RefundStatus status = RefundStatus.succeeded,
    RefundReason reason = RefundReason.requestedByCustomer,
  }) {
    return Refund(
      id: id ?? 'refund-123',
      paymentId: paymentId ?? 'payment-123',
      reservationId: reservationId ?? 'reservation-123',
      amount: amount ?? 25.0,
      status: status,
      reason: reason,
      createdAt: _now,
      processedAt: status == RefundStatus.succeeded ? _now : null,
    );
  }

  /// Cree un remboursement en attente
  static Refund createPendingRefund({
    String? id,
    double? amount,
  }) {
    return createRefund(
      id: id,
      amount: amount,
      status: RefundStatus.pending,
    );
  }

  /// Cree un remboursement echoue
  static Refund createFailedRefund({
    String? id,
    String? failureReason,
  }) {
    return Refund(
      id: id ?? 'refund-failed-123',
      paymentId: 'payment-123',
      reservationId: 'reservation-123',
      amount: 25.0,
      status: RefundStatus.failed,
      reason: RefundReason.requestedByCustomer,
      createdAt: _now,
      failureReason: failureReason ?? 'Fonds insuffisants',
    );
  }
}
