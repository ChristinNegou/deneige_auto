import 'package:deneige_auto/core/services/dispute_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException badResponse(Object data) {
  final options = RequestOptions(path: '/disputes/report-no-show/r1');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 400, data: data),
  );
}

void main() {
  test('shows the reason the server gave', () {
    final message = disputeErrorMessage(
      badResponse({
        'success': false,
        'message':
            'Vous pourrez signaler l’absence 30 minutes après l’heure de départ prévue.',
      }),
      'Réessayez',
    );
    expect(message, startsWith('Vous pourrez signaler'));
  });

  test('falls back to the first validation error', () {
    final message = disputeErrorMessage(
      badResponse({
        'errors': [
          {'msg': 'La description doit contenir entre 10 et 2000 caractères'}
        ]
      }),
      'Réessayez',
    );
    expect(message, contains('entre 10 et 2000'));
  });

  test('uses the fallback for anything else', () {
    expect(disputeErrorMessage(Exception('boom'), 'Réessayez'), 'Réessayez');
  });
}
