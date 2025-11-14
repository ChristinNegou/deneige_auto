// lib/core/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Obtient la position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier la permission
      final permission = await Permission.location.status;

      if (permission.isDenied) {
        final result = await Permission.location.request();
        if (result.isDenied) {
          return null;
        }
      }

      // Vérifier si le GPS est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      print('Erreur géolocalisation: $e');
      return null;
    }
  }

  /// Obtient la position ou retourne la position par défaut
  Future<Position> getPositionOrDefault() async {
    final position = await getCurrentPosition();

    if (position != null) {
      return position;
    }

    // Position par défaut (Trois-Rivières)
    return Position(
      latitude: 46.3432,
      longitude: -72.5476,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}