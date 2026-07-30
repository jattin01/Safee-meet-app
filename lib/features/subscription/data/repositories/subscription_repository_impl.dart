import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/subscription_checkout_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../remote_data_sources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remote;
  SubscriptionRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans() async {
    try {
      final models = await _remote.getPlans();
      final plans = models.where((m) => m.isActive).map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Right(plans);
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, SubscriptionCheckoutEntity>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  }) async {
    try {
      final data = await _remote.subscribe(
        planSlug: planSlug,
        billingCycle: billingCycle,
        stripePaymentMethodId: stripePaymentMethodId,
      );
      return Right(SubscriptionCheckoutEntity(
        subscriptionId:
            data['subscription_id']?.toString() ?? data['id']?.toString() ?? '',
        status: data['status'] as String? ?? 'incomplete',
        paymentIntentClientSecret: data['payment_intent_client_secret'] as String?,
      ));
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Failure _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    return ServerFailure(
      e.response?.data?['message'] as String? ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
