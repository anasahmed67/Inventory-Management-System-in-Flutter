import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Currency ───────────────────────────────────────────────────
  static const String currencySymbol = 'Rs.';

  // ── Color Tokens (Light) ───────────────────────────────────────
  static const Color primary = Color(0xFF4D7CFF);
  static const Color primaryLight = Color(0xFFC2D2FF);
  static const Color primaryDark = Color(0xFF2E5EDD);

  static const Color background = Color(0xFFFCFCFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F4FF);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF333333);
  static const Color textHint = Color(0xFF666666);

  static const Color success = Color(0xFF00FFBD);
  static const Color successLight = Color(0xFFD0FFF2);
  static const Color warning = Color(0xFFFAD21B);
  static const Color warningLight = Color(0xFFFFF7D6);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color dangerLight = Color(0xFFFFE5E5);

  static const Color info = Color(0xFF00D1FF);
  static const Color infoLight = Color(0xFFE0FAFF);

  static const Color divider = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // ── Color Tokens (Dark) ────────────────────────────────────────
  static const Color darkBg = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2A);
  static const Color darkSurfaceVariant = Color(0xFF2A2A3C);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFFB0B0C0);
  static const Color darkTextHint = Color(0xFF707088);
  static const Color darkBorder = Color(0xFF3A3A50);
  static const Color darkSidebarBg = Color(0xFF0E0E16);

  // ── Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4D7CFF), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Radii ─────────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 100;

  // ── Spacing ───────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;
  
  static double getResponsivePadding(BuildContext context) {
    return MediaQuery.of(context).size.width < 600 ? spacingMd : spacingLg;
  }

  // ── Sidebar ───────────────────────────────────────────────────
  static const double sidebarWidth = 260;
  static const Color sidebarBg = Color(0xFF000000);
  static const Color sidebarActiveItem = primary;
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarActiveText = Color(0xFF000000);

  // ── Borders ──────────────────────────────────────────────────
  static const double borderWidth = 2.5;

  // ── Animation Durations ───────────────────────────────────────
  static const Duration quickAnim = Duration(milliseconds: 120);
  static const Duration normalAnim = Duration(milliseconds: 300);
  static const Duration slowAnim = Duration(milliseconds: 500);
  static const Curve defaultCurve = Curves.easeOutCubic;

  // ── Box Shadows (Multi-Level) ─────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    const BoxShadow(
      color: Colors.black,
      offset: Offset(2, 2),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    const BoxShadow(
      color: Colors.black,
      offset: Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get softShadow => [
    const BoxShadow(
      color: Colors.black,
      offset: Offset(3, 3),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    const BoxShadow(
      color: Colors.black,
      offset: Offset(6, 6),
      blurRadius: 0,
    ),
  ];

  // ── Dark Mode Shadows ─────────────────────────────────────────
  static List<BoxShadow> get darkCardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      offset: const Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> get darkSoftShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      offset: const Offset(3, 3),
      blurRadius: 0,
    ),
  ];

  // ════════════════════════════════════════════════════════════════
  // Light Theme
  // ════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        brightness: Brightness.light,
      ),

      // Text
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary, fontWeight: FontWeight.w500),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textHint),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: borderWidth),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Colors.black, width: borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Colors.black, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Colors.black, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: borderWidth + 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: borderWidth + 1),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 14),
        prefixIconColor: textPrimary,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: const BorderSide(color: Colors.black, width: borderWidth),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: warning,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Colors.black, width: borderWidth),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Colors.black,
        thickness: borderWidth,
        space: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Colors.black, width: borderWidth),
        ),
        backgroundColor: surface,
        elevation: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: primary, width: borderWidth),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Dark Theme
  // ════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: danger,
        brightness: Brightness.dark,
      ),

      // Text
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w900),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w900),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w800),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w800),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w700),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w600),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: darkTextSecondary, fontWeight: FontWeight.w500),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: darkTextHint),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w700),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: darkBorder, width: borderWidth)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: darkTextPrimary),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: darkBorder, width: borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: darkBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: darkBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: borderWidth + 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: borderWidth + 1),
        ),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.inter(color: darkTextHint, fontSize: 14),
        prefixIconColor: darkTextPrimary,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: BorderSide(color: darkBorder, width: borderWidth),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextPrimary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: warning,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: darkBorder, width: borderWidth),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: darkBorder, thickness: borderWidth, space: 0),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: darkBorder, width: borderWidth),
        ),
        backgroundColor: darkSurface,
        elevation: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: primary, width: borderWidth),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: darkBorder, width: 1.5),
        ),
      ),

      // NavigationBar (for bottom nav in dark mode)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primary.withValues(alpha: 0.2),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Dark-mode-aware helpers
  // ════════════════════════════════════════════════════════════════
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color bgColor(BuildContext context) =>
      isDark(context) ? darkBg : background;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : Colors.black;

  static Color textColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color secondaryTextColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color hintColor(BuildContext context) =>
      isDark(context) ? darkTextHint : textHint;

  static Color surfaceVariantColor(BuildContext context) =>
      isDark(context) ? darkSurfaceVariant : surfaceVariant;

  static Color sidebarColor(BuildContext context) =>
      isDark(context) ? darkSidebarBg : sidebarBg;

  static List<BoxShadow> adaptiveShadow(BuildContext context) =>
      isDark(context) ? darkCardShadow : cardShadow;

  static List<BoxShadow> adaptiveSoftShadow(BuildContext context) =>
      isDark(context) ? darkSoftShadow : softShadow;
}
