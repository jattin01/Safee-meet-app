import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../shared/failures/failures.dart';

enum PaymentSheetOutcome { completed, canceled }

/// Wraps Stripe's native Payment Sheet — the actual on-screen checkout UI
/// ("Add your payment information" + a Pay button) that lets a tester see
/// and drive the payment step themselves, instead of it being confirmed
/// silently in the background.
class StripePaymentService {
  Future<Either<Failure, PaymentSheetOutcome>> presentCheckout({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return const Right(PaymentSheetOutcome.completed);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return const Right(PaymentSheetOutcome.canceled);
      }
      debugPrint(
        '[StripePaymentService] StripeException: '
        'code=${e.error.code} message=${e.error.message} '
        'localizedMessage=${e.error.localizedMessage}',
      );
      return Left(ServerFailure(
        e.error.localizedMessage ?? e.error.message ?? 'Payment declined.',
      ));
    } catch (e, st) {
      debugPrint('[StripePaymentService] Unexpected error: $e');
      debugPrintStack(stackTrace: st);
      return Left(UnknownFailure('Payment could not be confirmed: $e'));
    }
  }
}
