import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.muted,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "404",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Oops! Page not found",
              style: TextStyle(fontSize: 20, color: colors.mutedForeground),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
              child: Text(
                "Return to Home",
                style: TextStyle(
                  fontSize: 16,
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
