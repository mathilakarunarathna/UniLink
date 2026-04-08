import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class ProPageTransitionsBuilder extends PageTransitionsBuilder {
  const ProPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static TextTheme _premiumTextTheme(TextTheme base, Color foreground) {
    return GoogleFonts.plusJakartaSansTextTheme(base)
        .copyWith(
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(
          bodyColor: foreground,
          displayColor: foreground,
        );
  }

  static ThemeData get lightTheme {
    final c = AppCustomColors.light;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        onPrimary: c.primaryForeground,
        secondary: c.secondary,
        onSecondary: c.secondaryForeground,
        surface: c.card,
        onSurface: c.cardForeground,
        error: const Color(0xFFEF4444), // Standard destructive
        onError: Colors.white,
      ),
      textTheme: _premiumTextTheme(ThemeData.light().textTheme, c.foreground),
      extensions: [c],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ProPageTransitionsBuilder(),
          TargetPlatform.iOS: ProPageTransitionsBuilder(),
          TargetPlatform.windows: ProPageTransitionsBuilder(),
          TargetPlatform.macOS: ProPageTransitionsBuilder(),
          TargetPlatform.linux: ProPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: c.foreground,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x145775A6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        focusColor: c.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.ring, width: 2),
        ),
        hintStyle: TextStyle(
          color: c.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          elevation: 0,
          shadowColor: c.primary.withValues(alpha: 0.28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.campusViolet,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.muted,
        disabledColor: c.muted,
        selectedColor: c.primary.withValues(alpha: 0.12),
        secondarySelectedColor: c.primary.withValues(alpha: 0.12),
        side: BorderSide(color: c.border),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: c.foreground,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        indicatorColor: c.primary.withValues(alpha: 0.18),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.foreground,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.border.withValues(alpha: 0.8),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final c = AppCustomColors.dark;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        onPrimary: c.primaryForeground,
        secondary: c.secondary,
        onSecondary: c.secondaryForeground,
        surface: c.card,
        onSurface: c.cardForeground,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      textTheme: _premiumTextTheme(ThemeData.dark().textTheme, c.foreground),
      extensions: [c],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ProPageTransitionsBuilder(),
          TargetPlatform.iOS: ProPageTransitionsBuilder(),
          TargetPlatform.windows: ProPageTransitionsBuilder(),
          TargetPlatform.macOS: ProPageTransitionsBuilder(),
          TargetPlatform.linux: ProPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: c.foreground,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x145775A6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        focusColor: c.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.ring, width: 2),
        ),
        hintStyle: TextStyle(
          color: c.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          elevation: 0,
          shadowColor: c.primary.withValues(alpha: 0.28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.campusViolet,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.muted,
        disabledColor: c.muted,
        selectedColor: c.primary.withValues(alpha: 0.16),
        secondarySelectedColor: c.primary.withValues(alpha: 0.16),
        side: BorderSide(color: c.border),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: c.foreground,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        indicatorColor: c.primary.withValues(alpha: 0.2),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.foreground,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.border.withValues(alpha: 0.8),
        thickness: 1,
      ),
    );
  }
}
