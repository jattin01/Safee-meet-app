import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_observer.dart';
import '../../../../core/shared/utils/verification_gate.dart';
import '../../../meetings/presentation/bloc/meetings_bloc.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';

const _tabs = [
  _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Search'),
  _TabItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
  _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  _TabItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More'),
];

class AppShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void initState() {
    super.initState();
    sl<MeetingsBloc>();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<CurrentUserCubit>().load(forceRefresh: true);
    context.read<CurrentSubscriptionCubit>().load(forceRefresh: true);
    context.read<MeetingsBloc>().add(const MeetingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    
    return Scaffold(
      extendBody: true, // Allows body to scroll behind the floating nav bar
      resizeToAvoidBottomInset: false, // Prevents FAB and BottomNavBar from jumping up with the keyboard
      body: widget.navigationShell,
      floatingActionButton: const _SosButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _SlidingNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if ((index == 1 || index == 2) && !requireVerification(context)) {
            return;
          }
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
      ),
    );
  }
}

class _SlidingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SlidingNavBar({required this.currentIndex, required this.onTap});

  @override
  State<_SlidingNavBar> createState() => _SlidingNavBarState();
}

class _SlidingNavBarState extends State<_SlidingNavBar> {
  // Mapping index (0..4) to physical positions in the Row.
  double _getIndicatorPosition(int index, double tabWidth) {
    if (index == 0) return 0;
    if (index == 2) return tabWidth;
    if (index == 3) return tabWidth * 2 + 72; // jump over SOS gap
    if (index == 4) return tabWidth * 3 + 72;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = (screenWidth - 72) / 4;

    return Container(
      height: 65 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32), // Matched with top header
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Navigation Items
          Row(
            children: [
              _NavItem(tabWidth: tabWidth, tab: _tabs[0], isActive: widget.currentIndex == 0, onTap: () => widget.onTap(0)),
              _NavItem(tabWidth: tabWidth, tab: _tabs[2], isActive: widget.currentIndex == 2, onTap: () => widget.onTap(2)),
              const SizedBox(width: 72), // SOS gap
              _NavItem(tabWidth: tabWidth, tab: _tabs[3], isActive: widget.currentIndex == 3, onTap: () => widget.onTap(3)),
              _NavItem(tabWidth: tabWidth, tab: _tabs[4], isActive: widget.currentIndex == 4, onTap: () => widget.onTap(4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final double tabWidth;
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tabWidth,
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: isActive ? 1.15 : 1.0,
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tab.label,
              style: TextStyle(
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatefulWidget {
  const _SosButton();

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  late Animation<double> _borderAnim;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower, smoother pulse
    )..repeat(reverse: true);
    _borderAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!requireVerification(context)) return;
        context.push(AppRoutes.sos);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        width: 60,
        height: 60,
        child: AnimatedBuilder(
          animation: _borderController,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF230000), Color(0xFF1A0000)], // Very dark red core
                ),
                border: Border.all(
                  // Pulsing crisp red border
                  color: AppColors.primary.withOpacity(0.5 + (_borderAnim.value * 0.5)),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(_borderAnim.value * 0.3),
                    blurRadius: 12 + (_borderAnim.value * 8),
                    spreadRadius: 1 + (_borderAnim.value * 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

