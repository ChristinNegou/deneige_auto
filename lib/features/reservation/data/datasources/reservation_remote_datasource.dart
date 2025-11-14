
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/vehicle.dart';
import '../models/parking_spot_model.dart';
import '../models/reservation_model.dart';
import '../models/vehicule_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<VehicleModel>> getVehicles();
  Future<List<ParkingSpotModel>> getParkingSpots({bool availableOnly});
  Future<List<ReservationModel>> getReservations({bool? upcoming});
  Future<ReservationModel> createReservation(Map<String, dynamic> data);
  Future<void> cancelReservation(String reservationId);
  Future<Vehicle> addVehicle(Map<String, dynamic> data);


}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final Dio dio;

  ReservationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final response = await dio.get('/vehicles');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['vehicles'] ?? response.data;
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des véhicules',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<List<ParkingSpotModel>> getParkingSpots({bool availableOnly = false}) async {
    try {
      final queryParams = {'available': availableOnly};

      final response = await dio.get(
        '/parking-spots',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['parkingSpots'] ?? response.data;
        return data.map((json) => ParkingSpotModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des places de parking',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<List<ReservationModel>> getReservations({bool? upcoming}) async {
    try {
      final queryParams = upcoming != null ? {'upcoming': upcoming} : null;

      final response = await dio.get(
        '/reservations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['reservations'] ?? response.data;
        return data.map((json) => ReservationModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des réservations',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<ReservationModel> createReservation(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/reservations', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ReservationModel.fromJson(response.data['reservation'] ?? response.data);
      } else {
        throw ServerException(
          message: 'Erreur de création de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<Vehicle> addVehicle(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '/vehicles',
        data: data,
      );

      if (response.statusCode == 201) {
        // Convertir la réponse en VehicleModel
        return VehicleModel.fromJson(response.data['vehicle']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de l\'ajout du véhicule',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }



  @override
  Future<void> cancelReservation(String reservationId) async {
    try {
      final response = await dio.delete('/reservations/$reservationId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Erreur d\'annulation de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }
}