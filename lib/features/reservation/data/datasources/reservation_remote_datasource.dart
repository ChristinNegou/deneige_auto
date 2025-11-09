import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/reservation_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<ReservationModel>> getReservations({bool? upcoming});
  Future<ReservationModel> createReservation(Map<String, dynamic> data);
  Future<void> cancelReservation(String reservationId);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final Dio dio;

  ReservationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ReservationModel>> getReservations({bool? upcoming}) async {
    try {
      final queryParams = upcoming != null ? {'upcoming': upcoming} : null;

      final response = await dio.get(
        '/reservations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReservationModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des réservations',
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      throw NetworkException(message: 'Erreur réseau');
    }
  }

  @override
  Future<ReservationModel> createReservation(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/reservations', data: data);

      if (response.statusCode == 201) {
        return ReservationModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Erreur de création de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      throw NetworkException(message: 'Erreur réseau');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    try {
      final response = await dio.delete('/reservations/$reservationId');

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Erreur d\'annulation de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      throw NetworkException(message: 'Erreur réseau');
    }
  }
}