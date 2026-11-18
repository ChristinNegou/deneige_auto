import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/data/models/reservation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> json(List<String> options) => {
        '_id': 'r1',
        'userId': 'u1',
        'vehicle': {
          '_id': 'v1',
          'userId': 'u1',
          'make': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'color': 'Gris',
          'licensePlate': 'ABC123',
          'type': 'car',
        },
        'parkingSpotNumber': 'P1',
        'departureTime': '2026-11-20T12:00:00.000Z',
        'status': 'pending',
        'serviceOptions': options,
        'basePrice': 15,
        'totalPrice': 20,
      };

  test('reads all eight options instead of turning them into scraping', () {
    final model = ReservationModel.fromJson(json([
      'roofClearing',
      'salt_spreading',
      'lightsCleaning',
      'perimeterClearance',
      'exhaustCheck',
    ]));

    expect(model.serviceOptions, [
      ServiceOption.roofClearing,
      ServiceOption.saltSpreading,
      ServiceOption.lightsCleaning,
      ServiceOption.perimeterClearance,
      ServiceOption.exhaustCheck,
    ]);
  });

  test('ignores an unknown option', () {
    final model = ReservationModel.fromJson(json(['doorDeicing', 'carWash']));

    expect(model.serviceOptions, [ServiceOption.doorDeicing]);
  });
}
