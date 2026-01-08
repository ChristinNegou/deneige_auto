import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/support_request.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_datasource.dart';
import '../models/support_request_model.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;

  SupportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> submitSupportRequest(
      SupportRequest request) async {
    try {
      final model = SupportRequestModel.fromEntity(request);
      await remoteDataSource.submitSupportRequest(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SupportRequest>>> getMyRequests() async {
    try {
      final requests = await remoteDataSource.getMyRequests();
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
