import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Tokens ──────────────────────────────────────────────
  static const String currencySymbol = 'Rs.';
  static const Color primary = Color(0xFF4D7CFF); // High-contrast Blue
  static const Color primaryLight = Color(0xFFC2D2FF);
  static const Color primaryDark = Color(0xFF2E5EDD);

  static const Color background = Color(0xFFFCFCFC); // Off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F4FF);

  static const Color textPrimary = Color(0xFF000000); // Pure Black
  static const Color textSecondary = Color(0xFF333333);
  static const Color textHint = Color(0xFF666666);

  static const Color success = Color(0xFF00FFBD); // Neo Green
  static const Color successLight = Color(0xFFD0FFF2);
  static const Color warning = Color(0xFFFAD21B); // Gumroad Yellow
  static const Color warningLight = Color(0xFFFFF7D6);
  static const Color danger = Color(0xFFFF5C5C); // Solid Red
  static const Color dangerLight = Color(0xFFFFE5E5);

  static const Color info = Color(0xFF00D1FF); // Cyan-ish Blue
  static const Color infoLight = Color(0xFFE0FAFF);

  static const Color divider = Color(0xFF000000); // Black for borders
  static const Color shadow = Color(0xFF000000);

  // ── Radii ─────────────────────────────────────────────────────
  static const double radiusSm = 2;
  static const double radiusMd = 4; // Slightly rounded
  static const double radiusLg = 4;
  static const double radiusXl = 4;
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
  static const Color sidebarBg = Color(0xFF000000); // Black Sidebar
  static const Color sidebarActiveItem = primary;
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarActiveText = Color(0xFF000000);

  // ── Borders ──────────────────────────────────────────────────
  static const double borderWidth = 2.5;

  // ── Box Shadows (Hard Shadows) ────────────────────────────────
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

  // ── Theme Data ────────────────────────────────────────────────
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
          fontWeight: FontWeight.w900, // Heavier
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
        ).copyWith(
          // Simulate press effect by shifting shadow? Hard to do in pure styleFrom
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

}
