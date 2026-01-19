import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/verification_remote_datasource.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRemoteDatasource remoteDatasource;

  VerificationBloc({required this.remoteDatasource})
      : super(const VerificationInitial()) {
    on<LoadVerificationStatus>(_onLoadVerificationStatus);
    on<SubmitVerification>(_onSubmitVerification);
    on<ResetVerificationState>(_onResetState);
  }

  Future<void> _onLoadVerificationStatus(
    LoadVerificationStatus event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());

    try {
      final status = await remoteDatasource.getVerificationStatus();
      emit(VerificationStatusLoaded(status));
    } catch (e) {
      emit(VerificationError(e.toString()));
    }
  }

  Future<void> _onSubmitVerification(
    SubmitVerification event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationSubmitting());

    try {
      await remoteDatasource.submitVerification(
        idFront: event.idFront,
        idBack: event.idBack,
        selfie: event.selfie,
      );

      emit(const VerificationSubmitted(
        message: 'Documents soumis avec succès. Vérification en cours...',
      ));

      // Reload status after a brief delay
      await Future.delayed(const Duration(seconds: 1));
      add(const LoadVerificationStatus());
    } catch (e) {
      emit(VerificationError(e.toString()));
    }
  }

  void _onResetState(
    ResetVerificationState event,
    Emitter<VerificationState> emit,
  ) {
    emit(const VerificationInitial());
  }
}
