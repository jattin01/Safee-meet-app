import '../../domain/entities/subscription_comparison_entity.dart';

class ComparisonPlanModel {
  final int id;
  final String slug;
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? trialDays;

  const ComparisonPlanModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.trialDays,
  });

  factory ComparisonPlanModel.fromJson(Map<String, dynamic> json) =>
      ComparisonPlanModel(
        id: (json['id'] as num).toInt(),
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        monthlyPrice: _toDouble(json['monthly_price']),
        yearlyPrice: _toDouble(json['yearly_price']),
        trialDays: (json['trial_days'] as num?)?.toInt(),
      );

  ComparisonPlanEntity toEntity() => ComparisonPlanEntity(
        id: id,
        slug: slug,
        name: name,
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        trialDays: trialDays,
      );
}

class ComparisonFeatureValueModel {
  final bool included;
  final String? value;

  const ComparisonFeatureValueModel({required this.included, this.value});

  factory ComparisonFeatureValueModel.fromJson(Map<String, dynamic> json) =>
      ComparisonFeatureValueModel(
        included: json['included'] as bool? ?? false,
        value: json['value']?.toString(),
      );

  ComparisonFeatureValueEntity toEntity() =>
      ComparisonFeatureValueEntity(included: included, value: value);
}

class ComparisonFeatureModel {
  final String slug;
  final String name;
  final String type; // "boolean" | "limit"

  /// Keyed by plan slug — the API returns each feature's per-plan
  /// availability as an object (`{"free_trial": {...}, "basic": {...}}`),
  /// not a list.
  final Map<String, ComparisonFeatureValueModel> plans;

  const ComparisonFeatureModel({
    required this.slug,
    required this.name,
    required this.type,
    required this.plans,
  });

  factory ComparisonFeatureModel.fromJson(Map<String, dynamic> json) {
    final plansJson = json['plans'] as Map<String, dynamic>? ?? const {};
    return ComparisonFeatureModel(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'boolean',
      plans: plansJson.map(
        (planSlug, v) => MapEntry(
          planSlug,
          ComparisonFeatureValueModel.fromJson(v as Map<String, dynamic>),
        ),
      ),
    );
  }

  ComparisonFeatureEntity toEntity() => ComparisonFeatureEntity(
        slug: slug,
        name: name,
        type: type == 'limit'
            ? ComparisonFeatureType.limit
            : ComparisonFeatureType.boolean,
        valuesByPlanSlug:
            plans.map((slug, v) => MapEntry(slug, v.toEntity())),
      );
}

class ComparisonGroupModel {
  final String name;
  final List<ComparisonFeatureModel> features;

  const ComparisonGroupModel({required this.name, required this.features});

  factory ComparisonGroupModel.fromJson(Map<String, dynamic> json) =>
      ComparisonGroupModel(
        name: json['name'] as String? ?? '',
        features: (json['features'] as List<dynamic>? ?? [])
            .map((e) => ComparisonFeatureModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ComparisonGroupEntity toEntity() => ComparisonGroupEntity(
        name: name,
        features: features.map((f) => f.toEntity()).toList(),
      );
}

class SubscriptionComparisonModel {
  final List<ComparisonPlanModel> plans;
  final List<ComparisonGroupModel> groups;

  const SubscriptionComparisonModel({
    required this.plans,
    required this.groups,
  });

  factory SubscriptionComparisonModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionComparisonModel(
        plans: (json['plans'] as List<dynamic>? ?? [])
            .map((e) => ComparisonPlanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        groups: (json['groups'] as List<dynamic>? ?? [])
            .map((e) => ComparisonGroupModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  SubscriptionComparisonEntity toEntity() => SubscriptionComparisonEntity(
        plans: plans.map((p) => p.toEntity()).toList(),
        groups: groups.map((g) => g.toEntity()).toList(),
      );
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  return v is String ? double.parse(v) : (v as num).toDouble();
}
