import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    _TabItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    _TabItem(icon: Icons.menu_outlined, activeIcon: Icons.menu, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: _SosButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home, then Chat instead of Search.
            ...[0, 2].map((i) => _NavItem(
              tab: AppShellPage._tabs[i],
              isActive: currentIndex == i,
              onTap: () => onTap(i),
            )),
            // Space for FAB
            const SizedBox(width: 64),
            ...List.generate(2, (i) => _NavItem(
              tab: AppShellPage._tabs[i + 3],
              isActive: currentIndex == i + 3,
              onTap: () => onTap(i + 3),
            )),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.tab, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.sos),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
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
