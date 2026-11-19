import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime tomorrowAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  test('accepte un départ très tôt le matin ou tard le soir', () {
    for (final departure in [
      tomorrowAt(3, 0),
      tomorrowAt(4, 30),
      tomorrowAt(23, 30)
    ]) {
      expect(NewReservationState(departureDateTime: departure).canProceedStep3,
          isTrue,
          reason: 'départ à ${departure.hour}:${departure.minute}');
    }
  });

  test('refuse toujours un départ trop proche', () {
    final soon = DateTime.now().add(const Duration(minutes: 10));
    expect(
        NewReservationState(departureDateTime: soon).canProceedStep3, isFalse);
  });
}
