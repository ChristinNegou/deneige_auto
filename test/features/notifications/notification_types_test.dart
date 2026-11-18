import 'package:deneige_auto/features/notifications/data/models/notification_model.dart';
import 'package:deneige_auto/features/notifications/domain/entities/notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NotificationModel parse(String type, {Map<String, dynamic>? metadata}) =>
      NotificationModel.fromJson({
        '_id': 'n1',
        'userId': 'u1',
        'type': type,
        'title': 'Titre',
        'message': 'Message',
        'createdAt': '2026-11-18T12:00:00.000Z',
        if (metadata != null) 'metadata': metadata,
      });

  test('a dispute notification keeps the dispute to open', () {
    final n = parse('dispute', metadata: {'disputeId': 'd42'});
    expect(n.type, NotificationType.systemNotification);
    expect(n.metadata?['disputeId'], 'd42');
  });

  test('server payment and expiry types map to the app ones', () {
    expect(parse('payment_success').type, NotificationType.paymentSuccess);
    expect(parse('payment_failed').type, NotificationType.paymentFailed);
    expect(
        parse('reservationUpdate').type, NotificationType.reservationCancelled);
  });
}
