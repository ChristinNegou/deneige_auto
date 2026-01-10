import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.reservationId,
    required super.amount,
    super.refundedAmount,
    required super.status,
    required super.methodType,
    super.paymentIntentId,
    super.last4,
    super.cardBrand,
    required super.createdAt,
    super.paidAt,
    super.refundedAt,
    super.failureMessage,
    super.receiptUrl,
    super.vehicleMake,
    super.vehicleModel,
    super.parkingSpotNumber,
  });

  /// Create from Reservation data (for payment history)
  factory PaymentModel.fromReservation(Map<String, dynamic> json) {
    // Déterminer le statut de paiement
    // Si paymentIntentId existe mais paymentStatus n'est pas 'paid',
    // on considère que le paiement a réussi
    final paymentIntentId = json['paymentIntentId'];
    final hasPaymentIntent = paymentIntentId != null &&
        paymentIntentId.toString().isNotEmpty &&
        paymentIntentId.toString() != 'null';

    PaymentStatus status;
    if (hasPaymentIntent && json['paymentStatus'] == 'pending') {
      // Paiement effectué mais status mal enregistré
      status = PaymentStatus.succeeded;
    } else {
      status = _parsePaymentStatus(json['paymentStatus']);
    }

    return PaymentModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      reservationId: json['_id'] ?? json['id'],
      amount: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      refundedAmount: json['refundedAmount'] != null
          ? (json['refundedAmount'] as num).toDouble()
          : null,
      status: status,
      methodType: _parsePaymentMethodType(json['paymentMethod']),
      paymentIntentId: paymentIntentId?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
      // Extract vehicle and parking info
      vehicleMake: json['vehicle']?['make'],
      vehicleModel: json['vehicle']?['model'],
      parkingSpotNumber: json['parkingSpot']?['spotNumber'] ??
          json['parkingSpotNumber'] ??
          json['customLocation'],
    );
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethodType _parsePaymentMethodType(String? method) {
    switch (method?.toLowerCase()) {
      case 'card':
        return PaymentMethodType.card;
      case 'cash':
        return PaymentMethodType.cash;
      case 'subscription':
        return PaymentMethodType.subscription;
      default:
        return PaymentMethodType.card;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reservationId': reservationId,
      'amount': amount,
      'refundedAmount': refundedAmount,
      'status': status.name,
      'methodType': methodType.name,
      'paymentIntentId': paymentIntentId,
      'last4': last4,
      'cardBrand': cardBrand,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'parkingSpotNumber': parkingSpotNumber,
    };
  }
}
