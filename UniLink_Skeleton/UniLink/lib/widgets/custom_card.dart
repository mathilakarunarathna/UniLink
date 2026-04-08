import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final void Function()? onTap;
  final bool isGradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.onTap,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    final cardWidget = Container(
      decoration: BoxDecoration(
        color: isGradient ? null : colors.card,
        gradient: isGradient ? AppColors.gradientCard(context) : null,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return cardWidget;
  }
}
