import 'package:dio/dio.dart';
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
        final message = response.data['message'] ?? 'Failed to submit request';
        throw Exception(message);
      }
    } on DioException catch (e) {
      throw Exception('Error submitting request: ${e.message}');
    } catch (e) {
      throw Exception('Error submitting request: $e');
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
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }
}
