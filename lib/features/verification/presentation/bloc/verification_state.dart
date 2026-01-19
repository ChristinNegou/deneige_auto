import 'package:equatable/equatable.dart';

import '../../domain/entities/verification_status.dart';

abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {
  const VerificationInitial();
}

class VerificationLoading extends VerificationState {
  const VerificationLoading();
}

class VerificationStatusLoaded extends VerificationState {
  final VerificationStatus status;

  const VerificationStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class VerificationSubmitting extends VerificationState {
  const VerificationSubmitting();
}

class VerificationSubmitted extends VerificationState {
  final String message;

  const VerificationSubmitted({
    this.message = 'Documents soumis avec succès',
  });

  @override
  List<Object?> get props => [message];
}

class VerificationError extends VerificationState {
  final String message;

  const VerificationError(this.message);

  @override
  List<Object?> get props => [message];
}
