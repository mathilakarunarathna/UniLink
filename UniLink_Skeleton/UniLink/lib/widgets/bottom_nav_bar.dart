import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  const BottomNavBar({super.key, required this.currentRoute, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark 
                  ? colors.background.withValues(alpha: 0.7) 
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark 
                    ? colors.border.withValues(alpha: 0.15) 
                    : colors.border.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.foreground.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  icon: LucideIcons.home,
                  label: "Home",
                  isActive: currentRoute == '/dashboard',
                  path: '/dashboard',
                  colors: colors,
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.map,
                  label: "UniMap",
                  isActive: currentRoute == '/unimap',
                  path: '/unimap',
                  colors: colors,
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.user,
                  label: "Profile",
                  isActive: currentRoute == '/settings',
                  path: '/settings',
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required String path,
    required AppCustomColors colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (isActive) return;

        if (onNavigate != null) {
          onNavigate!(path);
        } else {
          Navigator.pushReplacementNamed(context, path);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? Colors.white 
                  : colors.mutedForeground.withValues(alpha: 0.8),
              size: isActive ? 20 : 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
