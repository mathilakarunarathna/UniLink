import 'package:flutter/material.dart';

class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color destructive;
  final Color error;

  final Color campusTeal;
  final Color campusIndigo;
  final Color campusCoral;
  final Color campusAmber;
  final Color campusEmerald;
  final Color campusRose;
  final Color campusSky;
  final Color campusViolet;

  const AppCustomColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.campusTeal,
    required this.campusIndigo,
    required this.campusCoral,
    required this.campusAmber,
    required this.campusEmerald,
    required this.campusRose,
    required this.campusSky,
    required this.campusViolet,
    required this.destructive,
    required this.error,
  });

  @override
  ThemeExtension<AppCustomColors> copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? campusTeal,
    Color? campusIndigo,
    Color? campusCoral,
    Color? campusAmber,
    Color? campusEmerald,
    Color? campusRose,
    Color? campusSky,
    Color? campusViolet,
    Color? destructive,
    Color? error,
  }) {
    return AppCustomColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      campusTeal: campusTeal ?? this.campusTeal,
      campusIndigo: campusIndigo ?? this.campusIndigo,
      campusCoral: campusCoral ?? this.campusCoral,
      campusAmber: campusAmber ?? this.campusAmber,
      campusEmerald: campusEmerald ?? this.campusEmerald,
      campusRose: campusRose ?? this.campusRose,
      campusSky: campusSky ?? this.campusSky,
      campusViolet: campusViolet ?? this.campusViolet,
      destructive: destructive ?? this.destructive,
      error: error ?? this.error,
    );
  }

  @override
  ThemeExtension<AppCustomColors> lerp(
    ThemeExtension<AppCustomColors>? other,
    double t,
  ) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(
        primaryForeground,
        other.primaryForeground,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(
        secondaryForeground,
        other.secondaryForeground,
        t,
      )!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      campusTeal: Color.lerp(campusTeal, other.campusTeal, t)!,
      campusIndigo: Color.lerp(campusIndigo, other.campusIndigo, t)!,
      campusCoral: Color.lerp(campusCoral, other.campusCoral, t)!,
      campusAmber: Color.lerp(campusAmber, other.campusAmber, t)!,
      campusEmerald: Color.lerp(campusEmerald, other.campusEmerald, t)!,
      campusRose: Color.lerp(campusRose, other.campusRose, t)!,
      campusSky: Color.lerp(campusSky, other.campusSky, t)!,
      campusViolet: Color.lerp(campusViolet, other.campusViolet, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }

  static const light = AppCustomColors(
    background: Color(0xFFF5F7FC),
    foreground: Color(0xFF1B1F35),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF1B1F35),
    primary: Color(0xFF7A4BFF),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF4F8CFF),
    secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFFEEF2FA),
    mutedForeground: Color(0xFF667196),
    accent: Color(0xFF18BFA6),
    accentForeground: Color(0xFFFFFFFF),
    border: Color(0xFFDCE3F2),
    input: Color(0xFFDCE3F2),
    ring: Color(0xFF7A4BFF),
    campusTeal: Color(0xFF1BBEAA),
    campusIndigo: Color(0xFF5F3CFF),
    campusCoral: Color(0xFFFF6D91),
    campusAmber: Color(0xFFF59E43),
    campusEmerald: Color(0xFF2EB875),
    campusRose: Color.fromARGB(255, 255, 2, 2),
    campusSky: Color(0xFF0EA5E9),
    campusViolet: Color(0xFF8B5CF6),
    destructive: Color(0xFFEF4444),
    error: Color(0xFFEF4444),
  );

  static const dark = AppCustomColors(
    background: Color(0xFF090A12),
    foreground: Color(0xFFF2F3FA),
    card: Color(0xFF131626),
    cardForeground: Color(0xFFF2F3FA),
    primary: Color(0xFFB89BFF),
    primaryForeground: Color(0xFF0D0F1A),
    secondary: Color(0xFF8FD3FF),
    secondaryForeground: Color(0xFF0D0F1A),
    muted: Color(0xFF1A1E31),
    mutedForeground: Color(0xFFC2C9E4),
    accent: Color(0xFF9EE8DE),
    accentForeground: Color(0xFF08211D),
    border: Color(0xFF2A3050),
    input: Color(0xFF2A3050),
    ring: Color(0xFFC2AEFF),
    campusTeal: Color(0xFF7CE3D5),
    campusIndigo: Color(0xFF9A85FF),
    campusCoral: Color(0xFFFFA7B8),
    campusAmber: Color(0xFFFFC781),
    campusEmerald: Color(0xFF89E8B2),
    campusRose: Color(0xFFFF98C8),
    campusSky: Color(0xFF8DC6FF),
    campusViolet: Color(0xFFCBB7FF),
    destructive: Color(0xFFF87171),
    error: Color(0xFFF87171),
  );
}

class AppColors {
  // Helper to access custom colors via context
  static AppCustomColors of(BuildContext context) =>
      Theme.of(context).extension<AppCustomColors>() ?? AppCustomColors.light;

  // Standard material mappings (mostly for migration shim)
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color foreground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color card(BuildContext context) => Theme.of(context).cardColor;

  // Custom colors exposed for convenience
  static Color primary(BuildContext context) => of(context).primary;
  static Color primaryForeground(BuildContext context) =>
      of(context).primaryForeground;
  static Color secondary(BuildContext context) => of(context).secondary;
  static Color secondaryForeground(BuildContext context) =>
      of(context).secondaryForeground;
  static Color muted(BuildContext context) => of(context).muted;
  static Color mutedForeground(BuildContext context) =>
      of(context).mutedForeground;
  static Color accent(BuildContext context) => of(context).accent;
  static Color accentForeground(BuildContext context) =>
      of(context).accentForeground;
  static Color border(BuildContext context) => of(context).border;
  static Color ring(BuildContext context) => of(context).ring;

  static Color campusTeal(BuildContext context) => of(context).campusTeal;
  static Color campusIndigo(BuildContext context) => of(context).campusIndigo;
  static Color campusCoral(BuildContext context) => of(context).campusCoral;
  static Color campusAmber(BuildContext context) => of(context).campusAmber;
  static Color campusEmerald(BuildContext context) => of(context).campusEmerald;
  static Color campusRose(BuildContext context) => of(context).campusRose;
  static Color campusSky(BuildContext context) => of(context).campusSky;
  static Color campusViolet(BuildContext context) => of(context).campusViolet;
  static Color destructive(BuildContext context) => of(context).destructive;
  static Color error(BuildContext context) => of(context).error;

  // Gradients
  static LinearGradient gradientPrimary(BuildContext context) {
    final colors = of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.campusViolet, colors.campusIndigo],
    );
  }

  static LinearGradient gradientHero(BuildContext context) {
    final colors = of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.campusIndigo, colors.campusSky],
    );
  }

  static LinearGradient gradientWarm(BuildContext context) {
    final colors = of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.campusCoral, colors.campusAmber],
    );
  }

  static LinearGradient gradientCard(BuildContext context) {
    final colors = of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.card, colors.muted.withValues(alpha: 0.85)],
    );
  }
}
