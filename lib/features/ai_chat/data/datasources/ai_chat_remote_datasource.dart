import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/ai_chat_message_model.dart';
import '../../domain/repositories/ai_chat_repository.dart';

/// Interface du datasource distant pour le chat IA
abstract class AIChatRemoteDataSource {
  /// Récupère le statut du service IA
  Future<AIChatStatus> getStatus();

  /// Récupère les conversations
  Future<List<AIConversationModel>> getConversations({
    int page = 1,
    int limit = 20,
  });

  /// Crée une nouvelle conversation
  Future<AIConversationModel> createConversation({
    String? reservationId,
    String? vehicleId,
  });

  /// Récupère une conversation
  Future<AIConversationModel> getConversation(String conversationId);

  /// Envoie un message
  Future<AIChatMessageModel> sendMessage(String conversationId, String content);

  /// Archive une conversation
  Future<void> deleteConversation(String conversationId);

  /// Récupère les messages d'une conversation
  Future<List<AIChatMessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  });
}

/// Implémentation du datasource distant
class AIChatRemoteDataSourceImpl implements AIChatRemoteDataSource {
  final Dio dio;

  AIChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<AIChatStatus> getStatus() async {
    try {
      final response = await dio.get('/ai-chat/status');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        final quickActionsJson = data['quickActions'] as List<dynamic>? ?? [];
        final quickActions = quickActionsJson
            .map((a) => AIQuickActionModel.fromJson(a as Map<String, dynamic>))
            .toList();

        return AIChatStatus(
          enabled: data['enabled'] as bool? ?? false,
          configured: data['configured'] as bool? ?? false,
          quickActions: quickActions,
        );
      }

      throw ServerException(
        message: response.data['message'] ??
            'Erreur lors de la récupération du statut',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AIConversationModel>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/ai-chat/conversations',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final conversationsJson =
            response.data['conversations'] as List<dynamic>? ?? [];
        return conversationsJson
            .map((c) => AIConversationModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(
        message: response.data['message'] ??
            'Erreur lors de la récupération des conversations',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AIConversationModel> createConversation({
    String? reservationId,
    String? vehicleId,
  }) async {
    try {
      final response = await dio.post(
        '/ai-chat/conversations',
        data: {
          'context': {
            if (reservationId != null) 'reservationId': reservationId,
            if (vehicleId != null) 'vehicleId': vehicleId,
          },
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return AIConversationModel.fromJson(
          response.data['conversation'] as Map<String, dynamic>,
        );
      }

      throw ServerException(
        message: response.data['message'] ??
            'Erreur lors de la création de la conversation',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AIConversationModel> getConversation(String conversationId) async {
    try {
      final response = await dio.get('/ai-chat/conversations/$conversationId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AIConversationModel.fromJson(
          response.data['conversation'] as Map<String, dynamic>,
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'Conversation non trouvée',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AIChatMessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final response = await dio.post(
        '/ai-chat/conversations/$conversationId/messages',
        data: {'content': content},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AIChatMessageModel.fromJson(
          response.data['message'] as Map<String, dynamic>,
        );
      }

      throw ServerException(
        message:
            response.data['message'] ?? 'Erreur lors de l\'envoi du message',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      final response =
          await dio.delete('/ai-chat/conversations/$conversationId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la suppression',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AIChatMessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await dio.get(
        '/ai-chat/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          if (before != null) 'before': before,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final messagesJson = response.data['messages'] as List<dynamic>? ?? [];
        return messagesJson
            .map((m) => AIChatMessageModel.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(
        message: response.data['message'] ??
            'Erreur lors de la récupération des messages',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convertit une DioException en exception applicative typée (Network/Server).
  /// Gère les cas spécifiques : timeout, 503 (service indisponible), 429 (rate limit).
  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(message: 'Délai de connexion dépassé');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Erreur de connexion au serveur');
    }

    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    if (statusCode == 503) {
      return ServerException(
        message: message ?? 'Service IA temporairement indisponible',
        statusCode: statusCode,
      );
    }

    if (statusCode == 429) {
      return ServerException(
        message: 'Trop de requêtes. Veuillez patienter.',
        statusCode: statusCode,
      );
    }

    return ServerException(
      message: message ?? 'Erreur serveur',
      statusCode: statusCode,
    );
  }
}
