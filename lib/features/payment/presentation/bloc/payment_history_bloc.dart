import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';

// Events
abstract class PaymentHistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentHistoryEvent {}

class RefreshPaymentHistory extends PaymentHistoryEvent {}

class FilterPaymentsByStatus extends PaymentHistoryEvent {
  final PaymentStatus? status;

  FilterPaymentsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

// States
class PaymentHistoryState extends Equatable {
  final List<Payment> payments;
  final List<Payment> filteredPayments;
  final bool isLoading;
  final String? errorMessage;
  final PaymentStatus? currentFilter;

  const PaymentHistoryState({
    this.payments = const [],
    this.filteredPayments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentFilter,
  });

  // Getters for statistics
  double get totalSpent => payments
      .where((p) => p.status == PaymentStatus.succeeded)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get totalRefunded => payments
      .where((p) => p.status == PaymentStatus.refunded ||
                   p.status == PaymentStatus.partiallyRefunded)
      .fold(0.0, (sum, p) => sum + (p.refundedAmount ?? 0.0));

  int get transactionCount => payments
      .where((p) => p.status == PaymentStatus.succeeded)
      .length;

  double get averagePerTransaction =>
      transactionCount > 0 ? totalSpent / transactionCount : 0.0;

  PaymentHistoryState copyWith({
    List<Payment>? payments,
    List<Payment>? filteredPayments,
    bool? isLoading,
    String? errorMessage,
    PaymentStatus? currentFilter,
    bool clearError = false,
  }) {
    return PaymentHistoryState(
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  @override
  List<Object?> get props => [
    payments,
    filteredPayments,
    isLoading,
    errorMessage,
    currentFilter,
  ];
}

// BLoC
class PaymentHistoryBloc extends Bloc<PaymentHistoryEvent, PaymentHistoryState> {
  final GetPaymentHistoryUseCase getPaymentHistory;

  PaymentHistoryBloc({
    required this.getPaymentHistory,
  }) : super(const PaymentHistoryState()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RefreshPaymentHistory>(_onRefreshPaymentHistory);
    on<FilterPaymentsByStatus>(_onFilterPaymentsByStatus);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await getPaymentHistory();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (payments) {
        // Sort by date (newest first)
        final sortedPayments = List<Payment>.from(payments)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(state.copyWith(
          isLoading: false,
          payments: sortedPayments,
          filteredPayments: sortedPayments,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onRefreshPaymentHistory(
    RefreshPaymentHistory event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    // Similar to load, but without showing loading initially
    final result = await getPaymentHistory();

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (payments) {
        final sortedPayments = List<Payment>.from(payments)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Reapply current filter
        final filtered = state.currentFilter != null
            ? sortedPayments.where((p) => p.status == state.currentFilter).toList()
            : sortedPayments;

        emit(state.copyWith(
          payments: sortedPayments,
          filteredPayments: filtered,
          clearError: true,
        ));
      },
    );
  }

  void _onFilterPaymentsByStatus(
    FilterPaymentsByStatus event,
    Emitter<PaymentHistoryState> emit,
  ) {
    if (event.status == null) {
      // Show all
      emit(state.copyWith(
        filteredPayments: state.payments,
        currentFilter: null,
      ));
    } else {
      // Filter by status
      final filtered = state.payments
          .where((p) => p.status == event.status)
          .toList();

      emit(state.copyWith(
        filteredPayments: filtered,
        currentFilter: event.status,
      ));
    }
  }
}
