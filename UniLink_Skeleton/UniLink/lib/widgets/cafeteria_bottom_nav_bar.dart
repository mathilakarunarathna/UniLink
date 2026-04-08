import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CafeteriaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CafeteriaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1111), // Match cafeteria theme
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: LucideIcons.home,
                activeIcon: LucideIcons.home,
                label: "Home",
              ),
              _buildNavItem(
                index: 1,
                icon: LucideIcons.list,
                activeIcon: LucideIcons.list,
                label: "Menu Mgmt",
              ),
              _buildNavItem(
                index: 2,
                icon: LucideIcons.user,
                activeIcon: LucideIcons.userCheck,
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;
    const primaryColor = Colors.orangeAccent;
    final inactiveColor = Colors.white.withAlpha(128);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20.0 : 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? primaryColor : inactiveColor,
                size: 24,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 1.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
