import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatMessageModel>> getMessages(
    String reservationId, {
    int limit = 50,
    String? before,
  });
  Future<ChatMessageModel> sendMessage(
    String reservationId,
    String content, {
    String messageType = 'text',
    String? imageUrl,
    double? latitude,
    double? longitude,
  });
  Future<int> getUnreadCount(String reservationId);
  Future<void> markAsRead(String reservationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ChatMessageModel>> getMessages(
    String reservationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before,
      };

      final response = await dio.get(
        '/messages/$reservationId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['messages'] ?? [];
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des messages',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw ServerException(
          message: 'Accès non autorisé à cette conversation',
          statusCode: 403,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(
    String reservationId,
    String content, {
    String messageType = 'text',
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
        'messageType': messageType,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (latitude != null && longitude != null)
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
      };

      final response = await dio.post(
        '/messages/$reservationId',
        data: data,
      );

      if (response.statusCode == 201) {
        return ChatMessageModel.fromJson(response.data['message']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur d\'envoi du message',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Erreur réseau: ${e.message}';
      throw ServerException(
          message: message, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<int> getUnreadCount(String reservationId) async {
    try {
      final response = await dio.get('/messages/$reservationId/unread');

      if (response.statusCode == 200) {
        return response.data['unreadCount'] as int? ?? 0;
      } else {
        throw ServerException(
          message: 'Erreur de comptage des messages',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<void> markAsRead(String reservationId) async {
    try {
      final response = await dio.patch('/messages/$reservationId/read');

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Erreur de marquage des messages',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }
}
