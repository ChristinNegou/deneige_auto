import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/usecases/delete_payment_method_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/save_payment_method_usecase.dart';
import '../../domain/usecases/set_default_payment_method_usecase.dart';

// Events
abstract class PaymentMethodsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentMethodsEvent {}

class SavePaymentMethod extends PaymentMethodsEvent {
  final String paymentMethodId;
  final bool setAsDefault;

  SavePaymentMethod(this.paymentMethodId, {this.setAsDefault = false});

  @override
  List<Object?> get props => [paymentMethodId, setAsDefault];
}

class DeletePaymentMethod extends PaymentMethodsEvent {
  final String paymentMethodId;

  DeletePaymentMethod(this.paymentMethodId);

  @override
  List<Object?> get props => [paymentMethodId];
}

class SetDefaultPaymentMethod extends PaymentMethodsEvent {
  final String paymentMethodId;

  SetDefaultPaymentMethod(this.paymentMethodId);

  @override
  List<Object?> get props => [paymentMethodId];
}

// States
class PaymentMethodsState extends Equatable {
  final List<PaymentMethod> methods;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PaymentMethodsState({
    this.methods = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  PaymentMethod? get defaultMethod {
    try {
      return methods.firstWhere((m) => m.isDefault);
    } catch (e) {
      return null;
    }
  }

  PaymentMethodsState copyWith({
    List<PaymentMethod>? methods,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PaymentMethodsState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [methods, isLoading, errorMessage, successMessage];
}

// BLoC
class PaymentMethodsBloc
    extends Bloc<PaymentMethodsEvent, PaymentMethodsState> {
  final GetPaymentMethodsUseCase getPaymentMethods;
  final SavePaymentMethodUseCase savePaymentMethod;
  final DeletePaymentMethodUseCase deletePaymentMethod;
  final SetDefaultPaymentMethodUseCase setDefaultPaymentMethod;

  PaymentMethodsBloc({
    required this.getPaymentMethods,
    required this.savePaymentMethod,
    required this.deletePaymentMethod,
    required this.setDefaultPaymentMethod,
  }) : super(const PaymentMethodsState()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SavePaymentMethod>(_onSavePaymentMethod);
    on<DeletePaymentMethod>(_onDeletePaymentMethod);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await getPaymentMethods();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (methods) => emit(state.copyWith(
        isLoading: false,
        methods: methods,
        clearMessages: true,
      )),
    );
  }

  Future<void> _onSavePaymentMethod(
    SavePaymentMethod event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await savePaymentMethod(
      paymentMethodId: event.paymentMethodId,
      setAsDefault: event.setAsDefault,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (_) async {
        // Reload payment methods
        final reloadResult = await getPaymentMethods();
        reloadResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          )),
          (methods) => emit(state.copyWith(
            isLoading: false,
            methods: methods,
            successMessage: 'Méthode de paiement ajoutée',
          )),
        );
      },
    );
  }

  Future<void> _onDeletePaymentMethod(
    DeletePaymentMethod event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await deletePaymentMethod(event.paymentMethodId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (_) {
        // Remove from list locally
        final updated = state.methods
            .where((m) => m.stripePaymentMethodId != event.paymentMethodId)
            .toList();

        emit(state.copyWith(
          isLoading: false,
          methods: updated,
          successMessage: 'Méthode de paiement supprimée',
        ));
      },
    );
  }

  Future<void> _onSetDefaultPaymentMethod(
    SetDefaultPaymentMethod event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await setDefaultPaymentMethod(event.paymentMethodId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (_) async {
        // Reload payment methods to get updated default
        final reloadResult = await getPaymentMethods();
        reloadResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          )),
          (methods) => emit(state.copyWith(
            isLoading: false,
            methods: methods,
            successMessage: 'Méthode par défaut mise à jour',
          )),
        );
      },
    );
  }
}
