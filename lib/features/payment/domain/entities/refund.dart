import 'package:equatable/equatable.dart';

enum RefundStatus {
  pending,
  processing,
  succeeded,
  failed,
  canceled,
}

enum RefundReason {
  requestedByCustomer,
  duplicate,
  fraudulent,
  serviceCanceled,
  other,
}

class Refund extends Equatable {
  final String id;
  final String paymentId;
  final String reservationId;
  final double amount;
  final RefundStatus status;
  final RefundReason reason;
  final String? reasonNote;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;
  final String? stripeRefundId;

  const Refund({
    required this.id,
    required this.paymentId,
    required this.reservationId,
    required this.amount,
    required this.status,
    required this.reason,
    this.reasonNote,
    required this.createdAt,
    this.processedAt,
    this.failureReason,
    this.stripeRefundId,
  });

  bool get isProcessing {
    return status == RefundStatus.pending ||
           status == RefundStatus.processing;
  }

  bool get isCompleted {
    return status == RefundStatus.succeeded;
  }

  Refund copyWith({
    String? id,
    String? paymentId,
    String? reservationId,
    double? amount,
    RefundStatus? status,
    RefundReason? reason,
    String? reasonNote,
    DateTime? createdAt,
    DateTime? processedAt,
    String? failureReason,
    String? stripeRefundId,
  }) {
    return Refund(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      reservationId: reservationId ?? this.reservationId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      stripeRefundId: stripeRefundId ?? this.stripeRefundId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    paymentId,
    reservationId,
    amount,
    status,
    reason,
    reasonNote,
    createdAt,
    processedAt,
    failureReason,
    stripeRefundId,
  ];
}
