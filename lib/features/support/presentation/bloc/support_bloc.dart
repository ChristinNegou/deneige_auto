import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_request.dart';
import '../../domain/usecases/submit_support_request_usecase.dart';

// Events
abstract class SupportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitSupportRequest extends SupportEvent {
  final SupportSubject subject;
  final String message;

  SubmitSupportRequest({
    required this.subject,
    required this.message,
  });

  @override
  List<Object?> get props => [subject, message];
}

class ClearSupportMessages extends SupportEvent {}

class ResetSupportForm extends SupportEvent {}

// States
class SupportState extends Equatable {
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;
  final String? successMessage;

  const SupportState({
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.successMessage,
  });

  SupportState copyWith({
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SupportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isSubmitting,
        isSubmitted,
        errorMessage,
        successMessage,
      ];
}

// BLoC
class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SubmitSupportRequestUseCase submitSupportRequest;

  SupportBloc({
    required this.submitSupportRequest,
  }) : super(const SupportState()) {
    on<SubmitSupportRequest>(_onSubmitSupportRequest);
    on<ClearSupportMessages>(_onClearMessages);
    on<ResetSupportForm>(_onResetForm);
  }

  Future<void> _onSubmitSupportRequest(
    SubmitSupportRequest event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final request = SupportRequest(
      subject: event.subject,
      message: event.message,
    );

    final result = await submitSupportRequest(request);

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        successMessage: 'support_messageSentSuccess',
      )),
    );
  }

  void _onClearMessages(
    ClearSupportMessages event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }

  void _onResetForm(
    ResetSupportForm event,
    Emitter<SupportState> emit,
  ) {
    emit(const SupportState());
  }
}
