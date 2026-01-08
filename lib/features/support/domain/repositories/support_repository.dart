import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/support_request.dart';

abstract class SupportRepository {
  Future<Either<Failure, void>> submitSupportRequest(SupportRequest request);
  Future<Either<Failure, List<SupportRequest>>> getMyRequests();
}
