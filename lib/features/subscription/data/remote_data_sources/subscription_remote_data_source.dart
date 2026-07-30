import '../../../../core/services/api_client.dart';
import '../models/subscription_plan_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<Map<String, dynamic>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient _api;
  SubscriptionRemoteDataSourceImpl(this._api);

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _api.dio.get('/v1/subscriptions/plans');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  }) async {
    final response = await _api.dio.post('/v1/subscriptions/subscribe', data: {
      'plan_slug': planSlug,
      'billing_cycle': billingCycle,
      if (stripePaymentMethodId != null)
        'stripe_payment_method_id': stripePaymentMethodId,
    });
    return response.data as Map<String, dynamic>;
  }
}
