import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/verification_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

/// BLoC de vérification d'identité du déneigeur.
/// Gère le chargement du statut de vérification et la soumission des documents (pièce d'identité, selfie).
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository repository;

  VerificationBloc({required this.repository})
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

    final result = await repository.getVerificationStatus();
    result.fold(
      (failure) => emit(VerificationError(failure.message)),
      (status) => emit(VerificationStatusLoaded(status)),
    );
  }

  /// Soumet les documents de vérification (recto/verso de la pièce d'identité et selfie).
  /// Recharge automatiquement le statut après soumission.
  Future<void> _onSubmitVerification(
    SubmitVerification event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationSubmitting());

    final result = await repository.submitVerification(
      idFront: event.idFront,
      idBack: event.idBack,
      selfie: event.selfie,
    );

    result.fold(
      (failure) => emit(VerificationError(failure.message)),
      (status) {
        emit(const VerificationSubmitted(
          message: 'Documents soumis avec succes. Verification en cours...',
        ));

        // Reload status after a brief delay
        Future.delayed(const Duration(seconds: 1), () {
          add(const LoadVerificationStatus());
        });
      },
    );
  }

  void _onResetState(
    ResetVerificationState event,
    Emitter<VerificationState> emit,
  ) {
    emit(const VerificationInitial());
  }
}
