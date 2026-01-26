import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/verification_status.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_datasource.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDatasource remoteDatasource;

  VerificationRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, VerificationStatus>> getVerificationStatus() async {
    try {
      final status = await remoteDatasource.getVerificationStatus();
      return Right(status);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerificationStatus>> submitVerification({
    required File idFront,
    File? idBack,
    required File selfie,
  }) async {
    try {
      final status = await remoteDatasource.submitVerification(
        idFront: idFront,
        idBack: idBack,
        selfie: selfie,
      );
      return Right(status);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
