import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';

// PROTOTYPE MODE: this page renders mock plan data only — there is no
// payment/billing integration. The "Get <Plan>" button is a placeholder
// (pops the page) until real checkout is wired up.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _yearly = false;
  String _selected = 'premium';

  static const _plans = [
    _Plan(
      id: 'free',
      name: 'Free Trial',
      tagline: 'Get started safely',
      icon: Icons.shield_outlined,
      emoji: null,
      color: AppColors.textTertiary,
      iconBg: Color(0xFFF1F5F9),
      monthlyPrice: 0.0,
      yearlyPrice: 0.0,
      features: [
        'Identity Registration',
        'Level 1 Verification',
        'SAFEE PIN Search',
        'Basic Safety Tips',
        'Community Guidelines Access',
        'Limited Meeting History',
      ],
    ),
    _Plan(
      id: 'basic',
      name: 'Basic',
      tagline: 'Essential safety',
      icon: Icons.star_outline,
      emoji: null,
      color: AppColors.blue,
      iconBg: Color(0xFFDCEBFF),
      monthlyPrice: AppConstants.basicMonthlyPrice,
      yearlyPrice: AppConstants.basicYearlyPrice,
      features: [
        'Everything in Free',
        'Verified Badge Display',
        'Unlimited PIN Search',
        'Priority Support',
        'QR Code Generation',
      ],
    ),
    _Plan(
      id: 'premium',
      name: 'Premium',
      tagline: 'Maximum trust & safety',
      icon: Icons.bolt,
      emoji: null,
      color: AppColors.primary,
      iconBg: Color(0xFFFFE1E6),
      monthlyPrice: AppConstants.premiumMonthlyPrice,
      yearlyPrice: AppConstants.premiumYearlyPrice,
      popular: true,
      features: [
        'Everything in Basic',
        'Background Verification',
        'Trust Score Calculation',
        'Safety Score Analytics',
        'Premium Badge',
        'Priority Visibility',
        'Trusted Contact Alerts',
      ],
    ),
    _Plan(
      id: 'professional',
      name: 'Professional',
      tagline: 'For businesses & pros',
      icon: null,
      emoji: '👑',
      color: AppColors.warning,
      iconBg: Color(0xFFFCEFC7),
      monthlyPrice: AppConstants.professionalMonthlyPrice,
      yearlyPrice: AppConstants.professionalYearlyPrice,
      features: [
        'Everything in Premium',
        'Professional Verification',
        'Business Listing',
        'API Access',
        'Dedicated Account Manager',
        'Custom Integrations',
      ],
    ),
  ];

  _Plan get _selectedPlan => _plans.firstWhere((p) => p.id == _selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._plans.map((p) => _PlanCard(
                        plan: p,
                        yearly: _yearly,
                        selected: _selected == p.id,
                        onSelect: () => setState(() => _selected = p.id),
                      )),
                  const SizedBox(height: 12),
                  _FeatureComparison(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _selected == 'free'
                        ? 'Continue with Free'
                        : 'Get ${_selectedPlan.name} — \$${_selectedPlan.price(_yearly).toStringAsFixed(2)}/mo',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Cancel anytime. No hidden fees.',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
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
            'Yearly ',
            style: GoogleFonts.inter(
              color: yearly ? Colors.white : AppColors.textTertiary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '-30%',
            style: GoogleFonts.inter(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String id;
  final String name;
  final String tagline;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final Color iconBg;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool popular;

  const _Plan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.iconBg,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.popular = false,
  });

  double price(bool yearly) => yearly ? yearlyPrice / 12 : monthlyPrice;
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
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
    final visibleFeatures = selected ? plan.features : plan.features.take(3).toList();
    final moreCount = plan.features.length - 3;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? plan.color : AppColors.border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (plan.popular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
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
                        decoration: BoxDecoration(color: plan.iconBg, shape: BoxShape.circle),
                        child: Center(
                          child: plan.icon != null
                              ? Icon(plan.icon, color: plan.color, size: 22)
                              : Text(plan.emoji!, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.name,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(plan.tagline, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.monthlyPrice == 0 ? '\$0' : '\$${plan.price(yearly).toStringAsFixed(2)}',
                            style: GoogleFonts.inter(color: plan.color, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          Text('per month', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...visibleFeatures.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check, color: plan.color, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(f,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      )),
                  if (!selected && moreCount > 0)
                    Text(
                      '+$moreCount more features',
                      style: GoogleFonts.inter(color: plan.color, fontSize: 13, fontWeight: FontWeight.w700),
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

class _FeatureComparison extends StatelessWidget {
  static const _rows = [
    _CompareRow('Verification', ['Level 1', 'Level 1', 'Level 2']),
    _CompareRow('PIN Search', ['5/mo', 'Unlimited', 'Unlimited']),
    _CompareRow('Background Check', [null, null, '✓']),
    _CompareRow('Trust Score', [null, null, '✓']),
    _CompareRow('Live Location', [null, '✓', '✓']),
    _CompareRow('SOS Protection', ['✓', '✓', '✓']),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feature Comparison',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    for (final label in const ['Free', 'Basic', 'Pro'])
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              ..._rows.map((row) => _ComparisonRow(row: row)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareRow {
  final String label;
  final List<String?> values;
  const _CompareRow(this.label, this.values);
}

class _ComparisonRow extends StatelessWidget {
  final _CompareRow row;
  const _ComparisonRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(row.label,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          ...row.values.map((v) => Expanded(
                child: Center(
                  child: v == null
                      ? Container(width: 14, height: 2, color: AppColors.border)
                      : v == '✓'
                          ? Icon(Icons.check, color: AppColors.success, size: 18)
                          : Text(v, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              )),
        ],
      ),
    );
  }
}
