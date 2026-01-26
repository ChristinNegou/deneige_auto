import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/verification_status.dart';

abstract class VerificationRepository {
  Future<Either<Failure, VerificationStatus>> getVerificationStatus();
  Future<Either<Failure, VerificationStatus>> submitVerification({
    required File idFront,
    File? idBack,
    required File selfie,
  });
}
