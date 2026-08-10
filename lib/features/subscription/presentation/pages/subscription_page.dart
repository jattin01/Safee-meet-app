import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
import '../cubit/current_subscription_cubit.dart';
import '../cubit/subscription_comparison_cubit.dart';
import '../widgets/feature_comparison_section.dart';
import 'package:safee_meet/core/shared/widgets/app_snackbar.dart';

// Prices, features and plan branding come from GET /v1/subscriptions/plans.
// Checkout (POST /v1/subscriptions/subscribe + Stripe's native Payment
// Sheet) is wired up for Stripe TEST mode only — see
// AppConstants.stripePublishableKey.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<SubscriptionBloc>()..add(const SubscriptionPlansRequested()),
        ),
        BlocProvider(
          create: (_) => sl<SubscriptionComparisonCubit>()..load(),
        ),
        // Top-level route (outside the bottom-nav shell), so the shell's
        // BlocProvider.value for this singleton isn't in scope here —
        // provide it directly instead. `.value` because it must never be
        // closed; `.load()` is a cheap no-op if already loaded/fresh.
        BlocProvider.value(value: sl<CurrentSubscriptionCubit>()..load()),
      ],
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatefulWidget {
  const _SubscriptionView();

  @override
  State<_SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<_SubscriptionView> {
  bool _yearly = false;
  int? _selectedId;
  // Once the user taps a plan card directly, their choice always wins —
  // _ensureSelection must never override it, even after the current-plan
  // lookup below resolves later.
  bool _userSelectedManually = false;

  void _ensureSelection(
    List<SubscriptionPlanEntity> plans,
    CurrentSubscriptionState currentSubscriptionState,
  ) {
    if (plans.isEmpty) return;
    if (_userSelectedManually &&
        _selectedId != null &&
        plans.any((p) => p.id == _selectedId)) {
      return;
    }

    // Don't lock in a default until we know whether the user has an active
    // subscription — otherwise we'd briefly default to "popular" and then
    // jump to the real plan once GET /v1/subscriptions/current resolves.
    if (!currentSubscriptionState.hasLoadedOnce) return;

    SubscriptionPlanEntity? defaultPlan;
    final currentPlanSlug = currentSubscriptionState.subscription?.plan.slug;
    if (currentPlanSlug != null) {
      for (final p in plans) {
        if (p.slug == currentPlanSlug) {
          defaultPlan = p;
          break;
        }
      }
    }
    defaultPlan ??= plans.firstWhere(
      (p) => p.slug == 'premium',
      orElse: () => plans.first,
    );
    _selectedId = defaultPlan.id;
  }

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<SubscriptionBloc>();
    final plansDone = bloc.stream
        .firstWhere((s) => s is SubscriptionLoaded || s is SubscriptionError);
    bloc.add(const SubscriptionPlansRequested());

    return Future.wait([
      plansDone,
      context.read<CurrentSubscriptionCubit>().load(forceRefresh: true),
    ]);
  }

  void _handleSubscribe(BuildContext context, SubscriptionPlanEntity plan) {
    final billingCycle = _yearly ? 'yearly' : 'monthly';

    context.read<SubscriptionBloc>().add(
          SubscribeRequested(
            planSlug: plan.slug,
            billingCycle: billingCycle,
            // Paid plans require some payment method on file before the
            // subscription can be created — the real, visible checkout step
            // (where a tester enters/confirms a card) is Stripe's Payment
            // Sheet, presented next from the bloc once we have the
            // PaymentIntent client secret. TEST mode only.
            stripeTestPaymentMethodId:
                plan.monthlyPrice == 0 ? null : 'pm_card_visa',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      // Also rebuilds when the current-subscription lookup resolves, so
      // _ensureSelection can (re)pick the plan matching the user's actual
      // subscription instead of staying stuck on whatever it defaulted to
      // before that lookup finished.
      body: BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
        builder: (context, subState) =>
            BlocConsumer<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              current is SubscriptionLoaded &&
              (previous is! SubscriptionLoaded ||
                  previous.checkoutStatus != current.checkoutStatus ||
                  previous.checkoutErrorMessage !=
                      current.checkoutErrorMessage),
          listener: (context, state) {
            if (state is! SubscriptionLoaded) return;
            if (state.checkoutStatus == CheckoutStatus.success) {
              AppSnackbar.success(context, 'Subscription activated successfully.');
              context.go(AppRoutes.subscription);
            } else if (state.checkoutErrorMessage != null) {
              AppSnackbar.error(context, state.checkoutErrorMessage!);
              context.go(AppRoutes.subscription);
            }
          },
          builder: (context, state) {
            if (state is SubscriptionLoading || state is SubscriptionInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SubscriptionError) {
              return _SubscriptionErrorState(
                message: state.message,
                onRetry: () => context
                    .read<SubscriptionBloc>()
                    .add(const SubscriptionPlansRequested()),
              );
            }

            final loaded = state as SubscriptionLoaded;
            final plans = loaded.plans;
            _ensureSelection(plans, subState);
            final selectedPlan = plans.firstWhere(
              (p) => p.id == _selectedId,
              orElse: () => plans.first,
            );
            final isProcessing =
                loaded.checkoutStatus == CheckoutStatus.processing;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(context),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarkScreenHeader(
                      title: 'Choose Your Plan',
                      titleFontSize: 21,
                      childGap: 20,
                      child: _PlanToggle(
                        yearly: _yearly,
                        onChanged: (v) => setState(() => _yearly = v),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 24, 20, context.bottomSafePadding(32)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...plans.map((p) => _PlanCard(
                                plan: p,
                                yearly: _yearly,
                                selected: _selectedId == p.id,
                                onSelect: () => setState(() {
                                  _selectedId = p.id;
                                  _userSelectedManually = true;
                                }),
                              )),
                          const SizedBox(height: 8),
                          const FeatureComparisonSection(),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: selectedPlan.monthlyPrice == 0
                                ? 'Continue with Free'
                                : 'Get ${selectedPlan.name} — \$${selectedPlan.price(_yearly).toStringAsFixed(2)}/mo'
                                    '${_yearly ? ' (billed yearly)' : ''}',
                            isLoading: isProcessing,
                            onPressed: isProcessing
                                ? null
                                : () => _handleSubscribe(context, selectedPlan),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Cancel anytime. No hidden fees.',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SubscriptionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SubscriptionErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppColors.textTertiary, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onChanged;

  const _PlanToggle({required this.yearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Monthly',
            style: GoogleFonts.inter(
              color: yearly ? AppColors.textTertiary : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: yearly,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.success,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
            ),
          ),
          Text(
            'Yearly',
            style: GoogleFonts.inter(
              color: yearly ? Colors.white : AppColors.textTertiary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps the backend's FontAwesome slug (e.g. "fa-crown") to a Material icon,
/// since the app doesn't bundle a FontAwesome icon font. `null` means the
/// caller should render [_emojiFor] instead.
IconData? _iconFor(String icon) {
  switch (icon) {
    case 'fa-shield-halved':
      return Icons.shield_outlined;
    case 'fa-star':
      return Icons.star_outline;
    case 'fa-briefcase':
      return Icons.business_center_outlined;
    case 'fa-crown':
      return null;
    default:
      return Icons.shield_outlined;
  }
}

String? _emojiFor(String icon) => icon == 'fa-crown' ? '👑' : null;

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final bool yearly;
  final bool selected;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visibleFeatures =
        selected ? plan.features : plan.features.take(3).toList();
    final moreCount = plan.features.length - 3;
    final color = _colorFromHex(plan.color);
    final icon = _iconFor(plan.icon);
    final emoji = _emojiFor(plan.icon);
    final popular = plan.slug == 'premium';

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (popular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight]),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'MOST POPULAR',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: Center(
                          child: icon != null
                              ? Icon(icon, color: color, size: 22)
                              : Text(emoji ?? '⭐',
                                  style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(plan.name,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (yearly && plan.yearlySavingsPercent > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Save ${plan.yearlySavingsPercent}%',
                                style: GoogleFonts.inter(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          Text(
                            plan.monthlyPrice == 0
                                ? '\$0'
                                : '\$${plan.price(yearly).toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                                color: color,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          Text('per month',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11)),
                          if (yearly && plan.monthlyPrice > 0)
                            Text(
                                'billed \$${plan.yearlyPrice.toStringAsFixed(2)}/yr',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...visibleFeatures.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check, color: color, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(f,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      )),
                  if (!selected && moreCount > 0)
                    Text(
                      '+$moreCount more features',
                      style: GoogleFonts.inter(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
