import 'package:equatable/equatable.dart';

enum ComparisonFeatureType { boolean, limit }

class ComparisonPlanEntity extends Equatable {
  final int id;
  final String slug;
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? trialDays;

  const ComparisonPlanEntity({
    required this.id,
    required this.slug,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.trialDays,
  });

  @override
  List<Object?> get props =>
      [id, slug, name, monthlyPrice, yearlyPrice, trialDays];
}

class ComparisonFeatureValueEntity extends Equatable {
  final bool included;
  final String? value;

  const ComparisonFeatureValueEntity({required this.included, this.value});

  @override
  List<Object?> get props => [included, value];
}

class ComparisonFeatureEntity extends Equatable {
  final String slug;
  final String name;
  final ComparisonFeatureType type;

  /// Keyed by plan slug (matches how GET /v1/subscriptions/comparison
  /// shapes each feature's per-plan availability) rather than by index or
  /// plan id, so lookups stay correct regardless of plan ordering.
  final Map<String, ComparisonFeatureValueEntity> valuesByPlanSlug;

  const ComparisonFeatureEntity({
    required this.slug,
    required this.name,
    required this.type,
    required this.valuesByPlanSlug,
  });

  ComparisonFeatureValueEntity? valueForPlan(String planSlug) =>
      valuesByPlanSlug[planSlug];

  @override
  List<Object?> get props => [slug, name, type, valuesByPlanSlug];
}

class ComparisonGroupEntity extends Equatable {
  final String name;
  final List<ComparisonFeatureEntity> features;

  const ComparisonGroupEntity({required this.name, required this.features});

  @override
  List<Object?> get props => [name, features];
}

/// Domain model for GET /v1/subscriptions/comparison. Column order (plans)
/// and row order (groups → features) always follow the API response —
/// nothing here is indexed or named against a hardcoded plan/feature list.
class SubscriptionComparisonEntity extends Equatable {
  final List<ComparisonPlanEntity> plans;
  final List<ComparisonGroupEntity> groups;

  const SubscriptionComparisonEntity({
    required this.plans,
    required this.groups,
  });

  bool get isEmpty =>
      groups.isEmpty || groups.every((g) => g.features.isEmpty);

  @override
  List<Object?> get props => [plans, groups];
}
