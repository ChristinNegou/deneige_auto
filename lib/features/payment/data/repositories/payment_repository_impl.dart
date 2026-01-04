import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/refund.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Payment>>> getPaymentHistory() async {
    try {
      final payments = await remoteDataSource.getPaymentHistory();
      return Right(payments);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() async {
    try {
      final methods = await remoteDataSource.getPaymentMethods();
      return Right(methods);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> savePaymentMethod({
    required String paymentMethodId,
    bool setAsDefault = false,
  }) async {
    try {
      await remoteDataSource.savePaymentMethod(
        paymentMethodId: paymentMethodId,
        setAsDefault: setAsDefault,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentMethod(
      String paymentMethodId) async {
    try {
      await remoteDataSource.deletePaymentMethod(paymentMethodId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultPaymentMethod(
      String paymentMethodId) async {
    try {
      await remoteDataSource.setDefaultPaymentMethod(paymentMethodId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Refund>> processRefund({
    required String reservationId,
    double? amount,
    required RefundReason reason,
    String? note,
  }) async {
    try {
      final refund = await remoteDataSource.processRefund(
        reservationId: reservationId,
        amount: amount,
        reason: reason,
        note: note,
      );
      return Right(refund);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Refund>> getRefundStatus(String refundId) async {
    try {
      final refund = await remoteDataSource.getRefundStatus(refundId);
      return Right(refund);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }
}
