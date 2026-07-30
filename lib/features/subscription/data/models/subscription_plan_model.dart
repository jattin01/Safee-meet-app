import '../../domain/entities/subscription_plan_entity.dart';

class SubscriptionPlanModel {
  final int id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? trialDays;
  final int? pinSearchLimit;
  final List<String> features;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.trialDays,
    this.pinSearchLimit,
    required this.features,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlanModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        slug: json['slug'] as String,
        monthlyPrice: _toDouble(json['monthly_price']),
        yearlyPrice: _toDouble(json['yearly_price']),
        trialDays: (json['trial_days'] as num?)?.toInt(),
        pinSearchLimit: (json['pin_search_limit'] as num?)?.toInt(),
        features: (json['features'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        icon: json['icon'] as String? ?? 'fa-shield-halved',
        color: json['color'] as String? ?? '#6b7280',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  static double _toDouble(dynamic v) =>
      v is String ? double.parse(v) : (v as num).toDouble();

  SubscriptionPlanEntity toEntity() => SubscriptionPlanEntity(
        id: id,
        name: name,
        slug: slug,
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        trialDays: trialDays,
        pinSearchLimit: pinSearchLimit,
        features: features,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
}
