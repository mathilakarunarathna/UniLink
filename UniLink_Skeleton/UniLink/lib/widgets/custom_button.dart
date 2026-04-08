import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonVariant {
  defaultVariant,
  destructive,
  outline,
  secondary,
  ghost,
  link,
}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonVariant variant;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.defaultVariant,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (variant) {
      case ButtonVariant.destructive:
        final colors = AppColors.of(context);
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.destructive,
            foregroundColor: colors.primaryForeground, // Destructive usually has primaryForeground (white)
          ),
          child: child,
        );
      case ButtonVariant.outline:
        return OutlinedButton(onPressed: onPressed, child: child);
      case ButtonVariant.secondary:
        final colors = AppColors.of(context);
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary,
            foregroundColor: colors.secondaryForeground,
          ),
          child: child,
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.foreground(context)),
          child: child,
        );
      case ButtonVariant.link:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: AppColors.primary(context),
          ),
          child: child,
        );
      case ButtonVariant.defaultVariant:
        return ElevatedButton(onPressed: onPressed, child: child);
    }
  }
}
