import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String reservationId, {
    int limit = 50,
    String? before,
  });

  Future<Either<Failure, ChatMessage>> sendMessage(
    String reservationId,
    String content, {
    String messageType = 'text',
    String? imageUrl,
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, int>> getUnreadCount(String reservationId);

  Future<Either<Failure, void>> markAsRead(String reservationId);
}
