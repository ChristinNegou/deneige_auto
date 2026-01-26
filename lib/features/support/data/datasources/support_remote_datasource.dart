import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/support_request_model.dart';

abstract class SupportRemoteDataSource {
  Future<void> submitSupportRequest(SupportRequestModel request);
  Future<List<SupportRequestModel>> getMyRequests();
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final Dio dio;

  SupportRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> submitSupportRequest(SupportRequestModel request) async {
    try {
      final response = await dio.post(
        '/support/request',
        data: request.toJson(),
      );

      if (response.statusCode != 201 || response.data['success'] != true) {
        final message = response.data['message'] ?? 'Erreur lors de l\'envoi';
        throw ServerException(message: message);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de l\'envoi de la demande de support: $e');
    }
  }

  @override
  Future<List<SupportRequestModel>> getMyRequests() async {
    try {
      final response = await dio.get('/support/my-requests');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> requestsJson = response.data['data'] ?? [];
        return requestsJson
            .map((json) => SupportRequestModel.fromJson(json))
            .toList();
      } else {
        throw const ServerException(
            message: 'Erreur lors du chargement des demandes de support');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des demandes de support: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Delai de connexion depasse. Verifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Impossible de se connecter au serveur.',
        );
      default:
        return ServerException(
          message: message ?? 'Une erreur serveur est survenue.',
          statusCode: statusCode,
        );
    }
  }
}
