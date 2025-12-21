import '../../domain/entities/refund.dart';

class RefundModel extends Refund {
  const RefundModel({
    required super.id,
    required super.paymentId,
    required super.reservationId,
    required super.amount,
    required super.status,
    required super.reason,
    super.reasonNote,
    required super.createdAt,
    super.processedAt,
    super.failureReason,
    super.stripeRefundId,
  });

  /// Create from Stripe API response
  factory RefundModel.fromStripeJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id'],
      paymentId: json['payment_intent'] ?? '',
      reservationId: json['metadata']?['reservationId'] ?? '',
      amount: (json['amount'] as num).toDouble() / 100, // Convert from cents
      status: _parseRefundStatus(json['status']),
      reason: _parseRefundReason(json['reason']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000),
      stripeRefundId: json['id'],
      failureReason: json['failure_reason'],
    );
  }

  static RefundStatus _parseRefundStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'succeeded':
        return RefundStatus.succeeded;
      case 'pending':
        return RefundStatus.pending;
      case 'failed':
        return RefundStatus.failed;
      case 'canceled':
        return RefundStatus.canceled;
      default:
        return RefundStatus.pending;
    }
  }

  static RefundReason _parseRefundReason(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'requested_by_customer':
        return RefundReason.requestedByCustomer;
      case 'duplicate':
        return RefundReason.duplicate;
      case 'fraudulent':
        return RefundReason.fraudulent;
      default:
        return RefundReason.other;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'reservationId': reservationId,
      'amount': amount,
      'status': status.name,
      'reason': reason.name,
      'reasonNote': reasonNote,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'failureReason': failureReason,
      'stripeRefundId': stripeRefundId,
    };
  }
}
