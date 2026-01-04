import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
  partiallyRefunded,
}

enum PaymentMethodType {
  card,
  cash,
  subscription,
}

class Payment extends Equatable {
  final String id;
  final String userId;
  final String reservationId;
  final double amount;
  final double? refundedAmount;
  final PaymentStatus status;
  final PaymentMethodType methodType;
  final String? paymentIntentId;
  final String? last4;
  final String? cardBrand;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final String? failureMessage;
  final String? receiptUrl;

  // Reservation details (for display in history)
  final String? vehicleMake;
  final String? vehicleModel;
  final String? parkingSpotNumber;

  const Payment({
    required this.id,
    required this.userId,
    required this.reservationId,
    required this.amount,
    this.refundedAmount,
    required this.status,
    required this.methodType,
    this.paymentIntentId,
    this.last4,
    this.cardBrand,
    required this.createdAt,
    this.paidAt,
    this.refundedAt,
    this.failureMessage,
    this.receiptUrl,
    this.vehicleMake,
    this.vehicleModel,
    this.parkingSpotNumber,
  });

  // Business logic methods
  bool get isRefundable {
    return status == PaymentStatus.succeeded &&
        refundedAmount == null &&
        !isExpired;
  }

  bool get isExpired {
    // Can't refund after 30 days
    if (paidAt == null) return false;
    final daysSincePaid = DateTime.now().difference(paidAt!).inDays;
    return daysSincePaid > 30;
  }

  bool get isPartiallyRefunded {
    return status == PaymentStatus.partiallyRefunded ||
        (refundedAmount != null && refundedAmount! < amount);
  }

  double get refundableAmount {
    return amount - (refundedAmount ?? 0.0);
  }

  String get displayDescription {
    final parts = <String>[];
    if (vehicleMake != null && vehicleModel != null) {
      parts.add('$vehicleMake $vehicleModel');
    }
    if (parkingSpotNumber != null) {
      parts.add('Place $parkingSpotNumber');
    }
    return parts.isEmpty ? 'Déneigement' : parts.join(' - ');
  }

  Payment copyWith({
    String? id,
    String? userId,
    String? reservationId,
    double? amount,
    double? refundedAmount,
    PaymentStatus? status,
    PaymentMethodType? methodType,
    String? paymentIntentId,
    String? last4,
    String? cardBrand,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? refundedAt,
    String? failureMessage,
    String? receiptUrl,
    String? vehicleMake,
    String? vehicleModel,
    String? parkingSpotNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reservationId: reservationId ?? this.reservationId,
      amount: amount ?? this.amount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      status: status ?? this.status,
      methodType: methodType ?? this.methodType,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      last4: last4 ?? this.last4,
      cardBrand: cardBrand ?? this.cardBrand,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      refundedAt: refundedAt ?? this.refundedAt,
      failureMessage: failureMessage ?? this.failureMessage,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      parkingSpotNumber: parkingSpotNumber ?? this.parkingSpotNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        reservationId,
        amount,
        refundedAmount,
        status,
        methodType,
        paymentIntentId,
        last4,
        cardBrand,
        createdAt,
        paidAt,
        refundedAt,
        failureMessage,
        receiptUrl,
        vehicleMake,
        vehicleModel,
        parkingSpotNumber,
      ];
}

// Extension for display helpers
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En traitement';
      case PaymentStatus.succeeded:
        return 'Payé';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.canceled:
        return 'Annulé';
      case PaymentStatus.refunded:
        return 'Remboursé';
      case PaymentStatus.partiallyRefunded:
        return 'Remboursement partiel';
    }
  }

  String get icon {
    switch (this) {
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.processing:
        return '🔄';
      case PaymentStatus.succeeded:
        return '✅';
      case PaymentStatus.failed:
        return '❌';
      case PaymentStatus.canceled:
        return '🚫';
      case PaymentStatus.refunded:
        return '↩️';
      case PaymentStatus.partiallyRefunded:
        return '↪️';
    }
  }
}
