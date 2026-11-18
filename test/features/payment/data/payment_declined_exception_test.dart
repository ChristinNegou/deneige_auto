import 'package:deneige_auto/features/payment/data/payment_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the reason Stripe gives the client', () {
    const stripeError = StripeException(
      error: LocalizedErrorMessage(
        code: FailureCode.Failed,
        localizedMessage: 'Votre carte a été refusée.',
        message: 'Your card was declined.',
        declineCode: 'insufficient_funds',
      ),
    );

    final declined = PaymentDeclinedException.fromStripe(stripeError);

    expect(declined.reason, 'Votre carte a été refusée.');
  });

  test('falls back to the raw message without a translation', () {
    const stripeError = StripeException(
      error: LocalizedErrorMessage(
        code: FailureCode.Failed,
        message: 'Your card was declined.',
      ),
    );

    expect(PaymentDeclinedException.fromStripe(stripeError).reason,
        'Your card was declined.');
  });
}
