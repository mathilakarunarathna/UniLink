import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search",
          style: TextStyle(
            color: colors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    color: colors.mutedForeground,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search campus services, events, etc.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Icon(
              LucideIcons.search,
              size: 64,
              color: colors.mutedForeground.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "What are you looking for?",
              style: TextStyle(color: colors.mutedForeground, fontSize: 16),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/search'),
    );
  }
}
