import 'package:deneige_auto/core/services/address_search_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> feature(
        Map<String, dynamic> props, double lon, double lat) =>
    {
      'properties': props,
      'geometry': {
        'coordinates': [lon, lat]
      },
    };

void main() {
  late MockDio dio;
  late AddressSearchService service;

  setUp(() {
    dio = MockDio();
    service = AddressSearchService(dio: dio);
  });

  void respondWith(List<Map<String, dynamic>> features) {
    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/'),
              data: {'features': features},
            ));
  }

  test('builds street and city lines from Photon results', () async {
    respondWith([
      feature({
        'housenumber': '3746',
        'street': 'Boulevard Jean-XXIII',
        'city': 'Trois-Rivières',
        'state': 'Québec',
        'postcode': 'G8Z 3X4',
      }, -72.58, 46.34),
    ]);

    final results = await service.search('3746 boulevard jean');

    expect(results, hasLength(1));
    expect(results.first.primary, '3746 Boulevard Jean-XXIII');
    expect(results.first.secondary, 'Trois-Rivières, Québec G8Z 3X4');
    expect(results.first.fullAddress,
        '3746 Boulevard Jean-XXIII, Trois-Rivières, Québec G8Z 3X4');
    expect(results.first.latitude, 46.34);
    expect(results.first.longitude, -72.58);
  });

  test('drops duplicates and results without a name', () async {
    final street = {'street': 'Rue des Forges', 'city': 'Trois-Rivières'};
    respondWith([
      feature(street, -72.54, 46.34),
      feature(street, -72.55, 46.35),
      feature({'city': 'Trois-Rivières'}, -72.5, 46.3),
    ]);

    final results = await service.search('rue des forges');

    expect(
        results.map((r) => r.fullAddress), ['Rue des Forges, Trois-Rivières']);
  });

  test('biases results toward the given position', () async {
    respondWith([]);

    await service.search('rue', latitude: 46.3, longitude: -72.5);

    final params = verify(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: captureAny(named: 'queryParameters')))
        .captured
        .single as Map<String, dynamic>;
    expect(params['lat'], 46.3);
    expect(params['lon'], -72.5);
    expect(params['lang'], 'fr');
  });
}
