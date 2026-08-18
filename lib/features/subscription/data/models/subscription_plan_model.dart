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
  final Set<String> featureSlugs;
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
    this.featureSlugs = const {},
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
        features: _parseFeatures(json['features']),
        // Fresh API responses carry slugs inline on each `features[]`
        // object; a value round-tripped through the Hive cache instead
        // carries the separate `feature_slugs` key written by [toJson]
        // below, since by then `features` has already been flattened to
        // plain display strings and no longer has slugs to re-parse.
        featureSlugs: json['feature_slugs'] is List
            ? Set<String>.from(json['feature_slugs'] as List)
            : _parseFeatureSlugs(json['features']),
        icon: json['icon'] as String? ?? 'fa-shield-halved',
        color: json['color'] as String? ?? '#6b7280',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  static double _toDouble(dynamic v) =>
      v is String ? double.parse(v) : (v as num).toDouble();

  /// The API now sends each feature as an object (`{id, slug, name}`)
  /// instead of a plain string, so the label the UI shows lives at
  /// `name`. Plain strings are still accepted for backward compatibility
  /// with any cached/older response shape.
  ///
  /// A `name` can also contain multiple labels glued together with a
  /// line/paragraph separator (seen in the Premium plan's "Priority
  /// Visibility Trusted Contact Alerts") — split those back into
  /// separate feature lines so each renders as its own checkmark item.
  static List<String> _parseFeatures(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list
        .map((e) => e is Map ? (e['name'] as String?) ?? '' : e.toString())
        .expand((name) => name.split(RegExp('[\u2028\u2029\n]')))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Pulls the `slug` out of every feature entry that has one (opaque
  /// objects, `{id, slug, name}`) — the machine-checkable subset of
  /// [_parseFeatures]'s display strings. Older/plain-string entries and
  /// entries with a null slug (free-text perks) are silently skipped since
  /// there's nothing to gate against.
  static Set<String> _parseFeatureSlugs(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) => e['slug'] as String?)
        .whereType<String>()
        .where((slug) => slug.isNotEmpty)
        .toSet();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'monthly_price': monthlyPrice,
        'yearly_price': yearlyPrice,
        'trial_days': trialDays,
        'pin_search_limit': pinSearchLimit,
        'features': features,
        'feature_slugs': featureSlugs.toList(),
        'icon': icon,
        'color': color,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  SubscriptionPlanEntity toEntity() => SubscriptionPlanEntity(
        id: id,
        name: name,
        slug: slug,
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        trialDays: trialDays,
        pinSearchLimit: pinSearchLimit,
        features: features,
        featureSlugs: featureSlugs,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
}
