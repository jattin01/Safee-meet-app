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
  final Map<String, int> featureLimits;
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
    this.featureLimits = const {},
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
        featureLimits: json['feature_limits'] is Map
            ? Map<String, int>.from(json['feature_limits'] as Map)
            : _parseFeatureLimits(json['features']),
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

  static Set<String> _parseFeatureSlugs(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    final slugsFromMaps = list
        .whereType<Map>()
        .map((e) => e['slug'] as String?)
        .whereType<String>();

    final slugsFromStrings = list.where((e) => e is String).map((e) {
      final s = (e as String).trim().toLowerCase();
      if (s.contains('verified badge')) return 'verified_badge';
      if (s.contains('premium badge')) return 'premium_badge';
      if (s.contains('qr code')) return 'qr_code';
      if (s.contains('trust score')) return 'trust_score';
      if (s.contains('level 1')) return 'level1_verification';
      if (s.contains('level 2')) return 'level2_clearance';
      if (s.contains('background verification')) return 'background_verification';
      if (s.contains('professional verification')) return 'professional_verification';
      if (s.contains('basic safety')) return 'basic_safety_tips';
      if (s.contains('community guidelines')) return 'community_guidelines';
      if (s.contains('safety score')) return 'safety_score_analytics';
      if (s.contains('priority visibility')) return 'priority_visibility';
      if (s.contains('trusted contact')) return 'trusted_contact_alerts';
      return s.replaceAll(' ', '_');
    });

    return [...slugsFromMaps, ...slugsFromStrings]
        .where((slug) => slug.isNotEmpty)
        .toSet();
  }

  /// Parses features that have `type: "limit"` into a map of slug to limit value.
  static Map<String, int> _parseFeatureLimits(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    final limits = <String, int>{};
    for (final e in list.whereType<Map>()) {
      final slug = e['slug'] as String?;
      final type = e['type'] as String?;
      final valueStr = e['value']?.toString();
      if (slug != null && slug.isNotEmpty && type == 'limit' && valueStr != null) {
        final val = int.tryParse(valueStr);
        if (val != null) limits[slug] = val;
      } else {
        // Fallback for plans (like Free Trial) that send a text-only feature without a slug/type.
        final name = (e['name'] as String?)?.toLowerCase() ?? '';
        if (name.contains('limited meeting history') && !limits.containsKey('meeting_history')) {
          limits['meeting_history'] = 3;
        }
      }
    }
    return limits;
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
        'feature_limits': featureLimits,
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
        featureLimits: featureLimits,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
}
