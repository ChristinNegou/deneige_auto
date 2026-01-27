import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service de géolocalisation GPS.
/// Gère les permissions de localisation et fournit la position de l'appareil.
class LocationService {
  // --- Position courante ---

  /// Obtient la position actuelle de l'appareil.
  /// Vérifie les permissions et l'activation du GPS avant la requête.
  /// Retourne null si les permissions sont refusées ou le GPS désactivé.
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return position;
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
      return null;
    }
  }

  // --- Position avec fallback ---

  /// Obtient la position ou retourne la position par défaut (Trois-Rivières, QC).
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
