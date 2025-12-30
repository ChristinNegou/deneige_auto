import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String reservationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        reservationId,
        limit: limit,
        before: before,
      );
      return Right(messages);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String reservationId,
    String content, {
    String messageType = 'text',
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        reservationId,
        content,
        messageType: messageType,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(message);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String reservationId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(reservationId);
      return Right(count);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String reservationId) async {
    try {
      await remoteDataSource.markAsRead(reservationId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }
}
