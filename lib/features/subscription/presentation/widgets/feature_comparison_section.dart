import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../domain/entities/subscription_comparison_entity.dart';
import '../cubit/subscription_comparison_cubit.dart';

/// Renders GET /v1/subscriptions/comparison as a table. Column count (plans),
/// row grouping (groups) and row order (features) all come straight from the
/// API response — nothing here assumes a fixed number/name of plans or
/// features, so new plans/groups/features show up automatically.
class FeatureComparisonSection extends StatelessWidget {
  const FeatureComparisonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionComparisonCubit, SubscriptionComparisonState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Feature Comparison',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildBody(context, state),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SubscriptionComparisonState state) {
    switch (state.status) {
      case ComparisonStatus.initial:
      case ComparisonStatus.loading:
        return const _ComparisonPlaceholder(
          child: Center(child: CircularProgressIndicator()),
        );
      case ComparisonStatus.error:
        return _ComparisonPlaceholder(
          child: _ComparisonError(
            message: state.errorMessage ?? 'Something went wrong.',
            onRetry: () => context
                .read<SubscriptionComparisonCubit>()
                .load(forceRefresh: true),
          ),
        );
      case ComparisonStatus.loaded:
        final comparison = state.comparison!;
        if (comparison.plans.isEmpty || comparison.isEmpty) {
          return const _ComparisonPlaceholder(
            child: Center(
              child: Text(
                'No comparison data available right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          );
        }
        return _ComparisonTable(comparison: comparison);
    }
  }
}

class _ComparisonPlaceholder extends StatelessWidget {
  final Widget child;
  const _ComparisonPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _ComparisonError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ComparisonError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textTertiary, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final SubscriptionComparisonEntity comparison;
  const _ComparisonTable({required this.comparison});

  static const double _labelColumnWidth = 168;
  static const double _planColumnWidth = 90;

  @override
  Widget build(BuildContext context) {
    final plans = comparison.plans;
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(_labelColumnWidth),
      for (var i = 0; i < plans.length; i++)
        i + 1: const FixedColumnWidth(_planColumnWidth),
    };
    final totalWidth = _labelColumnWidth + _planColumnWidth * plans.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(plans: plans, columnWidths: columnWidths),
              for (final (index, group) in comparison.groups.indexed)
                if (group.features.isNotEmpty)
                  _GroupSection(
                    group: group,
                    plans: plans,
                    columnWidths: columnWidths,
                    totalWidth: totalWidth,
                    showLabel: group.name.isNotEmpty,
                    isFirst: index == 0,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<ComparisonPlanEntity> plans;
  final Map<int, TableColumnWidth> columnWidths;
  const _HeaderRow({required this.plans, required this.columnWidths});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Table(
        columnWidths: columnWidths,
        children: [
          TableRow(
            children: [
              const SizedBox(height: 48),
              for (final plan in plans)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    plan.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final ComparisonGroupEntity group;
  final List<ComparisonPlanEntity> plans;
  final Map<int, TableColumnWidth> columnWidths;
  final double totalWidth;
  final bool showLabel;
  final bool isFirst;

  const _GroupSection({
    required this.group,
    required this.plans,
    required this.columnWidths,
    required this.totalWidth,
    required this.showLabel,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabel)
          Padding(
            padding: EdgeInsets.fromLTRB(16, isFirst ? 14 : 18, 16, 8),
            child: Text(
              group.name.toUpperCase(),
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Table(
          columnWidths: columnWidths,
          children: [
            for (final feature in group.features)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      feature.name,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final plan in plans)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: _FeatureCell(feature: feature, plan: plan),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCell extends StatelessWidget {
  final ComparisonFeatureEntity feature;
  final ComparisonPlanEntity plan;
  const _FeatureCell({required this.feature, required this.plan});

  @override
  Widget build(BuildContext context) {
    final value = feature.valueForPlan(plan.slug);
    final included = value?.included ?? false;

    if (feature.type == ComparisonFeatureType.limit) {
      if (included && value?.value != null && value!.value!.isNotEmpty) {
        return Text(
          value.value!,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      return const _Dash();
    }

    return included
        ? const Icon(Icons.check, color: AppColors.success, size: 18)
        : const _Dash();
  }
}

class _Dash extends StatelessWidget {
  const _Dash();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
    );
  }
}
