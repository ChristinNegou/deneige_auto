import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadVerificationStatus extends VerificationEvent {
  const LoadVerificationStatus();
}

class SubmitVerification extends VerificationEvent {
  final File idFront;
  final File? idBack;
  final File selfie;

  const SubmitVerification({
    required this.idFront,
    this.idBack,
    required this.selfie,
  });

  @override
  List<Object?> get props => [idFront, idBack, selfie];
}

class ResetVerificationState extends VerificationEvent {
  const ResetVerificationState();
}
