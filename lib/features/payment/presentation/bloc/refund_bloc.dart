import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/refund.dart';
import '../../domain/usecases/process_refund_usecase.dart';

// Events
abstract class RefundEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProcessRefund extends RefundEvent {
  final String reservationId;
  final double? amount;
  final RefundReason reason;
  final String? note;

  ProcessRefund({
    required this.reservationId,
    this.amount,
    required this.reason,
    this.note,
  });

  @override
  List<Object?> get props => [reservationId, amount, reason, note];
}

class ResetRefund extends RefundEvent {}

// States
class RefundState extends Equatable {
  final bool isProcessing;
  final Refund? refund;
  final String? errorMessage;
  final String? successMessage;

  const RefundState({
    this.isProcessing = false,
    this.refund,
    this.errorMessage,
    this.successMessage,
  });

  RefundState copyWith({
    bool? isProcessing,
    Refund? refund,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return RefundState(
      isProcessing: isProcessing ?? this.isProcessing,
      refund: refund ?? this.refund,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isProcessing, refund, errorMessage, successMessage];
}

// BLoC
class RefundBloc extends Bloc<RefundEvent, RefundState> {
  final ProcessRefundUseCase processRefund;

  RefundBloc({
    required this.processRefund,
  }) : super(const RefundState()) {
    on<ProcessRefund>(_onProcessRefund);
    on<ResetRefund>(_onResetRefund);
  }

  Future<void> _onProcessRefund(
    ProcessRefund event,
    Emitter<RefundState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, clearMessages: true));

    final result = await processRefund(
      reservationId: event.reservationId,
      amount: event.amount,
      reason: event.reason,
      note: event.note,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isProcessing: false,
        errorMessage: failure.message,
      )),
      (refund) => emit(state.copyWith(
        isProcessing: false,
        refund: refund,
        successMessage: refund.isCompleted
            ? 'Remboursement effectué avec succès'
            : 'Remboursement en cours de traitement',
      )),
    );
  }

  void _onResetRefund(ResetRefund event, Emitter<RefundState> emit) {
    emit(const RefundState());
  }
}
