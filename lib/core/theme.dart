import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const accent = Color(0xFFFD79A8);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDCB6E);
  static const danger = Color(0xFFE17055);

  static const lightBg = Color(0xFFF8F9FD);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF2D3436);
  static const lightMuted = Color(0xFF636E72);

  static const darkBg = Color(0xFF0E0E14);
  static const darkSurface = Color(0xFF1A1A24);
  static const darkText = Color(0xFFF5F5F8);
  static const darkMuted = Color(0xFF9E9EB5);

  static const gradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = lightBg;
  static const surface = lightSurface;
  static const textDark = lightText;
  static const textGrey = lightMuted;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 100.0;
}

abstract final class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> colored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}

extension ShopHubTheme on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => scheme.surface;
  Color get onSurface => scheme.onSurface;

  Color get textMuted => isDark ? AppColors.darkMuted : AppColors.lightMuted;

  List<BoxShadow> get softShadow => isDark ? const [] : AppShadows.soft;
  List<BoxShadow> get mediumShadow => isDark ? const [] : AppShadows.medium;
  List<BoxShadow> coloredShadow(Color color) =>
      isDark ? const [] : AppShadows.colored(color);
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: surface,
        onSurface: text,
      ),
      textTheme: _textTheme(base.textTheme, text, muted),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: _inputTheme(surface, muted),
      elevatedButtonTheme: _buttonTheme,
      navigationBarTheme: _navTheme(surface),
      iconTheme: IconThemeData(color: text),
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color text, Color muted) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.25,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: muted,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: muted),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color surface, Color muted) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: muted, fontSize: 14),
    );
  }

  static final _buttonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  );

  static NavigationBarThemeData _navTheme(Color surface) {
    return NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
