import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/ai_chat_remote_datasource.dart';

/// Implémentation du repository pour le chat IA
class AIChatRepositoryImpl implements AIChatRepository {
  final AIChatRemoteDataSource remoteDataSource;

  AIChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AIChatStatus>> getStatus() async {
    try {
      final status = await remoteDataSource.getStatus();
      return Right(status);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AIConversation>>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final conversations = await remoteDataSource.getConversations(
        page: page,
        limit: limit,
      );
      return Right(conversations);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AIConversation>> createConversation({
    String? reservationId,
    String? vehicleId,
  }) async {
    try {
      final conversation = await remoteDataSource.createConversation(
        reservationId: reservationId,
        vehicleId: vehicleId,
      );
      return Right(conversation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AIConversation>> getConversation(
    String conversationId,
  ) async {
    try {
      final conversation =
          await remoteDataSource.getConversation(conversationId);
      return Right(conversation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AIChatMessage>> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final message =
          await remoteDataSource.sendMessage(conversationId, content);
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
  Stream<Either<Failure, String>> sendMessageStreaming(
    String conversationId,
    String content,
  ) {
    // TODO: Implémenter le streaming SSE si nécessaire
    // Pour l'instant, on utilise la méthode non-streaming
    throw UnimplementedError('Streaming non implémenté');
  }

  @override
  Future<Either<Failure, void>> deleteConversation(
      String conversationId) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
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
  Future<Either<Failure, List<AIChatMessage>>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        conversationId,
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
}
