import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/current_subscription_entity.dart';
import '../../domain/entities/subscription_checkout_entity.dart';
import '../../domain/entities/subscription_comparison_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../local_data_sources/subscription_local_data_source.dart';
import '../models/current_subscription_model.dart';
import '../remote_data_sources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remote;
  final SubscriptionLocalDataSource _local;
  SubscriptionRepositoryImpl(this._remote, this._local);

  // Simple in-memory cache — the comparison table rarely changes within a
  // session, so avoid re-fetching every time the plans screen is reopened.
  SubscriptionComparisonEntity? _cachedComparison;

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

  @override
  Future<Either<Failure, SubscriptionComparisonEntity>> getComparison({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedComparison != null) {
      return Right(_cachedComparison!);
    }
    try {
      final model = await _remote.getComparison();
      final entity = model.toEntity();
      _cachedComparison = entity;
      return Right(entity);
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, CurrentSubscriptionEntity?>> getCurrentSubscription({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _local.getCachedCurrentSubscription();
      if (cached != null) {
        return Right(
          cached.json == null
              ? null
              : CurrentSubscriptionModel.fromJson(cached.json!).toEntity(),
        );
      }
    }
    try {
      final model = await _remote.getCurrentSubscription();
      await _local.cacheCurrentSubscription(model);
      return Right(model?.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _local.cacheCurrentSubscription(null);
        return const Right(null);
      }
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Failure _mapError(DioException e) => mapDioException(e);
}
