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
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  double price(bool yearly) => yearly ? yearlyPrice / 12 : monthlyPrice;

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
        icon,
        color,
        sortOrder,
      ];
}
