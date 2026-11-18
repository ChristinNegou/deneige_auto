import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Adresse proposee pendant la saisie, deja geolocalisee.
class AddressSuggestion {
  /// Numero et rue (ou nom du lieu), ex. "3746 Boulevard Jean-XXIII".
  final String primary;

  /// Ville, province et code postal, ex. "Trois-Rivières, Québec G8Z 3X4".
  final String secondary;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.primary,
    required this.secondary,
    required this.latitude,
    required this.longitude,
  });

  String get fullAddress =>
      secondary.isEmpty ? primary : '$primary, $secondary';
}

/// Autocompletion d'adresses via Photon (OpenStreetMap) : gratuit, sans cle.
/// Les resultats sont limites au Quebec et classes par proximite quand la
/// position de l'utilisateur est connue.
class AddressSearchService {
  AddressSearchService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://photon.komoot.io',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {'User-Agent': 'DeneigeAuto/1.0'},
            ));

  final Dio _dio;

  /// Quebec et ses abords (lon min, lat min, lon max, lat max).
  static const _bbox = '-80.0,44.0,-57.0,63.0';

  /// Retourne au plus [limit] adresses ; une liste vide si rien ne correspond.
  /// Leve une exception si le service est injoignable.
  Future<List<AddressSuggestion>> search(
    String query, {
    double? latitude,
    double? longitude,
    String language = 'fr',
    int limit = 6,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/',
      queryParameters: {
        'q': query,
        'limit': limit + 2, // marge pour les doublons retires plus bas
        'lang': language == 'fr' ? 'fr' : 'en',
        'bbox': _bbox,
        if (latitude != null && longitude != null) ...{
          'lat': latitude,
          'lon': longitude,
        },
      },
    );

    final features = (response.data?['features'] as List?) ?? const [];
    final seen = <String>{};
    final results = <AddressSuggestion>[];

    for (final feature in features) {
      try {
        final props = feature['properties'] as Map<String, dynamic>;
        final coords = feature['geometry']['coordinates'] as List;
        final suggestion = _fromProperties(
          props,
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
        );
        if (suggestion != null && seen.add(suggestion.fullAddress)) {
          results.add(suggestion);
        }
      } catch (e) {
        debugPrint('Suggestion d\'adresse ignoree: $e');
      }
      if (results.length >= limit) break;
    }
    return results;
  }

  AddressSuggestion? _fromProperties(
    Map<String, dynamic> p, {
    required double latitude,
    required double longitude,
  }) {
    final number = p['housenumber'] as String?;
    final street = p['street'] as String?;
    final name = p['name'] as String?;
    final city = (p['city'] ?? p['town'] ?? p['village']) as String?;

    final primary =
        street != null ? [if (number != null) number, street].join(' ') : name;
    if (primary == null || primary.isEmpty) return null;

    final region = [p['state'], p['postcode']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    final secondary = [city, region]
        .whereType<String>()
        .where((s) => s.isNotEmpty && s != primary)
        .join(', ');

    return AddressSuggestion(
      primary: primary,
      secondary: secondary,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
