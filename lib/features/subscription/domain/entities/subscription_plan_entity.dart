import 'package:equatable/equatable.dart';

class SubscriptionPlanEntity extends Equatable {
  final int id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? trialDays;
  final int? pinSearchLimit;
  final List<String> features;

  /// Machine-checkable feature slugs this plan unlocks (e.g. `qr_code`,
  /// `priority_support`) — the subset of [features] whose API entry had a
  /// non-null `slug`. Free-text perks (like "8 SAFEE PIN Search/Chat") have
  /// no slug and only ever appear in [features] for display; use this set
  /// with [hasFeature] to gate actual app behaviour, never string-match
  /// against [features] display text.
  final Set<String> featureSlugs;

  /// Map of feature slug to its dynamic limit value (e.g. `meeting_history` -> 8).
  /// Only contains features where API returned `type: "limit"` and a numeric `value`.
  final Map<String, int> featureLimits;

  final String icon;
  final String color;
  final int sortOrder;

  const SubscriptionPlanEntity({
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
  });

  bool hasFeature(String featureSlug) => featureSlugs.contains(featureSlug);

  int? getFeatureLimit(String featureSlug) => featureLimits[featureSlug];

  double price(bool yearly) => yearly ? yearlyPrice / 12 : monthlyPrice;

  /// How much cheaper billing yearly is vs. paying monthly for 12 months,
  /// as a whole-number percentage — computed straight from [monthlyPrice]/
  /// [yearlyPrice], never hardcoded. 0 when there's no discount (or the
  /// yearly price isn't actually cheaper).
  int get yearlySavingsPercent {
    if (monthlyPrice <= 0) return 0;
    final annualIfPaidMonthly = monthlyPrice * 12;
    if (annualIfPaidMonthly <= 0) return 0;
    final savings = 1 - (yearlyPrice / annualIfPaidMonthly);
    return savings > 0 ? (savings * 100).round() : 0;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        monthlyPrice,
        yearlyPrice,
        trialDays,
        pinSearchLimit,
        features,
        featureSlugs,
        featureLimits,
        icon,
        color,
        sortOrder,
      ];
}
